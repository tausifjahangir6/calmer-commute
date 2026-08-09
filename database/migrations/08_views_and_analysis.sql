-- ============================================================================
-- 08_views_and_analysis.sql
-- Views the application reads, plus the analysis queries.
-- Safe to re-run.
--
-- Every view exposes `display_name`, because `sensor_name` holds a device code
-- ("Swa295_T") while the readable name lives in `sensor_description`
-- ("Melbourne Central"). Anything user-facing must read display_name.
--
-- Run AFTER 07_load_from_raw.sql.
-- ============================================================================

SET search_path TO hush, public;

-- ============================================================================
-- PART 1 - Views
-- ============================================================================

-- Dropped rather than replaced: CREATE OR REPLACE VIEW cannot rename a column,
-- and if an earlier version of these views exists it exposes sensor_name.
-- Views hold no data, so this costs nothing.
DROP VIEW IF EXISTS v_current_density      CASCADE;
DROP VIEW IF EXISTS v_hourly_profile       CASCADE;
DROP VIEW IF EXISTS v_low_sensory_landmark CASCADE;
DROP VIEW IF EXISTS v_minute_count_local   CASCADE;
DROP VIEW IF EXISTS v_data_quality         CASCADE;
DROP VIEW IF EXISTS v_sensor               CASCADE;


-- Local date/time parts, derived rather than stored (the 2NF fix).
-- The source timestamp is UTC; "hour of day" only means something locally.
CREATE VIEW v_minute_count_local AS
SELECT
    m.location_id,
    m.sensing_datetime,
    (m.sensing_datetime AT TIME ZONE 'Australia/Melbourne')::date AS sensing_date,
    (m.sensing_datetime AT TIME ZONE 'Australia/Melbourne')::time AS sensing_time,
    EXTRACT(HOUR FROM m.sensing_datetime AT TIME ZONE 'Australia/Melbourne')::smallint AS hour_day,
    EXTRACT(DOW  FROM m.sensing_datetime AT TIME ZONE 'Australia/Melbourne')::smallint AS day_of_week,
    m.direction_1,
    m.direction_2,
    m.total_of_direction
FROM pedestrian_minute_count m;


-- Canonical sensor list with a usable name. Everything user-facing reads this.
CREATE VIEW v_sensor AS
SELECT
    s.location_id,
    COALESCE(NULLIF(btrim(s.sensor_description), ''), s.sensor_name) AS display_name,
    s.sensor_name AS device_code,
    s.sensor_description,
    s.location_type,
    s.status,
    s.latitude,
    s.longitude,
    s.direction_1,
    s.direction_2,
    s.installation_date,
    s.is_cbd,
    (s.status = 'A') AS is_active
FROM sensor_location s;


-- Latest reading per sensor, banded. This is the live map feed.
CREATE VIEW v_current_density AS
SELECT DISTINCT ON (m.location_id)
    s.location_id,
    s.display_name,
    s.latitude,
    s.longitude,
    m.sensing_datetime,
    m.total_of_direction AS people_per_minute,
    b.band_name          AS density_level
FROM pedestrian_minute_count m
JOIN v_sensor     s ON s.location_id = m.location_id
JOIN density_band b ON m.total_of_direction >= b.min_count
                   AND (b.max_count IS NULL OR m.total_of_direction <= b.max_count)
WHERE s.is_active
ORDER BY m.location_id, m.sensing_datetime DESC;


-- Typical crowd per sensor per hour. Backs the quiet-window advice.
CREATE VIEW v_hourly_profile AS
SELECT
    h.location_id,
    s.display_name,
    h.hour_day,
    COUNT(*)                                  AS observations,
    ROUND(AVG(h.total_of_direction))::integer AS avg_count,
    MIN(h.total_of_direction)                 AS min_count,
    MAX(h.total_of_direction)                 AS max_count,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY h.total_of_direction)::integer AS median_count
FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
GROUP BY h.location_id, s.display_name, h.hour_day;


CREATE VIEW v_low_sensory_landmark AS
SELECT l.landmark_id, l.feature_name, t.theme_name, c.sub_theme,
       c.sensory_load, l.latitude, l.longitude
FROM landmark          l
JOIN landmark_category c ON c.category_id = l.category_id
JOIN theme             t ON t.theme_id    = c.theme_id
WHERE c.sensory_load = 'low';


CREATE VIEW v_data_quality AS
SELECT 'pedestrian_minute_count' AS table_name,
       COUNT(*)                                              AS row_count,
       COUNT(*) FILTER (WHERE direction_1 IS NULL
                           OR direction_2 IS NULL)           AS rows_missing_direction,
       MIN(sensing_datetime)                                 AS earliest,
       MAX(sensing_datetime)                                 AS latest,
       COUNT(DISTINCT location_id)                           AS distinct_sensors
FROM pedestrian_minute_count
UNION ALL
SELECT 'pedestrian_hour_count',
       COUNT(*),
       COUNT(*) FILTER (WHERE direction_1 IS NULL OR direction_2 IS NULL),
       MIN(sensing_date)::timestamptz,
       MAX(sensing_date)::timestamptz,
       COUNT(DISTINCT location_id)
FROM pedestrian_hour_count;


-- Restore the app grants that the DROPs removed.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hush_app') THEN
        GRANT SELECT ON v_current_density, v_hourly_profile,
                        v_low_sensory_landmark, v_minute_count_local,
                        v_sensor, v_data_quality, density_band TO hush_app;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hush_analyst') THEN
        GRANT SELECT ON ALL TABLES IN SCHEMA hush TO hush_analyst;
    END IF;
END
$$;


