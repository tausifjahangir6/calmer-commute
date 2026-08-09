-- ============================================================================
-- 14_sensor_coverage_audit.sql
-- Which sensors are in the training file, which are not, and why.
--
-- Answers the two questions raised in review:
--   1. Why does the training file have 65 sensors when 100 report hourly data?
--   2. Are the missing hours concentrated at commute times?
--
-- Every query is read-only. Run them one at a time in pgAdmin and use the
-- download button to share the results.
-- ============================================================================

SET search_path TO hush, public;

-- ============================================================================
-- 1. THE FUNNEL -- where sensors drop out at each stage
-- ============================================================================
SELECT '1. sensors in the sensor list'   AS stage,
       COUNT(*)::bigint                  AS sensors
FROM sensor_location
UNION ALL
SELECT '2. have hourly counts',
       COUNT(DISTINCT location_id)
FROM pedestrian_hour_count
UNION ALL
SELECT '3. in the training export',
       COUNT(DISTINCT location_id)
FROM mv_model_features;


-- ============================================================================
-- 2. FULL SENSOR REGISTER -- one row per sensor, with its status
--
-- This is the table to share. It shows every sensor and exactly why it is or
-- isn't in the training file.
-- ============================================================================
SELECT
    s.location_id,
    s.sensor_description                       AS sensor,
    s.location_type,
    s.status                                   AS sensor_status,
    s.installation_date,
    s.is_cbd,
    COALESCE(h.hourly_rows, 0)                 AS hourly_rows,
    h.first_seen,
    h.last_seen,
    COALESCE(m.trainable_rows, 0)              AS trainable_rows,
    CASE
        WHEN h.hourly_rows IS NULL
            THEN 'EXCLUDED - no hourly data at all (indoor/other programme)'
        WHEN m.trainable_rows IS NULL
            THEN 'EXCLUDED - history too sparse for lag features'
        ELSE 'INCLUDED in training file'
    END                                        AS outcome
FROM sensor_location s
LEFT JOIN (
    SELECT location_id,
           COUNT(*)          AS hourly_rows,
           MIN(sensing_date) AS first_seen,
           MAX(sensing_date) AS last_seen
    FROM pedestrian_hour_count
    GROUP BY location_id
) h ON h.location_id = s.location_id
LEFT JOIN (
    SELECT location_id, COUNT(*) AS trainable_rows
    FROM mv_model_features
    GROUP BY location_id
) m ON m.location_id = s.location_id
ORDER BY
    CASE WHEN h.hourly_rows IS NULL THEN 3
         WHEN m.trainable_rows IS NULL THEN 2
         ELSE 1 END,
    COALESCE(h.hourly_rows, 0) DESC;


-- ============================================================================
-- 3. GROUP A -- has hourly data but did NOT make the training file
--
-- These are the ~35. pct_complete shows how patchy their history is: a sensor
-- needs the same hour on the previous day AND the previous week to produce a
-- single usable row, so anything intermittent falls out entirely.
-- ============================================================================
SELECT
    h.location_id,
    s.sensor_description                                     AS sensor,
    s.location_type,
    COUNT(*)                                                 AS hourly_rows,
    MIN(h.sensing_date)                                      AS first_seen,
    MAX(h.sensing_date)                                      AS last_seen,
    (MAX(h.sensing_date) - MIN(h.sensing_date) + 1)          AS days_spanned,
    (MAX(h.sensing_date) - MIN(h.sensing_date) + 1) * 24     AS possible_rows,
    ROUND(100.0 * COUNT(*)
          / NULLIF((MAX(h.sensing_date) - MIN(h.sensing_date) + 1) * 24, 0), 1)
                                                             AS pct_complete
FROM pedestrian_hour_count h
JOIN sensor_location s ON s.location_id = h.location_id
WHERE NOT EXISTS (SELECT 1 FROM mv_model_features m
                  WHERE m.location_id = h.location_id)
GROUP BY h.location_id, s.sensor_description, s.location_type
ORDER BY hourly_rows DESC;


