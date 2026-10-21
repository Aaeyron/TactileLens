import json
import logging
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from services.official_api_client import (
    BAIDU_DAILY_PAGE_LIMIT,
    DailyPageCounter,
    HostedOcrError,
    HostedOcrJobFailed,
    HostedOcrQuotaExceeded,
    HostedOcrTimeout,
    HostedOcrUnavailable,
    HttpResponse,
    OfficialApiClient,
    TransportError,
)

FIXTURES = Path(__file__).resolve().parent / "fixtures"
JOB_URL = "https://ocr.example.invalid/api/v2/ocr/jobs"
RESULT_URL = "https://files.example.invalid/result.jsonl"
TOKEN = "fake-token-for-tests-0123456789"


def fixture(name: str) -> bytes:
    return (FIXTURES / name).read_bytes()


def _json(status: int, payload) -> HttpResponse:
    return HttpResponse(status, json.dumps(payload).encode())


def _state(state: str, **extra) -> HttpResponse:
    return _json(200, {"code": 0, "msg": "Success", "data": {"state": state, **extra}})


SUBMITTED = _json(200, {"code": 0, "msg": "Success", "data": {"jobId": "job-1"}})
DONE = _state("done", resultUrl={"jsonUrl": RESULT_URL, "markdownUrl": "x"})


class FakeTransport:
    """Scripted Baidu. Records every request; never touches the network."""

    def __init__(self, submit=SUBMITTED, polls=(DONE,), download=None):
        self.submit = submit
        self.polls = list(polls)
        self.download = download or HttpResponse(200, fixture("official_api_02_algebra.jsonl"))
        self.calls: list[tuple[str, str, dict]] = []

    def __call__(self, method, url, headers, body, timeout):
        self.calls.append((method, url, dict(headers)))

        if method == "POST":
            if isinstance(self.submit, Exception):
                raise self.submit
            return self.submit

        if url == RESULT_URL:
            if isinstance(self.download, Exception):
                raise self.download
            return self.download

        response = self.polls.pop(0) if len(self.polls) > 1 else self.polls[0]

        if isinstance(response, Exception):
            raise response
        return response

    def count(self, method):
        return sum(call[0] == method for call in self.calls)


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


def _client(transport, cap=100, deadline=150.0, counter=None):
    clock = FakeClock()
    return OfficialApiClient(
        token=TOKEN,
        page_counter=counter or DailyPageCounter(daily_cap=cap),
        job_url=JOB_URL,
        deadline_seconds=deadline,
        poll_seconds=2.0,
        transport=transport,
        clock=clock,
        sleep=clock.sleep,
    )


def _parse(client):
    return client.parse_document(b"\xff\xd8\xff fake jpeg", "page.jpg")


class ReplayTests(unittest.TestCase):
    def test_replays_the_02_algebra_response(self):
        transport = FakeTransport(polls=(_state("pending"), _state("running"), DONE))

        pages = _parse(_client(transport))

        self.assertEqual(len(pages), 1)
        self.assertEqual((pages[0]["width"], pages[0]["height"]), (305, 228))
        labels = [block["block_label"] for block in pages[0]["parsing_res_list"]]
        self.assertEqual(labels, ["text"] + ["display_formula"] * 5)

        self.assertEqual(transport.count("POST"), 1)
        self.assertEqual(transport.count("GET"), 4)  # three polls + download

    def test_replays_the_03_table_response(self):
        transport = FakeTransport(
            download=HttpResponse(200, fixture("official_api_03_table.jsonl"))
        )

        block = _parse(_client(transport))[0]["parsing_res_list"][0]

        self.assertEqual(block["block_label"], "table")
        self.assertIsNone(block["block_order"])

    def test_token_only_goes_in_the_authorization_header_to_baidu(self):
        transport = FakeTransport()
        _parse(_client(transport))

        for method, url, headers in transport.calls:
            if url == RESULT_URL:
                self.assertNotIn("Authorization", headers)
            else:
                self.assertEqual(headers["Authorization"], f"bearer {TOKEN}")

    def test_image_links_and_extra_fields_are_dropped(self):
        line = json.loads(fixture("official_api_02_algebra.jsonl"))
        layout = line["result"]["layoutParsingResults"][0]
        layout["inputImage"] = "https://files.example.invalid/input.jpg"
        layout["outputImages"] = {"layout": "https://files.example.invalid/l.jpg"}
        layout["markdown"] = {"text": "x", "images": {"a.jpg": "https://files.example.invalid/a.jpg"}}
        layout["prunedResult"]["layout_det_res"] = {"boxes": []}
        layout["prunedResult"]["parsing_res_list"][0]["extra"] = "https://files.example.invalid/b"
        line["logId"] = "log-1"
        line["result"]["preprocessedImages"] = ["https://files.example.invalid/p.jpg"]

        transport = FakeTransport(download=HttpResponse(200, json.dumps(line).encode()))
        pages = _parse(_client(transport))

        dumped = json.dumps(pages)
        self.assertNotIn("http", dumped)
        self.assertNotIn("layout_det_res", dumped)
        self.assertEqual(set(pages[0]), {"width", "height", "parsing_res_list"})

    def test_fixtures_contain_no_links(self):
        for path in FIXTURES.glob("official_api_*.jsonl"):
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertNotIn("http", text)
                self.assertNotIn("logId", text)


