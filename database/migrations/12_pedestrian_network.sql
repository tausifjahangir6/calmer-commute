-- ============================================================================
-- 12_pedestrian_network.sql
-- Walking-distance catchment from the Pedestrian Network CSV.
--
-- *** NO POSTGIS REQUIRED. NO EXTENSIONS AT ALL. ***
--   You have under a week. Installing PostGIS and learning pgRouting is not
--   the best use of it. The geometry in this file is just coordinate pairs in
--   JSON, and plain PostgreSQL can parse them, measure them and walk the
--   graph. That removes the whole install risk.
--
-- WHAT THIS GIVES YOU
--   Real walking distance from every sensor to every low-sensory landmark,
--   replacing the straight-line distance in 08 Q6. In the CBD, with the Yarra
--   and the rail corridor in the way, crow-flies distance is regularly wrong
--   by a factor of two -- it will happily "recommend" a park across a river.
--
-- WHAT THE CSV ACTUALLY CONTAINS (measured, quote these)
--   85,326 rows, 4 columns: Geo Point, Geo Shape, OBJECTID, NeworkID (sic)
--     71,060 LineStrings -> the network. NeworkID is EMPTY on every one.
--     14,266 Points      -> property connectors, NOT nodes. Each shares its
--                           OBJECTID with exactly one line (a real FK).
--   No street name, no link type, NO SIGNALISED-CROSSING FLAG.
--   1,234.2 km total | median segment 9.9 m | 62,096 endpoints
--   80% of endpoints shared by 2+ segments -> genuinely connected
--   12,434 dead ends (20%) -> property spurs
--   Sensor snap distance: worst 9.5 m, median ~2 m (15 sensors tested)
--
--   The portal advertises "penalising busy crossings with traffic lights".
--   Those attributes are in the ZIP download, not this CSV. Do not claim a
--   crossing penalty in your report based on this file.
--
-- ORDER
--   PART 1  create staging       -> then load the CSV
--   PART 2-4 build the graph
--   PART 5  snap sensors
--   PART 6  catchment + landmark walking distances   <- the deliverable
--   PART 7  verify
-- ============================================================================

SET search_path TO hush, public;
SET work_mem = '512MB';


-- ============================================================================
-- PART 1 - Staging.  Run this, then load the CSV, then continue.
--
--   python3 etl/load_network_csv.py --file pedestrian-network.csv
--   (or pgAdmin -> right-click stg_network -> Import/Export Data,
--    Header = Yes, Delimiter = comma, Encoding = UTF8)
-- ============================================================================

DROP TABLE IF EXISTS stg_network;
CREATE TABLE stg_network (
    geo_point TEXT,
    geo_shape TEXT,
    objectid  TEXT,
    networkid TEXT
);


-- ============================================================================
-- PART 2 - Helpers
-- ============================================================================

-- Great-circle distance in metres. Same formula as the landmark query in 08,
-- so the two are directly comparable.
CREATE OR REPLACE FUNCTION hush.hav_m(lat1 double precision, lon1 double precision,
                                      lat2 double precision, lon2 double precision)
RETURNS double precision AS $$
    SELECT 6371000 * 2 * ASIN(SQRT(LEAST(1,
        POWER(SIN(RADIANS(lat2 - lat1) / 2), 2)
      + COS(RADIANS(lat1)) * COS(RADIANS(lat2))
      * POWER(SIN(RADIANS(lon2 - lon1) / 2), 2))));
$$ LANGUAGE sql IMMUTABLE;

-- Node identity: coordinates rounded to 7 decimal places (about 1 cm).
-- Two segments meet if and only if their endpoints round to the same key.
CREATE OR REPLACE FUNCTION hush.node_key(lon double precision, lat double precision)
RETURNS TEXT AS $$
    SELECT ROUND(lon::numeric, 7)::text || ',' || ROUND(lat::numeric, 7)::text;
$$ LANGUAGE sql IMMUTABLE;


-- ============================================================================
-- PART 3 - Schema
--
-- A network is naturally nodes + edges, already in 3NF with no decomposition
-- needed. Worth contrasting in your report with the count datasets, which
-- required real normalisation work.
-- ============================================================================

DROP TABLE IF EXISTS sensor_landmark_walk;
DROP TABLE IF EXISTS sensor_node;
DROP TABLE IF EXISTS landmark_node;
DROP TABLE IF EXISTS walk_edge;
DROP TABLE IF EXISTS walk_node;

CREATE TABLE walk_node (
    node_id  BIGSERIAL PRIMARY KEY,
    node_key TEXT NOT NULL UNIQUE,
    lat      double precision NOT NULL,
    lon      double precision NOT NULL
);

