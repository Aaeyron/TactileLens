const db = require("../../config/database");

// ==========================
// Create Material
// ==========================

const createMaterial = async (materialData) => {
  const {
    user_id,
    title,
    subject,
    description,
    file_name,
    file_path,
    file_type,
    file_size,
  } = materialData;

  const query = `
    INSERT INTO materials
    (
      user_id,
      title,
      subject,
      description,
      file_name,
      file_path,
      file_type,
      file_size
    )
    VALUES
    ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *;
  `;

  const values = [
    user_id,
    title,
    subject,
    description,
    file_name,
    file_path,
    file_type,
    file_size,
  ];

  const result = await db.query(query, values);

  return result.rows[0];
};

// ==========================
// Get All Materials
// ==========================

const getAllMaterials = async () => {
  const query = `
    SELECT *
    FROM materials
    ORDER BY uploaded_at DESC;
  `;

  const result = await db.query(query);

  return result.rows;
};

// ==========================
// Get Material By ID
// ==========================

const getMaterialById = async (id) => {
  const query = `
    SELECT *
    FROM materials
    WHERE id = $1;
  `;

  const result = await db.query(query, [id]);

  return result.rows[0];
};

// ==========================
// Delete Material
// ==========================

const deleteMaterial = async (id) => {
  const query = `
    DELETE FROM materials
    WHERE id = $1
    RETURNING *;
  `;

  const result = await db.query(query, [id]);

  return result.rows[0];
};

// ==========================
// Export
// ==========================

module.exports = {
  createMaterial,
  getAllMaterials,
  getMaterialById,
  deleteMaterial,
};