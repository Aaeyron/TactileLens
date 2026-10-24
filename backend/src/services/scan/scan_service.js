const historyService = require("../history/history_service");

const {
  ScanServiceError,
  requestDocumentScan,
} = require("./ai_service_client");

const MAX_TITLE_LENGTH = 150;

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

const FORMULA_TYPES = new Set([
  "formula",
  "display_formula",
  "inline_formula",
]);

const getBlockType = (block) =>
  String(block?.type ?? "").trim().toLowerCase();

const isFormulaBlock = (block) =>
  block?.is_formula === true || FORMULA_TYPES.has(getBlockType(block));

const buildAutomaticTitle = (blocks) => {
  const hasFormulas = blocks.some(isFormulaBlock);
  const hasText = blocks.some((block) => getBlockType(block) === "text");

  if (hasText && hasFormulas) {
    return "Text and Equation Scan";
  }

  if (hasFormulas) {
    return "Equation Scan";
  }

  if (hasText) {
    return "Printed Text Scan";
  }

  return "Document Scan";
};

const buildTitle = (rawTitle, blocks) => {
  const cleanTitle = typeof rawTitle === "string" ? rawTitle.trim() : "";

  if (cleanTitle) {
    return cleanTitle.slice(0, MAX_TITLE_LENGTH);
  }

  return buildAutomaticTitle(blocks).slice(0, MAX_TITLE_LENGTH);
};

// ==========================
// Scan and Save
// ==========================

const scanDocument = async ({ userId, file, title }) => {
  const aiResult = await requestDocumentScan({
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
      title: buildTitle(title, blocks),
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