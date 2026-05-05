// migrations/001_initial_schema.sql
-- MenuLo PostgreSQL Şeması — v1.0
-- Tüm tablolar bu dosyada tanımlanır.
-- Çalıştırmak için: psql -U menulo_user -d menulo_db -f migrations/001_initial_schema.sql

-- UUID desteği
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Full-text search için Türkçe dil desteği
CREATE EXTENSION IF NOT EXISTS unaccent;

-- ─────────────────────────────────────────────
-- 1. KULLANICILAR
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type     VARCHAR(20) NOT NULL CHECK (user_type IN ('customer', 'business')),
    profile_image_url TEXT,
    is_verified   BOOLEAN DEFAULT FALSE,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 2. RESTORANLAR (İşletmeler)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS restaurants (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name          VARCHAR(200) NOT NULL,
    description   TEXT,
    cuisine_type  VARCHAR(100),
    address       TEXT NOT NULL,
    city          VARCHAR(100) NOT NULL,
    latitude      DECIMAL(9, 6),
    longitude     DECIMAL(9, 6),
    phone         VARCHAR(20),
    website       VARCHAR(255),
    cover_image_url TEXT,
    is_active     BOOLEAN DEFAULT TRUE,
    opens_at      TIME,
    closes_at     TIME,
    average_rating DECIMAL(3,2) DEFAULT 0.0,
    total_reviews  INTEGER DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Konum bazlı arama için index
CREATE INDEX IF NOT EXISTS idx_restaurants_location
  ON restaurants (latitude, longitude);

-- ─────────────────────────────────────────────
-- 3. MENÜ KATEGORİLERİ
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS menu_categories (
    id            SERIAL PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          VARCHAR(100) NOT NULL,
    description   TEXT,
    display_order INTEGER DEFAULT 0,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 4. MENÜ ÖĞELERİ
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS menu_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id   UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id     INTEGER REFERENCES menu_categories(id) ON DELETE SET NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    price           DECIMAL(10, 2) NOT NULL,
    image_url       TEXT,
    is_available    BOOLEAN DEFAULT TRUE,
    is_vegetarian   BOOLEAN DEFAULT FALSE,
    is_vegan        BOOLEAN DEFAULT FALSE,
    is_gluten_free  BOOLEAN DEFAULT FALSE,
    calories        INTEGER,
    allergens       TEXT[],           -- PostgreSQL array: ['gluten', 'süt'] gibi
    tags            TEXT[],           -- ['popüler', 'yeni', 'önerilen']
    -- Green Menu (gıda israfı önleme)
    is_green_menu   BOOLEAN DEFAULT FALSE,
    green_price     DECIMAL(10, 2),   -- İndirimli fiyat
    green_expires_at TIMESTAMPTZ,     -- Bu saatten sonra otomatik kaldırılır
    -- Full-text search için
    search_vector   TSVECTOR,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Full-text search index (Türkçe menü araması için)
CREATE INDEX IF NOT EXISTS idx_menu_items_search
  ON menu_items USING GIN(search_vector);

-- search_vector'ü otomatik güncelleyen trigger
CREATE OR REPLACE FUNCTION update_menu_item_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('simple', coalesce(NEW.name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.description, '')), 'B');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER menu_item_search_update
  BEFORE INSERT OR UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION update_menu_item_search_vector();

-- ─────────────────────────────────────────────
-- 5. QR KODLAR
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS qr_codes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_number  VARCHAR(20),
    qr_token      VARCHAR(255) UNIQUE NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- 6. KARAR ODALARI (Room)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rooms (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    room_code     VARCHAR(8) UNIQUE NOT NULL,   -- Arkadaşların katılacağı kısa kod
    name          VARCHAR(100),
    status        VARCHAR(20) DEFAULT 'waiting'
                  CHECK (status IN ('waiting', 'voting', 'decided', 'closed')),
    budget_min    DECIMAL(10,2),
    budget_max    DECIMAL(10,2),
    location_lat  DECIMAL(9,6),
    location_lng  DECIMAL(9,6),
    radius_km     INTEGER DEFAULT 5,
    dietary_filters TEXT[],           -- ['vegetarian', 'vegan', 'gluten_free']
    decided_restaurant_id UUID REFERENCES restaurants(id),
    expires_at    TIMESTAMPTZ DEFAULT NOW() + INTERVAL '2 hours',
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS room_members (
    id        SERIAL PRIMARY KEY,
    room_id   UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id   UUID REFERENCES users(id) ON DELETE SET NULL,
    nickname  VARCHAR(50),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(room_id, user_id)
);

CREATE TABLE IF NOT EXISTS room_votes (
    id            SERIAL PRIMARY KEY,
    room_id       UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id       UUID REFERENCES users(id) ON DELETE SET NULL,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    score         INTEGER CHECK (score BETWEEN 1 AND 5),
    voted_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(room_id, user_id, restaurant_id)
);

-- ─────────────────────────────────────────────
-- 7. MENUBOT (AI Sohbet Geçmişi)
--    PostgreSQL JSONB: ChatBot için ideal —
--    JSON verisini ikili formatta saklayıp indexlenebilir yapar
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS menubot_conversations (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    messages    JSONB DEFAULT '[]'::JSONB,
    -- Örnek messages formatı:
    -- [{"role": "user", "content": "...", "ts": "2026-05-05T12:00:00Z"},
    --  {"role": "bot",  "content": "...", "ts": "2026-05-05T12:00:01Z"}]
    context     JSONB DEFAULT '{}'::JSONB,
    -- context: {"budget": 150, "location": {...}, "dietary": ["vegan"]}
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- JSONB index — hızlı sorgulama için
CREATE INDEX IF NOT EXISTS idx_menubot_user
  ON menubot_conversations (user_id);

-- ─────────────────────────────────────────────
-- 8. YORUMLAR & PUANLAMALAR
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reviews (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    rating        INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment       TEXT,
    is_approved   BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, restaurant_id)
);

-- Restoran puan ortalamasını otomatik güncelleyen fonksiyon
CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE restaurants
  SET
    average_rating = (SELECT AVG(rating) FROM reviews WHERE restaurant_id = NEW.restaurant_id),
    total_reviews  = (SELECT COUNT(*) FROM reviews WHERE restaurant_id = NEW.restaurant_id)
  WHERE id = NEW.restaurant_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER review_rating_update
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_restaurant_rating();

-- ─────────────────────────────────────────────
-- 9. FAVORİLER
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorites (
    id            SERIAL PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, restaurant_id)
);

-- ─────────────────────────────────────────────
-- 10. REFRESH TOKEN'LAR (JWT güvenliği)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id         SERIAL PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token      VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Süresi geçmiş token'ları otomatik silmek için index
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires
  ON refresh_tokens (expires_at);

-- updated_at'ı otomatik güncelleyen genel fonksiyon
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ları tablolara bağla
CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER restaurants_updated_at
  BEFORE UPDATE ON restaurants
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER menu_items_updated_at
  BEFORE UPDATE ON menu_items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
