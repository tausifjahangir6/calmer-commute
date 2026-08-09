-- ============================================================================
-- 10_load_bulk.sql
-- Transforms the bulk staging tables (filled by etl/fetch_bulk.py) into the
-- clean 3NF tables. Built for millions of rows.
--
-- Requires the helper functions from 07_load_from_raw.sql PART 1, and a
-- populated sensor_location (07 PART 2.1) -- the foreign key is enforced.
--
-- Parts 1 and 2 SKIP THEMSELVES if you didn't bulk-fetch that dataset, so
-- running the whole file is safe whichever datasets you pulled.
--
-- THE to_jsonb TRICK
--   Staging columns are named from whatever the CSV header said, so they
--   can't be hard-coded. to_jsonb(t) turns each row into a JSON object keyed
--   by column name, letting the same hush.jget candidate lists used elsewhere
--   work here unchanged. Rename-proof, and no duplicated mapping logic.
-- ============================================================================

SET search_path TO hush, public;

-- Sized for a 24GB machine. Session-scoped; reverts when you disconnect.
-- work_mem governs sorts (the DISTINCT ON below); maintenance_work_mem
-- governs VACUUM and index builds.
SET work_mem = '512MB';
SET maintenance_work_mem = '1GB';


-- ============================================================================
-- PART 1 - HOURLY counts   (the training data for the forecaster)
-- Skips itself if stg_bulk_hourly does not exist.
-- ============================================================================
DO $do$
DECLARE n bigint;
BEGIN
    IF to_regclass('hush.stg_bulk_hourly') IS NULL THEN
        RAISE NOTICE 'SKIPPED Part 1: hush.stg_bulk_hourly not found.';
        RAISE NOTICE '  To load it:  python3 fetch_bulk.py --dataset hourly --where "sensing_date>=date''2020-01-01''"';
        RETURN;
    END IF;

    INSERT INTO pedestrian_hour_count (
        location_id, sensing_date, hour_day, direction_1, direction_2, total_of_direction)
    SELECT DISTINCT ON (x.location_id, x.sensing_date, x.hour_day)
        x.location_id, x.sensing_date, x.hour_day, x.d1, x.d2,
        COALESCE(x.total, COALESCE(x.d1, 0) + COALESCE(x.d2, 0))
    FROM (
        SELECT
            hush.to_int(hush.jget(j, 'location_id', 'sensor_id'))     AS location_id,
            hush.to_date_safe(hush.jget(j, 'sensing_date', 'date'))   AS sensing_date,
            hush.to_hour(hush.jget(j, 'hourday', 'hour_day', 'time')) AS hour_day,
            hush.to_int(hush.jget(j, 'direction_1'))                  AS d1,
            hush.to_int(hush.jget(j, 'direction_2'))                  AS d2,
            hush.to_int(hush.jget(j, 'pedestriancount', 'hourly_counts',
                                  'total_of_directions'))             AS total
        FROM stg_bulk_hourly t
        CROSS JOIN LATERAL (SELECT to_jsonb(t) AS j) AS conv
    ) x
    JOIN sensor_location sl ON sl.location_id = x.location_id  -- referential check
    WHERE x.location_id  IS NOT NULL
      AND x.sensing_date IS NOT NULL
      AND x.hour_day     IS NOT NULL
      AND COALESCE(x.total, COALESCE(x.d1, 0) + COALESCE(x.d2, 0)) >= 0
    ORDER BY x.location_id, x.sensing_date, x.hour_day, x.total DESC NULLS LAST
    ON CONFLICT (location_id, sensing_date, hour_day) DO UPDATE SET
        direction_1        = EXCLUDED.direction_1,
        direction_2        = EXCLUDED.direction_2,
        total_of_direction = EXCLUDED.total_of_direction;

    GET DIAGNOSTICS n = ROW_COUNT;
    RAISE NOTICE 'Part 1: % hourly rows inserted or updated.', n;
END
$do$;


