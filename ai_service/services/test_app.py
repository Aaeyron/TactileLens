"""app.py through FastAPI's test client.

Runs where FastAPI is installed (ai_service/.venv) and is skipped
elsewhere. The token is fake, the API URL points at a closed local port
and every scan goes to a scripted fake, so nothing can reach Baidu.
"""

import importlib
import io
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from services.braille.braille_translation_service import BrailleTranslationService
from services.ocr.official_api_client import (
    DailyPageCounter,
    OfficialApiClient,
)
from services.ocr.test_official_api_client import (
    TOKEN,
    FakeClock,
    FakeTransport,
    _json,
    _state,
)

try:
    from fastapi.testclient import TestClient
except ImportError:
    TestClient = None

try:
    BrailleTranslationService()
    _LIBLOUIS = True
except FileNotFoundError:
    _LIBLOUIS = False

SERVICE_KEY = "test-service-key-not-real"

ENVIRONMENT = {
    "PADDLEOCR_ENGINE": "official_api",
    "PADDLEOCR_ACCESS_TOKEN": TOKEN,
    "PADDLEOCR_API_URL": "http://127.0.0.1:9/never-baidu",
    "PADDLEOCR_DAILY_PAGE_CAP": "100",
    "PADDLEOCR_PAGE_COUNT_FILE": "",
    "AI_SERVICE_SECRET": SERVICE_KEY,
}

KEY = {"X-Service-Key": SERVICE_KEY}


def _png() -> bytes:
    buffer = io.BytesIO()
    Image.new("RGB", (305, 228), "white").save(buffer, format="PNG")
    return buffer.getvalue()


@unittest.skipIf(TestClient is None, "FastAPI is not installed (use ai_service/.venv)")
@unittest.skipUnless(_LIBLOUIS, "Liblouis runtime not installed")
class AppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._environment = mock.patch.dict(os.environ, ENVIRONMENT)
        cls._environment.start()

        # app.py reads AI_SERVICE_SECRET when it is imported.
        import app as app_module

        cls.app_module = importlib.reload(app_module)
        cls.client = TestClient(cls.app_module.app)
        cls.client.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.client.__exit__(None, None, None)
        cls._environment.stop()

    def use_baidu(self, transport):
        clock = FakeClock()
        self.transport = transport
        self.app_module.app.state.ocr_service._api_client = OfficialApiClient(
            token=TOKEN,
            page_counter=DailyPageCounter(daily_cap=100),
            job_url=ENVIRONMENT["PADDLEOCR_API_URL"],
            transport=transport,
            clock=clock,
            sleep=clock.sleep,
        )

    def scan(self, headers=KEY, data=None, name="page.png", content_type="image/png"):
        return self.client.post(
            "/api/scan-document",
            headers=headers,
            files={"image": (name, data if data is not None else _png(), content_type)},
        )

    # ---------- open and closed routes ----------

    def test_health_is_open_and_reports_the_engine(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["engine"], "official_api")
        self.assertEqual(body["device"], "official_api")
        self.assertEqual(body["model"], "PaddleOCR-VL-1.6")
        self.assertTrue(body["ready"])
        self.assertNotIn(TOKEN, response.text)

    def test_every_other_route_needs_the_key(self):
        for method, path, headers in (
            ("POST", "/api/scan-document", {}),
            ("POST", "/api/scan-document", {"X-Service-Key": "wrong"}),
            ("GET", "/docs", {}),
            ("GET", "/openapi.json", {}),
        ):
            with self.subTest(method=method, path=path, headers=headers):
                response = self.client.request(method, path, headers=headers)
                self.assertEqual(response.status_code, 403)
                self.assertEqual(response.json(), {"detail": "Forbidden"})

    def test_the_right_key_without_an_image_is_422(self):
        response = self.client.post("/api/scan-document", headers=KEY)
        self.assertEqual(response.status_code, 422)

    def test_a_file_that_is_not_an_image_is_415_and_never_sent(self):
        self.use_baidu(FakeTransport())

        response = self.scan(data=b"not an image at all")

        self.assertEqual(response.status_code, 415)
        self.assertEqual(self.transport.calls, [])

    # ---------- scans through the fake Baidu ----------

    def test_a_scan_returns_blocks_without_links_or_the_token(self):
        self.use_baidu(FakeTransport())

        response = self.scan()

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["device"], "official_api")
        self.assertEqual(len(body["blocks"]), 6)
        self.assertNotIn(TOKEN, response.text)
        self.assertNotIn("example.invalid", response.text)
        self.assertEqual(sum(call[0] == "POST" for call in self.transport.calls), 1)

    def test_hosted_errors_become_the_agreed_statuses(self):
        cases = (
            (
                FakeTransport(submit=_json(429, {"code": 12002, "msg": "Too frequent"})),
                503,
                "hosted_ocr_quota",
            ),
            (
                FakeTransport(submit=_json(503, {"code": 503, "msg": "Busy"})),
                503,
                "hosted_ocr_unavailable",
            ),
            (
                FakeTransport(polls=(_state("failed", errorMsg="Parsing failed"),)),
                502,
                "hosted_ocr_failed",
            ),
            (
                FakeTransport(polls=(_state("running"),)),
                504,
                "hosted_ocr_timeout",
            ),
        )

        for transport, status, code in cases:
            with self.subTest(code=code):
                self.use_baidu(transport)

                response = self.scan()

                self.assertEqual(response.status_code, status)
                detail = response.json()["detail"]
                self.assertEqual(detail["code"], code)
                self.assertIsInstance(detail["message"], str)
                self.assertNotIn(TOKEN, response.text)
                # One submit at most; never resent.
                self.assertLessEqual(
                    sum(call[0] == "POST" for call in transport.calls), 1
                )

    def test_temporary_uploads_are_removed(self):
        self.use_baidu(FakeTransport())
        uploads = self.app_module.UPLOAD_DIR
        before = set(uploads.glob("*"))
        temporary = Path(tempfile.gettempdir())
        before_prepared = set(temporary.glob("tactilelens_ocr_*"))

        self.scan()
        self.use_baidu(FakeTransport(submit=_json(503, {"code": 503})))
        self.scan()

        self.assertEqual(set(uploads.glob("*")), before)
        self.assertEqual(set(temporary.glob("tactilelens_ocr_*")), before_prepared)


if __name__ == "__main__":
    unittest.main()
