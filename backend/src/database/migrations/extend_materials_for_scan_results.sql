BEGIN;

ALTER TABLE materials
  ADD COLUMN IF NOT EXISTS source_type VARCHAR(30)
    NOT NULL DEFAULT 'uploaded_file',
  ADD COLUMN IF NOT EXISTS recognized_content TEXT
    NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS braille_content TEXT
    NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS document_blocks JSONB
    NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS model_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS pipeline_version VARCHAR(30),
  ADD COLUMN IF NOT EXISTS processing_time_ms DOUBLE PRECISION;

DO $$
BEGIN
  ALTER TABLE materials
    ADD CONSTRAINT materials_source_type_check
    CHECK (
      source_type IN (
        'uploaded_file',
        'scan_result'
      )
    );
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END
$$;

COMMIT;