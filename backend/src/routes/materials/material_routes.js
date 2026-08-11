const express = require("express");

const materialController = require(
  "../../controllers/materials/material_controller",
);

const {
  authenticateToken,
} = require(
  "../../middleware/auth/auth_middleware",
);

const uploadMaterial = require(
  "../../middleware/materials/upload_material_middleware",
);

const router = express.Router();

// Every Materials route requires a valid JWT.
router.use(authenticateToken);

// ==========================
// Upload Material
// ==========================

router.post(
  "/upload",
  uploadMaterial.single("file"),
  materialController.uploadMaterial,
);

// ==========================
// Get All Owned Materials
// ==========================

router.get(
  "/",
  materialController.getAllMaterials,
);

// ==========================
// Get One Owned Material
// ==========================

router.get(
  "/:id",
  materialController.getMaterialById,
);

// ==========================
// Delete One Owned Material
// ==========================

router.delete(
  "/:id",
  materialController.deleteMaterial,
);

// ==========================
// Export
// ==========================

module.exports = router;