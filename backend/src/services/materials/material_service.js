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

const getAllMaterials = async () => {
  return await materialModel.getAllMaterials();
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