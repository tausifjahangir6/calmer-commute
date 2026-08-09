-- ============================================================================
-- 06_demo_seed.sql        *** SYNTHETIC DATA -- TESTING AND DEMOS ONLY ***
--
-- Sensor names and coordinates are real public locations. THE COUNTS ARE
-- GENERATED, not measured. They follow a plausible commuter curve so the
-- analysis queries return sensible-looking output.
--
-- DO NOT quote these numbers as findings. Every figure in your report must
-- come from real data loaded via 07_load_from_raw.sql.
--
-- Remove later with:   SELECT hush.clear_demo_data();
-- ============================================================================

SET search_path TO hush, public;

BEGIN;

-- Sensors (real locations; note = 'DEMO DATA' is how cleanup finds them)
INSERT INTO sensor_location (location_id, sensor_name, sensor_description,
                             location_type, status, latitude, longitude,
                             direction_1, direction_2, installation_date, note, is_cbd)
VALUES
 (9001, 'DEMO_Bou_N',  'Bourke Street Mall (North)', 'Outdoor', 'A', -37.813600, 144.964600, 'East', 'West', '2009-03-01', 'DEMO DATA', TRUE),
 (9002, 'DEMO_Bou_S',  'Bourke Street Mall (South)', 'Outdoor', 'A', -37.813800, 144.965100, 'East', 'West', '2009-03-01', 'DEMO DATA', TRUE),
 (9003, 'DEMO_MelCen', 'Melbourne Central',          'Outdoor', 'A', -37.810800, 144.963300, 'North','South', '2009-03-01', 'DEMO DATA', TRUE),
 (9004, 'DEMO_TownH',  'Town Hall (West)',           'Outdoor', 'A', -37.814900, 144.966300, 'North','South', '2009-03-01', 'DEMO DATA', TRUE),
 (9005, 'DEMO_PriBri', 'Princes Bridge',             'Outdoor', 'A', -37.818600, 144.967900, 'North','South', '2009-03-01', 'DEMO DATA', TRUE),
 (9006, 'DEMO_FlinSt', 'Flinders Street Station',    'Outdoor', 'A', -37.818200, 144.966900, 'East', 'West', '2009-03-01', 'DEMO DATA', TRUE),
 (9007, 'DEMO_Flag',   'Flagstaff Station',          'Outdoor', 'A', -37.812200, 144.955700, 'North','South', '2010-06-01', 'DEMO DATA', TRUE),
 (9008, 'DEMO_ColPl',  'Collins Place (South)',      'Outdoor', 'A', -37.814000, 144.973300, 'East', 'West', '2011-02-01', 'DEMO DATA', TRUE),
 (9009, 'DEMO_Spark',  'Flinders Street Spark Lane', 'Outdoor', 'A', -37.816200, 144.969700, 'East', 'West', '2013-01-01', 'DEMO DATA', TRUE),
 (9010, 'DEMO_Lons',   'Lonsdale St (South)',        'Outdoor', 'A', -37.810600, 144.962000, 'East', 'West', '2014-08-01', 'DEMO DATA', TRUE)
ON CONFLICT (location_id) DO NOTHING;

-- Hourly counts: 60 days x 24 hours x 10 sensors (~14,400 rows).
-- Morning peak ~08:00, lunch bump ~12:30, evening peak ~17:00, quiet
-- overnight, weekends flatter and lower.
INSERT INTO pedestrian_hour_count (location_id, sensing_date, hour_day,
                                   direction_1, direction_2, total_of_direction)
SELECT
    s.location_id,
    d.day::date,
    h.hour::smallint,
    NULL, NULL,
    GREATEST(0, ROUND(
        s.busyness
        * CASE WHEN EXTRACT(DOW FROM d.day) IN (0, 6) THEN 0.55 ELSE 1.0 END
        * (  20
           +  900 * EXP(-POWER(h.hour -  8.0, 2) / 2.0)
           +  500 * EXP(-POWER(h.hour - 12.5, 2) / 3.0)
           + 1100 * EXP(-POWER(h.hour - 17.0, 2) / 2.5)
           +  150 * EXP(-POWER(h.hour - 21.0, 2) / 6.0))
        * (0.85 + 0.30 * ((s.location_id * 7 + h.hour * 13
                           + EXTRACT(DOY FROM d.day)::int * 3) % 100) / 100.0)
    ))::integer
