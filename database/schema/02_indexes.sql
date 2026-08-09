-- ============================================================================
-- 02_indexes.sql   -- Indexes only. Safe to re-run.
--
-- The views that used to live in this file have moved to
-- 08_views_and_analysis.sql, so they are created once with the correct
-- display_name column rather than created here and dropped there.
-- ============================================================================

SET search_path TO hush, public;

-- "latest reading across all sensors" and "last N hours for one sensor"
CREATE INDEX IF NOT EXISTS idx_pmc_datetime
    ON pedestrian_minute_count (sensing_datetime DESC);
CREATE INDEX IF NOT EXISTS idx_pmc_location_datetime
    ON pedestrian_minute_count (location_id, sensing_datetime DESC);

-- "typical crowd at 5pm on a Tuesday"
CREATE INDEX IF NOT EXISTS idx_phc_date_hour
    ON pedestrian_hour_count (sensing_date, hour_day);
CREATE INDEX IF NOT EXISTS idx_phc_location_hour
    ON pedestrian_hour_count (location_id, hour_day);

-- map queries: partial index, only active sensors are ever plotted
CREATE INDEX IF NOT EXISTS idx_sensor_active
    ON sensor_location (status) WHERE status = 'A';

CREATE INDEX IF NOT EXISTS idx_landmark_category
    ON landmark (category_id);

-- staging replay and per-dataset filtering during load
CREATE INDEX IF NOT EXISTS idx_raw_dataset_fetched
    ON raw_ingest (dataset_id, fetched_at DESC);

-- Confirm
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'hush'
ORDER BY tablename, indexname;
