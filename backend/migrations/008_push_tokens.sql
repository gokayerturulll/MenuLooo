-- Migration 008: APNs push token tablosu
-- Her kullanıcı birden fazla cihaza sahip olabilir.
-- user_id + device_token çifti unique olduğundan aynı token tekrar kaydedilince
-- ON CONFLICT ile updated_at güncellenir (upsert).

CREATE TABLE IF NOT EXISTS push_token (
    token_id     SERIAL PRIMARY KEY,
    user_id      INTEGER NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    device_token TEXT    NOT NULL,
    platform     TEXT    NOT NULL DEFAULT 'ios' CHECK (platform IN ('ios', 'android')),
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, device_token)
);

CREATE INDEX IF NOT EXISTS idx_push_token_user_id ON push_token(user_id);