-- ============================================================================
-- PART 2 - MINUTE counts
-- Skips itself if stg_bulk_minute does not exist -- which is the case if you
-- only ran  fetch_bulk.py --dataset hourly.
--
-- You may not need this. The minute feed is a rolling recent window used for
-- the live density map; the hourly series is what a forecaster trains on.
-- The ~10,000 minute rows already loaded by fetch_to_db.py are enough for the
-- live view.
-- ============================================================================
DO $do$
DECLARE n bigint;
BEGIN
    IF to_regclass('hush.stg_bulk_minute') IS NULL THEN
        RAISE NOTICE 'SKIPPED Part 2: hush.stg_bulk_minute not found. This is fine if you only bulk-fetched hourly.';
        RAISE NOTICE '  To load it:  python3 fetch_bulk.py --dataset minute';
        RETURN;
    END IF;

    INSERT INTO pedestrian_minute_count (
        location_id, sensing_datetime, direction_1, direction_2, total_of_direction)
    SELECT DISTINCT ON (x.location_id, x.sensing_datetime)
        x.location_id, x.sensing_datetime, x.d1, x.d2,
        COALESCE(x.total, COALESCE(x.d1, 0) + COALESCE(x.d2, 0))
    FROM (
        SELECT
            hush.to_int(hush.jget(j, 'location_id', 'sensor_id'))  AS location_id,
            hush.to_ts(hush.jget(j, 'sensing_datetime'))           AS sensing_datetime,
            hush.to_int(hush.jget(j, 'direction_1'))               AS d1,
            hush.to_int(hush.jget(j, 'direction_2'))               AS d2,
            hush.to_int(hush.jget(j, 'total_of_directions'))       AS total
        FROM stg_bulk_minute t
        CROSS JOIN LATERAL (SELECT to_jsonb(t) AS j) AS conv
    ) x
    JOIN sensor_location sl ON sl.location_id = x.location_id
    WHERE x.location_id      IS NOT NULL
      AND x.sensing_datetime IS NOT NULL
      AND COALESCE(x.total, COALESCE(x.d1, 0) + COALESCE(x.d2, 0)) >= 0
    ORDER BY x.location_id, x.sensing_datetime, x.total DESC NULLS LAST
    ON CONFLICT (location_id, sensing_datetime) DO UPDATE SET
        direction_1        = EXCLUDED.direction_1,
        direction_2        = EXCLUDED.direction_2,
        total_of_direction = EXCLUDED.total_of_direction;

    GET DIAGNOSTICS n = ROW_COUNT;
    RAISE NOTICE 'Part 2: % minute rows inserted or updated.', n;
END
$do$;


-- ============================================================================
-- PART 3 - Housekeeping after a large load
-- ============================================================================

-- Planner statistics are stale after a million inserts. Without this, the
-- analysis queries can choose bad plans and appear to hang.
ANALYZE pedestrian_hour_count;
ANALYZE pedestrian_minute_count;

-- Reclaim space from the ON CONFLICT updates.
-- VACUUM cannot run inside a transaction block. Highlight this ONE line and
-- run it alone. If you get "VACUUM cannot run inside a transaction block",
-- enable auto-commit in pgAdmin (dropdown beside the play button). Skipping it
-- is harmless -- autovacuum handles it eventually.
VACUUM (ANALYZE) pedestrian_hour_count;


-- ============================================================================
-- PART 4 - Verify.  Run one at a time.
-- ============================================================================

-- 4.1  What landed
SELECT 'pedestrian_hour_count'     AS table_name, COUNT(*) AS row_count,
       MIN(sensing_date)::text     AS earliest,
       MAX(sensing_date)::text     AS latest,
       COUNT(DISTINCT location_id) AS sensors
FROM pedestrian_hour_count
UNION ALL
SELECT 'pedestrian_minute_count', COUNT(*),
       MIN(sensing_datetime)::date::text, MAX(sensing_datetime)::date::text,
       COUNT(DISTINCT location_id)
