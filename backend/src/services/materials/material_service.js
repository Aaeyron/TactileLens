const fs = require("fs");
const path = require("path");

const materialModel = require("../../models/materials/material_model");

const materialFolderModel = require("../../models/materials/material_folder_model");

const BACKEND_DIRECTORY = path.resolve(__dirname, "../../..");

const UPLOADS_DIRECTORY = path.join(BACKEND_DIRECTORY, "uploads");

// ==========================
// Create Material
// ==========================

const createMaterial = (materialData) => {
  return materialModel.createMaterial(materialData);
};

// ==========================
// Get All Owned Materials
// ==========================

const getAllMaterials = (userId) => {
  return materialModel.getAllMaterials(userId);
};

// ==========================
// Get One Owned Material
// ==========================

const getMaterialById = ({ materialId, userId }) => {
  return materialModel.getMaterialById({
    materialId,
    userId,
  });
};

// ==========================
// Delete Stored File Safely
// ==========================

const deleteStoredFile = async (storedPath) => {
  if (typeof storedPath !== "string" || storedPath.trim().length === 0) {
    return;
  }

  const resolvedFilePath = path.isAbsolute(storedPath)
    ? path.resolve(storedPath)
    : path.resolve(BACKEND_DIRECTORY, storedPath);

  const relativePath = path.relative(UPLOADS_DIRECTORY, resolvedFilePath);

  const isInsideUploadsDirectory =
    relativePath.length > 0 &&
    !relativePath.startsWith("..") &&
    !path.isAbsolute(relativePath);

  if (!isInsideUploadsDirectory) {
    console.warn("Skipped deleting a file outside the uploads directory.");
    return;
  }

  try {
    await fs.promises.unlink(resolvedFilePath);
  } catch (error) {
    if (error.code !== "ENOENT") {
      console.warn(
        "Material record was deleted, but its uploaded file could not be removed:",
        error.message,
      );
    }
  }
};

// ==========================
// Delete One Owned Material
// ==========================

const deleteMaterial = async ({ materialId, userId }) => {
  const material = await materialModel.getMaterialById({
    materialId,
    userId,
  });

  if (!material) {
    return null;
  }

  const deletedMaterial = await materialModel.deleteMaterial({
    materialId,
    userId,
  });

  if (!deletedMaterial) {
    return null;
  }

  await deleteStoredFile(deletedMaterial.file_path);

  return deletedMaterial;
};

// ==========================
// Move Owned Material to Folder
// ==========================

const moveMaterialToFolder = ({ materialId, folderId, userId }) => {
  return materialFolderModel.moveMaterialToFolder({
    materialId,
    folderId,
    userId,
  });
};

// ==========================
// Export
// ==========================

module.exports = {
  createMaterial,
  getAllMaterials,
  getMaterialById,
  moveMaterialToFolder,
  deleteMaterial,
};
