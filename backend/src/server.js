require("dotenv").config();
require("./config/database");

const express = require("express");

const {
  warnAboutConfiguration,
} = require("./services/scan/ai_service_client");

warnAboutConfiguration();

const authRoutes = require("./routes/auth/auth_routes");

const materialRoutes = require("./routes/materials/material_routes");

const materialFolderRoutes = require("./routes/materials/material_folder_routes");

const historyRoutes = require("./routes/history/history_routes");

const scanRoutes = require("./routes/scan/scan_routes");

const app = express();

// ==========================
// Middleware
// ==========================

app.use(
  express.json({
    limit: "5mb",
  }),
);

app.use(
  express.urlencoded({
    extended: true,
    limit: "5mb",
  }),
);

// ==========================
// Routes
// ==========================

// Authentication Routes
app.use("/api/auth", authRoutes);

// Material Routes
app.use("/api/materials", materialRoutes);

// Material Folder Routes
app.use("/api/material-folders", materialFolderRoutes);

// Scan History Routes
app.use("/api/history", historyRoutes);

// Scan Routes (PaddleOCR-VL through the backend)
app.use("/api/scan-document", scanRoutes);

// ==========================
// Default Route
// ==========================

app.get("/", (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Welcome to the TactileLens Backend API!",
  });
});

// ==========================
// Unknown Route Handler
// ==========================

app.use((req, res) => {
  return res.status(404).json({
    success: false,
    message: "API endpoint not found.",
  });
});

// ==========================
// Global Error Handler
// ==========================

app.use((err, req, res, next) => {
  if (res.headersSent) {
    return next(err);
  }

  const status = err.status || err.statusCode || 500;

  if (status >= 500) {
    console.error(err);
  }

  if (status >= 500) {
    return res.status(500).json({
      success: false,
      message: "Internal server error.",
    });
  }

  return res.status(status).json({
    success: false,
    message: err.expose ? err.message : "Invalid request.",
  });
});

// ==========================
// Server
// ==========================

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on port ${PORT}`);
});