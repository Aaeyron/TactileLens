const { OAuth2Client } = require("google-auth-library");

class GoogleAuthServiceError extends Error {
  constructor(message, code) {
    super(message);

    this.name = "GoogleAuthServiceError";
    this.code = code;
  }
}

const googleClient = new OAuth2Client();

const getGoogleClientId = () => {
  const clientId = process.env.GOOGLE_CLIENT_ID?.trim();

  if (!clientId) {
    throw new GoogleAuthServiceError(
      "GOOGLE_CLIENT_ID is not configured.",
      "google_not_configured",
    );
  }

  return clientId;
};

const readString = (value) => {
  return typeof value === "string" ? value.trim() : "";
};

const verifyGoogleIdToken = async (idToken) => {
  const normalizedToken = readString(idToken);

  if (!normalizedToken) {
    throw new GoogleAuthServiceError(
      "A Google ID token is required.",
      "missing_google_token",
    );
  }

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken: normalizedToken,
      audience: getGoogleClientId(),
    });

    const payload = ticket.getPayload();

    if (!payload) {
      throw new GoogleAuthServiceError(
        "Google did not return an identity.",
        "invalid_google_token",
      );
    }

    const googleSub = readString(payload.sub);
    const email = readString(payload.email).toLowerCase();

    if (!googleSub || !email) {
      throw new GoogleAuthServiceError(
        "The Google account information is incomplete.",
        "incomplete_google_identity",
      );
    }

    if (payload.email_verified !== true) {
      throw new GoogleAuthServiceError(
        "The Google email address is not verified.",
        "unverified_google_email",
      );
    }

    const fullName = readString(payload.name);
    const nameParts = fullName.split(/\s+/).filter(Boolean);

    const firstName =
      readString(payload.given_name) || nameParts[0] || "Google";

    const lastName =
      readString(payload.family_name) || nameParts.slice(1).join(" ") || "User";

    return {
      googleSub,
      email,
      firstName,
      lastName,
      pictureUrl: readString(payload.picture),
    };
  } catch (error) {
    if (error instanceof GoogleAuthServiceError) {
      throw error;
    }

    throw new GoogleAuthServiceError(
      "The Google identity could not be verified.",
      "invalid_google_token",
    );
  }
};

module.exports = {
  GoogleAuthServiceError,
  verifyGoogleIdToken,
};
