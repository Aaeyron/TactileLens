const historyModel = require("../../models/history/history_model");

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

const MAX_TITLE_LENGTH = 150;
const MAX_CONTENT_LENGTH = 1_000_000;
const MAX_BRAILLE_LENGTH = 2_000_000;
const MAX_DOCUMENT_BLOCKS = 500;

// ==========================
// Custom Service Errors
// ==========================

class HistoryValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = "HistoryValidationError";
    this.statusCode = 400;
  }
}

class HistoryNotFoundError extends Error {
  constructor(message = "History record not found.") {
    super(message);
    this.name = "HistoryNotFoundError";
    this.statusCode = 404;
  }
}

// ==========================
// Create History
// ==========================

const createHistory = async ({
  userId,
  title,
  recognizedContent,
  brailleContent,
  documentBlocks,
  modelName,
  pipelineVersion,
  processingTimeMs,
}) => {
  const validUserId = parsePositiveInteger(userId, "Authenticated user ID");

  const cleanTitle = normalizeOptionalString(
    title,
    "Untitled Scan",
    MAX_TITLE_LENGTH,
    "Title",
  );

  const cleanRecognizedContent = normalizeRequiredString(
    recognizedContent,
    MAX_CONTENT_LENGTH,
    "Recognized content",
  );

  const cleanBrailleContent = normalizeOptionalString(
    brailleContent,
    "",
    MAX_BRAILLE_LENGTH,
    "Braille content",
  );

  const cleanDocumentBlocks = normalizeDocumentBlocks(documentBlocks);

  const cleanModelName = normalizeNullableString(modelName, 100, "Model name");

  const cleanPipelineVersion = normalizeNullableString(
    pipelineVersion,
    30,
    "Pipeline version",
  );

  const cleanProcessingTimeMs = normalizeProcessingTime(processingTimeMs);

  return historyModel.createHistory({
    userId: validUserId,
    title: cleanTitle,
    recognizedContent: cleanRecognizedContent,
    brailleContent: cleanBrailleContent,
    documentBlocks: cleanDocumentBlocks,
    sourceImagePath: null,
    modelName: cleanModelName,
    pipelineVersion: cleanPipelineVersion,
    processingTimeMs: cleanProcessingTimeMs,
  });
};

// ==========================
// List User History
// ==========================

const listHistory = async ({
  userId,
  page = DEFAULT_PAGE,
  limit = DEFAULT_LIMIT,
}) => {
  const validUserId = parsePositiveInteger(userId, "Authenticated user ID");

  const validPage = normalizePaginationNumber(
    page,
    DEFAULT_PAGE,
    Number.MAX_SAFE_INTEGER,
    "Page",
  );

  const validLimit = normalizePaginationNumber(
    limit,
    DEFAULT_LIMIT,
    MAX_LIMIT,
    "Limit",
  );

  const offset = (validPage - 1) * validLimit;

  const [records, total] = await Promise.all([
    historyModel.getHistoryByUser({
      userId: validUserId,
      limit: validLimit,
      offset,
    }),
    historyModel.countHistoryByUser(validUserId),
  ]);

  return {
    records,
    pagination: {
      page: validPage,
      limit: validLimit,
      total,
      totalPages: total === 0 ? 0 : Math.ceil(total / validLimit),
    },
  };
};

// ==========================
// Get One History Record
// ==========================

const getHistory = async ({ historyId, userId }) => {
  const validHistoryId = parsePositiveInteger(historyId, "History ID");

  const validUserId = parsePositiveInteger(userId, "Authenticated user ID");

  const record = await historyModel.getHistoryById({
    historyId: validHistoryId,
    userId: validUserId,
  });

  if (!record) {
    throw new HistoryNotFoundError();
  }

  return record;
};

// ==========================
// Rename History
// ==========================

const renameHistory = async ({ historyId, userId, title }) => {
  const validHistoryId = parsePositiveInteger(historyId, "History ID");

  const validUserId = parsePositiveInteger(userId, "Authenticated user ID");

  const cleanTitle = normalizeRequiredString(title, MAX_TITLE_LENGTH, "Title");

  const record = await historyModel.updateHistoryTitle({
    historyId: validHistoryId,
    userId: validUserId,
    title: cleanTitle,
  });

  if (!record) {
    throw new HistoryNotFoundError();
  }

  return record;
};

