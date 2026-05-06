-- Migration: 001_initial_schema
-- Description: Initial schema setup for MenuLo, including PostGIS and pgvector extensions.

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Clean Up Existing Tables (Reverse Dependency Order)
DROP TABLE IF EXISTS moderation_log CASCADE;
DROP TABLE IF EXISTS search_analytics CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS room_member CASCADE;
DROP TABLE IF EXISTS friend_room CASCADE;
DROP TABLE IF EXISTS favorite CASCADE;
DROP TABLE IF EXISTS green_menu CASCADE;
DROP TABLE IF EXISTS menu_item CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS menu CASCADE;
DROP TABLE IF EXISTS restaurant CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- 3. Custom Types
CREATE TYPE user_role AS ENUM ('Customer', 'Owner', 'Admin');

-- 4. Table Definitions

-- USER Table
-- Note: Quoted as "user" because it is a reserved keyword in PostgreSQL
CREATE TABLE "user" (
    user_id SERIAL PRIMARY KEY,
    role user_role NOT NULL DEFAULT 'Customer',
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    location geometry(Point, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RESTAURANT Table
CREATE TABLE restaurant (
    restaurant_id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    address TEXT,
    location_point geometry(Point, 4326),
    work_hours JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_restaurant_owner FOREIGN KEY (owner_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- MENU Table
CREATE TABLE menu (
    menu_id SERIAL PRIMARY KEY,
    restaurant_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurant(restaurant_id) ON DELETE CASCADE
);

-- CATEGORY Table
CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    menu_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT fk_category_menu FOREIGN KEY (menu_id) REFERENCES menu(menu_id) ON DELETE CASCADE
);

-- MENU_ITEM Table
CREATE TABLE menu_item (
    item_id SERIAL PRIMARY KEY,
    category_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    dietary_tags TEXT[], -- PostgreSQL array for tags like Vegan, Gluten-free
    embedding VECTOR(1536), -- Added for MenuBot AI semantic search
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_menu_item_category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE
);

-- GREEN_MENU Table
CREATE TABLE green_menu (
    green_item_id SERIAL PRIMARY KEY,
    item_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    discounted_price DECIMAL(10, 2) NOT NULL,
    expiration_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_green_menu_item FOREIGN KEY (item_id) REFERENCES menu_item(item_id) ON DELETE CASCADE
);

-- FAVORITE Table
CREATE TABLE favorite (
    favorite_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    target_id INT NOT NULL,
    type VARCHAR(50) NOT NULL, -- e.g., 'Restaurant', 'MenuItem'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_favorite_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- FRIEND_ROOM Table
CREATE TABLE friend_room (
    room_id SERIAL PRIMARY KEY,
    creator_id INT NOT NULL,
    qr_code VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_friend_room_creator FOREIGN KEY (creator_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- ROOM_MEMBER Table
-- Using composite primary key (room_id, user_id) as it's a join table
CREATE TABLE room_member (
    room_id INT NOT NULL,
    user_id INT NOT NULL,
    individual_preferences TEXT,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (room_id, user_id),
    CONSTRAINT fk_room_member_room FOREIGN KEY (room_id) REFERENCES friend_room(room_id) ON DELETE CASCADE,
    CONSTRAINT fk_room_member_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- REVIEW Table
CREATE TABLE review (
    review_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    target_id INT NOT NULL,
    rating_score INT NOT NULL CHECK (rating_score >= 1 AND rating_score <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- SEARCH_ANALYTICS Table
CREATE TABLE search_analytics (
    search_id SERIAL PRIMARY KEY,
    user_id INT, -- Nullable for anonymous searches
    query_text TEXT NOT NULL,
    is_miss BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_search_analytics_user FOREIGN KEY (user_id) REFERENCES "user"(user_id) ON DELETE SET NULL
);

-- MODERATION_LOG Table
CREATE TABLE moderation_log (
    log_id SERIAL PRIMARY KEY,
    admin_id INT NOT NULL,
    target_owner_id INT NOT NULL,
    action_taken TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_moderation_log_admin FOREIGN KEY (admin_id) REFERENCES "user"(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_moderation_log_target FOREIGN KEY (target_owner_id) REFERENCES "user"(user_id) ON DELETE CASCADE
);

-- 5. Create Indexes for Performance
CREATE INDEX idx_user_location ON "user" USING GIST (location);
CREATE INDEX idx_restaurant_location_point ON restaurant USING GIST (location_point);
CREATE INDEX idx_menu_item_embedding ON menu_item USING hnsw (embedding vector_l2_ops);
