const express = require("express");
const rateLimit = require("express-rate-limit");

const {
  register,
  login,
  changePassword,
  requestPasswordReset,
  resetPassword,
  registerWithGoogle,
  loginWithGoogle,
} = require("../../controllers/auth/auth_controller");

const {
  authenticateToken,
} = require("../../middleware/auth/auth_middleware");

const router = express.Router();

// ==========================
// Rate Limit For Auth Routes
// ==========================
// Allows 20 requests per IP every 15 minutes on sign-in and account routes.

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many attempts. Please try again in a few minutes.",
  },
});

// ==========================
// Register Local User
// ==========================

router.post("/register", authLimiter, register);

// ==========================
// Login Local User
// ==========================

router.post("/login", authLimiter, login);

// ==========================
// Request Password Reset
// ==========================

router.post("/forgot-password", authLimiter, requestPasswordReset);

// ==========================
// Reset Forgotten Password
// ==========================

router.post("/reset-password", authLimiter, resetPassword);

// ==========================
// Change Password
// ==========================

router.patch("/password", authenticateToken, changePassword);

// ==========================
// Register With Google
// ==========================

router.post("/google/register", authLimiter, registerWithGoogle);

// ==========================
// Sign In With Google
// ==========================

router.post("/google/login", authLimiter, loginWithGoogle);

module.exports = router;