CREATE TABLE walk_edge (
    edge_id   BIGINT PRIMARY KEY,            -- source OBJECTID, unique per line
    from_node BIGINT NOT NULL REFERENCES walk_node (node_id),
    to_node   BIGINT NOT NULL REFERENCES walk_node (node_id),
    length_m  NUMERIC(10,2) NOT NULL CHECK (length_m >= 0)
);
CREATE INDEX idx_walk_edge_from ON walk_edge (from_node);
CREATE INDEX idx_walk_edge_to   ON walk_edge (to_node);

COMMENT ON TABLE walk_edge IS
    'Pedestrian Network segments (CC BY 4.0, City of Melbourne). Geometry
     reduced to a graph: endpoints plus true along-path length.';


-- ============================================================================
-- PART 4 - Build the graph from the staged JSON
-- ============================================================================

-- 4.1  Every vertex of every LineString, in order.
CREATE TEMP TABLE _vertex AS
SELECT s.objectid::bigint                       AS edge_id,
       v.ord::int                               AS ord,
       (v.c ->> 0)::double precision            AS lon,
       (v.c ->> 1)::double precision            AS lat
FROM stg_network s
CROSS JOIN LATERAL jsonb_array_elements(s.geo_shape::jsonb -> 'coordinates')
           WITH ORDINALITY AS v(c, ord)
WHERE (s.geo_shape::jsonb ->> 'type') = 'LineString'
  AND s.objectid ~ '^\d+$';

CREATE INDEX ON _vertex (edge_id, ord);

-- 4.2  First and last vertex of each segment, plus its true along-path length.
--      array_agg with ORDER BY avoids DISTINCT ON inside a UNION, which
--      PostgreSQL rejects without extra parentheses.
CREATE TEMP TABLE _ends AS
SELECT v.edge_id,
       (array_agg(v.lon ORDER BY v.ord))[1]       AS lon1,
       (array_agg(v.lat ORDER BY v.ord))[1]       AS lat1,
       (array_agg(v.lon ORDER BY v.ord DESC))[1]  AS lon2,
       (array_agg(v.lat ORDER BY v.ord DESC))[1]  AS lat2
FROM _vertex v
GROUP BY v.edge_id;

CREATE INDEX ON _ends (edge_id);

-- True length: sum of great-circle hops between consecutive vertices, not the
-- straight line between endpoints -- segments bend.
CREATE TEMP TABLE _edge_len AS
SELECT edge_id,
       ROUND(SUM(hush.hav_m(prev_lat, prev_lon, lat, lon))::numeric, 2) AS length_m
FROM (
    SELECT edge_id, lat, lon,
           LAG(lat) OVER (PARTITION BY edge_id ORDER BY ord) AS prev_lat,
           LAG(lon) OVER (PARTITION BY edge_id ORDER BY ord) AS prev_lon
    FROM _vertex
) t
WHERE prev_lat IS NOT NULL
GROUP BY edge_id;

CREATE INDEX ON _edge_len (edge_id);

-- 4.3  Nodes = the distinct endpoints.
INSERT INTO walk_node (node_key, lat, lon)
SELECT DISTINCT ON (hush.node_key(e.lon, e.lat))
       hush.node_key(e.lon, e.lat), e.lat, e.lon
FROM (
    SELECT lon1 AS lon, lat1 AS lat FROM _ends
    UNION ALL
    SELECT lon2,        lat2        FROM _ends
) e
ORDER BY hush.node_key(e.lon, e.lat)
ON CONFLICT (node_key) DO NOTHING;

-- 4.4  Edges, joined to their endpoint nodes.
INSERT INTO walk_edge (edge_id, from_node, to_node, length_m)
SELECT e.edge_id, n1.node_id, n2.node_id, GREATEST(l.length_m, 0.01)
FROM _ends e
JOIN _edge_len l  ON l.edge_id  = e.edge_id
JOIN walk_node n1 ON n1.node_key = hush.node_key(e.lon1, e.lat1)
JOIN walk_node n2 ON n2.node_key = hush.node_key(e.lon2, e.lat2)
WHERE n1.node_id <> n2.node_id;      -- drop zero-length self-loops

ANALYZE walk_node;
ANALYZE walk_edge;


-- ============================================================================
-- PART 5 - Attach sensors and landmarks to their nearest node
--
-- Snapping to a node rather than a point on an edge is a deliberate
-- simplification: median segment length is 9.9 m, so the error it introduces
-- is a few metres -- far smaller than the error it removes.
-- ============================================================================

CREATE TABLE sensor_node (
    location_id INTEGER PRIMARY KEY REFERENCES sensor_location (location_id) ON DELETE CASCADE,
    node_id     BIGINT  NOT NULL REFERENCES walk_node (node_id),
    snap_m      NUMERIC(10,2) NOT NULL
);

