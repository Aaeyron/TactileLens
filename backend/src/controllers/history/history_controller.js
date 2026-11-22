const historyService = require("../../services/history/history_service");
const {
  HistoryIdempotencyStore,
} = require("../../services/history/history_idempotency");

// One store per server process (see history_idempotency.js).
const historyIdempotency = new HistoryIdempotencyStore();

// ==========================
// Create History
// ==========================

const createHistory = async (req, res) => {
  const userId = req.user.id;
  const key = req.get ? req.get("Idempotency-Key") : undefined;

  if (key !== undefined) {
    if (!HistoryIdempotencyStore.isValidKey(key)) {
      return res.status(400).json({
        success: false,
        message: "The Idempotency-Key is not valid.",
      });
    }

    const decision = historyIdempotency.begin({ userId, key });

    // Already saved with this key: the same answer, nothing stored again.
    if (decision.outcome === "done") {
      return res.status(decision.statusCode).json(decision.body);
    }

    if (decision.outcome === "in_progress") {
      return res.status(409).json({
        success: false,
        message: "This scan is already being saved. Please try again.",
      });
    }
  }

  try {
    const record = await historyService.createHistory({
      userId,
      title: req.body.title,
      recognizedContent: req.body.recognized_content,
      brailleContent: req.body.braille_content,
      documentBlocks: req.body.document_blocks,
      documentPages: req.body.document_pages,
      modelName: req.body.model_name,
      pipelineVersion: req.body.pipeline_version,
      processingTimeMs: req.body.processing_time_ms,
    });

    const body = {
      success: true,
      message: "Scan history saved successfully.",
      data: record,
    };

    if (key !== undefined) {
      historyIdempotency.complete({ userId, key, statusCode: 201, body });
    }

    return res.status(201).json(body);
  } catch (error) {
    // Not saved: the key is freed, so a retry can save it.
    if (key !== undefined) {
      historyIdempotency.complete({ userId, key, statusCode: 500 });
    }

    return handleHistoryError(error, res, "Failed to save scan history.");
  }
};

// ==========================
// List Authenticated User's History
// ==========================

const listHistory = async (req, res) => {
  try {
    const result = await historyService.listHistory({
      userId: req.user.id,
      page: req.query.page,
      limit: req.query.limit,
    });

    return res.status(200).json({
      success: true,
      data: result.records,
      pagination: result.pagination,
    });
  } catch (error) {
    return handleHistoryError(error, res, "Failed to retrieve scan history.");
  }
};

// ==========================
// Get One History Record
// ==========================

const getHistory = async (req, res) => {
  try {
    const record = await historyService.getHistory({
      historyId: req.params.id,
      userId: req.user.id,
    });

    return res.status(200).json({
      success: true,
      data: record,
    });
  } catch (error) {
    return handleHistoryError(
      error,
      res,
      "Failed to retrieve the scan history record.",
    );
  }
};

// ==========================
// Rename History
// ==========================

const renameHistory = async (req, res) => {
  try {
    const record = await historyService.renameHistory({
      historyId: req.params.id,
      userId: req.user.id,
      title: req.body.title,
    });

    return res.status(200).json({
      success: true,
      message: "Scan history renamed successfully.",
      data: record,
    });
  } catch (error) {
    return handleHistoryError(
      error,
      res,
      "Failed to rename the scan history record.",
    );
  }
};

// ==========================
// Delete History
// ==========================

const deleteHistory = async (req, res) => {
  try {
    const deletedRecord = await historyService.removeHistory({
      historyId: req.params.id,
      userId: req.user.id,
    });

    return res.status(200).json({
      success: true,
      message: "Scan history deleted successfully.",
      data: deletedRecord,
    });
  } catch (error) {
    return handleHistoryError(
      error,
      res,
      "Failed to delete the scan history record.",
    );
  }
};

// ==========================
// Error Handler
// ==========================

const handleHistoryError = (error, res, fallbackMessage) => {
  if (
    error instanceof historyService.HistoryValidationError ||
    error instanceof historyService.HistoryNotFoundError
  ) {
    return res.status(error.statusCode).json({
      success: false,
      message: error.message,
    });
  }

  console.error(fallbackMessage, error);

  return res.status(500).json({
    success: false,
    message: fallbackMessage,
  });
};

// ==========================
// Export
// ==========================

module.exports = {
  historyIdempotency,
  createHistory,
  listHistory,
  getHistory,
  renameHistory,
  deleteHistory,
};
