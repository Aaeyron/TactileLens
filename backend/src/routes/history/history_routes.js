const express = require("express");

const historyController = require("../../controllers/history/history_controller");

const { authenticateToken } = require("../../middleware/auth/auth_middleware");

const router = express.Router();

// Every history endpoint requires a valid login token.
router.use(authenticateToken);

// Create a history record
router.post("/", historyController.createHistory);

// List the authenticated user's history
router.get("/", historyController.listHistory);

// Get one history record
router.get("/:id", historyController.getHistory);

// Rename a history record
router.patch("/:id", historyController.renameHistory);

// Delete a history record
router.delete("/:id", historyController.deleteHistory);

module.exports = router;
