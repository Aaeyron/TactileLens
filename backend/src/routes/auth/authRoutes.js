const express = require("express");

const {
  register,
  login,
  continueWithGoogle,
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
// Continue With Google
// ==========================

router.post("/google", continueWithGoogle);

module.exports = router;