FROM (VALUES
        (9001, 1.00), (9002, 0.95), (9003, 1.30), (9004, 1.15), (9005, 0.80),
        (9006, 1.60), (9007, 0.45), (9008, 0.55), (9009, 0.60), (9010, 0.70)
     ) AS s(location_id, busyness)
CROSS JOIN generate_series(CURRENT_DATE - 59, CURRENT_DATE, INTERVAL '1 day') AS d(day)
CROSS JOIN generate_series(0, 23) AS h(hour)
ON CONFLICT (location_id, sensing_date, hour_day) DO NOTHING;

-- Minute counts: last 3 hours, deliberately sparse (~25% of minutes dropped)
-- so gap detection has something real to work on.
INSERT INTO pedestrian_minute_count (location_id, sensing_datetime,
                                     direction_1, direction_2, total_of_direction)
SELECT
    s.location_id,
    m.ts,
    d1.v,
    GREATEST(0, ROUND(d1.v * (0.7 + 0.6 * ((s.location_id * 3
                     + EXTRACT(MINUTE FROM m.ts)::int) % 10) / 10.0)))::integer,
    d1.v + GREATEST(0, ROUND(d1.v * (0.7 + 0.6 * ((s.location_id * 3
                     + EXTRACT(MINUTE FROM m.ts)::int) % 10) / 10.0)))::integer
FROM (VALUES
        (9001, 1.00), (9002, 0.95), (9003, 1.30), (9004, 1.15), (9005, 0.80),
        (9006, 1.60), (9007, 0.45), (9008, 0.55), (9009, 0.60), (9010, 0.70)
     ) AS s(location_id, busyness)
CROSS JOIN generate_series(date_trunc('minute', now()) - INTERVAL '3 hours',
                           date_trunc('minute', now()), INTERVAL '1 minute') AS m(ts)
CROSS JOIN LATERAL (
    SELECT GREATEST(0, ROUND(
        s.busyness
        * (  2
           + 30 * EXP(-POWER(EXTRACT(HOUR FROM m.ts AT TIME ZONE 'Australia/Melbourne') -  8.0, 2) / 2.0)
           + 45 * EXP(-POWER(EXTRACT(HOUR FROM m.ts AT TIME ZONE 'Australia/Melbourne') - 17.0, 2) / 2.5))
        * (0.6 + 0.8 * ((s.location_id * 11
                         + EXTRACT(MINUTE FROM m.ts)::int * 7) % 100) / 100.0)
    ))::integer AS v) d1
WHERE (s.location_id * 17 + EXTRACT(MINUTE FROM m.ts)::int * 31) % 4 <> 0
ON CONFLICT (location_id, sensing_datetime) DO NOTHING;

COMMIT;


-- ---------------------------------------------------------------------------
-- Cleanup. Removes only demo rows; real data and real ETL runs are untouched.
-- Landmarks are NOT seeded, so nothing to clean there.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION hush.clear_demo_data() RETURNS text AS $$
DECLARE n_min bigint; n_hr bigint; n_sen bigint;
BEGIN
    DELETE FROM pedestrian_minute_count
     WHERE location_id IN (SELECT location_id FROM sensor_location WHERE note = 'DEMO DATA');
    GET DIAGNOSTICS n_min = ROW_COUNT;

    DELETE FROM pedestrian_hour_count
     WHERE location_id IN (SELECT location_id FROM sensor_location WHERE note = 'DEMO DATA');
    GET DIAGNOSTICS n_hr = ROW_COUNT;

    -- Legacy: an earlier version of this file seeded landmarks 9001-9013.
    DELETE FROM landmark WHERE landmark_id BETWEEN 9001 AND 9013;

    DELETE FROM sensor_location WHERE note = 'DEMO DATA';
    GET DIAGNOSTICS n_sen = ROW_COUNT;

    RETURN format('Removed %s minute rows, %s hourly rows, %s demo sensors.',
                  n_min, n_hr, n_sen);
END;
$$ LANGUAGE plpgsql;


SELECT 'sensor_location' AS table_name, COUNT(*) AS row_count FROM sensor_location
UNION ALL SELECT 'pedestrian_hour_count',   COUNT(*) FROM pedestrian_hour_count
UNION ALL SELECT 'pedestrian_minute_count', COUNT(*) FROM pedestrian_minute_count
ORDER BY table_name;
