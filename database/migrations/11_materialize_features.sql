-- ============================================================================
-- 11_materialize_features.sql   *** CORRECTED -- run this before handover ***
--
-- TWO BUGS FIXED HERE. Both would have silently corrupted model training.
--
-- BUG 1 - POSITIONAL LAGS ACROSS GAPS
--   The original view used LAG(total_of_direction, 24) OVER (ORDER BY date, hour).
--   That means "24 ROWS back", not "24 HOURS back". Your data has gaps --
--   2025 holds 799,469 rows against a possible 876,000, so about 9% of hours
--   are missing. Wherever a sensor skipped hours, LAG(24) silently reached
--   back 25, 30, 40 hours instead and labelled it "same hour yesterday".
--
--   A model trained on that learns from mislabelled history and cannot be
--   debugged from the outside -- the numbers look perfectly reasonable.
--
--   Fixed by joining explicitly on (sensing_date - 1, hour_day) and
--   (sensing_date - 7, hour_day). Now a missing hour yields NULL, which is
--   honest, instead of a wrong value, which is not. The rolling mean uses a
--   RANGE window over real time rather than a row count, for the same reason.
--
-- BUG 2 - display_name IS NOT UNIQUE
--   Sensors 123 and 124 are both "Birrarung Marr East - Batman Ave Bridge
--   Entry". Grouping by display_name merges them -- which is why Q5 reported
--   14 and 16 "weeks of evidence" when 8 weeks is the maximum possible.
--   Always key on location_id. display_name is for display only.
--
-- Run AFTER 10_load_bulk.sql Parts 1-4.
-- ============================================================================

SET search_path TO hush, public;
SET work_mem = '512MB';
SET maintenance_work_mem = '1GB';


-- ============================================================================
-- PART 1 - Corrected feature view
-- ============================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_model_features;
DROP VIEW IF EXISTS v_train_test_split;
DROP VIEW IF EXISTS v_model_features;

CREATE VIEW v_model_features AS
SELECT
    -- keys: location_id is the real identity, display_name is a label
    h.location_id,
    s.display_name,
    h.sensing_date,
    h.hour_day,
    (h.sensing_date + make_interval(hours => h.hour_day::int)) AS obs_ts,

    -- calendar features
    EXTRACT(DOW   FROM h.sensing_date)::smallint AS day_of_week,
    EXTRACT(MONTH FROM h.sensing_date)::smallint AS month,
    EXTRACT(DOY   FROM h.sensing_date)::smallint AS day_of_year,
    (EXTRACT(DOW FROM h.sensing_date) IN (0, 6)) AS is_weekend,

    -- cyclical encodings, so hour 23 sits next to hour 0 for the model
    SIN(2 * PI() * h.hour_day / 24.0)                      AS hour_sin,
    COS(2 * PI() * h.hour_day / 24.0)                      AS hour_cos,
    SIN(2 * PI() * EXTRACT(DOW FROM h.sensing_date) / 7.0) AS dow_sin,
    COS(2 * PI() * EXTRACT(DOW FROM h.sensing_date) / 7.0) AS dow_cos,

    -- location features
    s.latitude,
    s.longitude,
    s.is_cbd,

    -- target
    h.total_of_direction AS target_count,
    h.direction_1,
    h.direction_2,

    -- LAGS BY EXPLICIT TIME, not by row position.
    -- NULL where the hour genuinely wasn't recorded -- that is the correct
    -- answer, and the modeller can drop or impute it deliberately.
    h24.total_of_direction  AS lag_24h,
    h168.total_of_direction AS lag_168h,

    -- Trailing 24-hour mean over real time, excluding the current row so no
    -- target leaks into its own feature. RANGE (not ROWS) makes this correct
    -- even where hours are missing.
    AVG(h.total_of_direction) OVER (
        PARTITION BY h.location_id
        ORDER BY (h.sensing_date + make_interval(hours => h.hour_day::int))
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING
                  AND INTERVAL '1 hour'   PRECEDING) AS rolling_mean_24h,

    -- How complete the trailing window actually is. A modeller can filter on
    -- this instead of trusting a mean built from three observations.
    COUNT(*) OVER (
        PARTITION BY h.location_id
        ORDER BY (h.sensing_date + make_interval(hours => h.hour_day::int))
        RANGE BETWEEN INTERVAL '24 hours' PRECEDING
                  AND INTERVAL '1 hour'   PRECEDING) AS obs_in_window_24h

FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
-- same hour, previous day. Uses the primary key index.
LEFT JOIN pedestrian_hour_count h24
       ON h24.location_id  = h.location_id
      AND h24.sensing_date = h.sensing_date - 1
      AND h24.hour_day     = h.hour_day
-- same hour, same weekday, previous week
LEFT JOIN pedestrian_hour_count h168
       ON h168.location_id  = h.location_id
      AND h168.sensing_date = h.sensing_date - 7
      AND h168.hour_day     = h.hour_day;

COMMENT ON VIEW v_model_features IS
    'Model features. Lags are joined on explicit dates, not row offsets, so a
     NULL lag means the hour was genuinely not recorded. Key on location_id --
     display_name is NOT unique (sensors 123 and 124 share one).';


-- ============================================================================
-- PART 2 - Materialise it. The view does two self-joins over 1.59M rows;
-- computing once beats recomputing on every query your ML team runs.
-- ============================================================================

CREATE MATERIALIZED VIEW mv_model_features AS
SELECT * FROM v_model_features
WHERE lag_168h IS NOT NULL      -- needs a full week of history
  AND lag_24h  IS NOT NULL;     -- and yesterday's same hour

CREATE INDEX idx_mvmf_location ON mv_model_features (location_id);
CREATE INDEX idx_mvmf_date     ON mv_model_features (sensing_date);
CREATE INDEX idx_mvmf_loc_date ON mv_model_features (location_id, sensing_date, hour_day);

ANALYZE mv_model_features;

COMMENT ON MATERIALIZED VIEW mv_model_features IS
    'Training snapshot. Refresh after loading new data:
     REFRESH MATERIALIZED VIEW hush.mv_model_features;';


-- ============================================================================
-- PART 3 - Time-based train/test split
--
-- A time-series model must be split by TIME, never randomly. A random split
-- lets the model see the future during training and produces accuracy that
-- collapses in production. Worth stating explicitly in the report.
-- ============================================================================

CREATE VIEW v_train_test_split AS
SELECT *,
       CASE
           WHEN sensing_date < CURRENT_DATE - INTERVAL '90 days' THEN 'train'
           WHEN sensing_date < CURRENT_DATE - INTERVAL '30 days' THEN 'validation'
           ELSE 'test'
       END AS split_label
FROM mv_model_features;


-- ============================================================================
-- PART 4 - Verify.  Run one at a time.
-- ============================================================================

-- 4.1  Size of the training set
SELECT COUNT(*)                    AS rows,
       COUNT(DISTINCT location_id) AS sensors,
       MIN(sensing_date)           AS earliest,
       MAX(sensing_date)           AS latest
FROM mv_model_features;

-- 4.2  How many rows the lag fix removed. These are hours where the previous
--      day or week genuinely wasn't recorded -- previously they carried a
--      wrong value instead of being excluded.
SELECT (SELECT COUNT(*) FROM pedestrian_hour_count) AS all_hours,
       (SELECT COUNT(*) FROM mv_model_features)     AS trainable_rows,
       (SELECT COUNT(*) FROM pedestrian_hour_count)
        - (SELECT COUNT(*) FROM mv_model_features)  AS dropped_incomplete_history;

-- 4.3  Sensors sharing a display_name -- proof that location_id is the key
SELECT display_name, COUNT(DISTINCT location_id) AS sensor_count,
       string_agg(DISTINCT location_id::text, ', ' ORDER BY location_id::text) AS ids
FROM v_sensor
GROUP BY display_name
HAVING COUNT(DISTINCT location_id) > 1;

-- 4.4  Train/validation/test split
SELECT split_label, COUNT(*) AS rows,
       MIN(sensing_date) AS from_date, MAX(sensing_date) AS to_date
FROM v_train_test_split
GROUP BY split_label
ORDER BY from_date;

-- 4.5  Sample -- eyeball that lag_24h looks like a plausible same-hour value
SELECT location_id, display_name, sensing_date, hour_day,
       target_count, lag_24h, lag_168h,
       ROUND(rolling_mean_24h, 1) AS rolling_mean_24h,
       obs_in_window_24h
FROM mv_model_features
ORDER BY sensing_date DESC, location_id, hour_day
LIMIT 20;
