const fs = require("fs");

const materialService = require("../../services/materials/material_service");

const ALLOWED_SOURCE_TYPES = new Set(["uploaded_file", "scan_result"]);

// ==========================
// Helpers
// ==========================

const readRequiredText = (value) => {
  return typeof value === "string" ? value.trim() : "";
};

const readOptionalText = (value) => {
  const normalizedValue = readRequiredText(value);

  return normalizedValue.length > 0 ? normalizedValue : null;
};

const readOptionalNumber = (value) => {
  if (value === undefined || value === null || value === "") {
    return null;
  }

  const parsedValue = Number(value);

  return Number.isFinite(parsedValue) ? parsedValue : null;
};

const readDocumentBlocks = (value) => {
  if (value === undefined || value === null || value === "") {
    return [];
  }

  const parsedValue = typeof value === "string" ? JSON.parse(value) : value;

  if (!Array.isArray(parsedValue)) {
    throw new TypeError("document_blocks must be a JSON array.");
  }

  return parsedValue;
};

const readMaterialId = (value) => {
  const materialId = Number(value);

  if (!Number.isInteger(materialId) || materialId <= 0) {
    return null;
  }

  return materialId;
};

const removeUploadedFile = async (file) => {
  if (!file?.path) {
    return;
  }

  try {
    await fs.promises.unlink(file.path);
  } catch (error) {
    if (error.code !== "ENOENT") {
      console.warn(
        "Failed to clean up an uploaded material file:",
        error.message,
      );
    }
  }
};

// ==========================
// Upload Material
// ==========================

const uploadMaterial = async (req, res) => {
  let materialCreated = false;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No file was uploaded.",
      });
    }

    const title = readRequiredText(req.body.title);
    const subject = readRequiredText(req.body.subject);

    if (!title || !subject) {
      await removeUploadedFile(req.file);

      return res.status(400).json({
        success: false,
        message: "Title and subject are required.",
      });
    }

    const sourceType =
      readOptionalText(req.body.source_type) ?? "uploaded_file";

    if (!ALLOWED_SOURCE_TYPES.has(sourceType)) {
      await removeUploadedFile(req.file);

      return res.status(400).json({
        success: false,
        message: "The material source type is invalid.",
      });
    }

    let documentBlocks;

    try {
      documentBlocks = readDocumentBlocks(req.body.document_blocks);
    } catch (error) {
      await removeUploadedFile(req.file);

      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    const materialData = {
      user_id: req.user.id,
      title,
      subject,
      description: readOptionalText(req.body.description),
      file_name: req.file.filename,
      file_path: req.file.path,
      file_type: req.file.mimetype,
      file_size: req.file.size,
      source_type: sourceType,
      recognized_content: readRequiredText(req.body.recognized_content),
      braille_content: readRequiredText(req.body.braille_content),
      document_blocks: documentBlocks,
      model_name: readOptionalText(req.body.model_name),
      pipeline_version: readOptionalText(req.body.pipeline_version),
      processing_time_ms: readOptionalNumber(req.body.processing_time_ms),
    };

    const material = await materialService.createMaterial(materialData);

    materialCreated = true;

    return res.status(201).json({
      success: true,
      message: "Material saved successfully.",
      data: material,
    });
  } catch (error) {
    if (!materialCreated) {
      await removeUploadedFile(req.file);
    }

    console.error("Failed to upload material:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to save the material.",
    });
  }
};

// ==========================
// Get All Owned Materials
// ==========================

const getAllMaterials = async (req, res) => {
  try {
    const materials = await materialService.getAllMaterials(req.user.id);

    return res.status(200).json({
      success: true,
      data: materials,
    });
  } catch (error) {
    console.error("Failed to retrieve materials:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve materials.",
    });
  }
};

// ==========================
// Get One Owned Material
// ==========================

const getMaterialById = async (req, res) => {
  try {
    const materialId = readMaterialId(req.params.id);

    if (materialId === null) {
      return res.status(400).json({
        success: false,
        message: "The material ID is invalid.",
      });
    }

    const material = await materialService.getMaterialById({
      materialId,
      userId: req.user.id,
    });

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
    console.error("Failed to retrieve material:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve material.",
    });
  }
};

// ==========================
// Move Owned Material to Folder
// ==========================

const moveMaterialToFolder = async (req, res) => {
  try {
    const materialId = readMaterialId(req.params.id);

    if (materialId === null) {
      return res.status(400).json({
        success: false,
        message: "The material ID is invalid.",
      });
    }

    if (!Object.prototype.hasOwnProperty.call(req.body, "folder_id")) {
      return res.status(400).json({
        success: false,
        message: "A folder ID is required.",
      });
    }

    const requestedFolderId = req.body.folder_id;

    let folderId = null;

    if (requestedFolderId !== null) {
      folderId = readMaterialId(requestedFolderId);

      if (folderId === null) {
        return res.status(400).json({
          success: false,
          message: "The folder ID is invalid.",
        });
      }
    }

    const material = await materialService.moveMaterialToFolder({
      materialId,
      folderId,
      userId: req.user.id,
    });

    if (!material) {
      return res.status(404).json({
        success: false,
        message: "The material or selected folder could not be found.",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        folderId === null
          ? "Material removed from the folder."
          : "Material moved to the folder successfully.",
      data: material,
    });
  } catch (error) {
    console.error("Failed to move material to folder:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to move the material.",
    });
  }
};

// ==========================
// Delete One Owned Material
// ==========================

const deleteMaterial = async (req, res) => {
  try {
    const materialId = readMaterialId(req.params.id);

    if (materialId === null) {
      return res.status(400).json({
        success: false,
        message: "The material ID is invalid.",
      });
    }

    const material = await materialService.deleteMaterial({
      materialId,
      userId: req.user.id,
    });

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
    console.error("Failed to delete material:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete material.",
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
  moveMaterialToFolder,
  deleteMaterial,
};
