const multer = require("multer");
const path = require("path");

// ==========================
// Storage Configuration
// ==========================

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/materials/");
  },

  filename: (req, file, cb) => {
    const uniqueName =
      Date.now() + "-" + Math.round(Math.random() * 1e9);

    cb(
    null,
    uniqueName + path.extname(file.originalname).toLowerCase()
  );
  },
});

// ==========================
// File Validation
// ==========================

const fileFilter = (req, file, cb) => {
  const allowedExtensions = [
    ".pdf",
    ".jpg",
    ".jpeg",
    ".png",
  ];

  const extension = path
    .extname(file.originalname)
    .toLowerCase();

  if (allowedExtensions.includes(extension)) {

    file.mimetype =
      extension === ".pdf"
        ? "application/pdf"
        : "image/" + extension.replace(".", "");

    cb(null, true);

  } else {
    cb(
      new Error(
        "Only PDF, JPG, JPEG, and PNG files are allowed."
      ),
      false
    );
  }
};

// ==========================
// Upload Configuration
// ==========================

const uploadMaterial = multer({
  storage,
  fileFilter,

  limits: {
    fileSize: 20 * 1024 * 1024,
  },
});

// ==========================
// Export
// ==========================

module.exports = uploadMaterial;