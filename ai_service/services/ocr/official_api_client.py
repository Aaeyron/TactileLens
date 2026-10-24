"""Client for PaddleOCR's official hosted API (Baidu AI Studio).

Used when PADDLEOCR_ENGINE=official_api. It sends one prepared image as an
asynchronous job, polls it, downloads the JSON Lines result and returns
only the page data the serializer reads (prunedResult with its block
fields). Everything else, including Baidu's image links, is dropped and
never stored, logged or returned.

Rules:
- The access token is a server-side secret from PADDLEOCR_ACCESS_TOKEN.
  It is only placed in the Authorization header; it is never logged,
  returned or included in an error.
- A job is submitted at most once. Nothing is resubmitted after a
  failure, including a network error during submit. Polling the same job
  again is not a resubmission.
- A daily page cap, kept below Baidu's 3,000 pages per day, stops
  submissions before Baidu's own limit is reached.

Uses only the standard library.
"""

import json
import logging
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable

logger = logging.getLogger("tactilelens.ai")

DEFAULT_JOB_URL = "https://paddleocr.aistudio-app.com/api/v2/ocr/jobs"
DEFAULT_MODEL = "PaddleOCR-VL-1.6"
DEFAULT_AUTH_SCHEME = "bearer"

# Provisional until the remaining timing runs; see the Phase 2 plan.
DEFAULT_DEADLINE_SECONDS = 150.0
DEFAULT_POLL_SECONDS = 2.0
REQUEST_TIMEOUT_SECONDS = 30.0

BAIDU_DAILY_PAGE_LIMIT = 3000
DEFAULT_DAILY_PAGE_CAP = 2500

# Baidu counts days in China Standard Time (UTC+8), as does the
# Philippines.
QUOTA_TIMEZONE = timezone(timedelta(hours=8))

# Same options as the official async sample; layout detection is on by
# default, orientation correction and unwarping are off as in the local
# engine.
OPTIONAL_PAYLOAD = {
    "useDocOrientationClassify": False,
    "useDocUnwarping": False,
    "useChartRecognition": False,
}

PAGE_FIELDS = ("width", "height", "page_index")
BLOCK_FIELDS = (
    "block_label",
    "block_content",
    "block_bbox",
    "block_polygon_points",
    "block_id",
    "block_order",
)

# Baidu error codes (async API guide and quota page).
QUOTA_CODES = frozenset({12001, 12002})
UNAVAILABLE_CODES = frozenset({10010})
JOB_GONE_CODES = frozenset({11001, 11002, 11003})


# ==========================
# Errors
# ==========================


class HostedOcrError(Exception):
    """Base error. status_code and code are what the AI service returns."""

    status_code = 502
    code = "hosted_ocr_error"
    public_message = "The online OCR service could not process the image."


class HostedOcrQuotaExceeded(HostedOcrError):
    status_code = 503
    code = "hosted_ocr_quota"
    public_message = "The online OCR limit for today has been reached."


class HostedOcrUnavailable(HostedOcrError):
    status_code = 503
    code = "hosted_ocr_unavailable"
    public_message = "The online OCR service is unavailable."


class HostedOcrJobFailed(HostedOcrError):
    status_code = 502
    code = "hosted_ocr_failed"
    public_message = "The online OCR service could not read the image."


class HostedOcrTimeout(HostedOcrError):
    status_code = 504
    code = "hosted_ocr_timeout"
    public_message = "The online OCR service took too long."


# ==========================
# HTTP
# ==========================


