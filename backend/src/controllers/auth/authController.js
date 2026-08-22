const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const {
  createUser,
  createGoogleUser,
  findUserByEmail,
  findUserByGoogleSub,
} = require("../../models/users/userModel");

const {
  GoogleAuthServiceError,
  verifyGoogleIdToken,
} = require("../../services/auth/google_auth_service");

const TOKEN_EXPIRATION = process.env.JWT_EXPIRES_IN || "7d";

const ALLOWED_ROLES = new Set(["Student", "Educator"]);

// ==========================
// Helpers
// ==========================

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error("JWT_SECRET is not configured in the backend environment.");
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
    },
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

const createAuthenticationResponse = (user, message, isNewUser) => {
  return {
    success: true,
    message,
    token: createAccessToken(user),
    token_type: "Bearer",
    expires_in: TOKEN_EXPIRATION,
    is_new_user: isNewUser,
    user: sanitizeUser(user),
  };
};

const normalizeRole = (role) => {
  if (typeof role !== "string") {
    return "";
  }

  const normalizedRole = role.trim();

  return ALLOWED_ROLES.has(normalizedRole) ? normalizedRole : "";
};

// ==========================
// Register Local User
// ==========================

const register = async (req, res) => {
  try {
    const { first_name, last_name, email, password, role } = req.body;

    const normalizedRole = normalizeRole(role);

    if (!first_name || !last_name || !email || !password || !normalizedRole) {
      return res.status(400).json({
        success: false,
        message: "All registration fields and a valid role are required.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await findUserByEmail(normalizedEmail);

    if (existingUser) {
      return res.status(409).json({
        success: false,
        code: "email_already_registered",
        message: "Email is already registered.",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await createUser(
      first_name.trim(),
      last_name.trim(),
      normalizedEmail,
      hashedPassword,
      normalizedRole,
    );

    return res.status(201).json({
      success: true,
      message: "Account created successfully.",
      user: sanitizeUser(user),
    });
  } catch (error) {
    console.error("Registration failed:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        code: "email_already_registered",
        message: "Email is already registered.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Unable to create the account.",
    });
  }
};

// ==========================
// Login Local User
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

    const user = await findUserByEmail(normalizedEmail);

    if (!user) {
      return res.status(401).json({
        success: false,
        code: "invalid_credentials",
        message: "Invalid email or password.",
      });
    }

    if (!user.password) {
      return res.status(401).json({
        success: false,
        code: "google_sign_in_required",
        message: "This account uses Continue with Google.",
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        code: "invalid_credentials",
        message: "Invalid email or password.",
      });
    }

    return res
      .status(200)
      .json(createAuthenticationResponse(user, "Login successful.", false));
  } catch (error) {
    console.error("Login failed:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to sign in.",
    });
  }
};

// ==========================
// Continue With Google
// ==========================

const continueWithGoogle = async (req, res) => {
  try {
    const { id_token, role } = req.body;

    if (!id_token) {
      return res.status(400).json({
        success: false,
        code: "missing_google_token",
        message: "A Google ID token is required.",
      });
    }

    const googleIdentity = await verifyGoogleIdToken(id_token);

    const existingGoogleUser = await findUserByGoogleSub(
      googleIdentity.googleSub,
    );

    if (existingGoogleUser) {
      return res
        .status(200)
        .json(
          createAuthenticationResponse(
            existingGoogleUser,
            "Google sign-in successful.",
            false,
          ),
        );
    }

    const existingEmailUser = await findUserByEmail(googleIdentity.email);

    if (existingEmailUser) {
      return res.status(409).json({
        success: false,
        code: "account_link_required",
        message:
          "An account already uses this email. Sign in with your password before linking Google.",
      });
    }

    const normalizedRole = normalizeRole(role);

    if (!normalizedRole) {
      return res.status(400).json({
        success: false,
        code: "role_required",
        message: "Choose Student or Educator to create your account.",
      });
    }

    const user = await createGoogleUser({
      firstName: googleIdentity.firstName,
      lastName: googleIdentity.lastName,
      email: googleIdentity.email,
      role: normalizedRole,
      googleSub: googleIdentity.googleSub,
    });

    return res
      .status(201)
      .json(
        createAuthenticationResponse(
          user,
          "Google account created successfully.",
          true,
        ),
      );
  } catch (error) {
    console.error("Google authentication failed:", error);

    if (error instanceof GoogleAuthServiceError) {
      if (error.code === "google_not_configured") {
        return res.status(503).json({
          success: false,
          code: error.code,
          message: "Google authentication is temporarily unavailable.",
        });
      }

      if (error.code === "missing_google_token") {
        return res.status(400).json({
          success: false,
          code: error.code,
          message: error.message,
        });
      }

      return res.status(401).json({
        success: false,
        code: error.code,
        message: "The Google account could not be verified.",
      });
    }

    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        code: "google_account_conflict",
        message: "This Google account or email is already registered.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Unable to continue with Google.",
    });
  }
};

module.exports = {
  register,
  login,
  continueWithGoogle,
};
