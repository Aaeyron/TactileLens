const jwt = require("jsonwebtoken");

// ==========================
// Authenticate Access Token
// ==========================

const authenticateToken = (req, res, next) => {
  const authorizationHeader = req.headers.authorization;

  if (!authorizationHeader) {
    return res.status(401).json({
      success: false,
      message: "Authentication is required.",
    });
  }

  const [scheme, token] = authorizationHeader.trim().split(/\s+/);

  if (
    scheme?.toLowerCase() !== "bearer" ||
    !token
  ) {
    return res.status(401).json({
      success: false,
      message: "A valid Bearer token is required.",
    });
  }

  const jwtSecret = process.env.JWT_SECRET;

  if (!jwtSecret) {
    console.error("JWT_SECRET is not configured.");

    return res.status(500).json({
      success: false,
      message: "Authentication service is unavailable.",
    });
  }

  try {
    const decodedToken = jwt.verify(token, jwtSecret);

    if (
      typeof decodedToken !== "object" ||
      !decodedToken.sub
    ) {
      return res.status(401).json({
        success: false,
        message: "The access token is invalid.",
      });
    }

    const userId = Number(decodedToken.sub);

    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(401).json({
        success: false,
        message: "The access token contains an invalid user.",
      });
    }

    req.user = {
      id: userId,
      role:
          typeof decodedToken.role === "string"
              ? decodedToken.role
              : null,
    };

    return next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({
        success: false,
        message: "Your session has expired. Please sign in again.",
      });
    }

    if (error instanceof jwt.JsonWebTokenError) {
      return res.status(401).json({
        success: false,
        message: "The access token is invalid.",
      });
    }

    console.error("JWT verification failed:", error);

    return res.status(500).json({
      success: false,
      message: "Authentication could not be completed.",
    });
  }
};

module.exports = {
  authenticateToken,
};