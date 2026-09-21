const nodemailer = require("nodemailer");

class EmailServiceError extends Error {
  constructor(code, message, cause = null) {
    super(message);

    this.name = "EmailServiceError";
    this.code = code;
    this.cause = cause;
  }
}

let transporter = null;

// ==========================
// SMTP Configuration
// ==========================

const readRequiredEnvironmentValue = (name) => {
  const value = process.env[name]?.trim();

  if (!value) {
    throw new EmailServiceError(
      "email_not_configured",
      `${name} is not configured.`,
    );
  }

  return value;
};

const createTransporter = () => {
  const host = readRequiredEnvironmentValue("SMTP_HOST");
  const username = readRequiredEnvironmentValue("SMTP_USER");
  const password = readRequiredEnvironmentValue("SMTP_PASSWORD");

  const portValue = process.env.SMTP_PORT?.trim() || "587";
  const port = Number.parseInt(portValue, 10);

  if (!Number.isInteger(port) || port <= 0 || port > 65535) {
    throw new EmailServiceError(
      "email_not_configured",
      "SMTP_PORT must be a valid network port.",
    );
  }

  const secureValue = process.env.SMTP_SECURE?.trim().toLowerCase();

  const secure =
    secureValue === "true" ||
    (secureValue !== "false" && port === 465);

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user: username,
      pass: password,
    },
    pool: true,
    maxConnections: 3,
    maxMessages: 100,
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
  });
};

const getTransporter = () => {
  if (!transporter) {
    transporter = createTransporter();
  }

  return transporter;
};

// ==========================
// Email Content Helpers
// ==========================

const escapeHtml = (value) => {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
};

const getSender = () => {
  const address =
    process.env.SMTP_FROM_EMAIL?.trim() ||
    readRequiredEnvironmentValue("SMTP_USER");

  const name =
    process.env.SMTP_FROM_NAME?.trim() ||
    "TactileLens";

  return {
    name,
    address,
  };
};

// ==========================
// Verify SMTP Connection
// ==========================

const verifyEmailTransport = async () => {
  try {
    await getTransporter().verify();

    return true;
  } catch (error) {
    throw new EmailServiceError(
      "email_transport_unavailable",
      "The email service could not connect to the configured SMTP server.",
      error,
    );
  }
};

// ==========================
// Send Password Reset Code
// ==========================

const sendPasswordResetCode = async ({
  recipientEmail,
  recipientFirstName,
  resetCode,
  expiresInMinutes,
}) => {
  const normalizedEmail = recipientEmail?.trim();
  const normalizedCode = resetCode?.trim();

  if (!normalizedEmail || !normalizedCode) {
    throw new EmailServiceError(
      "invalid_email_message",
      "The recipient email and reset code are required.",
    );
  }

  const displayName =
    recipientFirstName?.trim() ||
    "TactileLens user";

  const safeDisplayName = escapeHtml(displayName);
  const safeResetCode = escapeHtml(normalizedCode);
  const safeExpiration = escapeHtml(expiresInMinutes);

  try {
    const information = await getTransporter().sendMail({
      from: getSender(),
      to: normalizedEmail,
      subject: "Reset your TactileLens password",
      text: [
        `Hello ${displayName},`,
        "",
        `Your TactileLens password reset code is: ${normalizedCode}`,
        "",
        `This code expires in ${expiresInMinutes} minutes.`,
        "If you did not request this reset, you can ignore this email.",
        "",
        "TactileLens",
      ].join("\n"),
      html: `
        <div style="font-family: Arial, sans-serif; color: #10213d;">
          <h2 style="color: #1268f3;">
            Reset your TactileLens password
          </h2>

          <p>Hello ${safeDisplayName},</p>

          <p>Use this verification code to reset your password:</p>

          <p
            style="
              display: inline-block;
              padding: 14px 20px;
              border-radius: 10px;
              background: #edf4ff;
              color: #0758dd;
              font-size: 28px;
              font-weight: 700;
              letter-spacing: 6px;
            "
          >
            ${safeResetCode}
          </p>

          <p>
            This code expires in ${safeExpiration} minutes.
          </p>

          <p>
            If you did not request this reset, you can safely ignore
            this email.
          </p>

          <p>TactileLens</p>
        </div>
      `,
    });

    return {
      messageId: information.messageId,
      accepted: information.accepted,
      rejected: information.rejected,
    };
  } catch (error) {
    if (error instanceof EmailServiceError) {
      throw error;
    }

    throw new EmailServiceError(
      "email_delivery_failed",
      "The password reset email could not be delivered.",
      error,
    );
  }
};

module.exports = {
  EmailServiceError,
  verifyEmailTransport,
  sendPasswordResetCode,
};