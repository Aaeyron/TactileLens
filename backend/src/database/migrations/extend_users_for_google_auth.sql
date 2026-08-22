const pool = require("../../config/database");

// ==========================
// Create Local User
// ==========================

const createUser = async (
  firstName,
  lastName,
  email,
  hashedPassword,
  role
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
  role,
  googleSub,
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
    SELECT *
    FROM users
    WHERE email = $1
    LIMIT 1;
  `;

  const result = await pool.query(query, [email]);

  return result.rows[0];
};

// ==========================
// Find User By Google ID
// ==========================

const findUserByGoogleSub = async (googleSub) => {
  const query = `
    SELECT *
    FROM users
    WHERE google_sub = $1
    LIMIT 1;
  `;

  const result = await pool.query(query, [googleSub]);

  return result.rows[0];
};

module.exports = {
  createUser,
  createGoogleUser,
  findUserByEmail,
  findUserByGoogleSub,
};