-- Migration: 005_room_phase1
-- Description: Add Group Decision Room Phase-1 columns to friend_room table.

ALTER TABLE friend_room
    ADD COLUMN IF NOT EXISTS name            VARCHAR(255),
    ADD COLUMN IF NOT EXISTS categories      TEXT[],
    ADD COLUMN IF NOT EXISTS budget          INT            DEFAULT 100,
    ADD COLUMN IF NOT EXISTS max_distance_km DECIMAL(5, 1)  DEFAULT 3.0,
    ADD COLUMN IF NOT EXISTS status          VARCHAR(50)    DEFAULT 'active';

-- creator_id was added in 001; alias host_id for clarity in new queries (no schema change needed)
-- room_member composite PK (room_id, user_id) already prevents duplicates
