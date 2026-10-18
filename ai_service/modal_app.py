"""
Modal deployment for the TactileLens AI service.

Wraps the existing FastAPI app (ai_service/app.py) without changing its OCR code.
  - requires X-Service-Key on every route except /health
  - /health for warm-up requests
  - GPU container that scales to zero when idle

Dev test:  modal serve modal_app.py
Deploy:    modal deploy modal_app.py

Create the secret once (value must match AI_SERVICE_SECRET in backend/.env):
  modal secret create tactilelens-ai AI_SERVICE_SECRET=<value>
"""

import hmac
import os

import modal

GPU_TYPE = "L4"            # 24 GB, low cost
IDLE_SECONDS = 120         # GPU shuts down after 2 idle minutes
MAX_REQUEST_SECONDS = 180  # matches AI_SCAN_TIMEOUT_MS

app = modal.App("tactilelens-ai")

image = (
    modal.Image.from_registry("nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04", add_python="3.11")
    .apt_install("libgl1", "libglib2.0-0", "liblouis-bin", "liblouis-data")
    .run_commands("ln -s /usr/bin/lou_translate /usr/bin/lou_translate.exe")
    .pip_install(
        "fastapi==0.141.1",
        "uvicorn==0.52.1",
        "python-multipart==0.0.32",
        "paddleocr[doc-parser]==3.7.0",
        "python-docx==1.2.0",
    )
    # PaddlePaddle GPU wheels for CUDA 12.6 come from Paddle's own index, not PyPI.
    .pip_install(
        "paddlepaddle-gpu==3.2.1",
        index_url="https://www.paddlepaddle.org.cn/packages/stable/cu126/",
    )
    .env({"PYTHONPATH": "/root", "LIBLOUIS_ROOT": "/usr"})
    .add_local_file("app.py", "/root/app.py")
    .add_local_dir("services", "/root/services", ignore=["__pycache__"])
)

secret = modal.Secret.from_name("tactilelens-ai")

PUBLIC_PATHS = {"/health"}


@app.function(
    image=image,
    gpu=GPU_TYPE,
    secrets=[secret],
    scaledown_window=IDLE_SECONDS,
    timeout=MAX_REQUEST_SECONDS,
    min_containers=0,
)
@modal.concurrent(max_inputs=1)  # one scan per GPU at a time
@modal.asgi_app()
def web():
    from fastapi import Request
    from fastapi.responses import JSONResponse

    from app import app as inner

    expected = os.environ.get("AI_SERVICE_SECRET", "")
    if not expected:
        raise RuntimeError("AI_SERVICE_SECRET is not set in the Modal secret.")

    @inner.middleware("http")
    async def require_service_key(request: Request, call_next):
        if request.url.path not in PUBLIC_PATHS:
            given = request.headers.get("x-service-key", "")
            if not hmac.compare_digest(given.encode(), expected.encode()):
                return JSONResponse({"detail": "Forbidden"}, status_code=403)
        return await call_next(request)

    if not any(getattr(r, "path", None) == "/health" for r in inner.routes):
        @inner.get("/health")
        def health():
            return {"status": "ok"}

    return inner