-- ============================================================================
-- 07_load_from_raw.sql
-- Loads hush.raw_ingest (filled by etl/fetch_to_db.py) into the 3NF tables.
-- Safe to re-run: every insert is an idempotent upsert.
--
-- MAPPED AGAINST THE REAL API FIELD NAMES, confirmed by --probe:
--
--   * The join key is `location_id` in all four datasets. The portal's prose
--     documentation says "sensor_id" -- that describes the CSV export, not the
--     v2.1 API. The original course sample was right.
--   * `sensor_name` is a device code ("Swa295_T"). The readable name is in
--     `sensor_description` ("Melbourne Central").
--   * Hourly's total column is `pedestriancount`, and it DOES carry
--     direction_1 / direction_2 despite the portal saying it doesn't.
--   * The landmarks dataset has NO id column -- only feature_name, theme,
--     sub_theme, co_ordinates. A content hash supplies the key.
--   * Minute `sensing_datetime` is UTC (+00:00); `sensing_date` and
--     `sensing_time` are Melbourne local.
-- ============================================================================

SET search_path TO hush, public;

-- ============================================================================
-- PART 1 - Helper functions.  All CREATE OR REPLACE, safe to re-run.
-- ============================================================================

-- Coordinates arrive as {"lon": 144.96, "lat": -37.81} -- LONGITUDE FIRST.
-- Reading "the first number" would put every sensor in Kazakhstan, so these
-- read the key name and fall back to position only when no key is present.
CREATE OR REPLACE FUNCTION hush.coord_a(txt text) RETURNS numeric AS $$
    SELECT CASE
        WHEN txt IS NULL OR btrim(txt) = '' THEN NULL
        WHEN txt ~* 'lat' THEN
            (regexp_match(txt, 'lat(?:itude)?"?\s*[:=]?\s*(-?\d+(?:\.\d+)?)', 'i'))[1]::numeric
        ELSE (regexp_match(txt, '(-?\d+(?:\.\d+)?)'))[1]::numeric
    END;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION hush.coord_b(txt text) RETURNS numeric AS $$
    SELECT CASE
        WHEN txt IS NULL OR btrim(txt) = '' THEN NULL
        WHEN txt ~* 'lon' THEN
            (regexp_match(txt, 'lon(?:gitude)?"?\s*[:=]?\s*(-?\d+(?:\.\d+)?)', 'i'))[1]::numeric
        ELSE (regexp_match(txt, '(-?\d+(?:\.\d+)?)[^0-9.-]+(-?\d+(?:\.\d+)?)'))[2]::numeric
    END;
$$ LANGUAGE sql IMMUTABLE;

-- In Melbourne the latitude is always the negative value, whichever slot it
-- arrived in. This repairs a swapped pair automatically.
CREATE OR REPLACE FUNCTION hush.pick_lat(a numeric, b numeric) RETURNS numeric AS $$
    SELECT CASE WHEN a IS NULL OR b IS NULL THEN COALESCE(a, b)
                WHEN a < 0 THEN a ELSE b END;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION hush.pick_lon(a numeric, b numeric) RETURNS numeric AS $$
    SELECT CASE WHEN a IS NULL OR b IS NULL THEN NULL
                WHEN a < 0 THEN b ELSE a END;
$$ LANGUAGE sql IMMUTABLE;

-- Safe casts: NULL on junk rather than aborting the whole load.
CREATE OR REPLACE FUNCTION hush.to_int(txt text) RETURNS integer AS $$
BEGIN
    RETURN NULLIF(btrim(txt), '')::numeric::integer;
EXCEPTION WHEN others THEN RETURN NULL;
END; $$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION hush.to_ts(txt text) RETURNS timestamptz AS $$
BEGIN
    RETURN NULLIF(btrim(txt), '')::timestamptz;
