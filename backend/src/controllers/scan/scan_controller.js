const scanService = require("../../services/scan/scan_service");

// ==========================
// Scan Document
// ==========================

const scanDocument = async (req, res) => {
  try {
    const result = await scanService.scanDocument({
      userId: req.user.id,
      file: req.file,
      title: req.body.title,
    });

    return res.status(200).json(result);
  } catch (error) {
    if (error instanceof scanService.ScanServiceError) {
      // fallback_recommended: the app may offer scanning on the device.
      return res.status(error.statusCode).json({
        success: false,
        message: error.message,
        code: error.code,
        fallback_recommended: error.fallbackRecommended,
      });
    }

    console.error("Scan request failed:", error);

    return res.status(500).json({
      success: false,
      message: "The document could not be scanned.",
    });
  }
};

// ==========================
// Export
// ==========================

module.exports = {
  scanDocument,
};