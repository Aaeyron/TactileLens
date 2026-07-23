require("dotenv").config();
require("./config/database");

const express = require("express");
const cors = require("cors");
const path = require("path");

const authRoutes = require("./routes/authRoutes");
const materialRoutes = require("./routes/materials/material_routes");

const app = express();

// ==========================
// Middleware
// ==========================

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ==========================
// Static Files
// ==========================

app.use(
  "/uploads",
  express.static(path.join(__dirname, "../uploads"))
);

// ==========================
// Routes
// ==========================

// Authentication Routes
app.use("/api/auth", authRoutes);

// Material Routes
app.use("/api/materials", materialRoutes);

// ==========================
// Default Route
// ==========================

app.get("/", (req, res) => {
  res.send("Welcome to the TactileLens Backend API!");
});

// ==========================
// Server
// ==========================

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});