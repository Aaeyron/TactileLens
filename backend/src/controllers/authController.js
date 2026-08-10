const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const {
  createUser,
  findUserByEmail,
} = require("../models/userModel");

const TOKEN_EXPIRATION =
  process.env.JWT_EXPIRES_IN || "7d";

// ==========================
// Helpers
// ==========================

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error(
      "JWT_SECRET is not configured in the backend environment."
    );
  }

  return secret;
};

const createAccessToken = (user) => {
  return jwt.sign(
    {
      role: user.role,
    },
    getJwtSecret(),
    {
      subject: String(user.id),
      expiresIn: TOKEN_EXPIRATION,
    }
  );
};

const sanitizeUser = (user) => {
  return {
    id: user.id,
    first_name: user.first_name,
    last_name: user.last_name,
    email: user.email,
    role: user.role,
  };
};

// ==========================
// Register User
// ==========================

const register = async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      email,
      password,
      role,
    } = req.body;

    if (
      !first_name ||
      !last_name ||
      !email ||
      !password ||
      !role
    ) {
      return res.status(400).json({
        success: false,
        message: "All registration fields are required.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await findUserByEmail(
      normalizedEmail
    );

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "Email is already registered.",
      });
    }

    const hashedPassword = await bcrypt.hash(
      password,
      10
    );

    const user = await createUser(
      first_name.trim(),
      last_name.trim(),
      normalizedEmail,
      hashedPassword,
      role
    );

    return res.status(201).json({
      success: true,
      message: "Account created successfully.",
      user: sanitizeUser(user),
    });
  } catch (error) {
    console.error("Registration failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to create the account.",
    });
  }
};

// ==========================
// Login User
// ==========================

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const user = await findUserByEmail(
      normalizedEmail
    );

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password.",
      });
    }

    const isMatch = await bcrypt.compare(
      password,
      user.password
    );

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password.",
      });
    }

    const accessToken = createAccessToken(user);

    return res.status(200).json({
      success: true,
      message: "Login successful.",
      token: accessToken,
      token_type: "Bearer",
      expires_in: TOKEN_EXPIRATION,
      user: sanitizeUser(user),
    });
  } catch (error) {
    console.error("Login failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to sign in.",
    });
  }
};

module.exports = {
  register,
  login,
};