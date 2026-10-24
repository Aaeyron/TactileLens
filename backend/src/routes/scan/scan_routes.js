const express = require("express");

const scanController = require("../../controllers/scan/scan_controller");

const { authenticateToken } = require("../../middleware/auth/auth_middleware");

const {
  createScanGuard,
} = require("../../middleware/scan/scan_guard_middleware");

const {
  uploadScanImage,
} = require("../../middleware/scan/scan_upload_middleware");

const {
  InMemoryScanGuardStore,
  limitsFromEnvironment,
} = require("../../services/scan/scan_guard_store");

const router = express.Router();

// In memory for now: counts reset when Node restarts, until the
// PostgreSQL store is added with the hosting changes.
const scanGuard = createScanGuard({
  store: new InMemoryScanGuardStore(limitsFromEnvironment()),
});

// Scanning requires a valid login token.
router.use(authenticateToken);

// Limits and lock are checked before the image is read; then one image is
// forwarded to the AI service and the result saved.
router.post("/", scanGuard, uploadScanImage, scanController.scanDocument);

module.exports = router;