class NoResubmitTests(unittest.TestCase):
    def test_a_network_error_on_submit_is_not_retried(self):
        transport = FakeTransport(submit=TransportError("URLError"))
        counter = DailyPageCounter(daily_cap=10)

        with self.assertRaises(HostedOcrUnavailable):
            _parse(_client(transport, counter=counter))

        self.assertEqual(transport.count("POST"), 1)
        self.assertEqual(transport.count("GET"), 0)
        # The page may have reached Baidu, so it stays counted.
        self.assertEqual(counter.pages_today, 1)

    def test_a_poll_network_error_keeps_polling_the_same_job(self):
        transport = FakeTransport(polls=(TransportError("timeout"), _state("running"), DONE))

        pages = _parse(_client(transport))

        self.assertTrue(pages)
        self.assertEqual(transport.count("POST"), 1)

    def test_the_deadline_gives_a_timeout_and_no_new_job(self):
        transport = FakeTransport(polls=(_state("running"),))

        with self.assertRaises(HostedOcrTimeout):
            _parse(_client(transport, deadline=10))

        self.assertEqual(transport.count("POST"), 1)


class ErrorMappingTests(unittest.TestCase):
    def assert_submit_error(self, response, error_type):
        transport = FakeTransport(submit=response)

        with self.assertRaises(error_type) as context:
            _parse(_client(transport))

        self.assertEqual(transport.count("POST"), 1)
        return context.exception

    def test_quota(self):
        for response in (
            _json(429, {"code": 12002, "msg": "Request frequency too high"}),
            _json(403, {"code": 12001, "msg": "Daily page limit reached"}),
            _json(429, {"code": 429, "msg": "Exceeded maximum daily parsing page count"}),
        ):
            with self.subTest(response=response):
                self.assert_submit_error(response, HostedOcrQuotaExceeded)

    def test_outage_and_login(self):
        for response in (
            _json(503, {"code": 503, "msg": "Too many current requests"}),
            _json(500, {"code": 500, "msg": "System Error"}),
            _json(200, {"code": 10010, "msg": "Job submission queue is full"}),
            _json(401, {"code": 401, "msg": "Unauthorized"}),
            HttpResponse(502, b"<html>bad gateway</html>"),
        ):
            with self.subTest(response=response):
                self.assert_submit_error(response, HostedOcrUnavailable)

    def test_rejected_image(self):
        self.assert_submit_error(
            _json(400, {"code": 10004, "msg": "File format not supported"}),
            HostedOcrJobFailed,
        )

    def test_failed_and_missing_jobs(self):
        for polls in (
            (_state("failed", errorMsg="Parsing failed"),),
            (_json(404, {"code": 11001, "msg": "jobId does not exist"}),),
            (_state("done"),),  # no result link
        ):
            with self.subTest(polls=polls):
                with self.assertRaises(HostedOcrJobFailed):
                    _parse(_client(FakeTransport(polls=polls)))

    def test_download_problems(self):
        for download, error_type in (
            (HttpResponse(403, b"denied"), HostedOcrUnavailable),
            (TransportError("reset"), HostedOcrUnavailable),
            (HttpResponse(200, b"not json"), HostedOcrJobFailed),
            (HttpResponse(200, b'{"result": {"layoutParsingResults": []}}'), HostedOcrJobFailed),
        ):
            with self.subTest(download=download):
                with self.assertRaises(error_type):
                    _parse(_client(FakeTransport(download=download)))

    def test_http_status_for_each_error(self):
        self.assertEqual(
            {
                error.code: error.status_code
                for error in (
                    HostedOcrQuotaExceeded(),
                    HostedOcrUnavailable(),
                    HostedOcrJobFailed(),
                    HostedOcrTimeout(),
                )
            },
            {
                "hosted_ocr_quota": 503,
                "hosted_ocr_unavailable": 503,
                "hosted_ocr_failed": 502,
                "hosted_ocr_timeout": 504,
            },
        )


