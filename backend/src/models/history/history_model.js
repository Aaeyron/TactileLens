const pool = require("../../config/database");

// ==========================
// Create History Record
// ==========================

const createHistory = async ({
  userId,
  title,
  recognizedContent,
  brailleContent = "",
  documentBlocks = [],
  sourceImagePath = null,
  modelName = null,
  pipelineVersion = null,
  processingTimeMs = null,
}) => {
  const query = `
    INSERT INTO scan_history (
      user_id,
      title,
      recognized_content,
      braille_content,
      document_blocks,
      source_image_path,
      model_name,
      pipeline_version,
      processing_time_ms
    )
    VALUES (
      $1,
      $2,
      $3,
      $4,
      $5::jsonb,
      $6,
      $7,
      $8,
      $9
    )
    RETURNING
      id,
      user_id,
      title,
      recognized_content,
      braille_content,
      document_blocks,
      source_image_path,
      model_name,
      pipeline_version,
      processing_time_ms,
      created_at,
      updated_at;
  `;

  const values = [
    userId,
    title,
    recognizedContent,
    brailleContent,
    JSON.stringify(documentBlocks),
    sourceImagePath,
    modelName,
    pipelineVersion,
    processingTimeMs,
  ];

  const result = await pool.query(query, values);

  return result.rows[0];
};

// ==========================
// Get User History
// ==========================

const getHistoryByUser = async ({ userId, limit, offset }) => {
  const query = `
    SELECT
      id,
      user_id,
      title,
      recognized_content,
      braille_content,
      document_blocks,
      source_image_path,
      model_name,
      pipeline_version,
      processing_time_ms,
      created_at,
      updated_at
    FROM scan_history
    WHERE user_id = $1
    ORDER BY created_at DESC, id DESC
    LIMIT $2
    OFFSET $3;
  `;

  const result = await pool.query(query, [userId, limit, offset]);

  return result.rows;
};

// ==========================
// Count User History
// ==========================

const countHistoryByUser = async (userId) => {
  const query = `
    SELECT COUNT(*)::integer AS total
    FROM scan_history
    WHERE user_id = $1;
  `;

  const result = await pool.query(query, [userId]);

  return result.rows[0]?.total ?? 0;
};

// ==========================
// Get One Owned History Record
// ==========================

const getHistoryById = async ({ historyId, userId }) => {
  const query = `
    SELECT
      id,
      user_id,
      title,
      recognized_content,
      braille_content,
      document_blocks,
      source_image_path,
      model_name,
      pipeline_version,
      processing_time_ms,
      created_at,
      updated_at
    FROM scan_history
    WHERE id = $1
      AND user_id = $2;
  `;

  const result = await pool.query(query, [historyId, userId]);

  return result.rows[0] ?? null;
};

// ==========================
// Update Owned History Title
// ==========================

const updateHistoryTitle = async ({ historyId, userId, title }) => {
  const query = `
    UPDATE scan_history
    SET
      title = $1,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $2
      AND user_id = $3
    RETURNING
      id,
      user_id,
      title,
      recognized_content,
      braille_content,
      document_blocks,
      source_image_path,
      model_name,
      pipeline_version,
      processing_time_ms,
      created_at,
      updated_at;
  `;

  const result = await pool.query(query, [title, historyId, userId]);

  return result.rows[0] ?? null;
};

// ==========================
// Delete Owned History Record
// ==========================

const deleteHistory = async ({ historyId, userId }) => {
  const query = `
    DELETE FROM scan_history
    WHERE id = $1
      AND user_id = $2
    RETURNING
      id,
      title,
      source_image_path;
  `;

  const result = await pool.query(query, [historyId, userId]);

  return result.rows[0] ?? null;
};

module.exports = {
  createHistory,
  getHistoryByUser,
  countHistoryByUser,
  getHistoryById,
  updateHistoryTitle,
  deleteHistory,
};
