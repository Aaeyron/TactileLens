const express = require("express");
const router = express.Router();

const materialController = require("../../controllers/materials/material_controller");
const uploadMaterial = require("../../middleware/materials/upload_material_middleware");

// ==========================
// Upload Material
// ==========================

router.post(
  "/upload",
  uploadMaterial.single("file"),
  materialController.uploadMaterial
);

// ==========================
// Get All Materials
// ==========================

router.get(
  "/",
  materialController.getAllMaterials
);

// ==========================
// Get Material By ID
// ==========================

router.get(
  "/:id",
  materialController.getMaterialById
);

// ==========================
// Delete Material
// ==========================

router.delete(
  "/:id",
  materialController.deleteMaterial
);

// ==========================
// Export
// ==========================

module.exports = router;