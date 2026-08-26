const db = require("../../config/database");

// ==========================
// Create Folder
// ==========================

const createFolder = async ({ userId, name }) => {
  const query = `
    INSERT INTO material_folders (
      user_id,
      name
    )
    VALUES ($1, BTRIM($2))
    RETURNING
      id,
      user_id,
      name,
      created_at,
      updated_at;
  `;

  const result = await db.query(query, [userId, name]);

  return {
    ...result.rows[0],
    item_count: 0,
  };
};

// ==========================
// Get All Owned Folders
// ==========================

const getFoldersByUser = async (userId) => {
  const query = `
    SELECT
      folders.id,
      folders.user_id,
      folders.name,
      folders.created_at,
      folders.updated_at,
      COUNT(materials.id)::INTEGER AS item_count
    FROM material_folders AS folders
    LEFT JOIN materials
      ON materials.folder_id = folders.id
      AND materials.user_id = folders.user_id
    WHERE folders.user_id = $1
    GROUP BY
      folders.id,
      folders.user_id,
      folders.name,
      folders.created_at,
      folders.updated_at
    ORDER BY
      LOWER(folders.name) ASC,
      folders.id ASC;
  `;

  const result = await db.query(query, [userId]);

  return result.rows;
};

// ==========================
// Get One Owned Folder
// ==========================

const getFolderById = async ({ folderId, userId }) => {
  const query = `
    SELECT
      folders.id,
      folders.user_id,
      folders.name,
      folders.created_at,
      folders.updated_at,
      COUNT(materials.id)::INTEGER AS item_count
    FROM material_folders AS folders
    LEFT JOIN materials
      ON materials.folder_id = folders.id
      AND materials.user_id = folders.user_id
    WHERE folders.id = $1
      AND folders.user_id = $2
    GROUP BY
      folders.id,
      folders.user_id,
      folders.name,
      folders.created_at,
      folders.updated_at;
  `;

  const result = await db.query(query, [folderId, userId]);

  return result.rows[0] ?? null;
};

// ==========================
// Find Owned Folder by Name
// ==========================

const findFolderByName = async ({ userId, name, excludeFolderId = null }) => {
  const query = `
    SELECT
      id,
      user_id,
      name,
      created_at,
      updated_at
    FROM material_folders
    WHERE user_id = $1
      AND LOWER(BTRIM(name)) = LOWER(BTRIM($2))
      AND (
        $3::INTEGER IS NULL
        OR id <> $3
      )
    LIMIT 1;
  `;

  const result = await db.query(query, [userId, name, excludeFolderId]);

  return result.rows[0] ?? null;
};

// ==========================
// Rename Owned Folder
// ==========================

const renameFolder = async ({ folderId, userId, name }) => {
  const query = `
    UPDATE material_folders
    SET
      name = BTRIM($3),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = $1
      AND user_id = $2
    RETURNING
      id,
      user_id,
      name,
      created_at,
      updated_at;
  `;

  const result = await db.query(query, [folderId, userId, name]);

  return result.rows[0] ?? null;
};

// ==========================
// Delete Owned Folder
// ==========================

const deleteFolder = async ({ folderId, userId }) => {
  const query = `
    DELETE FROM material_folders
    WHERE id = $1
      AND user_id = $2
    RETURNING
      id,
      user_id,
      name,
      created_at,
      updated_at;
  `;

  const result = await db.query(query, [folderId, userId]);

  return result.rows[0] ?? null;
};

// ==========================
// Move Material to Folder
// ==========================

const moveMaterialToFolder = async ({ materialId, folderId, userId }) => {
  const query = `
    UPDATE materials
    SET folder_id = $3
    WHERE id = $1
      AND user_id = $2
      AND (
        $3::INTEGER IS NULL
        OR EXISTS (
          SELECT 1
          FROM material_folders
          WHERE id = $3
            AND user_id = $2
        )
      )
    RETURNING *;
  `;

  const result = await db.query(query, [materialId, userId, folderId]);

  return result.rows[0] ?? null;
};

module.exports = {
  createFolder,
  getFoldersByUser,
  getFolderById,
  findFolderByName,
  renameFolder,
  deleteFolder,
  moveMaterialToFolder,
};