// ==========================
// Delete History
// ==========================

const removeHistory = async ({ historyId, userId }) => {
  const validHistoryId = parsePositiveInteger(historyId, "History ID");

  const validUserId = parsePositiveInteger(userId, "Authenticated user ID");

  const deletedRecord = await historyModel.deleteHistory({
    historyId: validHistoryId,
    userId: validUserId,
  });

  if (!deletedRecord) {
    throw new HistoryNotFoundError();
  }

  return deletedRecord;
};

// ==========================
// Validation Helpers
// ==========================

const parsePositiveInteger = (value, fieldName) => {
  const parsedValue = Number(value);

  if (!Number.isSafeInteger(parsedValue) || parsedValue <= 0) {
    throw new HistoryValidationError(
      `${fieldName} must be a positive integer.`,
    );
  }

  return parsedValue;
};

const normalizeRequiredString = (value, maximumLength, fieldName) => {
  if (typeof value !== "string") {
    throw new HistoryValidationError(`${fieldName} is required.`);
  }

  const cleanValue = value.trim();

  if (!cleanValue) {
    throw new HistoryValidationError(`${fieldName} must not be empty.`);
  }

  if (cleanValue.length > maximumLength) {
    throw new HistoryValidationError(
      `${fieldName} must not exceed ${maximumLength} characters.`,
    );
  }

  return cleanValue;
};

const normalizeOptionalString = (
  value,
  fallbackValue,
  maximumLength,
  fieldName,
) => {
  if (value === undefined || value === null) {
    return fallbackValue;
  }

  if (typeof value !== "string") {
    throw new HistoryValidationError(`${fieldName} must be text.`);
  }

  const cleanValue = value.trim();

  if (!cleanValue) {
    return fallbackValue;
  }

  if (cleanValue.length > maximumLength) {
    throw new HistoryValidationError(
      `${fieldName} must not exceed ${maximumLength} characters.`,
    );
  }

  return cleanValue;
};

const normalizeNullableString = (value, maximumLength, fieldName) => {
  if (value === undefined || value === null) {
    return null;
  }

  if (typeof value !== "string") {
    throw new HistoryValidationError(`${fieldName} must be text.`);
  }

  const cleanValue = value.trim();

  if (!cleanValue) {
    return null;
  }

  if (cleanValue.length > maximumLength) {
    throw new HistoryValidationError(
      `${fieldName} must not exceed ${maximumLength} characters.`,
    );
  }

  return cleanValue;
};

const normalizeDocumentBlocks = (value) => {
  if (value === undefined || value === null) {
    return [];
  }

  if (!Array.isArray(value)) {
    throw new HistoryValidationError("Document blocks must be an array.");
  }

  if (value.length > MAX_DOCUMENT_BLOCKS) {
    throw new HistoryValidationError(
      `Document blocks must not contain more than ${MAX_DOCUMENT_BLOCKS} items.`,
    );
  }

  const containsInvalidBlock = value.some(
    (block) =>
      block === null || typeof block !== "object" || Array.isArray(block),
  );

  if (containsInvalidBlock) {
    throw new HistoryValidationError("Every document block must be an object.");
  }

  try {
    return JSON.parse(JSON.stringify(value));
  } catch {
    throw new HistoryValidationError("Document blocks contain invalid data.");
  }
};

const normalizeProcessingTime = (value) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const parsedValue = Number(value);

  if (!Number.isFinite(parsedValue) || parsedValue < 0) {
    throw new HistoryValidationError(
      "Processing time must be a non-negative number.",
    );
  }

  return parsedValue;
};

const normalizePaginationNumber = (
  value,
  fallbackValue,
  maximumValue,
  fieldName,
) => {
  if (value === undefined || value === null || value === "") {
    return fallbackValue;
  }

  const parsedValue = Number(value);

  if (
    !Number.isSafeInteger(parsedValue) ||
    parsedValue <= 0 ||
    parsedValue > maximumValue
  ) {
    throw new HistoryValidationError(
      `${fieldName} must be between 1 and ${maximumValue}.`,
    );
  }

  return parsedValue;
};

module.exports = {
  createHistory,
  listHistory,
  getHistory,
  renameHistory,
  removeHistory,
  HistoryValidationError,
  HistoryNotFoundError,
};