EXCEPTION WHEN others THEN
    BEGIN
        RETURN (NULLIF(btrim(txt), '')::timestamp) AT TIME ZONE 'Australia/Melbourne';
    EXCEPTION WHEN others THEN RETURN NULL;
    END;
END; $$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION hush.to_date_safe(txt text) RETURNS date AS $$
BEGIN
    RETURN NULLIF(btrim(txt), '')::date;
EXCEPTION WHEN others THEN RETURN NULL;
END; $$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION hush.to_hour(txt text) RETURNS smallint AS $$
DECLARE h integer;
BEGIN
    IF txt IS NULL OR btrim(txt) = '' THEN RETURN NULL; END IF;
    h := (regexp_match(btrim(txt), '^(\d{1,2})'))[1]::integer;
    IF btrim(txt) ~* 'PM' AND h < 12 THEN h := h + 12; END IF;
    IF btrim(txt) ~* 'AM' AND h = 12 THEN h := 0;      END IF;
    IF h BETWEEN 0 AND 23 THEN RETURN h::smallint; END IF;
    RETURN NULL;
EXCEPTION WHEN others THEN RETURN NULL;
END; $$ LANGUAGE plpgsql IMMUTABLE;

-- First present, non-empty key from a candidate list. If the portal renames a
-- column you add a name to a list instead of rewriting the query.
CREATE OR REPLACE FUNCTION hush.jget(payload jsonb, VARIADIC keys text[])
RETURNS text AS $$
DECLARE k text; v text;
BEGIN
    FOREACH k IN ARRAY keys LOOP
        IF payload ? k THEN
            v := payload ->> k;
            IF v IS NOT NULL AND btrim(v) <> '' THEN RETURN v; END IF;
        END IF;
    END LOOP;
    RETURN NULL;
END; $$ LANGUAGE plpgsql IMMUTABLE;

-- Same, but keeps nested JSON intact (needed for the coordinate objects).
CREATE OR REPLACE FUNCTION hush.jraw(payload jsonb, VARIADIC keys text[])
RETURNS text AS $$
DECLARE k text;
BEGIN
    FOREACH k IN ARRAY keys LOOP
        IF payload ? k AND payload -> k <> 'null'::jsonb THEN
            RETURN payload -> k #>> '{}';
        END IF;
    END LOOP;
    RETURN NULL;
END; $$ LANGUAGE plpgsql IMMUTABLE;

-- Deterministic surrogate key for landmarks, which ship no ID.
-- 28 bits keeps the value positive and inside integer range; the same landmark
-- always hashes to the same key, so re-running is idempotent.
CREATE OR REPLACE FUNCTION hush.surrogate_id(VARIADIC parts text[])
RETURNS integer AS $$
    SELECT ('x' || substr(md5(array_to_string(parts, '|')), 1, 7))::bit(28)::integer;
$$ LANGUAGE sql IMMUTABLE;


-- ============================================================================
-- PART 2 - Load.  Run 2.1 first: the fact tables have foreign keys to it.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 2.1  SENSOR_LOCATION  (134 records)
-- ---------------------------------------------------------------------------
INSERT INTO sensor_location (
    location_id, sensor_name, sensor_description, location_type, status,
    latitude, longitude, direction_1, direction_2, installation_date, note, is_cbd)
SELECT DISTINCT ON (t.location_id)
    t.location_id,
    COALESCE(t.sensor_name, 'Sensor ' || t.location_id),
    t.sensor_description,
    t.location_type,
    COALESCE(t.status, 'Unknown'),
    hush.pick_lat(t.ca, t.cb),
    hush.pick_lon(t.ca, t.cb),
    t.direction_1,
    t.direction_2,
    hush.to_date_safe(t.installation_date),
    t.note,
    (hush.pick_lat(t.ca, t.cb) BETWEEN -37.8300 AND -37.7950
     AND hush.pick_lon(t.ca, t.cb) BETWEEN 144.9300 AND 144.9800)
