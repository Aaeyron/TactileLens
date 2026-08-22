const historyService = require("../../services/history/history_service");

// ==========================
// Create History
// ==========================

const createHistory = async (req, res) => {
  try {
    const record = await historyService.createHistory({
      userId: req.user.id,
      title: req.body.title,
      recognizedContent: req.body.recognized_content,
      brailleContent: req.body.braille_content,
      documentBlocks: req.body.document_blocks,
      modelName: req.body.model_name,
      pipelineVersion: req.body.pipeline_version,
      processingTimeMs: req.body.processing_time_ms,
    });

    return res.status(201).json({
      success: true,
      message: "Scan history saved successfully.",
      data: record,
    });
  } catch (error) {
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
  createHistory,
  listHistory,
  getHistory,
  renameHistory,
  deleteHistory,
};
