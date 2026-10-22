const scanService = require("../../services/scan/scan_service");

// ==========================
// Scan Document
// ==========================

const scanDocument = async (req, res) => {
  // From here the scan may reach the AI service, so the scan guard keeps
  // the user's lock until the answer is recorded, even if the app
  // disconnects.
  req.scanStarted = true;

  let statusCode = 200;
  let body;

  try {
    body = await scanService.scanDocument({
      userId: req.user.id,
      file: req.file,
      title: req.body.title,
    });
  } catch (error) {
    if (error instanceof scanService.ScanServiceError) {
      // fallback_recommended: the app may offer scanning on the device.
      statusCode = error.statusCode;
      body = {
        success: false,
        message: error.message,
        code: error.code,
        fallback_recommended: error.fallbackRecommended,
      };
    } else {
      console.error("Scan request failed:", error);

      statusCode = 500;
      body = {
        success: false,
        message: "The document could not be scanned.",
      };
    }
  }

  // Saved for the request's Idempotency-Key, so a repeat gets this answer
  // instead of a second scan; also releases the one-scan-at-a-time lock.
  await req.scanGuard?.complete(statusCode, body);

  return res.status(statusCode).json(body);
};

// ==========================
// Export
// ==========================

module.exports = {
  scanDocument,
};
