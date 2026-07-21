const materialService = require("../../services/materials/material_service");

// ==========================
// Upload Material
// ==========================

const uploadMaterial = async (req, res) => {
  try {
    const {
      user_id,
      title,
      subject,
      description,
    } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file uploaded.",
      });
    }

    const materialData = {
      user_id,
      title,
      subject,
      description,

      file_name: req.file.filename,
      file_path: req.file.path,
      file_type: req.file.mimetype,
      file_size: req.file.size,
    };

    const material =
      await materialService.createMaterial(materialData);

    return res.status(201).json({
      success: true,
      message: "Material uploaded successfully.",
      data: material,
    });

  } catch (error) {

    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to upload material.",
      error: error.message,
    });
  }
};

// ==========================
// Get All Materials
// ==========================

const getAllMaterials = async (req, res) => {
  try {

    const materials =
      await materialService.getAllMaterials();

    return res.status(200).json({
      success: true,
      data: materials,
    });

  } catch (error) {

    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve materials.",
      error: error.message,
    });
  }
};

// ==========================
// Get Material By ID
// ==========================

const getMaterialById = async (req, res) => {
  try {

    const { id } = req.params;

    const material =
      await materialService.getMaterialById(id);

    if (!material) {
      return res.status(404).json({
        success: false,
        message: "Material not found.",
      });
    }

    return res.status(200).json({
      success: true,
      data: material,
    });

  } catch (error) {

    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve material.",
      error: error.message,
    });
  }
};

// ==========================
// Delete Material
// ==========================

const deleteMaterial = async (req, res) => {
  try {

    const { id } = req.params;

    const material =
      await materialService.deleteMaterial(id);

    if (!material) {
      return res.status(404).json({
        success: false,
        message: "Material not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Material deleted successfully.",
      data: material,
    });

  } catch (error) {

    console.error(error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete material.",
      error: error.message,
    });
  }
};

// ==========================
// Export
// ==========================

module.exports = {
  uploadMaterial,
  getAllMaterials,
  getMaterialById,
  deleteMaterial,
};