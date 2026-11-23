const { Pool } = require("pg");
require("dotenv").config();

const isLocalHost = (host) =>
  !host || host === "localhost" || host === "127.0.0.1";

const getSslConfig = () => {
  if (process.env.DB_SSL === "false") {
    return false;
  }

  if (process.env.DB_SSL === "true") {
    return { rejectUnauthorized: false };
  }

  // Auto-detect remote hosts when DB_SSL is unset
  if (
    process.env.DATABASE_URL &&
    !process.env.DATABASE_URL.includes("localhost") &&
    !process.env.DATABASE_URL.includes("127.0.0.1")
  ) {
    return { rejectUnauthorized: false };
  }

  if (process.env.DB_HOST && !isLocalHost(process.env.DB_HOST)) {
    return { rejectUnauthorized: false };
  }

  return false;
};

const poolConfig = process.env.DATABASE_URL
  ? {
      connectionString: process.env.DATABASE_URL,
      ssl: getSslConfig(),
      max: Number(process.env.DB_POOL_MAX) || 10,
    }
  : {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 5432,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: getSslConfig(),
      max: Number(process.env.DB_POOL_MAX) || 10,
    };

const pool = new Pool(poolConfig);

pool
  .connect()
  .then((client) => {
    console.log("✅ Connected to PostgreSQL Database");

    client.release();
  })
  .catch((err) => {
    console.error("❌ PostgreSQL Connection Error:", err.message);
  });

module.exports = pool;
