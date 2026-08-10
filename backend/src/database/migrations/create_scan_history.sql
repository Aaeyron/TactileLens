BEGIN;

CREATE TABLE IF NOT EXISTS scan_history (
    id BIGSERIAL PRIMARY KEY,

    user_id INTEGER NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    title VARCHAR(150) NOT NULL
        DEFAULT 'Untitled Scan',

    recognized_content TEXT NOT NULL,
    braille_content TEXT NOT NULL
        DEFAULT '',

    document_blocks JSONB NOT NULL
        DEFAULT '[]'::jsonb,

    source_image_path TEXT,

    model_name VARCHAR(100),
    pipeline_version VARCHAR(30),
    processing_time_ms DOUBLE PRECISION,

    created_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT scan_history_title_not_empty
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT scan_history_content_not_empty
        CHECK (char_length(trim(recognized_content)) > 0),

    CONSTRAINT scan_history_blocks_is_array
        CHECK (jsonb_typeof(document_blocks) = 'array'),

    CONSTRAINT scan_history_processing_time_valid
        CHECK (
            processing_time_ms IS NULL
            OR processing_time_ms >= 0
        )
);

CREATE INDEX IF NOT EXISTS idx_scan_history_user_created_at
    ON scan_history (user_id, created_at DESC);

COMMIT;