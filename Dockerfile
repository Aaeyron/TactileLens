# ==============================================================================
# TactileLens - Multi-Service Production Dockerfile for Render Free
# Combines:
# 1. Node.js 22 Express Backend (Public Gateway)
# 2. Python 3.11+ FastAPI AI Service (Internal Proxy on 127.0.0.1:8000)
# 3. Liblouis 3.x System Binaries & Braille Tables (/usr/bin/lou_translate)
# ==============================================================================

FROM node:22-bookworm-slim

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install Python, venv, curl, and Liblouis system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    liblouis-bin \
    liblouis-data \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set up isolated Python virtual environment (PEP 668 compliant)
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# 1. Install Python dependencies
COPY ai_service/requirements.txt /app/ai_service/requirements.txt
RUN pip install --no-cache-dir -r /app/ai_service/requirements.txt

# 2. Install Node.js dependencies
COPY backend/package*.json /app/backend/
WORKDIR /app/backend
RUN npm ci --omit=dev

# 3. Copy application code
WORKDIR /app
COPY ai_service/ /app/ai_service/
COPY backend/ /app/backend/
COPY start.sh /app/start.sh

# Ensure storage directories exist and entrypoint is executable
RUN mkdir -p /app/backend/uploads/materials /app/ai_service/uploads && \
    chmod +x /app/start.sh

# Production default environment configuration
ENV NODE_ENV=production \
    PORT=5000 \
    PADDLEOCR_ENGINE=official_api \
    LIBLOUIS_ROOT=/usr \
    LIBLOUIS_TRANSLATE=/usr/bin/lou_translate \
    AI_SERVICE_URL=http://127.0.0.1:8000 \
    AI_SCAN_TIMEOUT_MS=92000 \
    PADDLEOCR_API_DEADLINE_SECONDS=85

EXPOSE 5000

ENTRYPOINT ["/app/start.sh"]
