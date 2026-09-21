BEGIN;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL
        REFERENCES users(id)
        ON DELETE CASCADE,

    token_hash CHAR(64) NOT NULL UNIQUE,

    failed_attempts SMALLINT NOT NULL DEFAULT 0
        CHECK (failed_attempts >= 0 AND failed_attempts <= 5),

    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS
    password_reset_tokens_user_id_index
ON password_reset_tokens (user_id);

CREATE INDEX IF NOT EXISTS
    password_reset_tokens_expires_at_index
ON password_reset_tokens (expires_at);

CREATE INDEX IF NOT EXISTS
    password_reset_tokens_active_user_index
ON password_reset_tokens (user_id)
WHERE used_at IS NULL;

COMMIT;