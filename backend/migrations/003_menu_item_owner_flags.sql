-- 003_menu_item_owner_flags.sql
-- İşletme menü yönetimi (MenuManagerView) için menu_item tablosuna
-- iki yeni kolon ekler:
--   is_green_menu  → ürün "Yeşil Menü"de mi (gıda israfı önleme indirimi)
--   is_available   → ürün şu an aktif (müşteri menüsünde görünür) mü
--
-- Çalıştırma:  psql $DATABASE_URL -f migrations/003_menu_item_owner_flags.sql
-- Güvenli: IF NOT EXISTS ile re-run edilebilir.

BEGIN;

ALTER TABLE menu_item
    ADD COLUMN IF NOT EXISTS is_green_menu BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE menu_item
    ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE;

-- Aktif ürün sorguları sık çalıştığı için kısmi index
CREATE INDEX IF NOT EXISTS idx_menu_item_available
    ON menu_item (category_id)
    WHERE is_available = TRUE;

COMMIT;
