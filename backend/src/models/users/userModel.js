const pool = require("../../config/database");

// ==========================
// Create Local User
// ==========================

const createUser = async (
  firstName,
  lastName,
  email,
  hashedPassword,
  role,
) => {
  const query = `
    INSERT INTO users (
      first_name,
      last_name,
      email,
      password,
      role
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING
      id,
      first_name,
      last_name,
      email,
      role,
      google_sub,
      created_at;
  `;

  const values = [
    firstName,
    lastName,
    email,
    hashedPassword,
    role,
  ];

  const result = await pool.query(query, values);

  return result.rows[0];
};

// ==========================
// Create Google User
// ==========================

const createGoogleUser = async ({
  firstName,
  lastName,
  email,
  googleSub,
  role,
}) => {
  const query = `
    INSERT INTO users (
      first_name,
      last_name,
      email,
      password,
      role,
      google_sub
    )
    VALUES ($1, $2, $3, NULL, $4, $5)
    RETURNING
      id,
      first_name,
      last_name,
      email,
      role,
      google_sub,
      created_at;
  `;

  const values = [
    firstName,
    lastName,
    email,
    role,
    googleSub,
  ];

  const result = await pool.query(query, values);

  return result.rows[0];
};

// ==========================
// Find User By Email
// ==========================

const findUserByEmail = async (email) => {
  const query = `
    SELECT
      id,
      first_name,
      last_name,
      email,
      password,
      role,
      google_sub,
      created_at
    FROM users
    WHERE LOWER(email) = LOWER($1)
    LIMIT 1;
  `;

  const result = await pool.query(query, [email]);

  return result.rows[0];
};

// ==========================
// Find User By Google Subject
// ==========================

const findUserByGoogleSub = async (googleSub) => {
  const query = `
    SELECT
      id,
      first_name,
      last_name,
      email,
      password,
      role,
      google_sub,
      created_at
    FROM users
    WHERE google_sub = $1
    LIMIT 1;
  `;

  const result = await pool.query(query, [googleSub]);

  return result.rows[0];
};

// ==========================
// Find User By ID
// ==========================

const findUserById = async (userId) => {
  const query = `
    SELECT
      id,
      first_name,
      last_name,
      email,
      password,
      role,
      google_sub,
      created_at
    FROM users
    WHERE id = $1
    LIMIT 1;
  `;

  const result = await pool.query(query, [userId]);

  return result.rows[0];
};

// ==========================
// Update User Password
// ==========================

const updateUserPassword = async (
  userId,
  hashedPassword,
) => {
  const query = `
    UPDATE users
    SET password = $2
    WHERE id = $1
    RETURNING
      id,
      first_name,
      last_name,
      email,
      role,
      google_sub,
      created_at;
  `;

  const result = await pool.query(query, [
    userId,
    hashedPassword,
  ]);

  return result.rows[0];
};

// Keep exports after every const function has been initialized.
module.exports = {
  createUser,
  createGoogleUser,
  findUserByEmail,
  findUserByGoogleSub,
  findUserById,
  updateUserPassword,
};