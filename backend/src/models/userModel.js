const pool = require("../config/database");

const createUser = async (
  firstName,
  lastName,
  email,
  hashedPassword
) => {
  const query = `
    INSERT INTO users (
      first_name,
      last_name,
      email,
      password
    )
    VALUES ($1, $2, $3, $4)
    RETURNING id, first_name, last_name, email, created_at;
  `;

  const values = [
    firstName,
    lastName,
    email,
    hashedPassword,
  ];

  const result = await pool.query(query, values);

  return result.rows[0];
};

// Find user by email
const findUserByEmail = async (email) => {
  const query = `
    SELECT *
    FROM users
    WHERE email = $1;
  `;

  const result = await pool.query(query, [email]);

  return result.rows[0];
};

module.exports = {
  createUser,
  findUserByEmail,
};