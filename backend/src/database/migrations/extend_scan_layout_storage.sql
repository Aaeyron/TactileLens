BEGIN;

ALTER TABLE materials
ADD COLUMN IF NOT EXISTS document_pages JSONB
  NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE scan_history
ADD COLUMN IF NOT EXISTS document_pages JSONB
  NOT NULL DEFAULT '[]'::jsonb;

DO $$
BEGIN
  ALTER TABLE materials
  ADD CONSTRAINT materials_document_pages_is_array
  CHECK (
    jsonb_typeof(document_pages) = 'array'
  );
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END
$$;

DO $$
BEGIN
  ALTER TABLE scan_history
  ADD CONSTRAINT scan_history_document_pages_is_array
  CHECK (
    jsonb_typeof(document_pages) = 'array'
  );
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END
$$;

COMMIT;