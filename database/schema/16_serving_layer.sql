-- ============================================================================
-- 16_serving_layer.sql
-- Builds a COMPACT serving schema for Supabase.
--
-- WHY THIS EXISTS -- READ BEFORE MIGRATING
--
--   Supabase's free tier caps the database at 500 MB. Our full local database
--   does not fit:
--
--     mv_model_features    ~1.5M rows x ~25 cols   ≈ 350-400 MB
--     pedestrian_hour_count 1.59M rows             ≈ 130 MB with indexes
--     stg_bulk_hourly       1.6M text rows         ≈ 300 MB
--                                                  ---------------
--                                                  well over the cap
--
--   But the APP does not need any of that. It needs current conditions,
--   locations, refuge distances and an hourly profile. That is under 10 MB.
--
--   The 1.59M hourly rows exist to TRAIN a model, which happens offline on a
--   laptop, not in the serving database.
--
--   SPLIT THE TWO:
--     Supabase  -> serving layer (small, always on, what Flask queries)
--     Local     -> full history + staging + feature set (training only)
--
--   This is standard practice, not a workaround for the free tier: an
--   application database and an analytics database have different shapes,
--   different access patterns and different uptime requirements. Worth saying
--   so in the report.
--
-- Run locally AFTER 07-13. Then dump only the `serving` schema to Supabase.
-- ============================================================================

SET search_path TO hush, public;

DROP SCHEMA IF EXISTS serving CASCADE;
CREATE SCHEMA serving;

COMMENT ON SCHEMA serving IS
    'Compact application schema for Supabase. Source: City of Melbourne Open
     Data (CC BY 4.0). Rebuilt from hush by sql/16_serving_layer.sql.';


-- ---------------------------------------------------------------------------
-- 1. Sensors (134 rows)
-- ---------------------------------------------------------------------------
CREATE TABLE serving.sensor AS
SELECT s.location_id,
       s.display_name,
       s.device_code,
       s.latitude,
       s.longitude,
       s.is_cbd,
       s.is_active,
       s.direction_1,
       s.direction_2
FROM v_sensor s;

ALTER TABLE serving.sensor ADD PRIMARY KEY (location_id);


-- ---------------------------------------------------------------------------
-- 2. Density bands (3 rows) -- thresholds as data, not hard-coded in Flask
-- ---------------------------------------------------------------------------
CREATE TABLE serving.density_band AS
SELECT * FROM density_band;

ALTER TABLE serving.density_band ADD PRIMARY KEY (band_name);


-- ---------------------------------------------------------------------------
-- 3. Live minute counts (~10k rows, rolling window)
--    The only table the ETL writes to on a schedule.
-- ---------------------------------------------------------------------------
CREATE TABLE serving.minute_count (
    location_id        INTEGER     NOT NULL REFERENCES serving.sensor (location_id),
    sensing_datetime   TIMESTAMPTZ NOT NULL,
    direction_1        INTEGER,
    direction_2        INTEGER,
    total_of_direction INTEGER     NOT NULL,
    PRIMARY KEY (location_id, sensing_datetime)
);

INSERT INTO serving.minute_count
SELECT location_id, sensing_datetime, direction_1, direction_2, total_of_direction
FROM pedestrian_minute_count
WHERE sensing_datetime >= now() - INTERVAL '7 days';

CREATE INDEX idx_serving_minute_dt
    ON serving.minute_count (sensing_datetime DESC);
CREATE INDEX idx_serving_minute_loc_dt
    ON serving.minute_count (location_id, sensing_datetime DESC);


-- ---------------------------------------------------------------------------
-- 4. Hourly profile (100 sensors x 24 hours = ~2,400 rows)
--
--    This replaces 1.59M raw rows with the aggregate the app actually uses.
--    Recompute locally and re-push whenever the monthly data lands.
-- ---------------------------------------------------------------------------
CREATE TABLE serving.hourly_profile AS
SELECT location_id,
       display_name,
       hour_day,
       observations,
       avg_count,
       median_count,
       min_count,
       max_count
FROM v_hourly_profile;

ALTER TABLE serving.hourly_profile ADD PRIMARY KEY (location_id, hour_day);


-- ---------------------------------------------------------------------------
-- 5. Refuges: pre-computed walking distances (~1,000 rows)
--    Flattened so Flask needs no joins.
-- ---------------------------------------------------------------------------
CREATE TABLE serving.refuge AS
SELECT w.location_id,
       l.landmark_id,
       l.feature_name,
       t.theme_name,
       c.sub_theme,
       c.sensory_load,
       l.latitude,
       l.longitude,
       w.walk_m,
       w.walk_minutes,
       w.straight_m,
       w.detour_ratio,
       (ln.snap_m <= 50 AND w.detour_ratio <= 3.0) AS distance_reliable
FROM sensor_landmark_walk w
JOIN landmark          l  ON l.landmark_id  = w.landmark_id
JOIN landmark_node     ln ON ln.landmark_id = w.landmark_id
JOIN landmark_category c  ON c.category_id  = l.category_id
JOIN theme             t  ON t.theme_id     = c.theme_id;

ALTER TABLE serving.refuge ADD PRIMARY KEY (location_id, landmark_id);
CREATE INDEX idx_serving_refuge_loc ON serving.refuge (location_id, walk_m);


-- ---------------------------------------------------------------------------
-- 6. Network features per sensor (134 rows)
-- ---------------------------------------------------------------------------
CREATE TABLE serving.sensor_network AS
SELECT location_id,
       walkable_m_within_400m,
       nodes_within_400m,
       node_degree,
       low_sensory_within_800m,
       nearest_low_sensory_m,
       network_snap_reliable
FROM v_sensor_network_features;

ALTER TABLE serving.sensor_network ADD PRIMARY KEY (location_id);


-- ---------------------------------------------------------------------------
-- 7. The one view Flask reads for the live map
-- ---------------------------------------------------------------------------
CREATE VIEW serving.v_current_density AS
SELECT DISTINCT ON (m.location_id)
    s.location_id,
    s.display_name,
    s.latitude,
    s.longitude,
    m.sensing_datetime,
    m.total_of_direction AS people_per_minute,
    b.band_name          AS density_level,
    ROUND(EXTRACT(EPOCH FROM (now() - m.sensing_datetime)) / 60)::int
                         AS data_age_minutes
FROM serving.minute_count m
JOIN serving.sensor       s ON s.location_id = m.location_id
JOIN serving.density_band b ON m.total_of_direction >= b.min_count
                           AND (b.max_count IS NULL
                                OR m.total_of_direction <= b.max_count)
WHERE s.is_active
ORDER BY m.location_id, m.sensing_datetime DESC;


-- ============================================================================
-- Size check -- confirm this fits comfortably inside the free tier
-- ============================================================================
SELECT relname                                        AS table_name,
       n_live_tup                                     AS approx_rows,
       pg_size_pretty(pg_total_relation_size(relid))  AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'serving'
ORDER BY pg_total_relation_size(relid) DESC;

SELECT pg_size_pretty(SUM(pg_total_relation_size(relid))) AS serving_schema_total
FROM pg_stat_user_tables
WHERE schemaname = 'serving';
