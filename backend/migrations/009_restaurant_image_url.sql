-- 009_restaurant_image_url.sql
-- restaurant tablosuna profil görseli URL kolonu ekler.
-- Güvenli: IF NOT EXISTS ile re-run edilebilir.
--
-- Çalıştırma: psql $DATABASE_URL -f migrations/009_restaurant_image_url.sql

ALTER TABLE restaurant ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
