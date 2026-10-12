const express = require("express");

const scanController = require("../../controllers/scan/scan_controller");

const { authenticateToken } = require("../../middleware/auth/auth_middleware");

const {
  uploadScanImage,
} = require("../../middleware/scan/scan_upload_middleware");

const router = express.Router();

// Scanning requires a valid login token.
router.use(authenticateToken);

// Accept one image, forward it to PaddleOCR-VL, and save the result.
router.post("/", uploadScanImage, scanController.scanDocument);

module.exports = router;