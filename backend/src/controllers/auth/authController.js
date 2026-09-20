const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const {
  createUser,
  createGoogleUser,
  findUserByEmail,
  findUserByGoogleSub,
  findUserById,
  updateUserPassword,
} = require("../../models/users/userModel");

const {
  GoogleAuthServiceError,
  verifyGoogleIdToken,
} = require("../../services/auth/google_auth_service");

const TOKEN_EXPIRATION = process.env.JWT_EXPIRES_IN || "7d";

const ALLOWED_ROLES = new Set(["Student", "Educator"]);
const PASSWORD_MINIMUM_LENGTH = 8;
const PASSWORD_MAXIMUM_LENGTH = 128;

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
    auth_provider: user.google_sub ? "google" : "password",
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
      if (existingUser.google_sub) {
        return res.status(409).json({
          success: false,
          code: "google_email_already_registered",
          message:
            "This email is already registered with Google. Please sign in with Google instead.",
        });
      }

      return res.status(409).json({
        success: false,
        code: "email_already_registered",
        message: "This email is already registered. Please sign in instead.",
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
// Change Password
// ==========================

const changePassword = async (req, res) => {
  try {
    const userId = req.user?.id;

    const {
      current_password: currentPassword,
      new_password: newPassword,
    } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        code: "authentication_required",
        message: "Authentication is required.",
      });
    }

    if (
      typeof currentPassword !== "string" ||
      typeof newPassword !== "string" ||
      currentPassword.length === 0 ||
      newPassword.length === 0
    ) {
      return res.status(400).json({
        success: false,
        code: "password_fields_required",
        message: "Current password and new password are required.",
      });
    }

    if (
      newPassword.length < PASSWORD_MINIMUM_LENGTH ||
      newPassword.length > PASSWORD_MAXIMUM_LENGTH
    ) {
      return res.status(400).json({
        success: false,
        code: "invalid_new_password",
        message:
          "The new password must contain between 8 and 128 characters.",
      });
    }

    const user = await findUserById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        code: "user_not_found",
        message: "The authenticated account could not be found.",
      });
    }

    if (!user.password) {
      return res.status(409).json({
        success: false,
        code: "google_password_managed",
        message:
          "This account uses Google Sign-In. Manage your password through your Google Account.",
      });
    }

    const currentPasswordIsValid = await bcrypt.compare(
      currentPassword,
      user.password,
    );

    if (!currentPasswordIsValid) {
      return res.status(401).json({
        success: false,
        code: "incorrect_current_password",
        message: "The current password is incorrect.",
      });
    }

    const passwordIsUnchanged = await bcrypt.compare(
      newPassword,
      user.password,
    );

    if (passwordIsUnchanged) {
      return res.status(400).json({
        success: false,
        code: "password_unchanged",
        message:
          "The new password must be different from your current password.",
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await updateUserPassword(userId, hashedPassword);

    return res.status(200).json({
      success: true,
      message: "Your password was changed successfully.",
    });
  } catch (error) {
    console.error("Password change failed:", error);

    return res.status(500).json({
      success: false,
      code: "password_change_failed",
      message: "Unable to change your password.",
    });
  }
};

// ==========================
// Google Authentication Error Handler
// ==========================

const handleGoogleAuthenticationError = (error, res, fallbackMessage) => {
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
    code: "google_authentication_failed",
    message: fallbackMessage,
  });
};

// ==========================
// Register With Google
// ==========================

const registerWithGoogle = async (req, res) => {
  try {
    const { id_token, role } = req.body;

    if (!id_token) {
      return res.status(400).json({
        success: false,
        code: "missing_google_token",
        message: "A Google ID token is required.",
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

    const googleIdentity = await verifyGoogleIdToken(id_token);

    const existingGoogleUser = await findUserByGoogleSub(
      googleIdentity.googleSub,
    );

    if (existingGoogleUser) {
      return res.status(409).json({
        success: false,
        code: "google_account_already_registered",
        message:
          "This Google account is already registered. Please sign in instead.",
      });
    }

    const existingEmailUser = await findUserByEmail(googleIdentity.email);

    if (existingEmailUser) {
      return res.status(409).json({
        success: false,
        code: "account_link_required",
        message:
          "An account already uses this email. Please sign in using your password.",
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
    return handleGoogleAuthenticationError(
      error,
      res,
      "Unable to create an account with Google.",
    );
  }
};

// ==========================
// Sign In With Google
// ==========================

const loginWithGoogle = async (req, res) => {
  try {
    const { id_token } = req.body;

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
        code: "google_account_not_linked",
        message:
          "This email uses password sign-in and is not linked to Google.",
      });
    }

    return res.status(404).json({
      success: false,
      code: "google_account_not_found",
      message:
        "No TactileLens account was found for this Google account. Please sign up first.",
    });
  } catch (error) {
    return handleGoogleAuthenticationError(
      error,
      res,
      "Unable to sign in with Google.",
    );
  }
};

module.exports = {
  register,
  login,
  changePassword,
  registerWithGoogle,
  loginWithGoogle,
};