-- ============================================================================
-- PART 2 - Analysis queries.  Run ONE AT A TIME.
-- Each maps to a claim in the Data Management Plan.
-- ============================================================================

-- Q1. Live crowd density map   (DMP: "crowd density estimation by location")
SELECT display_name, people_per_minute, density_level, sensing_datetime
FROM v_current_density
ORDER BY people_per_minute DESC;


-- Q2. Quiet travel windows at one location  (DMP: "quiet travel windows")
--     Pick a name from:  SELECT display_name FROM v_sensor ORDER BY 1;
SELECT hour_day, avg_count, median_count,
       CASE WHEN avg_count <= 50  THEN 'Low'
            WHEN avg_count <= 150 THEN 'Medium'
            ELSE 'High' END AS typical_level
FROM v_hourly_profile
WHERE display_name ILIKE '%Melbourne Central%'
ORDER BY avg_count ASC
LIMIT 5;


-- Q3. Peak commuting hours across the CBD   (DMP: "peak commuting hours")
SELECT h.hour_day,
       SUM(h.total_of_direction)                 AS total_pedestrians,
       ROUND(AVG(h.total_of_direction))::integer AS avg_per_sensor
FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
WHERE s.is_cbd
GROUP BY h.hour_day
ORDER BY total_pedestrians DESC;


-- Q4. Weekday vs weekend pattern   (DMP: "daily patterns")
SELECT CASE WHEN EXTRACT(DOW FROM sensing_date) IN (0, 6)
            THEN 'Weekend' ELSE 'Weekday' END  AS day_type,
       hour_day,
       ROUND(AVG(total_of_direction))::integer AS avg_count
FROM pedestrian_hour_count
GROUP BY day_type, hour_day
ORDER BY day_type, hour_day;


-- Q5. Naive forecast baseline: same sensor, same hour, same weekday, trailing
--     8 weeks. Report this number. Any ML model added later has to beat it,
--     and stating the baseline upfront is what makes a modelling claim
--     credible rather than decorative.
SELECT s.display_name,
       h.hour_day,
       ROUND(AVG(h.total_of_direction))::integer         AS forecast_count,
       ROUND(STDDEV_SAMP(h.total_of_direction))::integer AS forecast_stddev,
       COUNT(*)                                          AS weeks_of_evidence
FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
WHERE h.sensing_date >= CURRENT_DATE - INTERVAL '56 days'
  AND EXTRACT(DOW FROM h.sensing_date) = EXTRACT(DOW FROM CURRENT_DATE)
GROUP BY s.display_name, h.hour_day
HAVING COUNT(*) >= 4
ORDER BY s.display_name, h.hour_day;


-- Q6. Low-sensory landmarks near a currently quiet sensor
--     Haversine in plain SQL -- no PostGIS extension needed.
WITH quiet AS (
    SELECT location_id, display_name, latitude, longitude
    FROM v_current_density
    WHERE density_level = 'Low'
)
SELECT q.display_name AS near_sensor,
       l.feature_name, l.theme_name, l.sub_theme,
       ROUND((6371 * ACOS(LEAST(1,
              COS(RADIANS(q.latitude)) * COS(RADIANS(l.latitude))
              * COS(RADIANS(l.longitude) - RADIANS(q.longitude))
            + SIN(RADIANS(q.latitude)) * SIN(RADIANS(l.latitude)))))::numeric, 3)
           AS distance_km
FROM quiet q
CROSS JOIN v_low_sensory_landmark l
WHERE (6371 * ACOS(LEAST(1,
              COS(RADIANS(q.latitude)) * COS(RADIANS(l.latitude))
              * COS(RADIANS(l.longitude) - RADIANS(q.longitude))
            + SIN(RADIANS(q.latitude)) * SIN(RADIANS(l.latitude))))) < 0.5
ORDER BY q.display_name, distance_km;


-- Q7. Active sensors silent for over 30 minutes.
--     The real feed only emits a row when someone walks past, so an overnight
--     gap at a quiet sensor is normal. Say that in the report rather than
--     treating every gap as a fault.
SELECT s.location_id, s.display_name,
       MAX(m.sensing_datetime)         AS last_seen,
       now() - MAX(m.sensing_datetime) AS staleness
FROM v_sensor s
LEFT JOIN pedestrian_minute_count m ON m.location_id = s.location_id
WHERE s.is_active
GROUP BY s.location_id, s.display_name
HAVING MAX(m.sensing_datetime) IS NULL
    OR MAX(m.sensing_datetime) < now() - INTERVAL '30 minutes'
ORDER BY last_seen NULLS FIRST;


-- Q8. Directional split at morning peak. Possible on the historical series
--     because the hourly dataset carries directions after all.
SELECT s.display_name,
       s.direction_1 AS dir_1_meaning,
       s.direction_2 AS dir_2_meaning,
       SUM(h.direction_1) AS dir_1_total,
       SUM(h.direction_2) AS dir_2_total,
       ROUND(100.0 * SUM(h.direction_1)
             / NULLIF(SUM(h.direction_1) + SUM(h.direction_2), 0), 1) AS pct_dir_1
FROM pedestrian_hour_count h
JOIN v_sensor s ON s.location_id = h.location_id
WHERE h.hour_day BETWEEN 7 AND 9
  AND h.direction_1 IS NOT NULL
GROUP BY s.display_name, s.direction_1, s.direction_2
HAVING SUM(h.direction_1) + SUM(h.direction_2) > 0
ORDER BY SUM(h.direction_1) + SUM(h.direction_2) DESC
LIMIT 20;


-- Q9. Data quality summary  (evidence for the Data Cleansing section)
SELECT * FROM v_data_quality;
