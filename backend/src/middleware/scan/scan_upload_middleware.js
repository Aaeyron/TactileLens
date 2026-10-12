const multer = require("multer");
const path = require("path");

// ==========================
// Configuration
// ==========================

const MAX_IMAGE_MB = Number(process.env.AI_MAX_UPLOAD_MB) || 20;

// Extension -> MIME types accepted for that extension.
const ALLOWED_IMAGE_TYPES = {
  ".jpg": ["image/jpeg", "image/jpg"],
  ".jpeg": ["image/jpeg", "image/jpg"],
  ".png": ["image/png"],
  ".webp": ["image/webp"],
  ".bmp": ["image/bmp"],
  ".tif": ["image/tiff"],
  ".tiff": ["image/tiff"],
};

// ==========================
// File Validation
// ==========================

const fileFilter = (req, file, cb) => {
  const extension = path.extname(file.originalname || "").toLowerCase();
  const mimeType = (file.mimetype || "").toLowerCase();
  const allowedMimeTypes = ALLOWED_IMAGE_TYPES[extension];

    // Flutter's http package sends files as application/octet-stream unless
  // a type is set. Trust the allowed extension in that case.
  const isGenericType = mimeType === "application/octet-stream";

  if (
    !allowedMimeTypes ||
    (!allowedMimeTypes.includes(mimeType) && !isGenericType)
  ) {
    const error = new Error(
      "Only JPG, JPEG, PNG, WEBP, BMP, and TIFF images are allowed.",
    );
    error.statusCode = 415;
    return cb(error, false);
  }

  return cb(null, true);
};

// The image is kept in memory and forwarded to the AI service.
// It is never written to disk on the backend.
const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter,
  limits: {
    fileSize: MAX_IMAGE_MB * 1024 * 1024,
    files: 1,
  },
}).single("image");

// ==========================
// Middleware Wrapper
// ==========================

// Turns multer and validation errors into the same JSON shape
// the rest of the API uses.
const uploadScanImage = (req, res, next) => {
  upload(req, res, (error) => {
    if (!error) {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "An image file must be sent in the 'image' field.",
        });
      }

      return next();
    }

    if (error instanceof multer.MulterError) {
      if (error.code === "LIMIT_FILE_SIZE") {
        return res.status(413).json({
          success: false,
          message: `The image must not exceed ${MAX_IMAGE_MB} MB.`,
        });
      }

      return res.status(400).json({
        success: false,
        message: "The image upload is invalid.",
      });
    }

    return res.status(error.statusCode || 400).json({
      success: false,
      message: error.message || "The image upload is invalid.",
    });
  });
};

// ==========================
// Export
// ==========================

module.exports = {
  uploadScanImage,
};