-- ============================================================================
-- 4. GROUP B -- no hourly data at all (the 34)
--
-- Expect these to be indoor building counters: library lifts, visitor centre
-- doorways, building entrances. A separate counting programme from the street
-- sensors, so they never appear in the hourly dataset.
-- ============================================================================
SELECT s.location_id,
       s.sensor_description AS sensor,
       s.location_type,
       s.status,
       s.installation_date,
       s.is_cbd
FROM sensor_location s
WHERE NOT EXISTS (SELECT 1 FROM pedestrian_hour_count h
                  WHERE h.location_id = s.location_id)
ORDER BY s.location_id;


-- ============================================================================
-- 5. ARE THE MISSING HOURS AT COMMUTE TIMES?
--
-- The question behind the question. If outages cluster at 8am and 5pm, a
-- commute-time model is biased. If they're flat or overnight, it isn't.
--
-- pct_missing compares observed rows against the hours each sensor was active.
-- ============================================================================
WITH bounds AS (
    SELECT location_id, MIN(sensing_date) AS d0, MAX(sensing_date) AS d1
    FROM pedestrian_hour_count
    GROUP BY location_id
),
expected AS (
    SELECT b.location_id, h.hour_day, (b.d1 - b.d0 + 1) AS expected_rows
    FROM bounds b
    CROSS JOIN generate_series(0, 23) AS h(hour_day)
),
actual AS (
    SELECT location_id, hour_day, COUNT(*) AS actual_rows
    FROM pedestrian_hour_count
    GROUP BY location_id, hour_day
)
SELECT e.hour_day,
       CASE WHEN e.hour_day BETWEEN 7 AND 9   THEN 'morning commute'
            WHEN e.hour_day BETWEEN 16 AND 18 THEN 'evening commute'
            WHEN e.hour_day BETWEEN 0 AND 5   THEN 'overnight'
            ELSE 'other' END                            AS period,
       SUM(e.expected_rows)                             AS expected_rows,
       SUM(COALESCE(a.actual_rows, 0))                  AS actual_rows,
       ROUND(100.0 * (1 - SUM(COALESCE(a.actual_rows, 0))::numeric
                        / SUM(e.expected_rows)), 2)     AS pct_missing
FROM expected e
LEFT JOIN actual a ON a.location_id = e.location_id
                  AND a.hour_day    = e.hour_day
GROUP BY e.hour_day
ORDER BY e.hour_day;


-- ============================================================================
-- 6. SAME THING SUMMARISED -- the one-line answer for your teammate
--
-- If the three percentages are close, missing data is evenly spread and there
-- is no commute-hour bias. If commute periods are noticeably higher, say so.
-- ============================================================================
WITH bounds AS (
    SELECT location_id, MIN(sensing_date) AS d0, MAX(sensing_date) AS d1
    FROM pedestrian_hour_count GROUP BY location_id
),
expected AS (
    SELECT b.location_id, h.hour_day, (b.d1 - b.d0 + 1) AS expected_rows
    FROM bounds b CROSS JOIN generate_series(0, 23) AS h(hour_day)
),
actual AS (
    SELECT location_id, hour_day, COUNT(*) AS actual_rows
    FROM pedestrian_hour_count GROUP BY location_id, hour_day
)
SELECT CASE WHEN e.hour_day BETWEEN 7 AND 9   THEN '1. morning commute (7-9)'
            WHEN e.hour_day BETWEEN 16 AND 18 THEN '2. evening commute (16-18)'
            WHEN e.hour_day BETWEEN 0 AND 5   THEN '4. overnight (0-5)'
            ELSE '3. rest of day' END                   AS period,
       SUM(e.expected_rows)                             AS expected_rows,
       SUM(COALESCE(a.actual_rows, 0))                  AS actual_rows,
       ROUND(100.0 * (1 - SUM(COALESCE(a.actual_rows, 0))::numeric
                        / SUM(e.expected_rows)), 2)     AS pct_missing
FROM expected e
LEFT JOIN actual a ON a.location_id = e.location_id
                  AND a.hour_day    = e.hour_day
GROUP BY period
ORDER BY period;