FROM (
    SELECT
        hush.to_int(hush.jget(payload, 'location_id', 'sensor_id', 'id'))      AS location_id,
        hush.jget(payload, 'sensor_name')                                      AS sensor_name,
        hush.jget(payload, 'sensor_description', 'description')                AS sensor_description,
        hush.jget(payload, 'location_type', 'type')                            AS location_type,
        hush.jget(payload, 'status')                                           AS status,
        hush.jget(payload, 'direction_1')                                      AS direction_1,
        hush.jget(payload, 'direction_2')                                      AS direction_2,
        hush.jget(payload, 'installation_date')                                AS installation_date,
        hush.jget(payload, 'note', 'notes')                                    AS note,
        COALESCE(hush.jget(payload, 'latitude')::numeric,
                 hush.coord_a(hush.jraw(payload, 'location', 'geo_point_2d'))) AS ca,
        COALESCE(hush.jget(payload, 'longitude')::numeric,
                 hush.coord_b(hush.jraw(payload, 'location', 'geo_point_2d'))) AS cb
    FROM raw_ingest
    WHERE dataset_id = 'pedestrian-counting-system-sensor-locations'
) t
WHERE t.location_id IS NOT NULL
  AND hush.pick_lat(t.ca, t.cb) IS NOT NULL
  AND hush.pick_lon(t.ca, t.cb) IS NOT NULL
ORDER BY t.location_id, t.installation_date DESC NULLS LAST
ON CONFLICT (location_id) DO UPDATE SET
    sensor_name        = EXCLUDED.sensor_name,
    sensor_description = EXCLUDED.sensor_description,
    location_type      = EXCLUDED.location_type,
    status             = EXCLUDED.status,
    latitude           = EXCLUDED.latitude,
    longitude          = EXCLUDED.longitude,
    direction_1        = EXCLUDED.direction_1,
    direction_2        = EXCLUDED.direction_2,
    installation_date  = EXCLUDED.installation_date,
    note               = EXCLUDED.note,
    is_cbd             = EXCLUDED.is_cbd;


-- ---------------------------------------------------------------------------
-- 2.2  PEDESTRIAN_MINUTE_COUNT
-- DISTINCT ON collapses duplicates (the portal warns sensors 67/68/69 emit
-- them); the JOIN enforces referential integrity against the sensor table.
-- ---------------------------------------------------------------------------
INSERT INTO pedestrian_minute_count (
    location_id, sensing_datetime, direction_1, direction_2, total_of_direction)
SELECT DISTINCT ON (t.location_id, t.sensing_datetime)
    t.location_id, t.sensing_datetime, t.d1, t.d2,
    COALESCE(t.total, COALESCE(t.d1, 0) + COALESCE(t.d2, 0))
FROM (
    SELECT
        hush.to_int(hush.jget(payload, 'location_id', 'sensor_id'))  AS location_id,
        hush.to_ts(hush.jget(payload, 'sensing_datetime'))           AS sensing_datetime,
        hush.to_int(hush.jget(payload, 'direction_1'))               AS d1,
        hush.to_int(hush.jget(payload, 'direction_2'))               AS d2,
        hush.to_int(hush.jget(payload, 'total_of_directions'))       AS total
    FROM raw_ingest
    WHERE dataset_id = 'pedestrian-counting-system-past-hour-counts-per-minute'
) t
JOIN sensor_location sl ON sl.location_id = t.location_id
WHERE t.location_id IS NOT NULL
  AND t.sensing_datetime IS NOT NULL
  AND COALESCE(t.total, COALESCE(t.d1, 0) + COALESCE(t.d2, 0)) >= 0
ORDER BY t.location_id, t.sensing_datetime, t.total DESC NULLS LAST
ON CONFLICT (location_id, sensing_datetime) DO UPDATE SET
    direction_1        = EXCLUDED.direction_1,
    direction_2        = EXCLUDED.direction_2,
    total_of_direction = EXCLUDED.total_of_direction;