INSERT INTO sensor_node (location_id, node_id, snap_m)
SELECT s.location_id, n.node_id, n.d
FROM sensor_location s
CROSS JOIN LATERAL (
    SELECT w.node_id,
           ROUND(hush.hav_m(s.latitude, s.longitude, w.lat, w.lon)::numeric, 2) AS d
    FROM walk_node w
    -- bounding-box prefilter: ~0.004 degrees is about 400 m. Keeps this fast
    -- without a spatial index.
    WHERE w.lat BETWEEN s.latitude  - 0.004 AND s.latitude  + 0.004
      AND w.lon BETWEEN s.longitude - 0.005 AND s.longitude + 0.005
    ORDER BY hush.hav_m(s.latitude, s.longitude, w.lat, w.lon)
    LIMIT 1
) n;

CREATE TABLE landmark_node (
    landmark_id INTEGER PRIMARY KEY REFERENCES landmark (landmark_id) ON DELETE CASCADE,
    node_id     BIGINT  NOT NULL REFERENCES walk_node (node_id),
    snap_m      NUMERIC(10,2) NOT NULL
);

INSERT INTO landmark_node (landmark_id, node_id, snap_m)
SELECT l.landmark_id, n.node_id, n.d
FROM landmark l
CROSS JOIN LATERAL (
    SELECT w.node_id,
           ROUND(hush.hav_m(l.latitude, l.longitude, w.lat, w.lon)::numeric, 2) AS d
    FROM walk_node w
    WHERE w.lat BETWEEN l.latitude  - 0.004 AND l.latitude  + 0.004
      AND w.lon BETWEEN l.longitude - 0.005 AND l.longitude + 0.005
    ORDER BY hush.hav_m(l.latitude, l.longitude, w.lat, w.lon)
    LIMIT 1
) n;


-- ============================================================================
-- PART 6 - Catchment: bounded Dijkstra in plain PL/pgSQL
--
-- Relaxes outward from a start node until the distance budget is spent.
-- This is what pgr_drivingDistance does; written out here so you don't need
-- the extension, and so you can explain it in the report.
-- ============================================================================

CREATE OR REPLACE FUNCTION hush.walk_catchment(p_start BIGINT, p_max_m NUMERIC)
RETURNS TABLE (node_id BIGINT, dist_m NUMERIC) AS $$
DECLARE
    n_changed BIGINT;
    guard     INT := 0;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS _reach (
        node_id BIGINT PRIMARY KEY,
        dist_m  NUMERIC NOT NULL
    ) ON COMMIT DROP;
    TRUNCATE _reach;
    INSERT INTO _reach VALUES (p_start, 0);

    LOOP
        guard := guard + 1;
        EXIT WHEN guard > 200;      -- safety net; real diameters are far smaller

        INSERT INTO _reach (node_id, dist_m)
        SELECT c.nid, MIN(c.d)
        FROM (
            SELECT CASE WHEN e.from_node = r.node_id THEN e.to_node
                                                     ELSE e.from_node END AS nid,
                   r.dist_m + e.length_m AS d
            FROM _reach r
            JOIN walk_edge e ON e.from_node = r.node_id OR e.to_node = r.node_id
            WHERE r.dist_m + e.length_m <= p_max_m
        ) c
        GROUP BY c.nid
        ON CONFLICT (node_id) DO UPDATE
            SET dist_m = EXCLUDED.dist_m
            WHERE _reach.dist_m > EXCLUDED.dist_m;

        GET DIAGNOSTICS n_changed = ROW_COUNT;
        EXIT WHEN n_changed = 0;
    END LOOP;

    RETURN QUERY SELECT r.node_id, r.dist_m FROM _reach r;
END;
$$ LANGUAGE plpgsql;


-- 6.1  Precompute walking distance from every sensor to every low-sensory
--      landmark within a 10-minute walk (800 m at 1.33 m/s).
--
--      Takes a few minutes for 134 sensors. Materialised once so the app
--      reads it instantly.
CREATE TABLE sensor_landmark_walk (
    location_id   INTEGER NOT NULL,
    landmark_id   INTEGER NOT NULL,
    walk_m        NUMERIC(10,2) NOT NULL,
    straight_m    NUMERIC(10,2) NOT NULL,
    detour_ratio  NUMERIC(6,2)  NOT NULL,
    walk_minutes  NUMERIC(5,1)  NOT NULL,
    CONSTRAINT slw_pk PRIMARY KEY (location_id, landmark_id)
);

DO $do$
DECLARE
    s   RECORD;
    n   INT := 0;
