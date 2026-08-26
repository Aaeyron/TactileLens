const express = require("express");

const { authenticateToken } = require("../../middleware/auth/auth_middleware");

const {
  createFolder,
  getFolders,
  getFolderById,
  renameFolder,
  deleteFolder,
  moveMaterialToFolder,
} = require("../../controllers/materials/material_folder_controller");

const router = express.Router();

// Every folder endpoint requires an authenticated user.
router.use(authenticateToken);

// ==========================
// Folder Collection
// ==========================

// Create a folder.
router.post("/", createFolder);

// Get all folders owned by the authenticated user.
router.get("/", getFolders);

// ==========================
// Material Folder Assignment
// ==========================

// Move a material into a folder or remove it from a folder.
router.patch("/materials/:materialId", moveMaterialToFolder);

// ==========================
// Individual Folder
// ==========================

// Get one owned folder.
router.get("/:id", getFolderById);

// Rename one owned folder.
router.patch("/:id", renameFolder);

// Delete one owned folder.
router.delete("/:id", deleteFolder);

module.exports = router;
