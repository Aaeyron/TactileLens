import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from PIL import Image

from services.braille.braille_translation_service import BrailleTranslationService
from services.ocr.official_api_client import (
    DailyPageCounter,
    HostedOcrQuotaExceeded,
    HttpResponse,
    OfficialApiClient,
)
from services.ocr.paddleocr_vl_service import PaddleOcrVlService
from services.ocr.test_official_api_client import (
    FakeClock,
    FakeTransport,
    JOB_URL,
    TOKEN,
    fixture,
)

try:
    BrailleTranslationService()
    _LIBLOUIS = True
except FileNotFoundError:
    _LIBLOUIS = False

LOCAL_RESULT_KEYS = {
    "success",
    "model",
    "pipeline_version",
    "device",
    "page_count",
    "blocks",
    "pages",
    "processing_time_ms",
    "timings",
}


class EngineChoiceTests(unittest.TestCase):
    def test_an_unknown_engine_stops_startup(self):
        with mock.patch.dict(os.environ, {"PADDLEOCR_ENGINE": "cloud"}):
            with self.assertRaises(ValueError) as context:
                PaddleOcrVlService()

        self.assertIn("local, official_api", str(context.exception))

    @unittest.skipUnless(_LIBLOUIS, "Liblouis runtime not installed")
    def test_official_api_starts_without_paddle(self):
        with mock.patch.dict(
            os.environ,
            {"PADDLEOCR_ENGINE": "official_api", "PADDLEOCR_ACCESS_TOKEN": TOKEN},
        ):
            service = PaddleOcrVlService()

        self.assertEqual(service.engine, "official_api")
        self.assertEqual(service.device, "official_api")
        self.assertEqual(service.model_name, "PaddleOCR-VL-1.6")
        self.assertFalse(hasattr(service, "_pipeline"))

    @unittest.skipUnless(_LIBLOUIS, "Liblouis runtime not installed")
    def test_official_api_without_a_token_stops_startup(self):
        with mock.patch.dict(
            os.environ,
            {"PADDLEOCR_ENGINE": "official_api", "PADDLEOCR_ACCESS_TOKEN": ""},
        ):
            with self.assertRaises(ValueError):
                PaddleOcrVlService()


@unittest.skipUnless(_LIBLOUIS, "Liblouis runtime not installed")
class OfficialApiScanTests(unittest.TestCase):
    def setUp(self):
        with mock.patch.dict(
            os.environ,
            {"PADDLEOCR_ENGINE": "official_api", "PADDLEOCR_ACCESS_TOKEN": TOKEN},
        ):
            self.service = PaddleOcrVlService()

        self.directory = tempfile.TemporaryDirectory()
        self.image = Path(self.directory.name) / "upload.png"
        Image.new("RGB", (305, 228), "white").save(self.image)

    def tearDown(self):
        self.directory.cleanup()

    def use(self, transport, cap=100):
        clock = FakeClock()
        self.service._api_client = OfficialApiClient(
            token=TOKEN,
            page_counter=DailyPageCounter(daily_cap=cap),
            job_url=JOB_URL,
            transport=transport,
            clock=clock,
            sleep=clock.sleep,
        )

    def test_a_scan_has_the_same_shape_as_the_local_engine(self):
        self.use(FakeTransport())

        result = self.service.scan_document(self.image)

        self.assertEqual(set(result), LOCAL_RESULT_KEYS)
        self.assertEqual(result["device"], "official_api")
        self.assertEqual(result["page_count"], 1)
        self.assertEqual(len(result["blocks"]), 6)
        self.assertEqual(sum(block["is_formula"] for block in result["blocks"]), 5)
        self.assertTrue(all(block["braille_success"] for block in result["blocks"]))
        self.assertFalse(any(block["needs_review"] for block in result["blocks"]))
        self.assertNotIn("http", json.dumps(result))

    def test_the_table_response_keeps_blanks_and_gets_an_order(self):
        self.use(
            FakeTransport(
                download=HttpResponse(200, fixture("official_api_03_table.jsonl"))
            )
        )

        block = self.service.scan_document(self.image)["blocks"][0]

        self.assertTrue(block["is_table"])
        self.assertEqual(block["order"], 1)
        self.assertEqual(block["table_rows"][1], ["Output", "B", "", "", "", ""])
        self.assertIn("Row 2: Output; B; blank; blank; blank; blank", block["content"])

    def test_hosted_errors_reach_the_app_and_temporary_files_are_removed(self):
        self.use(FakeTransport(), cap=1)
        self.service.scan_document(self.image)

        temporary = Path(tempfile.gettempdir())
        before = set(temporary.glob("tactilelens_ocr_*"))

        with self.assertRaises(HostedOcrQuotaExceeded):
            self.service.scan_document(self.image)

        self.assertEqual(set(temporary.glob("tactilelens_ocr_*")), before)


if __name__ == "__main__":
    unittest.main()