BEGIN
    FOR s IN SELECT sn.location_id, sn.node_id FROM sensor_node sn ORDER BY 1 LOOP
        INSERT INTO sensor_landmark_walk
            (location_id, landmark_id, walk_m, straight_m, detour_ratio, walk_minutes)
        SELECT s.location_id,
               ln.landmark_id,
               ROUND(c.dist_m + ln.snap_m, 2),
               ROUND(straight.d, 2),
               ROUND(((c.dist_m + ln.snap_m) / GREATEST(straight.d, 1))::numeric, 2),
               ROUND(((c.dist_m + ln.snap_m) / 80.0)::numeric, 1)   -- 80 m/min
        FROM hush.walk_catchment(s.node_id, 800) c
        JOIN landmark_node ln ON ln.node_id = c.node_id
        JOIN landmark l       ON l.landmark_id = ln.landmark_id
        JOIN landmark_category lc ON lc.category_id = l.category_id
        JOIN sensor_location sl   ON sl.location_id = s.location_id
        CROSS JOIN LATERAL (
            SELECT hush.hav_m(sl.latitude, sl.longitude, l.latitude, l.longitude) AS d
        ) straight
        WHERE lc.sensory_load = 'low'
        ON CONFLICT (location_id, landmark_id) DO NOTHING;

        n := n + 1;
        IF n % 25 = 0 THEN
            RAISE NOTICE 'catchment computed for % sensors', n;
        END IF;
    END LOOP;
    RAISE NOTICE 'done: % sensors', n;
END
$do$;

CREATE INDEX idx_slw_location ON sensor_landmark_walk (location_id, walk_m);

-- 6.2  The replacement for 08 Q6: quiet landmarks near a currently quiet
--      sensor, ranked by ACTUAL walking distance.
CREATE OR REPLACE VIEW v_quiet_nearby AS
SELECT d.display_name        AS near_sensor,
       d.density_level,
       l.feature_name,
       t.theme_name,
       c.sub_theme,
       w.walk_m,
       w.walk_minutes,
       w.straight_m,
       w.detour_ratio
FROM sensor_landmark_walk w
JOIN v_current_density  d ON d.location_id = w.location_id
JOIN landmark           l ON l.landmark_id = w.landmark_id
JOIN landmark_category  c ON c.category_id = l.category_id
JOIN theme              t ON t.theme_id    = c.theme_id
WHERE d.density_level = 'Low';


-- ============================================================================
-- PART 7 - Verify.  Run one at a time.
-- ============================================================================

-- 7.1  Graph built correctly? Expect ~62,096 nodes and ~71,060 edges.
SELECT 'walk_node' AS table_name, COUNT(*) AS row_count FROM walk_node
UNION ALL SELECT 'walk_edge',            COUNT(*) FROM walk_edge
UNION ALL SELECT 'sensor_node',          COUNT(*) FROM sensor_node
UNION ALL SELECT 'landmark_node',        COUNT(*) FROM landmark_node
UNION ALL SELECT 'sensor_landmark_walk', COUNT(*) FROM sensor_landmark_walk;

-- 7.2  Network scale. Expect about 1,234 km, median segment 9.9 m.
SELECT ROUND(SUM(length_m) / 1000, 1) AS network_km,
       COUNT(*)                       AS segments,
       ROUND(AVG(length_m), 1)        AS avg_segment_m,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY length_m)::numeric, 1)
                                      AS median_segment_m
FROM walk_edge;

-- 7.3  Snap quality. Should be single-digit metres.
SELECT 'sensors'   AS what, COUNT(*) AS mapped,
       ROUND(AVG(snap_m), 1) AS avg_snap_m, MAX(snap_m) AS worst_snap_m
FROM sensor_node
UNION ALL
SELECT 'landmarks', COUNT(*), ROUND(AVG(snap_m), 1), MAX(snap_m)
FROM landmark_node;

-- 7.4  *** THE HEADLINE RESULT FOR YOUR REPORT ***
--      How wrong was straight-line distance? detour_ratio 1.0 means the walk
--      matches the crow flies; 2.0 means it is twice as far on foot.
SELECT ROUND(AVG(detour_ratio), 2)                     AS avg_detour_ratio,
       ROUND(MAX(detour_ratio), 2)                     AS worst_detour_ratio,
       COUNT(*) FILTER (WHERE detour_ratio > 1.5)      AS pairs_over_50pct_wrong,
       COUNT(*)                                        AS total_pairs
FROM sensor_landmark_walk;

-- 7.5  The worst offenders -- straight line says close, the walk says far.
--      These are the recommendations the old query would have got wrong.
SELECT s.display_name AS sensor, l.feature_name AS landmark,
       w.straight_m, w.walk_m, w.detour_ratio, w.walk_minutes
FROM sensor_landmark_walk w
JOIN v_sensor s ON s.location_id = w.location_id
JOIN landmark l ON l.landmark_id = w.landmark_id
ORDER BY w.detour_ratio DESC
LIMIT 20;

-- 7.6  What the app would actually show right now.
SELECT * FROM v_quiet_nearby
ORDER BY near_sensor, walk_m
LIMIT 40;