-- ---------------------------------------------------------------------------
-- 2.3  PEDESTRIAN_HOUR_COUNT
-- Total column is `pedestriancount`. sensor_name and location are NOT copied:
-- they depend only on location_id -- the 2NF partial dependency the DMP names.
-- ---------------------------------------------------------------------------
INSERT INTO pedestrian_hour_count (
    location_id, sensing_date, hour_day, direction_1, direction_2, total_of_direction)
SELECT DISTINCT ON (t.location_id, t.sensing_date, t.hour_day)
    t.location_id, t.sensing_date, t.hour_day, t.d1, t.d2,
    COALESCE(t.total, COALESCE(t.d1, 0) + COALESCE(t.d2, 0))
FROM (
    SELECT
        hush.to_int(hush.jget(payload, 'location_id', 'sensor_id'))  AS location_id,
        hush.to_date_safe(hush.jget(payload, 'sensing_date'))        AS sensing_date,
        hush.to_hour(hush.jget(payload, 'hourday', 'hour_day'))      AS hour_day,
        hush.to_int(hush.jget(payload, 'direction_1'))               AS d1,
        hush.to_int(hush.jget(payload, 'direction_2'))               AS d2,
        hush.to_int(hush.jget(payload, 'pedestriancount',
                              'hourly_counts', 'total_of_directions')) AS total
    FROM raw_ingest
    WHERE dataset_id = 'pedestrian-counting-system-monthly-counts-per-hour'
) t
JOIN sensor_location sl ON sl.location_id = t.location_id
WHERE t.location_id IS NOT NULL
  AND t.sensing_date IS NOT NULL
  AND t.hour_day IS NOT NULL
  AND COALESCE(t.total, COALESCE(t.d1, 0) + COALESCE(t.d2, 0)) >= 0
ORDER BY t.location_id, t.sensing_date, t.hour_day, t.total DESC NULLS LAST
ON CONFLICT (location_id, sensing_date, hour_day) DO UPDATE SET
    direction_1        = EXCLUDED.direction_1,
    direction_2        = EXCLUDED.direction_2,
    total_of_direction = EXCLUDED.total_of_direction;


-- ---------------------------------------------------------------------------
-- 2.4  THEME -> LANDMARK_CATEGORY -> LANDMARK  (242 records, no source ID)
--
-- Sensory ratings here are a rough first pass. 09_fix_sensory_classification.sql
-- replaces them with the reviewed version -- run it after this.
-- ---------------------------------------------------------------------------
INSERT INTO theme (theme_name)
SELECT DISTINCT COALESCE(hush.jget(payload, 'theme'), 'Unclassified')
FROM raw_ingest
WHERE dataset_id LIKE 'landmarks-and-places-of-interest%'
ON CONFLICT (theme_name) DO NOTHING;

INSERT INTO landmark_category (theme_id, sub_theme, sensory_load)
SELECT DISTINCT
    th.theme_id,
    COALESCE(hush.jget(r.payload, 'sub_theme', 'subtheme'), 'Unclassified'),
    'unrated'
FROM raw_ingest r
JOIN theme th ON th.theme_name = COALESCE(hush.jget(r.payload, 'theme'), 'Unclassified')
WHERE r.dataset_id LIKE 'landmarks-and-places-of-interest%'
ON CONFLICT (theme_id, sub_theme) DO NOTHING;

INSERT INTO landmark (landmark_id, category_id, feature_name, latitude, longitude)
SELECT DISTINCT ON (t.landmark_id)
    t.landmark_id, c.category_id, t.feature_name,
    hush.pick_lat(t.ca, t.cb), hush.pick_lon(t.ca, t.cb)
