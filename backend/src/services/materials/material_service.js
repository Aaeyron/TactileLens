const fs = require("fs");
const path = require("path");

const materialModel = require("../../models/materials/material_model");

// ==========================
// Create Material
// ==========================

const createMaterial = async (materialData) => {
  return await materialModel.createMaterial(materialData);
};

// ==========================
// Get All Materials
// ==========================

const getAllMaterials = async (userId) => {
  return await materialModel.getAllMaterials(userId);
};

// ==========================
// Get Material By ID
// ==========================

const getMaterialById = async (id) => {
  return await materialModel.getMaterialById(id);
};

// ==========================
// Delete Material
// ==========================

const deleteMaterial = async (id) => {

  // Find the material first
  const material = await materialModel.getMaterialById(id);

  if (!material) {
    return null;
  }

  // Delete the uploaded file
  console.log("Deleting file:", material.file_path);
console.log("Exists:", fs.existsSync(material.file_path));

if (material.file_path && fs.existsSync(material.file_path)) {
    await fs.promises.unlink(material.file_path);
    console.log("File deleted successfully.");
} else {
    console.log("File not found.");
}

  // Delete database record
  return await materialModel.deleteMaterial(id);
};

// ==========================
// Export
// ==========================

module.exports = {
  createMaterial,
  getAllMaterials,
  getMaterialById,
  deleteMaterial,
};