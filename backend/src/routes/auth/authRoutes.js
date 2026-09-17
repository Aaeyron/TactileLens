const express = require("express");

const {
  register,
  login,
  changePassword,
  registerWithGoogle,
  loginWithGoogle,
} = require("../../controllers/auth/authController");

const {
  authenticateToken,
} = require("../../middleware/auth/auth_middleware");

const router = express.Router();

// ==========================
// Register Local User
// ==========================

router.post("/register", register);

// ==========================
// Login Local User
// ==========================

router.post("/login", login);

// ==========================
// Change Password
// ==========================

router.patch("/password", authenticateToken, changePassword);

// ==========================
// Register With Google
// ==========================

router.post("/google/register", registerWithGoogle);

// ==========================
// Sign In With Google
// ==========================

router.post("/google/login", loginWithGoogle);

module.exports = router;
