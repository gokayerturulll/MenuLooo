-- 004_restaurant_profile_fields.sql
-- MyBusinessView (işletme profil ekranı) için restaurant tablosuna ek alanlar.
--   phone          → iletişim telefonu
--   website        → web sitesi URL'si
--   description    → işletme açıklaması (uzun metin)
--   cuisine_type   → mutfak tipi ("Türk Mutfağı" gibi free-form text)
--   working_hours  → JSONB; günler ve açılış/kapanış saatleri
--
-- Çalıştırma: psql $DATABASE_URL -f migrations/004_restaurant_profile_fields.sql
-- IF NOT EXISTS ile re-runnable.

BEGIN;

ALTER TABLE restaurant
    ADD COLUMN IF NOT EXISTS phone         TEXT,
    ADD COLUMN IF NOT EXISTS website       TEXT,
    ADD COLUMN IF NOT EXISTS description   TEXT,
    ADD COLUMN IF NOT EXISTS cuisine_type  TEXT,
    ADD COLUMN IF NOT EXISTS working_hours JSONB;

-- owner_id üzerinde index (login akışında ownership lookup hızlı olsun)
CREATE INDEX IF NOT EXISTS idx_restaurant_owner ON restaurant (owner_id);

COMMIT;
