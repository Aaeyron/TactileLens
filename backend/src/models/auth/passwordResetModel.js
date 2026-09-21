const pool = require("../../config/database");

const maximumFailedAttempts = 5;

// ==========================
// Find Latest Reset Request
// ==========================

const findLatestPasswordResetRequest = async (userId) => {
  const query = `
    SELECT
      id,
      user_id,
      failed_attempts,
      expires_at,
      used_at,
      created_at
    FROM public.password_reset_tokens
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 1;
  `;

  const result = await pool.query(query, [userId]);

  return result.rows[0];
};

// ==========================
// Replace Active Reset Token
// ==========================

const createPasswordResetToken = async ({
  userId,
  tokenHash,
  expiresAt,
}) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(
      `
        UPDATE public.password_reset_tokens
        SET used_at = CURRENT_TIMESTAMP
        WHERE user_id = $1
          AND used_at IS NULL;
      `,
      [userId],
    );

    const result = await client.query(
      `
        INSERT INTO public.password_reset_tokens (
          user_id,
          token_hash,
          failed_attempts,
          expires_at
        )
        VALUES ($1, $2, 0, $3)
        RETURNING
          id,
          user_id,
          failed_attempts,
          expires_at,
          used_at,
          created_at;
      `,
      [userId, tokenHash, expiresAt],
    );

    await client.query("COMMIT");

    return result.rows[0];
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

// ==========================
// Find Valid Active Token
// ==========================

const findActivePasswordResetToken = async (userId) => {
  const query = `
    SELECT
      id,
      user_id,
      token_hash,
      failed_attempts,
      expires_at,
      used_at,
      created_at
    FROM public.password_reset_tokens
    WHERE user_id = $1
      AND used_at IS NULL
      AND expires_at > CURRENT_TIMESTAMP
      AND failed_attempts < $2
    ORDER BY created_at DESC
    LIMIT 1;
  `;

  const result = await pool.query(query, [
    userId,
    maximumFailedAttempts,
  ]);

  return result.rows[0];
};

// ==========================
// Record Failed Attempt
// ==========================

const incrementPasswordResetAttempts = async (tokenId) => {
  const query = `
    UPDATE public.password_reset_tokens
    SET
      failed_attempts = LEAST(
        failed_attempts + 1,
        $2
      ),
      used_at = CASE
        WHEN failed_attempts + 1 >= $2
          THEN CURRENT_TIMESTAMP
        ELSE used_at
      END
    WHERE id = $1
      AND used_at IS NULL
    RETURNING
      id,
      user_id,
      failed_attempts,
      expires_at,
      used_at,
      created_at;
  `;

  const result = await pool.query(query, [
    tokenId,
    maximumFailedAttempts,
  ]);

  return result.rows[0];
};


// ==========================
// Invalidate Reset Token
// ==========================

const invalidatePasswordResetToken = async (tokenId) => {
  const query = `
    UPDATE public.password_reset_tokens
    SET used_at = COALESCE(
      used_at,
      CURRENT_TIMESTAMP
    )
    WHERE id = $1
    RETURNING
      id,
      user_id,
      failed_attempts,
      expires_at,
      used_at,
      created_at;
  `;

  const result = await pool.query(query, [tokenId]);

  return result.rows[0];
};

// ==========================
// Consume Token And Reset Password
// ==========================

const consumeTokenAndUpdatePassword = async ({
  tokenId,
  userId,
  hashedPassword,
}) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const consumedTokenResult = await client.query(
      `
        UPDATE public.password_reset_tokens
        SET used_at = CURRENT_TIMESTAMP
        WHERE id = $1
          AND user_id = $2
          AND used_at IS NULL
          AND expires_at > CURRENT_TIMESTAMP
          AND failed_attempts < $3
        RETURNING id;
      `,
      [
        tokenId,
        userId,
        maximumFailedAttempts,
      ],
    );

    if (consumedTokenResult.rowCount !== 1) {
      await client.query("ROLLBACK");
      return null;
    }

    const updatedUserResult = await client.query(
      `
        UPDATE public.users
        SET password = $2
        WHERE id = $1
          AND password IS NOT NULL
          AND google_sub IS NULL
        RETURNING
          id,
          first_name,
          last_name,
          email,
          role,
          google_sub,
          created_at;
      `,
      [userId, hashedPassword],
    );

    if (updatedUserResult.rowCount !== 1) {
      throw new Error(
        "The password account could not be updated.",
      );
    }

    await client.query(
      `
        UPDATE public.password_reset_tokens
        SET used_at = CURRENT_TIMESTAMP
        WHERE user_id = $1
          AND id <> $2
          AND used_at IS NULL;
      `,
      [userId, tokenId],
    );

    await client.query("COMMIT");

    return updatedUserResult.rows[0];
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  maximumFailedAttempts,
  findLatestPasswordResetRequest,
  createPasswordResetToken,
  findActivePasswordResetToken,
  incrementPasswordResetAttempts,
  invalidatePasswordResetToken,
  consumeTokenAndUpdatePassword,
};