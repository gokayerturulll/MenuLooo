-- 007_password_reset_and_review_reply.sql
-- İki yeni tablo:
--   1. password_reset_token — şifremi unuttum akışı için tek kullanımlık token
--   2. review_reply        — işletme sahibinin müşteri yorumuna yanıtı
--
-- Çalıştırma: psql $DATABASE_URL -f migrations/007_password_reset_and_review_reply.sql
-- Güvenli: IF NOT EXISTS ile re-run edilebilir.

BEGIN;

-- ─── Password Reset Tokens ──────────────────────────────────────────────────
-- token_hash: ham token kaydedilmez, SHA-256 hash tutulur (timing-safe lookup).
-- expires_at: oluşturulduktan 1 saat sonra geçersiz olur.
-- used_at: tek kullanımlık — bir kez kullanılınca tekrar geçerli olmaz.

CREATE TABLE IF NOT EXISTS password_reset_token (
    token_id    SERIAL PRIMARY KEY,
    user_id     INT NOT NULL,
    token_hash  VARCHAR(64) NOT NULL,
    expires_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at     TIMESTAMP WITH TIME ZONE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_prt_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_prt_hash_lookup
    ON password_reset_token (token_hash)
    WHERE used_at IS NULL;

-- ─── Review Replies ─────────────────────────────────────────────────────────
-- İşletme sahibinin müşteri yorumuna yanıtı. Yalnız restoran sahibi yazabilir
-- (controller'da owner_id eşleşmesi doğrulanır).
-- Her review tek bir reply alır (UNIQUE constraint).

CREATE TABLE IF NOT EXISTS review_reply (
    reply_id    SERIAL PRIMARY KEY,
    review_id   INT NOT NULL UNIQUE,
    user_id     INT NOT NULL,       -- yanıtlayan işletme sahibi
    content     TEXT NOT NULL CHECK (length(content) BETWEEN 1 AND 1000),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rr_review FOREIGN KEY (review_id) REFERENCES review(review_id) ON DELETE CASCADE,
    CONSTRAINT fk_rr_user   FOREIGN KEY (user_id)   REFERENCES "user"(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_review_reply_review_id ON review_reply (review_id);

COMMIT;
