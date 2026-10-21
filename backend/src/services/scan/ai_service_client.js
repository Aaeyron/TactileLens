// ==========================
// Call the TactileLens AI service (FastAPI)
// ==========================
//
// Timeouts must stay in this order (provisional, set after the
// remaining timing runs):
//   AI service hosted-OCR deadline  150 s  (PADDLEOCR_API_DEADLINE_SECONDS)
//   Node waiting for the AI service 170 s  (AI_SCAN_TIMEOUT_MS)
//   App waiting for Node            180 s  (AiService.requestTimeout)
// so each layer gives up after the one below it and can report why.

const DEFAULT_TIMEOUT_MS = 170000;
const APP_TIMEOUT_MS = 180000;

// Error codes returned to the app. fallbackRecommended tells the app
// that scanning on the device is worth offering.
const ERROR_CODES = {
  hosted_ocr_quota: { status: 503, fallback: true },
  hosted_ocr_unavailable: { status: 503, fallback: true },
  hosted_ocr_failed: { status: 502, fallback: true },
  hosted_ocr_timeout: { status: 504, fallback: true },
  ai_unavailable: { status: 503, fallback: true },
  ai_failed: { status: 502, fallback: true },
  ai_timeout: { status: 504, fallback: true },
  ai_not_configured: { status: 500, fallback: true },
  invalid_image: { status: 400, fallback: false },
};

class ScanServiceError extends Error {
  constructor(message, statusCode, code, fallbackRecommended) {
    super(message);
    this.name = "ScanServiceError";
    this.statusCode = statusCode;
    this.code = code;
    this.fallbackRecommended = fallbackRecommended;
  }
}

const scanError = (code, message, statusCode) => {
  const known = ERROR_CODES[code];

  return new ScanServiceError(
    message,
    statusCode ?? known.status,
    code,
    known.fallback,
  );
};

// ==========================
// Configuration
// ==========================

const getAiServiceUrl = () => {
  const url = (process.env.AI_SERVICE_URL || "").trim().replace(/\/+$/, "");

  if (!url) {
    throw scanError("ai_not_configured", "The AI service is not configured.");
  }

  return url;
};

const getTimeoutMs = () => {
  const value = Number(process.env.AI_SCAN_TIMEOUT_MS);

  return Number.isFinite(value) && value > 0 ? value : DEFAULT_TIMEOUT_MS;
};

// Called once at startup.
const warnAboutConfiguration = () => {
  if (!(process.env.AI_SERVICE_SECRET || "").trim()) {
    console.warn(
      "AI_SERVICE_SECRET is not set: requests to the AI service carry no " +
        "X-Service-Key. Use this only for local development.",
    );
  }

  if (getTimeoutMs() >= APP_TIMEOUT_MS) {
    console.warn(
      `AI_SCAN_TIMEOUT_MS (${getTimeoutMs()}) should be below the app's ` +
        `${APP_TIMEOUT_MS} ms timeout so the app hears why a scan stopped.`,
    );
  }
};

// ==========================
// Request
// ==========================

const requestDocumentScan = async ({ buffer, mimeType, fileName }) => {
  const baseUrl = getAiServiceUrl();

  const form = new FormData();
  form.append("image", new Blob([buffer], { type: mimeType }), fileName);

  const headers = {};
  const serviceKey = (process.env.AI_SERVICE_SECRET || "").trim();

  if (serviceKey) {
    headers["X-Service-Key"] = serviceKey;
  }

  let response;
  let bodyText;

  try {
    response = await fetch(`${baseUrl}/api/scan-document`, {
      method: "POST",
      headers,
      body: form,
      signal: AbortSignal.timeout(getTimeoutMs()),
    });

    bodyText = await response.text();
  } catch (error) {
    if (error?.name === "TimeoutError" || error?.name === "AbortError") {
      throw scanError("ai_timeout", "The AI service did not respond in time.");
    }

    console.error("AI service request failed:", error?.message ?? error);

    throw scanError(
      "ai_unavailable",
      "The AI service is unavailable. Make sure the AI server is running.",
    );
  }

  let payload = null;

  try {
    payload = bodyText ? JSON.parse(bodyText) : null;
  } catch {
    payload = null;
  }

  if (!response.ok) {
    throw errorFromResponse(response.status, payload, bodyText);
  }

  if (!payload || payload.success !== true || !Array.isArray(payload.blocks)) {
    throw scanError("ai_failed", "The AI service returned an invalid response.");
  }

  return payload;
};

const errorFromResponse = (status, payload, bodyText) => {
  const detail = payload?.detail ?? payload?.message;

  // Hosted OCR errors: {"detail": {"code": "hosted_ocr_quota", "message": ...}}
  if (detail && typeof detail === "object" && ERROR_CODES[detail.code]) {
    console.warn(`AI service reported ${detail.code} (HTTP ${status}).`);

    return scanError(
      detail.code,
      typeof detail.message === "string"
        ? detail.message
        : "The online OCR service could not process the image.",
    );
  }

  // A rejected service key is a server configuration problem, not the
  // user's: never pass a 401/403 on as if their login failed.
  if (status === 401 || status === 403) {
    console.error(
      "The AI service rejected the request (HTTP %d). Check AI_SERVICE_SECRET.",
      status,
    );

    return scanError("ai_unavailable", "The AI service is unavailable.");
  }

  if (status >= 400 && status < 500) {
    return scanError(
      "invalid_image",
      typeof detail === "string" ? detail : "The image could not be processed.",
      status,
    );
  }

  console.error(`AI service returned status ${status}:`, bodyText);

  return scanError("ai_failed", "The AI service failed to process the document.");
};

module.exports = {
  APP_TIMEOUT_MS,
  DEFAULT_TIMEOUT_MS,
  ScanServiceError,
  requestDocumentScan,
  warnAboutConfiguration,
};