FROM pedestrian_minute_count;

-- 4.2  Staged vs loaded
SELECT (SELECT COUNT(*) FROM stg_bulk_hourly)       AS staged_rows,
       (SELECT COUNT(*) FROM pedestrian_hour_count) AS loaded_rows;

-- 4.3  Rows rejected because the sensor is retired.
--      Expected: the sensor list is current, the history is not.
--      This is your Data Cleansing evidence at full scale.
SELECT hush.to_int(hush.jget(to_jsonb(t), 'location_id')) AS retired_sensor_id,
       COUNT(*)                                           AS rows_dropped
FROM stg_bulk_hourly t
WHERE NOT EXISTS (
        SELECT 1 FROM sensor_location sl
        WHERE sl.location_id = hush.to_int(hush.jget(to_jsonb(t), 'location_id')))
GROUP BY 1
ORDER BY rows_dropped DESC;

-- 4.4  Coverage per year -- confirms you have a real training set.
--      Note 2020-21: lockdown counts are genuine but atypical.
SELECT EXTRACT(YEAR FROM sensing_date)::int AS year,
       COUNT(*)                             AS row_count,
       COUNT(DISTINCT location_id)          AS sensors,
       ROUND(AVG(total_of_direction))       AS avg_hourly_count
FROM pedestrian_hour_count
GROUP BY year
ORDER BY year;


-- ============================================================================
-- PART 5 - Model-ready feature view
--
-- REQUIRES v_sensor, which is created in 08_views_and_analysis.sql.
-- Run 08 Part 1 before this, or you get "relation v_sensor does not exist".
--
-- Hand this to whoever builds the forecaster: calendar features, cyclical
-- encodings, lagged targets and a leakage-free rolling mean, computed once
-- here instead of reimplemented in each notebook.
-- ============================================================================

CREATE OR REPLACE VIEW v_model_features AS
SELECT
    h.location_id,
    s.display_name,
    h.sensing_date,
    h.hour_day,
    -- calendar
    EXTRACT(DOW   FROM h.sensing_date)::smallint AS day_of_week,
    EXTRACT(MONTH FROM h.sensing_date)::smallint AS month,
    EXTRACT(DOY   FROM h.sensing_date)::smallint AS day_of_year,
    (EXTRACT(DOW FROM h.sensing_date) IN (0, 6)) AS is_weekend,
    -- cyclical encodings, so hour 23 sits next to hour 0 for the model
    SIN(2 * PI() * h.hour_day / 24.0)                      AS hour_sin,
    COS(2 * PI() * h.hour_day / 24.0)                      AS hour_cos,
    SIN(2 * PI() * EXTRACT(DOW FROM h.sensing_date) / 7.0) AS dow_sin,
    COS(2 * PI() * EXTRACT(DOW FROM h.sensing_date) / 7.0) AS dow_cos,
    -- location
    s.latitude,
    s.longitude,
    s.is_cbd,
    -- target
    h.total_of_direction AS target_count,
    h.direction_1,
    h.direction_2,
    -- lags: same hour yesterday, same hour last week
    LAG(h.total_of_direction, 24)  OVER w AS lag_24h,
    LAG(h.total_of_direction, 168) OVER w AS lag_168h,
    -- trailing 24h mean, excluding the current row to avoid target leakage
    AVG(h.total_of_direction) OVER (
        PARTITION BY h.location_id
        ORDER BY h.sensing_date, h.hour_day
        ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING) AS rolling_mean_24h
FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
WINDOW w AS (PARTITION BY h.location_id ORDER BY h.sensing_date, h.hour_day);

COMMENT ON VIEW v_model_features IS
    'Model-ready features. lag_* and rolling_mean_24h are NULL for the first
     rows of each sensor -- drop those before training.';

-- Preview
SELECT * FROM v_model_features
WHERE lag_168h IS NOT NULL
ORDER BY location_id, sensing_date DESC, hour_day DESC
LIMIT 20;
