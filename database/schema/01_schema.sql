-- ============================================================================
-- 01_schema.sql   -- Tables only. Safe to re-run (everything IF NOT EXISTS).
-- Melbourne CBD pedestrian crowd-density database, normalised to 3NF.
-- PostgreSQL 15+
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS hush;
SET search_path TO hush, public;

-- ----------------------------------------------------------------------------
-- Staging: raw API payloads land here untouched.
-- Keeping the source JSON means a wrong cleaning rule costs a re-run of the
-- transform, not another trip to the API -- and the original stays auditable.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw_ingest (
    ingest_id   BIGSERIAL   PRIMARY KEY,
    dataset_id  TEXT        NOT NULL,
    payload     JSONB       NOT NULL,
    fetched_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_url  TEXT
);

-- ----------------------------------------------------------------------------
-- SENSOR_LOCATION
-- 1NF: the source `location` field is a non-atomic {"lon":..,"lat":..} pair.
--      It is split into latitude + longitude during load.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sensor_location (
    location_id        INTEGER      PRIMARY KEY,
    sensor_name        TEXT         NOT NULL,   -- device code, e.g. "Swa295_T"
    sensor_description TEXT,                    -- readable, e.g. "Melbourne Central"
    location_type      TEXT,
    status             TEXT         NOT NULL DEFAULT 'Unknown',  -- 'A' = active
    latitude           NUMERIC(9,6) NOT NULL,
    longitude          NUMERIC(9,6) NOT NULL,
    direction_1        TEXT,                    -- e.g. "North"
    direction_2        TEXT,                    -- e.g. "South"
    installation_date  DATE,
    note               TEXT,
    is_cbd             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT sensor_location_lat_chk CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT sensor_location_lon_chk CHECK (longitude BETWEEN -180 AND 180)
);

COMMENT ON TABLE  sensor_location IS
    'Pedestrian Counting System - Sensor Locations (CC BY 4.0, City of Melbourne)';
COMMENT ON COLUMN sensor_location.sensor_name IS
    'Device code from the source. Use sensor_description for anything user-facing.';

-- ----------------------------------------------------------------------------
-- PEDESTRIAN_MINUTE_COUNT   CPK: (location_id, sensing_datetime)
-- 2NF: sensing_date and sensing_time are NOT stored -- they depend only on
--      sensing_datetime, which is part of the key. Derived in a view instead.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedestrian_minute_count (
    location_id        INTEGER     NOT NULL,
    sensing_datetime   TIMESTAMPTZ NOT NULL,
    direction_1        INTEGER,
    direction_2        INTEGER,
    total_of_direction INTEGER     NOT NULL,
    CONSTRAINT pmc_pk PRIMARY KEY (location_id, sensing_datetime),
    CONSTRAINT pmc_location_fk FOREIGN KEY (location_id)
        REFERENCES sensor_location (location_id) ON DELETE RESTRICT,
    CONSTRAINT pmc_total_nonneg CHECK (total_of_direction >= 0),
    CONSTRAINT pmc_dir_nonneg   CHECK (COALESCE(direction_1,0) >= 0
                                   AND COALESCE(direction_2,0) >= 0)
);

-- ----------------------------------------------------------------------------
-- PEDESTRIAN_HOUR_COUNT   CPK: (location_id, sensing_date, hour_day)
--
-- DELIBERATE DEVIATION FROM THE COURSE SAMPLE: the sample declares
-- (location_id, sensing_date) while also storing hour_day. That key allows one
-- row per sensor per DAY, so 23 of every 24 hourly readings would collide.
-- hour_day belongs in the key. This is a functional-dependency error in the
-- sample, not a style preference.
--
-- sensor_name and location are absent by design: they depend only on
-- location_id, which is the 2NF partial dependency the sample itself calls out.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedestrian_hour_count (
    location_id        INTEGER  NOT NULL,
    sensing_date       DATE     NOT NULL,
    hour_day           SMALLINT NOT NULL,
    direction_1        INTEGER,
    direction_2        INTEGER,
    total_of_direction INTEGER  NOT NULL,
    CONSTRAINT phc_pk PRIMARY KEY (location_id, sensing_date, hour_day),
    CONSTRAINT phc_location_fk FOREIGN KEY (location_id)
        REFERENCES sensor_location (location_id) ON DELETE RESTRICT,
    CONSTRAINT phc_hour_chk     CHECK (hour_day BETWEEN 0 AND 23),
    CONSTRAINT phc_total_nonneg CHECK (total_of_direction >= 0)
);

-- ----------------------------------------------------------------------------
-- THEME / LANDMARK_CATEGORY / LANDMARK
-- 3NF: the source has category -> theme -> sub_theme (transitive).
--      THEME is extracted into its own table to remove it.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS theme (
    theme_id   SMALLSERIAL PRIMARY KEY,
    theme_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS landmark_category (
    category_id  SERIAL PRIMARY KEY,
    theme_id     SMALLINT NOT NULL,
    sub_theme    TEXT     NOT NULL,
    sensory_load TEXT     NOT NULL DEFAULT 'unrated',
    CONSTRAINT lc_theme_fk FOREIGN KEY (theme_id)
        REFERENCES theme (theme_id) ON DELETE RESTRICT,
    CONSTRAINT lc_unique UNIQUE (theme_id, sub_theme),
    CONSTRAINT lc_sensory_chk CHECK (sensory_load IN ('low','medium','high','unrated'))
);

-- The source landmarks dataset ships NO identifier column, so landmark_id is a
-- deterministic content hash generated during load (see 07, hush.surrogate_id).
CREATE TABLE IF NOT EXISTS landmark (
    landmark_id  INTEGER      PRIMARY KEY,
    category_id  INTEGER      NOT NULL,
    feature_name TEXT         NOT NULL,
    latitude     NUMERIC(9,6) NOT NULL,
    longitude    NUMERIC(9,6) NOT NULL,
    CONSTRAINT landmark_category_fk FOREIGN KEY (category_id)
        REFERENCES landmark_category (category_id) ON DELETE RESTRICT,
    CONSTRAINT landmark_lat_chk CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT landmark_lon_chk CHECK (longitude BETWEEN -180 AND 180)
);

-- ----------------------------------------------------------------------------
-- Density thresholds stored as data, not hard-coded in the application.
-- Note these do not overlap: the sample's 0-50 / 50-150 / 150+ bands leave 50
-- and 150 belonging to two bands at once.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS density_band (
    band_name TEXT    PRIMARY KEY,
    min_count INTEGER NOT NULL,
    max_count INTEGER,
    CONSTRAINT density_band_chk CHECK (max_count IS NULL OR max_count >= min_count)
);

INSERT INTO density_band (band_name, min_count, max_count) VALUES
    ('Low',    0,   50),
    ('Medium', 51,  150),
    ('High',   151, NULL)
ON CONFLICT (band_name) DO NOTHING;

-- ----------------------------------------------------------------------------
-- ETL audit log -- makes the "automated daily pipeline" claim verifiable.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS etl_run_log (
    run_id        BIGSERIAL   PRIMARY KEY,
    dataset_id    TEXT        NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at   TIMESTAMPTZ,
    rows_fetched  INTEGER     NOT NULL DEFAULT 0,
    rows_inserted INTEGER     NOT NULL DEFAULT 0,
    rows_rejected INTEGER     NOT NULL DEFAULT 0,
    status        TEXT        NOT NULL DEFAULT 'running',
    error_message TEXT,
    CONSTRAINT etl_status_chk CHECK (status IN ('running','success','failed'))
);

COMMIT;

-- Confirm
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'hush'
ORDER BY table_name;
