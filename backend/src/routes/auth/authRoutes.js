const express = require("express");

const {
  register,
  login,
  registerWithGoogle,
  loginWithGoogle,
} = require("../../controllers/auth/authController");

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
// Register With Google
// ==========================

router.post("/google/register", registerWithGoogle);

// ==========================
// Sign In With Google
// ==========================

router.post("/google/login", loginWithGoogle);

module.exports = router;
