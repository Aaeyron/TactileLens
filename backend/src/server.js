require("dotenv").config();
require("./config/database");

const express = require("express");
const cors = require("cors");
const path = require("path");

const authRoutes = require("./routes/authRoutes");
const materialRoutes = require(
  "./routes/materials/material_routes",
);
const historyRoutes = require(
  "./routes/history/history_routes",
);

const app = express();

// ==========================
// Middleware
// ==========================

app.use(cors());

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
// Static Files
// ==========================

app.use(
  "/uploads",
  express.static(path.join(__dirname, "../uploads")),
);

// ==========================
// Routes
// ==========================

// Authentication Routes
app.use("/api/auth", authRoutes);

// Material Routes
app.use("/api/materials", materialRoutes);

// Scan History Routes
app.use("/api/history", historyRoutes);

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
// Server
// ==========================

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on port ${PORT}`);
});