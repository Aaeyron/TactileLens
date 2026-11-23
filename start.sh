#!/usr/bin/env bash
set -e

# Generate a default service secret if none is provided
export AI_SERVICE_SECRET="${AI_SERVICE_SECRET:-tactilelens-internal-shared-key}"
export AI_SERVICE_URL="http://127.0.0.1:8000"
export PADDLEOCR_ENGINE="${PADDLEOCR_ENGINE:-official_api}"
export LIBLOUIS_ROOT="${LIBLOUIS_ROOT:-/usr}"
export LIBLOUIS_TRANSLATE="${LIBLOUIS_TRANSLATE:-/usr/bin/lou_translate}"
export PORT="${PORT:-5000}"

echo "================================================="
echo " Starting TactileLens Multi-Service Container   "
echo " Node.js Express + Python FastAPI (Render Free) "
echo "================================================="

echo "-> Starting Python AI Service on 127.0.0.1:8000..."
cd /app/ai_service
python3 -m uvicorn app:app --host 127.0.0.1 --port 8000 &
AI_PID=$!

echo "-> Waiting for AI Service to be ready..."
READY=0
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8000/health > /dev/null 2>&1; then
    echo "-> Python AI Service is healthy and ready!"
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "-> ERROR: Python AI Service failed to become ready within 30 seconds."
  kill -TERM "$AI_PID" 2>/dev/null || true
  exit 1
fi

echo "-> Starting Node.js Backend on 0.0.0.0:${PORT}..."
cd /app/backend
node src/server.js &
NODE_PID=$!

shutdown() {
  echo "-> Gracefully shutting down services..."
  kill -TERM "$NODE_PID" "$AI_PID" 2>/dev/null || true
  wait "$NODE_PID" 2>/dev/null || true
  wait "$AI_PID" 2>/dev/null || true
  echo "-> Services stopped."
  exit 0
}

trap shutdown SIGTERM SIGINT

wait -n "$NODE_PID" "$AI_PID"
EXIT_STATUS=$?
echo "-> A service process exited with code $EXIT_STATUS."
shutdown
