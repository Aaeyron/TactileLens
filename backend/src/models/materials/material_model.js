const db = require("../../config/database");

// ==========================
// Create Material
// ==========================

const createMaterial = async (materialData) => {
  const {
    user_id,
    title,
    subject,
    description = null,
    file_name,
    file_path,
    file_type,
    file_size,
    source_type = "uploaded_file",
    recognized_content = "",
    braille_content = "",
    document_blocks = [],
    model_name = null,
    pipeline_version = null,
    processing_time_ms = null,
  } = materialData;

  const query = `
    INSERT INTO materials (
      user_id,
      title,
      subject,
      description,
      file_name,
      file_path,
      file_type,
      file_size,
      source_type,
      recognized_content,
      braille_content,
      document_blocks,
      model_name,
      pipeline_version,
      processing_time_ms
    )
    VALUES (
      $1,
      $2,
      $3,
      $4,
      $5,
      $6,
      $7,
      $8,
      $9,
      $10,
      $11,
      $12::jsonb,
      $13,
      $14,
      $15
    )
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
    source_type,
    recognized_content,
    braille_content,
    JSON.stringify(document_blocks),
    model_name,
    pipeline_version,
    processing_time_ms,
  ];

  const result = await db.query(query, values);

  return result.rows[0];
};

// ==========================
// Get All Owned Materials
// ==========================

const getAllMaterials = async (userId) => {
  const query = `
    SELECT *
    FROM materials
    WHERE user_id = $1
    ORDER BY uploaded_at DESC, id DESC;
  `;

  const result = await db.query(query, [userId]);

  return result.rows;
};

// ==========================
// Get One Owned Material
// ==========================

const getMaterialById = async ({
  materialId,
  userId,
}) => {
  const query = `
    SELECT *
    FROM materials
    WHERE id = $1
      AND user_id = $2;
  `;

  const result = await db.query(query, [
    materialId,
    userId,
  ]);

  return result.rows[0] ?? null;
};

// ==========================
// Delete One Owned Material
// ==========================

const deleteMaterial = async ({
  materialId,
  userId,
}) => {
  const query = `
    DELETE FROM materials
    WHERE id = $1
      AND user_id = $2
    RETURNING *;
  `;

  const result = await db.query(query, [
    materialId,
    userId,
  ]);

  return result.rows[0] ?? null;
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