FROM (
    SELECT
        hush.surrogate_id(
            COALESCE(hush.jget(payload, 'feature_name', 'featurename'), ''),
            COALESCE(hush.jraw(payload, 'co_ordinates', 'coordinates'), ''))  AS landmark_id,
        COALESCE(hush.jget(payload, 'feature_name', 'featurename'), 'Unnamed') AS feature_name,
        COALESCE(hush.jget(payload, 'theme'), 'Unclassified')                  AS theme_name,
        COALESCE(hush.jget(payload, 'sub_theme', 'subtheme'), 'Unclassified')  AS sub_theme,
        COALESCE(hush.jget(payload, 'latitude')::numeric,
                 hush.coord_a(hush.jraw(payload, 'co_ordinates',
                                        'coordinates', 'geo_point_2d')))       AS ca,
        COALESCE(hush.jget(payload, 'longitude')::numeric,
                 hush.coord_b(hush.jraw(payload, 'co_ordinates',
                                        'coordinates', 'geo_point_2d')))       AS cb
    FROM raw_ingest
    WHERE dataset_id LIKE 'landmarks-and-places-of-interest%'
) t
JOIN theme th ON th.theme_name = t.theme_name
JOIN landmark_category c ON c.theme_id = th.theme_id AND c.sub_theme = t.sub_theme
WHERE hush.pick_lat(t.ca, t.cb) IS NOT NULL
  AND hush.pick_lon(t.ca, t.cb) IS NOT NULL
ORDER BY t.landmark_id
ON CONFLICT (landmark_id) DO UPDATE SET
    category_id  = EXCLUDED.category_id,
    feature_name = EXCLUDED.feature_name,
    latitude     = EXCLUDED.latitude,
    longitude    = EXCLUDED.longitude;


-- ============================================================================
-- PART 3 - Verify.  Run these ONE AT A TIME -- pgAdmin only shows the last
-- result set when you execute a whole block.
-- ============================================================================

-- 3.1  Row counts. Expect sensors 134, landmarks ~242, counts as fetched.
SELECT 'sensor_location'         AS table_name, COUNT(*) AS row_count FROM sensor_location
UNION ALL SELECT 'pedestrian_minute_count', COUNT(*) FROM pedestrian_minute_count
UNION ALL SELECT 'pedestrian_hour_count',   COUNT(*) FROM pedestrian_hour_count
UNION ALL SELECT 'theme',                   COUNT(*) FROM theme
UNION ALL SELECT 'landmark_category',       COUNT(*) FROM landmark_category
UNION ALL SELECT 'landmark',                COUNT(*) FROM landmark
ORDER BY table_name;

-- 3.2  Coordinate sanity. Latitude must be about -37.8, longitude about +144.9.
--      If these come back swapped, stop and say so.
SELECT MIN(latitude)  AS min_lat, MAX(latitude)  AS max_lat,
       MIN(longitude) AS min_lon, MAX(longitude) AS max_lon,
       COUNT(*) FILTER (WHERE is_cbd) AS in_cbd,
       COUNT(*)                       AS total
FROM sensor_location;

-- 3.3  How much raw data is staged, per dataset.
SELECT dataset_id, COUNT(*) AS raw_rows, MAX(fetched_at) AS last_fetched
FROM raw_ingest GROUP BY dataset_id ORDER BY dataset_id;

-- 3.4  Sensors that were rejected, and why.
--      Screenshot for the Data Cleansing section of the report.
SELECT hush.jget(payload, 'location_id') AS source_id,
       payload ->> 'sensor_description'  AS sensor,
       CASE WHEN hush.to_int(hush.jget(payload, 'location_id')) IS NULL
            THEN 'unparseable location_id'
            ELSE 'missing or unparseable coordinates' END AS reason
FROM raw_ingest
WHERE dataset_id = 'pedestrian-counting-system-sensor-locations'
  AND NOT EXISTS (SELECT 1 FROM sensor_location sl
                  WHERE sl.location_id = hush.to_int(hush.jget(payload, 'location_id')));

-- 3.5  Sample of what loaded, using the readable name.
SELECT location_id, sensor_description, status, latitude, longitude, is_cbd
FROM sensor_location
ORDER BY location_id
LIMIT 15;
