-- ============================================================================
-- 13_sensor_network_features.sql
-- Per-sensor STATIC features derived from the pedestrian network, for the
-- forecasting model.
--
-- READ THIS FIRST -- IT MATTERS
--   The catchment tables (sensor_landmark_walk, v_quiet_nearby) are NOT
--   training data. They power the app's recommendation feature. Feeding
--   "walking distance to the nearest church" into a pedestrian-count
--   forecaster would add noise, not signal.
--
--   What the network genuinely contributes to the MODEL is a measure of how
--   central and well-connected each sensor's location is. Street-network
--   density is a long-established predictor of pedestrian volume: a sensor
--   sitting on a dense grid of intersections sees far more foot traffic than
--   one on an isolated path, and that difference is stable over time.
--
--   These are static per-sensor attributes. Your ML team joins them to the
--   1.5M-row training set on location_id -- 134 rows, not another 40MB file.
--
-- Run AFTER 12_pedestrian_network.sql.
-- Takes 2-5 minutes (one bounded Dijkstra per sensor).
-- ============================================================================

SET search_path TO hush, public;
SET work_mem = '512MB';

DROP TABLE IF EXISTS sensor_network_feature CASCADE;

CREATE TABLE sensor_network_feature (
    location_id            INTEGER PRIMARY KEY
                           REFERENCES sensor_location (location_id) ON DELETE CASCADE,
    -- how well the sensor sits on the network
    snap_m                 NUMERIC(10,2) NOT NULL,
    node_degree            INTEGER       NOT NULL,
    -- CENTRALITY: how much walkable network is reachable on foot.
    -- The strongest network-derived predictor of foot traffic.
    nodes_within_400m      INTEGER       NOT NULL,
    walkable_m_within_400m NUMERIC(12,2) NOT NULL,
    -- destination richness within a 10-minute walk
    low_sensory_within_800m INTEGER      NOT NULL,
    nearest_low_sensory_m  NUMERIC(10,2),
    -- context already in your schema, repeated here so the join is one table
    is_cbd                 BOOLEAN       NOT NULL
);

COMMENT ON TABLE sensor_network_feature IS
    'Static per-sensor features from the City of Melbourne Pedestrian Network
     (CC BY 4.0). Join to training data on location_id. These do not change
     over time -- recompute only when the network or sensor list changes.';

-- ---------------------------------------------------------------------------
-- Build. One 400 m catchment per sensor.
-- ---------------------------------------------------------------------------
DO $do$
DECLARE
    s RECORD;
    n INT := 0;
BEGIN
    FOR s IN SELECT sn.location_id, sn.node_id, sn.snap_m
             FROM sensor_node sn ORDER BY sn.location_id LOOP

        WITH cat AS MATERIALIZED (
            SELECT c.node_id FROM hush.walk_catchment(s.node_id, 400) c
        )
        INSERT INTO sensor_network_feature (
            location_id, snap_m, node_degree,
            nodes_within_400m, walkable_m_within_400m,
            low_sensory_within_800m, nearest_low_sensory_m, is_cbd)
        SELECT
            s.location_id,
            s.snap_m,
            -- degree of the sensor's own node: 1 = dead end, 4+ = intersection
            (SELECT COUNT(*) FROM walk_edge e
              WHERE e.from_node = s.node_id OR e.to_node = s.node_id),
            (SELECT COUNT(*) FROM cat),
            (SELECT COALESCE(ROUND(SUM(e.length_m), 2), 0) FROM walk_edge e
              WHERE e.from_node IN (SELECT node_id FROM cat)
                AND e.to_node   IN (SELECT node_id FROM cat)),
            (SELECT COUNT(*) FROM sensor_landmark_walk w
              WHERE w.location_id = s.location_id),
            (SELECT MIN(w.walk_m) FROM sensor_landmark_walk w
              WHERE w.location_id = s.location_id),
            (SELECT sl.is_cbd FROM sensor_location sl
              WHERE sl.location_id = s.location_id)
        ON CONFLICT (location_id) DO NOTHING;

        n := n + 1;
        IF n % 25 = 0 THEN
            RAISE NOTICE 'network features computed for % sensors', n;
        END IF;
    END LOOP;
    RAISE NOTICE 'done: % sensors', n;
END
$do$;


-- ---------------------------------------------------------------------------
-- The shareable view. Export this for your ML team -- 134 rows.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_sensor_network_features AS
SELECT f.location_id,
       s.display_name,
       f.is_cbd,
       f.node_degree,
       f.nodes_within_400m,
       f.walkable_m_within_400m,
       ROUND(f.walkable_m_within_400m / 1000, 2) AS walkable_km_within_400m,
       f.low_sensory_within_800m,
       f.nearest_low_sensory_m,
       f.snap_m,
       -- data-quality flag: FALSE means the sensor sits awkwardly on the
       -- network and its centrality figures are less trustworthy
       (f.snap_m <= 25) AS network_snap_reliable
FROM sensor_network_feature f
JOIN v_sensor s ON s.location_id = f.location_id;


-- ============================================================================
-- Verify
-- ============================================================================

-- 1. Coverage. Expect 134.
SELECT COUNT(*) AS sensors_with_features FROM sensor_network_feature;

-- 2. Distribution. walkable_m_within_400m is the feature that should matter:
--    a wide spread means it can discriminate between locations.
SELECT ROUND(MIN(walkable_m_within_400m))                        AS min_walkable_m,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
             (ORDER BY walkable_m_within_400m)::numeric)         AS median_walkable_m,
       ROUND(MAX(walkable_m_within_400m))                        AS max_walkable_m,
       ROUND(AVG(node_degree), 2)                                AS avg_node_degree,
       COUNT(*) FILTER (WHERE node_degree = 1)                   AS sensors_on_dead_ends
FROM sensor_network_feature;

-- 3. *** DOES IT ACTUALLY PREDICT ANYTHING? Run this before handing it over. ***
--    Correlation between network centrality and mean hourly pedestrian count.
--    Above ~0.4 means the feature is worth including. Near 0 means it isn't,
--    and you should say so rather than shipping a useless column.
SELECT ROUND(CORR(f.walkable_m_within_400m, h.avg_count)::numeric, 3)
           AS corr_walkable_vs_count,
       ROUND(CORR(f.nodes_within_400m,      h.avg_count)::numeric, 3)
           AS corr_nodes_vs_count,
       ROUND(CORR(f.node_degree,            h.avg_count)::numeric, 3)
           AS corr_degree_vs_count,
       COUNT(*) AS sensors_compared
FROM sensor_network_feature f
JOIN (
    SELECT location_id, AVG(total_of_direction) AS avg_count
    FROM pedestrian_hour_count
    GROUP BY location_id
) h ON h.location_id = f.location_id;

-- 4. The export itself.
SELECT * FROM v_sensor_network_features ORDER BY location_id;
