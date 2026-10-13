const fs = require("fs/promises");
const path = require("path");

// ==========================
// Expected File Signatures
// ==========================

const FILE_SIGNATURES = {
  ".pdf": [[0x25, 0x50, 0x44, 0x46]],
  ".jpg": [[0xff, 0xd8, 0xff]],
  ".jpeg": [[0xff, 0xd8, 0xff]],
  ".png": [[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]],
};

const readHeader = async (filePath, length) => {
  const handle = await fs.open(filePath, "r");

  try {
    const buffer = Buffer.alloc(length);
    const { bytesRead } = await handle.read(buffer, 0, length, 0);

    return buffer.subarray(0, bytesRead);
  } finally {
    await handle.close();
  }
};

const matchesAnySignature = (header, signatures) =>
  signatures.some(
    (signature) =>
      header.length >= signature.length &&
      signature.every((byte, index) => header[index] === byte),
  );

// ==========================
// Validate Saved File Content
// ==========================

const validateMaterialFileContent = async (req, res, next) => {
  if (!req.file) {
    return next();
  }

  const extension = path.extname(req.file.originalname).toLowerCase();
  const signatures = FILE_SIGNATURES[extension];

  try {
    const header = await readHeader(req.file.path, 8);

    if (signatures && matchesAnySignature(header, signatures)) {
      return next();
    }
  } catch (error) {
    console.error("Material file check failed:", error.message);
  }

  await fs.unlink(req.file.path).catch(() => {});

  return res.status(400).json({
    success: false,
    message: "The file content does not match its type. Upload a real PDF, JPG, or PNG.",
  });
};

module.exports = {
  validateMaterialFileContent,
};