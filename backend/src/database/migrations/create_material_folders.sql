BEGIN;

CREATE TABLE IF NOT EXISTS material_folders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  name VARCHAR(80) NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT material_folders_name_not_blank
    CHECK (
      CHAR_LENGTH(BTRIM(name)) BETWEEN 1 AND 80
    ),

  CONSTRAINT fk_material_folder_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS
  material_folders_user_name_unique
ON material_folders (
  user_id,
  LOWER(BTRIM(name))
);

CREATE INDEX IF NOT EXISTS
  material_folders_user_id_index
ON material_folders (
  user_id
);

ALTER TABLE materials
ADD COLUMN IF NOT EXISTS folder_id INTEGER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_material_folder'
  ) THEN
    ALTER TABLE materials
    ADD CONSTRAINT fk_material_folder
      FOREIGN KEY (folder_id)
      REFERENCES material_folders(id)
      ON DELETE SET NULL;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS
  materials_folder_id_index
ON materials (
  folder_id
);

CREATE INDEX IF NOT EXISTS
  materials_user_folder_index
ON materials (
  user_id,
  folder_id
);

COMMIT;