class TokenSecrecyTests(unittest.TestCase):
    def test_the_token_never_appears_in_errors_repr_or_logs(self):
        cases = (
            FakeTransport(submit=TransportError("URLError")),
            FakeTransport(submit=_json(401, {"code": 401, "msg": "Unauthorized"})),
            FakeTransport(polls=(_state("failed", errorMsg="bad"),)),
            FakeTransport(polls=(_state("running"),)),
            FakeTransport(),
        )

        with self.assertLogs("tactilelens.ai", level=logging.DEBUG) as logs:
            logging.getLogger("tactilelens.ai").info("start")

            for transport in cases:
                client = _client(transport, deadline=6)
                self.assertNotIn(TOKEN, repr(client))

                try:
                    _parse(client)
                except HostedOcrError as error:
                    self.assertNotIn(TOKEN, str(error))
                    self.assertNotIn(TOKEN, repr(error))

        self.assertNotIn(TOKEN, "\n".join(logs.output))


class DailyCapTests(unittest.TestCase):
    def test_the_cap_stops_submissions_before_baidu_is_called(self):
        transport = FakeTransport()
        client = _client(transport, cap=2)

        _parse(client)
        _parse(client)

        with self.assertRaises(HostedOcrQuotaExceeded):
            _parse(client)

        self.assertEqual(transport.count("POST"), 2)

    def test_the_count_resets_on_a_new_day(self):
        day = ["2026-10-22"]
        counter = DailyPageCounter(daily_cap=1, today=lambda: day[0])

        counter.reserve()
        with self.assertRaises(HostedOcrQuotaExceeded):
            counter.reserve()

        day[0] = "2026-10-23"
        counter.reserve()
        self.assertEqual(counter.pages_today, 1)

    def test_the_count_survives_a_restart_with_a_state_file(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / "pages.json"
            today = lambda: "2026-10-22"  # noqa: E731

            DailyPageCounter(daily_cap=5, state_file=state, today=today).reserve(3)
            restarted = DailyPageCounter(daily_cap=5, state_file=state, today=today)

            self.assertEqual(restarted.pages_today, 3)

            tomorrow = DailyPageCounter(
                daily_cap=5, state_file=state, today=lambda: "2026-10-23"
            )
            self.assertEqual(tomorrow.pages_today, 0)

            state.write_text("not json", encoding="utf-8")
            with self.assertLogs("tactilelens.ai", level="WARNING"):
                broken = DailyPageCounter(daily_cap=5, state_file=state, today=today)
            self.assertEqual(broken.pages_today, 0)

    def test_the_cap_must_stay_below_baidus_limit(self):
        for cap in (0, -1, BAIDU_DAILY_PAGE_LIMIT, 5000):
            with self.subTest(cap=cap):
                with self.assertRaises(ValueError):
                    DailyPageCounter(daily_cap=cap)

        DailyPageCounter(daily_cap=BAIDU_DAILY_PAGE_LIMIT - 1)


class EnvironmentTests(unittest.TestCase):
    def test_settings_come_from_the_environment(self):
        with mock.patch.dict(
            os.environ,
            {
                "PADDLEOCR_ACCESS_TOKEN": TOKEN,
                "PADDLEOCR_DAILY_PAGE_CAP": "1200",
                "PADDLEOCR_API_DEADLINE_SECONDS": "90",
            },
        ):
            client = OfficialApiClient.from_environment()

        self.assertEqual(client.page_counter.daily_cap, 1200)
        self.assertEqual(client.deadline_seconds, 90.0)
        self.assertEqual(client.model, "PaddleOCR-VL-1.6")

    def test_defaults_keep_the_cap_below_the_limit(self):
        with mock.patch.dict(os.environ, {"PADDLEOCR_ACCESS_TOKEN": TOKEN}, clear=False):
            os.environ.pop("PADDLEOCR_DAILY_PAGE_CAP", None)
            client = OfficialApiClient.from_environment()

        self.assertEqual(client.page_counter.daily_cap, 2500)

    def test_a_missing_token_or_bad_cap_stops_startup(self):
        for environment in (
            {"PADDLEOCR_ACCESS_TOKEN": ""},
            {"PADDLEOCR_ACCESS_TOKEN": TOKEN, "PADDLEOCR_DAILY_PAGE_CAP": "3000"},
        ):
            with self.subTest(environment=environment):
                with mock.patch.dict(os.environ, environment):
                    with self.assertRaises(ValueError):
                        OfficialApiClient.from_environment()


if __name__ == "__main__":
    unittest.main()
