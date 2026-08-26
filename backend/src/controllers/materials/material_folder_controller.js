const materialFolderModel = require("../../models/materials/material_folder_model");

const MAXIMUM_FOLDER_NAME_LENGTH = 80;

// ==========================
// Helpers
// ==========================

const readFolderName = (value) => {
  return typeof value === "string" ? value.trim() : "";
};

const readPositiveId = (value) => {
  const id = Number(value);

  if (!Number.isInteger(id) || id <= 0) {
    return null;
  }

  return id;
};

const validateFolderName = (name) => {
  if (!name) {
    return "A folder name is required.";
  }

  if (name.length > MAXIMUM_FOLDER_NAME_LENGTH) {
    return `Folder names cannot exceed ${MAXIMUM_FOLDER_NAME_LENGTH} characters.`;
  }

  return null;
};

const isDuplicateFolderError = (error) => {
  return (
    error?.code === "23505" &&
    error?.constraint === "material_folders_user_name_unique"
  );
};

// ==========================
// Create Folder
// ==========================

const createFolder = async (req, res) => {
  try {
    const name = readFolderName(req.body.name);
    const validationMessage = validateFolderName(name);

    if (validationMessage) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_name",
        message: validationMessage,
      });
    }

    const existingFolder = await materialFolderModel.findFolderByName({
      userId: req.user.id,
      name,
    });

    if (existingFolder) {
      return res.status(409).json({
        success: false,
        code: "folder_name_exists",
        message: "You already have a folder with this name.",
      });
    }

    const folder = await materialFolderModel.createFolder({
      userId: req.user.id,
      name,
    });

    return res.status(201).json({
      success: true,
      message: "Folder created successfully.",
      data: folder,
    });
  } catch (error) {
    if (isDuplicateFolderError(error)) {
      return res.status(409).json({
        success: false,
        code: "folder_name_exists",
        message: "You already have a folder with this name.",
      });
    }

    console.error("Failed to create material folder:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to create the folder.",
    });
  }
};

// ==========================
// Get All Owned Folders
// ==========================

const getFolders = async (req, res) => {
  try {
    const folders = await materialFolderModel.getFoldersByUser(req.user.id);

    return res.status(200).json({
      success: true,
      data: folders,
    });
  } catch (error) {
    console.error("Failed to retrieve material folders:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve folders.",
    });
  }
};

// ==========================
// Get One Owned Folder
// ==========================

const getFolderById = async (req, res) => {
  try {
    const folderId = readPositiveId(req.params.id);

    if (folderId === null) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_id",
        message: "The folder ID is invalid.",
      });
    }

    const folder = await materialFolderModel.getFolderById({
      folderId,
      userId: req.user.id,
    });

    if (!folder) {
      return res.status(404).json({
        success: false,
        code: "folder_not_found",
        message: "Folder not found.",
      });
    }

    return res.status(200).json({
      success: true,
      data: folder,
    });
  } catch (error) {
    console.error("Failed to retrieve material folder:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to retrieve the folder.",
    });
  }
};

// ==========================
// Rename Owned Folder
// ==========================

const renameFolder = async (req, res) => {
  try {
    const folderId = readPositiveId(req.params.id);

    if (folderId === null) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_id",
        message: "The folder ID is invalid.",
      });
    }

    const name = readFolderName(req.body.name);
    const validationMessage = validateFolderName(name);

    if (validationMessage) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_name",
        message: validationMessage,
      });
    }

    const existingFolder = await materialFolderModel.findFolderByName({
      userId: req.user.id,
      name,
      excludeFolderId: folderId,
    });

    if (existingFolder) {
      return res.status(409).json({
        success: false,
        code: "folder_name_exists",
        message: "You already have a folder with this name.",
      });
    }

    const folder = await materialFolderModel.renameFolder({
      folderId,
      userId: req.user.id,
      name,
    });

    if (!folder) {
      return res.status(404).json({
        success: false,
        code: "folder_not_found",
        message: "Folder not found.",
      });
    }

    const updatedFolder = await materialFolderModel.getFolderById({
      folderId,
      userId: req.user.id,
    });

    return res.status(200).json({
      success: true,
      message: "Folder renamed successfully.",
      data: updatedFolder,
    });
  } catch (error) {
    if (isDuplicateFolderError(error)) {
      return res.status(409).json({
        success: false,
        code: "folder_name_exists",
        message: "You already have a folder with this name.",
      });
    }

    console.error("Failed to rename material folder:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to rename the folder.",
    });
  }
};

// ==========================
// Delete Owned Folder
// ==========================

const deleteFolder = async (req, res) => {
  try {
    const folderId = readPositiveId(req.params.id);

    if (folderId === null) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_id",
        message: "The folder ID is invalid.",
      });
    }

    const folder = await materialFolderModel.deleteFolder({
      folderId,
      userId: req.user.id,
    });

    if (!folder) {
      return res.status(404).json({
        success: false,
        code: "folder_not_found",
        message: "Folder not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Folder deleted successfully. Its materials were kept.",
      data: folder,
    });
  } catch (error) {
    console.error("Failed to delete material folder:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete the folder.",
    });
  }
};

// ==========================
// Move Material to Folder
// ==========================

const moveMaterialToFolder = async (req, res) => {
  try {
    const materialId = readPositiveId(req.params.materialId);

    if (materialId === null) {
      return res.status(400).json({
        success: false,
        code: "invalid_material_id",
        message: "The material ID is invalid.",
      });
    }

    const requestedFolderId = req.body.folder_id;

    const folderId =
      requestedFolderId === null ||
      requestedFolderId === undefined ||
      requestedFolderId === ""
        ? null
        : readPositiveId(requestedFolderId);

    if (
      requestedFolderId !== null &&
      requestedFolderId !== undefined &&
      requestedFolderId !== "" &&
      folderId === null
    ) {
      return res.status(400).json({
        success: false,
        code: "invalid_folder_id",
        message: "The folder ID is invalid.",
      });
    }

    if (folderId !== null) {
      const folder = await materialFolderModel.getFolderById({
        folderId,
        userId: req.user.id,
      });

      if (!folder) {
        return res.status(404).json({
          success: false,
          code: "folder_not_found",
          message: "Folder not found.",
        });
      }
    }

    const material = await materialFolderModel.moveMaterialToFolder({
      materialId,
      folderId,
      userId: req.user.id,
    });

    if (!material) {
      return res.status(404).json({
        success: false,
        code: "material_not_found",
        message: "Material not found.",
      });
    }

    return res.status(200).json({
      success: true,
      message:
        folderId === null
          ? "Material removed from its folder."
          : "Material moved successfully.",
      data: material,
    });
  } catch (error) {
    console.error("Failed to move material:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to move the material.",
    });
  }
};

// ==========================
// Export
// ==========================

module.exports = {
  createFolder,
  getFolders,
  getFolderById,
  renameFolder,
  deleteFolder,
  moveMaterialToFolder,
};