@dataclass(frozen=True)
class HttpResponse:
    status: int
    body: bytes

    def json(self) -> Any:
        try:
            return json.loads(self.body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None


class TransportError(Exception):
    """No HTTP response at all (DNS, connection, timeout)."""


Transport = Callable[[str, str, dict[str, str], bytes | None, float], HttpResponse]


def urllib_transport(
    method: str,
    url: str,
    headers: dict[str, str],
    body: bytes | None,
    timeout: float,
) -> HttpResponse:
    request = urllib.request.Request(url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return HttpResponse(response.status, response.read())
    except urllib.error.HTTPError as error:
        return HttpResponse(error.code, error.read())
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        # The message names the host and the reason, never the headers.
        raise TransportError(type(error).__name__) from None


# ==========================
# Daily page cap
# ==========================


class DailyPageCounter:
    """Pages submitted today, shared by every request in this process.

    With PADDLEOCR_PAGE_COUNT_FILE set, the count survives restarts.
    Each process keeps its own count, so run one AI service instance.
    """

    def __init__(
        self,
        daily_cap: int,
        state_file: Path | None = None,
        today: Callable[[], str] | None = None,
    ) -> None:
        if not 0 < daily_cap < BAIDU_DAILY_PAGE_LIMIT:
            raise ValueError(
                "PADDLEOCR_DAILY_PAGE_CAP must be between 1 and "
                f"{BAIDU_DAILY_PAGE_LIMIT - 1}."
            )

        self.daily_cap = daily_cap
        self._state_file = state_file
        self._today = today or (
            lambda: datetime.now(QUOTA_TIMEZONE).date().isoformat()
        )
        self._lock = threading.Lock()
        self._day, self._pages = self._load()

    def reserve(self, pages: int = 1) -> int:
        """Count pages before submitting. Raises when the cap is reached."""

        with self._lock:
            self._roll_over()

            if self._pages + pages > self.daily_cap:
                raise HostedOcrQuotaExceeded(
                    f"Daily page cap of {self.daily_cap} reached."
                )

            self._pages += pages
            self._save()

            return self._pages

    @property
    def pages_today(self) -> int:
        with self._lock:
            self._roll_over()
            return self._pages

    def _roll_over(self) -> None:
        today = self._today()

        if today != self._day:
            self._day, self._pages = today, 0

    def _load(self) -> tuple[str, int]:
        today = self._today()

        if self._state_file is None or not self._state_file.is_file():
            return today, 0

        try:
            state = json.loads(self._state_file.read_text(encoding="utf-8"))
            day, pages = str(state["day"]), int(state["pages"])
        except (OSError, ValueError, KeyError, TypeError):
            logger.warning("Page counter file unreadable; starting from 0.")
            return today, 0

        return (day, pages) if day == today else (today, 0)

    def _save(self) -> None:
        if self._state_file is None:
            return

        try:
            self._state_file.write_text(
                json.dumps({"day": self._day, "pages": self._pages}),
                encoding="utf-8",
            )
        except OSError:
            logger.warning("Could not save the page counter file.")


# ==========================
# Client
# ==========================


class OfficialApiClient:
    def __init__(
        self,
        *,
        token: str,
        page_counter: DailyPageCounter,
        job_url: str = DEFAULT_JOB_URL,
        model: str = DEFAULT_MODEL,
        auth_scheme: str = DEFAULT_AUTH_SCHEME,
        deadline_seconds: float = DEFAULT_DEADLINE_SECONDS,
        poll_seconds: float = DEFAULT_POLL_SECONDS,
        transport: Transport = urllib_transport,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        if not token:
            raise ValueError("PADDLEOCR_ACCESS_TOKEN is not set.")

        self._token = token
        self.page_counter = page_counter
        self.job_url = job_url
        self.model = model
        self.auth_scheme = auth_scheme
        self.deadline_seconds = deadline_seconds
        self.poll_seconds = poll_seconds
        self._transport = transport
        self._clock = clock
        self._sleep = sleep

    def __repr__(self) -> str:
        # Never show the token.
        return f"OfficialApiClient(model={self.model!r}, job_url={self.job_url!r})"

    @classmethod
    def from_environment(cls) -> "OfficialApiClient":
        state_file = os.getenv("PADDLEOCR_PAGE_COUNT_FILE", "").strip()

        return cls(
            token=os.getenv("PADDLEOCR_ACCESS_TOKEN", "").strip(),
            page_counter=DailyPageCounter(
                daily_cap=int(
                    os.getenv("PADDLEOCR_DAILY_PAGE_CAP", str(DEFAULT_DAILY_PAGE_CAP))
                ),
                state_file=Path(state_file) if state_file else None,
            ),
            job_url=os.getenv("PADDLEOCR_API_URL", DEFAULT_JOB_URL),
            model=os.getenv("PADDLEOCR_API_MODEL", DEFAULT_MODEL),
            auth_scheme=os.getenv("PADDLEOCR_API_AUTH_SCHEME", DEFAULT_AUTH_SCHEME),
            deadline_seconds=float(
                os.getenv(
                    "PADDLEOCR_API_DEADLINE_SECONDS", str(DEFAULT_DEADLINE_SECONDS)
                )
            ),
        )

    def parse_document(self, image_bytes: bytes, file_name: str) -> list[dict[str, Any]]:
        """Run one image through the hosted pipeline. Returns page dicts
        shaped like the local engine's result JSON."""

        started = self._clock()
        self.page_counter.reserve(1)

        job_id = self._submit(image_bytes, file_name)
        json_url = self._wait_for_result(job_id, started)
        pages = self._download_pages(job_id, json_url)

        logger.info(
            "Hosted OCR job %s finished in %.1f s (%d page(s), %d of %d pages today).",
            job_id,
            self._clock() - started,
            len(pages),
            self.page_counter.pages_today,
            self.page_counter.daily_cap,
        )

        return pages

    # ---------- submit ----------

    def _submit(self, image_bytes: bytes, file_name: str) -> str:
        body, content_type = _multipart(
            {"model": self.model, "optionalPayload": json.dumps(OPTIONAL_PAYLOAD)},
            file_name,
            image_bytes,
        )
        headers = self._headers()
        headers["Content-Type"] = content_type

        try:
            response = self._transport(
                "POST", self.job_url, headers, body, REQUEST_TIMEOUT_SECONDS
            )
        except TransportError as error:
            # The request may have reached Baidu. It is never resent.
            raise HostedOcrUnavailable(f"Submit failed ({error}); not retried.") from None

        payload = response.json()

        if not isinstance(payload, dict):
            payload = {}

        job_id = (payload.get("data") or {}).get("jobId")

        if response.status == 200 and payload.get("code") == 0 and job_id:
            return str(job_id)

        raise _error_for(response.status, payload, "submit")

    # ---------- poll ----------

    def _wait_for_result(self, job_id: str, started: float) -> str:
        url = f"{self.job_url}/{urllib.parse.quote(job_id, safe='')}"

        while True:
            if self._clock() - started > self.deadline_seconds:
                raise HostedOcrTimeout(
                    f"Job {job_id} not finished after {self.deadline_seconds:.0f} s."
                )

            try:
                response = self._transport(
                    "GET", url, self._headers(), None, REQUEST_TIMEOUT_SECONDS
                )
            except TransportError:
                # Asking about the same job again is safe; keep polling.
                self._sleep(self.poll_seconds)
                continue

            payload = response.json()

            if not isinstance(payload, dict):
                payload = {}

            if response.status != 200 or payload.get("code") != 0:
                raise _error_for(response.status, payload, f"job {job_id}")

            data = payload.get("data") or {}
            state = data.get("state")

            if state == "done":
                json_url = (data.get("resultUrl") or {}).get("jsonUrl")

                if not json_url:
                    raise HostedOcrJobFailed(f"Job {job_id} finished without a result.")

                return json_url

            if state == "failed":
                raise HostedOcrJobFailed(
                    f"Job {job_id} failed: {data.get('errorMsg') or 'no reason given'}"
                )

            self._sleep(self.poll_seconds)

    # ---------- result ----------

    def _download_pages(self, job_id: str, json_url: str) -> list[dict[str, Any]]:
        # The official sample downloads the result without the token.
        try:
            response = self._transport("GET", json_url, {}, None, REQUEST_TIMEOUT_SECONDS)
        except TransportError:
            raise HostedOcrUnavailable(
                f"Result of job {job_id} could not be downloaded."
            ) from None

        if response.status != 200:
            raise HostedOcrUnavailable(
                f"Result of job {job_id} could not be downloaded (HTTP {response.status})."
            )

        pages = _pages_from_jsonl(response.body)

        if not pages:
            raise HostedOcrJobFailed(f"Result of job {job_id} contained no pages.")

        return pages

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"{self.auth_scheme} {self._token}"}


# ==========================
# Helpers
# ==========================


def _error_for(status: int, payload: Any, context: str) -> HostedOcrError:
    code = payload.get("code") if isinstance(payload, dict) else None
    message = payload.get("msg") if isinstance(payload, dict) else None
    detail = f"{context}: HTTP {status}, code {code}, {message or 'no message'}"

    if status == 429 or code in QUOTA_CODES:
        return HostedOcrQuotaExceeded(detail)

    if code in JOB_GONE_CODES:
        return HostedOcrJobFailed(detail)

    if status in (401, 403) or status >= 500 or code in UNAVAILABLE_CODES:
        return HostedOcrUnavailable(detail)

    # Other 4xx: Baidu rejected this image (size, format, parameters).
    return HostedOcrJobFailed(detail)


def _multipart(
    fields: dict[str, str],
    file_name: str,
    file_bytes: bytes,
) -> tuple[bytes, str]:
    boundary = f"----tactilelens{uuid.uuid4().hex}"
    parts: list[bytes] = []

    for key, value in fields.items():
        parts += [
            f"--{boundary}".encode(),
            f'Content-Disposition: form-data; name="{key}"'.encode(),
            b"",
            value.encode("utf-8"),
        ]

    parts += [
        f"--{boundary}".encode(),
        f'Content-Disposition: form-data; name="file"; filename="{file_name}"'.encode(),
        b"Content-Type: image/jpeg",
        b"",
        file_bytes,
        f"--{boundary}--".encode(),
        b"",
    ]

    return b"\r\n".join(parts), f"multipart/form-data; boundary={boundary}"


def _pages_from_jsonl(body: bytes) -> list[dict[str, Any]]:
    """Keep only the page size and block fields of each prunedResult."""

    pages: list[dict[str, Any]] = []

    try:
        text = body.decode("utf-8")
    except UnicodeDecodeError:
        return pages

    for line in text.splitlines():
        if not line.strip():
            continue

        try:
            result = json.loads(line).get("result") or {}
        except (json.JSONDecodeError, AttributeError):
            continue

        for layout in result.get("layoutParsingResults") or []:
            pruned = layout.get("prunedResult") if isinstance(layout, dict) else None

            if not isinstance(pruned, dict):
                continue

            page = {field: pruned[field] for field in PAGE_FIELDS if field in pruned}
            page["parsing_res_list"] = [
                {field: block[field] for field in BLOCK_FIELDS if field in block}
                for block in pruned.get("parsing_res_list") or []
                if isinstance(block, dict)
            ]
            pages.append(page)

    return pages
