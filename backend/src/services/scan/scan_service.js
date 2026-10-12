const historyService = require("../history/history_service");

// ==========================
// Configuration
// ==========================

const DEFAULT_TIMEOUT_MS = 120000;
const MAX_TITLE_LENGTH = 150;

// ==========================
// Custom Service Error
// ==========================

class ScanServiceError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.name = "ScanServiceError";
    this.statusCode = statusCode;
  }
}

// ==========================
// Configuration Helpers
// ==========================

const getAiServiceUrl = () => {
  const url = (process.env.AI_SERVICE_URL || "").trim().replace(/\/+$/, "");

  if (!url) {
    throw new ScanServiceError("The AI service is not configured.", 500);
  }

  return url;
};

const getTimeoutMs = () => {
  const value = Number(process.env.AI_SCAN_TIMEOUT_MS);

  return Number.isFinite(value) && value > 0 ? value : DEFAULT_TIMEOUT_MS;
};

// ==========================
// Call PaddleOCR-VL (FastAPI)
// ==========================

const requestPaddleOcr = async ({ buffer, mimeType, fileName }) => {
  const baseUrl = getAiServiceUrl();

  const form = new FormData();
  form.append("image", new Blob([buffer], { type: mimeType }), fileName);

  let response;
  let bodyText;

  try {
    response = await fetch(`${baseUrl}/api/scan-document`, {
      method: "POST",
      body: form,
      signal: AbortSignal.timeout(getTimeoutMs()),
    });

    bodyText = await response.text();
  } catch (error) {
    if (error?.name === "TimeoutError" || error?.name === "AbortError") {
      throw new ScanServiceError(
        "The AI service did not respond in time.",
        504,
      );
    }

    console.error("AI service request failed:", error);

    throw new ScanServiceError(
      "The AI service is unavailable. Make sure the AI server is running.",
      503,
    );
  }

  let payload = null;

  try {
    payload = bodyText ? JSON.parse(bodyText) : null;
  } catch {
    payload = null;
  }

  if (!response.ok) {
    const detail = payload?.detail ?? payload?.message;

    if (response.status >= 400 && response.status < 500) {
      throw new ScanServiceError(
        typeof detail === "string"
          ? detail
          : "The image could not be processed.",
        response.status,
      );
    }

    console.error(
      `AI service returned status ${response.status}:`,
      bodyText,
    );

    throw new ScanServiceError(
      "The AI service failed to process the document.",
      502,
    );
  }

  if (!payload || payload.success !== true || !Array.isArray(payload.blocks)) {
    throw new ScanServiceError(
      "The AI service returned an invalid response.",
      502,
    );
  }

  return payload;
};

// ==========================
// Build Saved Content
// ==========================

const sortByOrder = (blocks) =>
  [...blocks].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

const buildRecognizedContent = (blocks) =>
  sortByOrder(blocks)
    .map((block) => (block.normalized_content || block.content || "").trim())
    .filter(Boolean)
    .join("\n\n");

const buildBrailleContent = (blocks) =>
  sortByOrder(blocks)
    .map((block) => (block.braille_content || "").trim())
    .filter(Boolean)
    .join("\n\n");

const buildTitle = (rawTitle) => {
  const cleanTitle = typeof rawTitle === "string" ? rawTitle.trim() : "";

  if (cleanTitle) {
    return cleanTitle.slice(0, MAX_TITLE_LENGTH);
  }

  const timestamp = new Date().toLocaleString("en-PH", {
    timeZone: "Asia/Manila",
  });

  return `Scan ${timestamp}`.slice(0, MAX_TITLE_LENGTH);
};

// ==========================
// Scan and Save
// ==========================

const scanDocument = async ({ userId, file, title }) => {
  const aiResult = await requestPaddleOcr({
    buffer: file.buffer,
    mimeType: file.mimetype,
    fileName: file.originalname,
  });

  const blocks = aiResult.blocks;
  const pages = Array.isArray(aiResult.pages) ? aiResult.pages : [];
  const recognizedContent = buildRecognizedContent(blocks);

  const response = {
    ...aiResult,
    history: null,
    history_saved: false,
  };

  if (!recognizedContent) {
    response.history_error =
      "No text was recognized, so nothing was saved to history.";

    return response;
  }

  try {
    const record = await historyService.createHistory({
      userId,
      title: buildTitle(title),
      recognizedContent,
      brailleContent: buildBrailleContent(blocks),
      documentBlocks: blocks,
      documentPages: pages,
      modelName: aiResult.model ?? null,
      pipelineVersion: aiResult.pipeline_version ?? null,
      processingTimeMs: aiResult.processing_time_ms ?? null,
    });

    response.history = record;
    response.history_saved = true;
  } catch (error) {
    console.error("Failed to save scan history:", error);

    response.history_error =
      error instanceof historyService.HistoryValidationError
        ? error.message
        : "The scan result could not be saved to history.";
  }

  return response;
};

// ==========================
// Export
// ==========================

module.exports = {
  scanDocument,
  ScanServiceError,
};