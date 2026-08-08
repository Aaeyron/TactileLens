import logging
import os
import time
from contextlib import asynccontextmanager
from pathlib import Path
from uuid import uuid4

from fastapi import (
    FastAPI,
    File,
    HTTPException,
    UploadFile,
    status,
)
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware

from services.paddleocr_vl_service import PaddleOcrVlService


logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format=(
        "%(asctime)s | %(levelname)s | "
        "%(name)s | %(message)s"
    ),
)

logger = logging.getLogger("tactilelens.ai")

BASE_DIR = Path(__file__).resolve().parent
UPLOAD_DIR = BASE_DIR / "uploads"

MAX_UPLOAD_BYTES = (
    int(os.getenv("MAX_UPLOAD_MB", "20"))
    * 1024
    * 1024
)

ALLOWED_IMAGE_TYPES = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/bmp": ".bmp",
    "image/tiff": ".tiff",
}

ALLOWED_IMAGE_EXTENSIONS = {
    ".jpg": ".jpg",
    ".jpeg": ".jpg",
    ".png": ".png",
    ".webp": ".webp",
    ".bmp": ".bmp",
    ".tif": ".tiff",
    ".tiff": ".tiff",
}


@asynccontextmanager
async def lifespan(app: FastAPI):
    UPLOAD_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    logger.info(
        "Loading PaddleOCR-VL service..."
    )

    app.state.ocr_service = await run_in_threadpool(
        PaddleOcrVlService
    )

    logger.info(
        "PaddleOCR-VL service is ready."
    )

    yield

    app.state.ocr_service = None


app = FastAPI(
    title="TactileLens AI Service",
    description=(
        "Document recognition using the full "
        "PaddleOCR-VL pipeline."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

allowed_origins = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS",
        "*",
    ).split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check() -> dict:
    service: PaddleOcrVlService = (
        app.state.ocr_service
    )

    return {
        "success": True,
        "service": "TactileLens AI Service",
        "model": service.model_name,
        "device": service.device,
        "ready": True,
    }


@app.post("/api/scan-document")
async def scan_document(
    image: UploadFile = File(...),
) -> dict:
    content_type = (
        image.content_type or ""
    ).lower()

    uploaded_filename = image.filename or ""

    uploaded_suffix = Path(
        uploaded_filename
    ).suffix.lower()

    file_extension = ALLOWED_IMAGE_TYPES.get(
        content_type
    )

    if file_extension is None:
        file_extension = (
            ALLOWED_IMAGE_EXTENSIONS.get(
                uploaded_suffix
            )
        )

    if file_extension is None:
        raise HTTPException(
            status_code=(
                status.HTTP_415_UNSUPPORTED_MEDIA_TYPE
            ),
            detail=(
                "Only JPG, JPEG, PNG, WEBP, BMP, "
                "and TIFF images are allowed."
            ),
        )

    logger.info(
        "Receiving image: filename=%s, content_type=%s",
        uploaded_filename,
        content_type or "not provided",
    )

    image_bytes = await image.read(
        MAX_UPLOAD_BYTES + 1
    )

    await image.close()

    if not image_bytes:
        raise HTTPException(
            status_code=(
                status.HTTP_400_BAD_REQUEST
            ),
            detail="The uploaded image is empty.",
        )

    if len(image_bytes) > MAX_UPLOAD_BYTES:
        maximum_size_mb = (
            MAX_UPLOAD_BYTES // (1024 * 1024)
        )

        raise HTTPException(
            status_code=(
                status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
            ),
            detail=(
                "The image must not exceed "
                f"{maximum_size_mb} MB."
            ),
        )

    temporary_path = (
        UPLOAD_DIR
        / f"{uuid4().hex}{file_extension}"
    )

    temporary_path.write_bytes(image_bytes)

    started_at = time.perf_counter()

    try:
        service: PaddleOcrVlService = (
            app.state.ocr_service
        )

        result = await run_in_threadpool(
            service.scan_document,
            temporary_path,
        )

        result["processing_time_ms"] = round(
            (
                time.perf_counter()
                - started_at
            )
            * 1000,
            2,
        )

        return result

    except ValueError as error:
        logger.warning(
            "Invalid scan request: %s",
            error,
        )

        raise HTTPException(
            status_code=(
                status.HTTP_422_UNPROCESSABLE_ENTITY
            ),
            detail=str(error),
        ) from error

    except Exception as error:
        logger.exception(
            "PaddleOCR-VL document scan failed."
        )

        raise HTTPException(
            status_code=(
                status.HTTP_500_INTERNAL_SERVER_ERROR
            ),
            detail=(
                "The document could not be processed."
            ),
        ) from error

    finally:
        temporary_path.unlink(
            missing_ok=True
        )