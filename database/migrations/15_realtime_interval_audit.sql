-- ============================================================================
-- 15_realtime_interval_audit.sql
-- What is the actual finest interval and freshest latency available?
--
-- This answers "how real-time can adaptive rerouting be?" with measurements
-- from our own data rather than assumptions.
--
-- IMPORTANT: re-fetch the minute feed IMMEDIATELY before running this, or the
-- latency numbers will just reflect how long ago you last pulled:
--
--     python3 scripts/fetch_to_db.py --datasets minute
--     -- then sql/07_load_from_raw.sql section 2.2
--
-- ============================================================================

SET search_path TO hush, public;

-- ============================================================================
-- 1. THE TWO FEEDS -- what granularity does each actually provide?
-- ============================================================================
SELECT 'minute feed'                      AS feed,
       COUNT(*)                           AS rows,
       COUNT(DISTINCT location_id)        AS sensors,
       MIN(sensing_datetime)              AS earliest,
       MAX(sensing_datetime)              AS latest
FROM pedestrian_minute_count
UNION ALL
SELECT 'hourly feed',
       COUNT(*),
       COUNT(DISTINCT location_id),
       MIN(sensing_date)::timestamptz,
       MAX(sensing_date)::timestamptz
FROM pedestrian_hour_count;


-- ============================================================================
-- 2. LATENCY -- how far behind "now" is the freshest reading?
--
-- This is the number that defines "real-time" for the product. Run it right
-- after a fresh fetch.
-- ============================================================================
SELECT MAX(sensing_datetime)                          AS freshest_reading,
       now()                                          AS clock_now,
       now() - MAX(sensing_datetime)                  AS data_age,
       ROUND(EXTRACT(EPOCH FROM (now() - MAX(sensing_datetime))) / 60)
                                                      AS data_age_minutes
FROM pedestrian_minute_count;


-- ============================================================================
-- 3. REPORTING INTERVAL -- the gap between consecutive readings per sensor
--
-- If most gaps are 1 minute, the feed is genuinely minute-level. If they
-- cluster at 5, that is the real resolution regardless of the dataset name.
-- ============================================================================
WITH gaps AS (
    SELECT location_id,
           EXTRACT(EPOCH FROM (sensing_datetime
               - LAG(sensing_datetime) OVER (PARTITION BY location_id
                                             ORDER BY sensing_datetime))) / 60
               AS gap_minutes
    FROM pedestrian_minute_count
)
SELECT ROUND(gap_minutes)                              AS gap_minutes,
       COUNT(*)                                        AS occurrences,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_gaps
FROM gaps
WHERE gap_minutes IS NOT NULL
GROUP BY ROUND(gap_minutes)
ORDER BY occurrences DESC
LIMIT 15;


-- ============================================================================
-- 4. PER-SENSOR MEDIAN INTERVAL -- is it uniform across sensors?
-- ============================================================================
WITH gaps AS (
    SELECT location_id,
           EXTRACT(EPOCH FROM (sensing_datetime
               - LAG(sensing_datetime) OVER (PARTITION BY location_id
                                             ORDER BY sensing_datetime))) / 60
               AS gap_minutes
    FROM pedestrian_minute_count
)
SELECT ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_minutes)::numeric, 1)
           AS median_gap_minutes_overall,
       ROUND(MIN(gap_minutes)::numeric, 1)             AS min_gap,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY gap_minutes)::numeric, 1)
           AS p95_gap,
       COUNT(DISTINCT location_id)                     AS sensors
FROM gaps
WHERE gap_minutes IS NOT NULL AND gap_minutes > 0;


-- ============================================================================
-- 5. SIMULTANEITY -- how many sensors report in the same minute?
--
-- Matters for rerouting: if only a handful of sensors update each minute, a
-- "live map" is really a rolling composite of readings taken minutes apart.
-- ============================================================================
SELECT date_trunc('minute', sensing_datetime)          AS minute,
       COUNT(DISTINCT location_id)                     AS sensors_reporting
FROM pedestrian_minute_count
GROUP BY 1
ORDER BY 1 DESC
LIMIT 20;


-- ============================================================================
-- 6. STALENESS SPREAD -- at any instant, how old is each sensor's reading?
--
-- v_current_density shows the latest reading per sensor. If those readings
-- span 30 minutes, the "live" map is not a single moment in time.
-- ============================================================================
SELECT ROUND(EXTRACT(EPOCH FROM (MAX(sensing_datetime) OVER ()
                                 - sensing_datetime)) / 60) AS minutes_behind_freshest,
       COUNT(*)                                             AS sensors
FROM (
    SELECT DISTINCT ON (location_id) location_id, sensing_datetime
    FROM pedestrian_minute_count
    ORDER BY location_id, sensing_datetime DESC
) latest
GROUP BY 1
ORDER BY 1;


-- ============================================================================
-- 7. SUMMARY FOR THE TEAM
-- ============================================================================
WITH latest AS (
    SELECT DISTINCT ON (location_id) location_id, sensing_datetime
    FROM pedestrian_minute_count
    ORDER BY location_id, sensing_datetime DESC
)
SELECT COUNT(*)                                              AS sensors_live,
       MIN(sensing_datetime)                                 AS oldest_current_reading,
       MAX(sensing_datetime)                                 AS newest_current_reading,
       ROUND(EXTRACT(EPOCH FROM (MAX(sensing_datetime)
                               - MIN(sensing_datetime))) / 60)
                                                             AS spread_minutes,
       ROUND(EXTRACT(EPOCH FROM (now() - MAX(sensing_datetime))) / 60)
                                                             AS freshest_age_minutes
FROM latest;
