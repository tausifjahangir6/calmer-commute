"""
route_scoring.py

DEV-US1.1-01 -- Crowd-based route scoring (High/Low/Unknown indicator)

Transforms supported pedestrian observations into reproducible route-level
High, Low, or Unknown crowd indicators. Segment mapping is built on OSMnx
(no dependency on Peter/Tausif's C3 PostGIS work -- see module note below).
Threshold basis reuses the live get_alert_thresholds() interface from
alert_thresholds.py (US1.3 placeholder), for consistency with AI-US2.2-01.

SCOPE GUARDRAIL: pedestrian density is the only sensory-risk proxy. Noise,
construction, events are out of scope. Outputs are guidance, not a safety
guarantee.

WHY OSMNX INSTEAD OF WAITING ON C3:
Real multi-block route segments and segment-to-sensor mapping do not exist
yet in the team's PostGIS schema. Rather than block on that, this module
builds segments directly from OpenStreetMap's walking network via OSMnx,
and snaps each sensor to its nearest OSM edge itself. This replaces both
"Route segments" and "Segment-to-sensor mapping" dependencies entirely --
no external team data required. sensor_network_features.csv (Council-
sourced) was investigated as a possible reuse of this snapping work, but
was built on a different network graph (Melbourne City Council's own
dataset, not OSMnx) with incompatible node/edge IDs, so it is NOT reused
for segment identity here. Its low_sensory_within_800m / nearest_low_sensory_m
columns remain independently useful (location-level refuge-proximity
features, not tied to a specific routing graph) and may be reintroduced as
a feature later -- out of scope for this card.

DATA INTEGRITY / REFUSAL PATTERN:
Mirrors baseline_model.py's established pattern: when there is insufficient
support for a classification, return an explicit Unknown result with a
reason, rather than guessing. This is deliberately conservative in BOTH
directions at the segment level, and specifically biased against false Low
at the route level (see aggregate_route).

SCORING VERSION: bump SCORING_VERSION whenever classification logic,
threshold basis, freshness window, or aggregation rule changes, per the
"Consistency" and "Traceability" acceptance criteria.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

import pandas as pd

from alert_thresholds import get_alert_thresholds


# ---------------------------------------------------------------------------
# Versioned constants -- change these deliberately, bump SCORING_VERSION
# whenever you do (Traceability / Consistency acceptance criteria).
# ---------------------------------------------------------------------------

SCORING_VERSION = "DEV-US1.1-01-v1.0"

# Freshness window: an observation must be within this many hours of the
# reference time to count as "current". Decided: 4h (midpoint of the
# 3-6h range discussed).
FRESHNESS_HOURS = 4.0

# A sensor snap to the OSM graph is only trusted if within this distance.
# ASSUMPTION, not yet confirmed with the team -- flagged for review.
# Mirrors the same concept as sensor_network_features.csv's
# network_snap_reliable column, but computed against the OSMnx graph here.
MAX_RELIABLE_SNAP_M = 50.0

# Catchment radius for block-level sensor matching (see snap_sensors_to_blocks
# below). Also a documented ASSUMPTION, not team-confirmed. Chosen
# separately from MAX_RELIABLE_SNAP_M because it solves a different
# problem: MAX_RELIABLE_SNAP_M gates whether a single nearest-edge match is
# trustworthy; DEFAULT_CATCHMENT_RADIUS_M controls how far a sensor's
# influence extends when matching to a merged street block, to counter the
# real sparsity problem (100 real sensors vs ~13,000 raw graph edges in the
# Melbourne CBD walk network -- confirmed via a live run: at raw-edge
# granularity, 31/32 segments on a real demo route had no sensor at all).
DEFAULT_CATCHMENT_RADIUS_M = 100.0

# Route aggregation rule: worst-segment-wins. High beats everything else
# regardless of coverage -- a single confirmed High segment is a directly
# measured fact, not something we're extrapolating, so it's reported at
# full confidence no matter how much of the rest of the route is unknown.
#
# For the Low case, this used to be strict: ANY unresolved segment made
# the whole route Unknown. Real data proved that rule unusable: run
# against 50 real random Melbourne CBD routes, it produced Unknown for
# 0/50 of them (see random_coverage_distribution.py). The rule below
# replaces that all-or-nothing cutoff with a floor + confidence tiers,
# so a route can be reported Low with an honest, visible confidence level
# rather than either a blind Low or a useless Unknown:
#
#   - coverage < MIN_COVERAGE_FOR_LOW_PCT (10%): still Unknown -- this
#     isn't a judgment call, it's the "we have essentially nothing to go
#     on" floor. Confirmed against real data: 5/50 real random routes
#     came back at LITERALLY 0% coverage (not "a little", zero), a real
#     recurring case, not a rare edge case -- a confidence score would be
#     meaningless with nothing behind it.
#   - coverage >= 10%: Low, tagged with a confidence tier (see
#     CONFIDENCE_TIERS below) rather than a hidden, silent Low.
AGGREGATION_RULE = "worst_segment_wins"

# Minimum route-level coverage below which the route stays Unknown,
# regardless of confidence tiering. Data-derived (see comment above) --
# not an arbitrary round number.
MIN_COVERAGE_FOR_LOW_PCT = 10.0

# Confidence tiers for a Low classification. Boundaries were chosen
# against the same real 50-route sample: the floor (10%) removes the
# zero-coverage cluster, and these three ranges split the remaining
# continuous distribution into roughly even real-world buckets (16, 17,
# and 12 routes out of 50 respectively) -- not guessed round numbers.
# Ranges are left-inclusive, right-exclusive except the top tier, which
# includes 100%.
CONFIDENCE_TIERS: list[tuple[float, float, str]] = [
    (10.0, 40.0, "low"),
    (40.0, 70.0, "medium"),
    (70.0, 100.0001, "high"),  # upper bound nudged past 100 so exact 100% lands in "high"
]


def get_confidence_tier(coverage_pct: float) -> Optional[str]:
    """
    Maps a route's segment coverage percentage to a confidence tier.
    Returns None if coverage_pct is below MIN_COVERAGE_FOR_LOW_PCT --
    callers should already be resolving those cases to Unknown before
    this is relevant.
    """
    for lo, hi, label in CONFIDENCE_TIERS:
        if lo <= coverage_pct < hi:
            return label
    return None


# ---------------------------------------------------------------------------
# Result shapes -- mirrors the explanation-object pattern from rf_explain.py
# (timestamp, reason, confidence/coverage, limitation flags) for consistency
# across the app's UI.
# ---------------------------------------------------------------------------

@dataclass
class SegmentClassification:
    segment_id: str
    sensor_id: Optional[int]
    label: str  # "High" | "Low" | "Unknown"
    reason: str
    observed_count: Optional[float]
    threshold: Optional[float]
    observation_ts: Optional[datetime]
    coverage: str  # e.g. "matched", "no_sensor", "unreliable_snap", "stale", "no_threshold"
    snap_m: Optional[float]
    scoring_version: str = SCORING_VERSION


@dataclass
class RouteClassification:
    route_id: str
    label: str  # "High" | "Low" | "Unknown"
    reason: str
    aggregation_rule: str
    coverage: str  # e.g. "3/4 segments resolved"
    segment_scores: list[SegmentClassification] = field(default_factory=list)
    confidence: Optional[str] = None  # "low" | "medium" | "high" -- only set for Low; High is always full-confidence, Unknown has none
    coverage_pct: Optional[float] = None  # raw number backing the tier -- kept for backend/debugging use even though the tier is what's shown
    scoring_version: str = SCORING_VERSION


# ---------------------------------------------------------------------------
# Segment mapping (OSMnx) -- replaces "Route segments" and
# "Segment-to-sensor mapping" dependencies.

# ---------------------------------------------------------------------------

def build_walk_graph(place: str = "Melbourne CBD, Victoria, Australia"):
    """
    Fetch the real walking-street graph for the given place from OSM.
    Requires network access to the Overpass API -- not available in every
    environment (e.g. sandboxed CI). Callers that need a deterministic,
    offline-testable graph should build a small synthetic networkx graph
    instead (see ai/tests/test_route_scoring.py for the pattern used here).

    This always hits the live API -- for repeated local runs across
    multiple scripts, use get_walk_graph_cached() instead, which wraps
    this with a disk cache so you only pay the 10-30s fetch cost once.
    """
    import osmnx as ox
    return ox.graph_from_place(place, network_type="walk")


# Default cache location: shared by every script that imports
# route_scoring, regardless of which directory the script itself runs
# from, since it's resolved relative to this file rather than the
# current working directory.
_CACHE_DIR = Path(__file__).resolve().parent / ".osm_cache"
DEFAULT_GRAPH_CACHE_PATH = _CACHE_DIR / "melbourne_cbd_walk.graphml"


def get_walk_graph_cached(
    place: str = "Melbourne CBD, Victoria, Australia",
    cache_path=DEFAULT_GRAPH_CACHE_PATH,
    force_refresh: bool = False,
):
    """
    Same graph as build_walk_graph(), but cached to disk as GraphML so
    repeated runs (across this script or any other that imports
    route_scoring) don't re-pay the 10-30s OSM fetch every time. First
    call fetches and saves; every call after that just loads from disk,
    near-instant.

    IMPORTANT CAVEAT: a cached graph is a SNAPSHOT of OSM at fetch time --
    OpenStreetMap itself keeps getting edited, so a stale cache won't
    reflect real-world changes (new paths, closures, renamed streets).
    This is arguably a feature for the Consistency acceptance criterion
    (identical inputs -> identical outputs, which a live-changing graph
    can't strictly guarantee), but it means the cache should be
    deliberately refreshed periodically -- pass force_refresh=True, or
    just delete the cache file -- not left stale indefinitely without
    anyone noticing, especially before anything that must reflect the
    current real street network (e.g. final deployment).
    """
    import osmnx as ox

    cache_path = Path(cache_path)
    if cache_path.exists() and not force_refresh:
        return ox.load_graphml(cache_path)

    graph = build_walk_graph(place)
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    ox.save_graphml(graph, cache_path)
    return graph


def snap_sensors_to_graph(
    graph,
    sensors_df: pd.DataFrame,
    lat_col: str = "latitude",
    lon_col: str = "longitude",
    id_col: str = "sensor_id",
    max_reliable_snap_m: float = MAX_RELIABLE_SNAP_M,
) -> pd.DataFrame:
    """
    Snap each sensor to its nearest OSM edge (= segment). Uses edges, not
    nodes, so a "segment" corresponds to an actual street block, matching
    the shape the crowd-scoring / routing step expects
    ({(u, v, key): score}) -- not a point placeholder.

    IMPORTANT: graph (from build_walk_graph) is unprojected lat/lon
    (EPSG:4326). OSMnx's nearest_edges returns distance in the SAME UNITS
    as the graph/points -- i.e. degrees, not metres, if you pass the
    unprojected graph directly. Comparing a degree-valued distance against
    a metre-valued threshold (MAX_RELIABLE_SNAP_M) would silently always
    pass, since degree values are always tiny numbers regardless of true
    distance. To get real metres, this function internally projects a
    copy of the graph (ox.project_graph) and reprojects the query points
    to match before calling nearest_edges. Node/edge IDs are unchanged by
    projection, so segment_id ("u_v_key") stays consistent with the
    unprojected graph used elsewhere (e.g. build_route_segments).

    Returns one row per sensor: sensor_id, segment_id, snap_m (real
    metres), snap_reliable.
    """
    import osmnx as ox
    from pyproj import Transformer

    graph_proj = ox.project_graph(graph)
    transformer = Transformer.from_crs(
        "EPSG:4326", graph_proj.graph["crs"], always_xy=True
    )

    rows = []
    for _, row in sensors_df.iterrows():
        x_proj, y_proj = transformer.transform(row[lon_col], row[lat_col])
        (u, v, key), dist_m = ox.nearest_edges(
            graph_proj, X=x_proj, Y=y_proj, return_dist=True
        )
        rows.append(
            {
                "sensor_id": row[id_col],
                "segment_id": f"{u}_{v}_{key}",
                "snap_m": float(dist_m),
                "snap_reliable": bool(dist_m <= max_reliable_snap_m),
            }
        )
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Route building -- turns an origin/destination pair into an ordered segment
# list, ready to hand to score_route(). This is what was missing before:
# classify_segment/aggregate_route can score a route, but nothing built
# the route itself. Uses OSMnx's own shortest-path routing (distance-
# weighted), NOT crowd-aware -- crowd-aware rerouting is DEV-US1.2-01's job,
# not this card's. This card answers "how crowded is this route", not
# "find me a route that avoids crowds".
# ---------------------------------------------------------------------------

def build_route_segments(graph, orig_lat: float, orig_lon: float, dest_lat: float, dest_lon: float):
    """
    Returns (node_path, segments) for the shortest walking path between two
    points on the graph. segments is a list of {"segment_id", "u", "v",
    "key"} dicts in travel order, ready to join with sensor mapping.
    """
    import osmnx as ox

    orig_node = ox.nearest_nodes(graph, X=orig_lon, Y=orig_lat)
    dest_node = ox.nearest_nodes(graph, X=dest_lon, Y=dest_lat)
    node_path = ox.shortest_path(graph, orig_node, dest_node, weight="length")

    if node_path is None:
        return None, []

    segments = []
    for u, v in zip(node_path[:-1], node_path[1:]):
        edge_data = graph.get_edge_data(u, v)
        key = min(edge_data, key=lambda k: edge_data[k].get("length", 0))
        segments.append({"segment_id": f"{u}_{v}_{key}", "u": u, "v": v, "key": key})
    return node_path, segments


def join_sensor_mapping(route_segments: list[dict], sensor_mapping_df: pd.DataFrame) -> list[dict]:
    """
    Attach sensor_id/snap_reliable/snap_m onto each route segment from
    snap_sensors_to_graph()'s output. Segments with no matching sensor get
    sensor_id=None (resolves to Unknown downstream, per Data Integrity --
    this is expected and correct, not an error).

    NOTE: sensor_mapping_df is one row per SENSOR, not per segment -- with
    a dense real sensor network, more than one sensor can legitimately
    snap to the same nearest edge (observed with the real 100-sensor set).
    When that happens, this keeps only the closest sensor (smallest
    snap_m) as that segment's representative, rather than crashing on a
    non-unique index. This is a real, documented decision, not an
    afterthought: a segment gets scored by its single nearest sensor, not
    an average of several.
    """
    deduped = sensor_mapping_df.sort_values("snap_m").drop_duplicates(
        subset="segment_id", keep="first"
    )
    lookup = deduped.set_index("segment_id").to_dict(orient="index")
    joined = []
    for seg in route_segments:
        match = lookup.get(seg["segment_id"])
        joined.append(
            {
                "segment_id": seg["segment_id"],
                "sensor_id": match["sensor_id"] if match else None,
                "snap_reliable": match["snap_reliable"] if match else None,
                "snap_m": match["snap_m"] if match else None,
            }
        )
    return joined


def validate_pedestrian_columns(
    pedestrian_df: pd.DataFrame,
    sensor_col: str = "sensor_id",
    ts_col: str = "timestamp",
    value_col: str = "count",
) -> None:
    """
    Fail fast, fail clear. Two of your project docs disagreed on whether
    load_validated_data.py renames columns (location_id->sensor_id,
    target_count->count) or leaves them as-is -- rather than let a
    mismatch surface as a cryptic KeyError deep in get_latest_observation,
    check up front and say exactly what's wrong.

    Call this once, right after loading your real dataframe, before
    passing it into score_route().
    """
    required = {sensor_col, ts_col, value_col}
    missing = required - set(pedestrian_df.columns)
    if missing:
        raise ValueError(
            f"pedestrian_df is missing expected column(s): {sorted(missing)}. "
            f"Columns actually present: {list(pedestrian_df.columns)}. "
            f"If your loader renames columns (e.g. location_id->sensor_id, "
            f"target_count->count), pass the renamed names explicitly via "
            f"sensor_col=/ts_col=/value_col= on classify_segment / "
            f"get_latest_observation / score_route."
        )
    if not pd.api.types.is_datetime64_any_dtype(pedestrian_df[ts_col]):
        raise ValueError(
            f"'{ts_col}' is not a datetime column (dtype: "
            f"{pedestrian_df[ts_col].dtype}). Freshness comparisons will "
            f"silently misbehave on strings -- convert with "
            f"pd.to_datetime() before scoring."
        )


def find_peak_reference_time(
    pedestrian_df: pd.DataFrame,
    base_thresholds: dict[int, float],
    sensor_col: str = "sensor_id",
    ts_col: str = "timestamp",
    value_col: str = "count",
) -> Optional[datetime]:
    """
    Finds the timestamp with the most sensors simultaneously reading at or
    above their own base threshold -- i.e. the busiest real moment in the
    dataset. Useful for testing the High-classification path against a
    genuinely busy real moment, rather than defaulting to the dataset's
    most recent timestamp (which, depending on when data collection last
    ran, can land overnight and never actually exercise the High path at
    all -- exactly what happened across every live run so far in this
    project). Returns None if no sensor ever met its own threshold.
    """
    if pedestrian_df.empty:
        return None
    df = pedestrian_df[[sensor_col, ts_col, value_col]].copy()
    df["_threshold"] = df[sensor_col].map(base_thresholds)
    over = df[df["_threshold"].notna() & (df[value_col] >= df["_threshold"])]
    if over.empty:
        return None
    counts_per_ts = over.groupby(ts_col).size()
    return counts_per_ts.idxmax()


def suggest_reliable_snap_threshold(
    sensor_mapping_df: pd.DataFrame, percentile: float = 90.0
) -> float:
    """
    Data-derived alternative to guessing MAX_RELIABLE_SNAP_M outright.
    Run this on your real snap_sensors_to_graph() output once you have
    the real graph, and use the result (or something close to it,
    rounded) as MAX_RELIABLE_SNAP_M -- then confirm with the team rather
    than shipping either number unchecked.

    e.g. suggest_reliable_snap_threshold(sensor_mapping) might return 42.0,
    meaning 90% of your real sensors snap within 42m -- a defensible,
    data-backed default rather than an arbitrary round number.
    """
    return float(sensor_mapping_df["snap_m"].quantile(percentile / 100.0))


# ---------------------------------------------------------------------------
# Block merging + catchment matching -- addresses the real sparsity problem
# confirmed on a live run: raw graph edges (~13,000 in the CBD walk graph)
# vastly outnumber real sensors (~100), so nearest-edge-only matching left
# 31/32 segments on a real demo route with no sensor at all, making almost
# every route resolve to Unknown regardless of actual crowding.
# ---------------------------------------------------------------------------

def merge_segments_by_street_name(graph, route_segments: list[dict]) -> list[dict]:
    """
    Groups consecutive route segments (from build_route_segments) that
    share the same OSM street name into a single block-level segment.
    Gives each segment a bigger geographic footprint, so it has a better
    chance of containing (or being near) one of the sparse real sensors.

    Unnamed edges (no OSM 'name' tag) are NOT merged with neighbours --
    without a shared name there's no reliable signal they're the same
    logical block, so each stays its own singleton block rather than being
    guessed into a bigger one.

    Returns a list of block dicts: segment_id (block-level), street_name,
    edge_keys (list of (u, v, key) tuples -- the raw edges making up this
    block), constituent_segment_ids (the original raw segment_ids, kept
    for traceability).
    """
    def _edge_name(u, v, key):
        data = graph.get_edge_data(u, v, key) or {}
        name = data.get("name")
        if isinstance(name, list):
            name = name[0] if name else None
        return name

    blocks: list[dict] = []
    current_edges: list[dict] = []
    current_name = None
    current_name_is_real = False

    def _flush():
        if not current_edges:
            return
        first, last = current_edges[0], current_edges[-1]
        block_id = f"BLOCK_{first['u']}_{last['v']}"
        blocks.append(
            {
                "segment_id": block_id,
                "street_name": current_name,
                "edge_keys": [(e["u"], e["v"], e["key"]) for e in current_edges],
                "constituent_segment_ids": [e["segment_id"] for e in current_edges],
            }
        )

    for seg in route_segments:
        name = _edge_name(seg["u"], seg["v"], seg["key"])
        is_real_name = name is not None
        if current_edges and is_real_name and current_name_is_real and name == current_name:
            current_edges.append(seg)
        else:
            _flush()
            current_edges = [seg]
            current_name = name
            current_name_is_real = is_real_name
    _flush()

    return blocks


def _block_geometry_from_projected_graph(graph_proj, edge_keys: list[tuple]):
    """
    Pure geometry helper -- no CRS/projection logic here, graph_proj must
    already be in a metric CRS (or, for tests, a synthetic planar graph
    with plain float x/y node attributes). Builds one combined line
    geometry spanning all of a block's constituent edges.
    """
    from shapely.geometry import LineString
    from shapely.ops import linemerge

    lines = []
    for (u, v, key) in edge_keys:
        edge_data = graph_proj.get_edge_data(u, v, key) or {}
        geom = edge_data.get("geometry")
        if geom is None:
            u_x, u_y = graph_proj.nodes[u]["x"], graph_proj.nodes[u]["y"]
            v_x, v_y = graph_proj.nodes[v]["x"], graph_proj.nodes[v]["y"]
            geom = LineString([(u_x, u_y), (v_x, v_y)])
        lines.append(geom)

    if len(lines) == 1:
        return lines[0]
    return linemerge(lines)


def match_blocks_to_projected_sensors(
    graph_proj,
    blocks: list[dict],
    sensor_points: list[dict],
    catchment_radius_m: float = DEFAULT_CATCHMENT_RADIUS_M,
) -> pd.DataFrame:
    """
    Pure-geometry catchment matching. graph_proj and sensor_points must
    already be in the SAME projected (metric) CRS -- this function does no
    projection itself, which is deliberate: it lets the matching logic be
    unit-tested on a small synthetic planar graph, with no OSM network
    access or OSMnx CRS machinery required. The real-world entry point
    (snap_sensors_to_blocks, below) handles projection and delegates here.

    sensor_points: list of {"sensor_id": ..., "x": ..., "y": ...}
    blocks: output of merge_segments_by_street_name

    For each block, finds the closest sensor to the block's combined
    geometry (not just a single nearest-edge point). If that closest
    sensor is within catchment_radius_m, it's a match (snap_reliable=True).
    Otherwise the block gets sensor_id=None (resolves to Unknown
    downstream via classify_segment's "no_sensor" path -- consistent with
    the existing Data Integrity refusal pattern).

    Returns one row per block: sensor_id, segment_id, snap_m, snap_reliable.
    """
    from shapely.geometry import Point

    rows = []
    for block in blocks:
        geom = _block_geometry_from_projected_graph(graph_proj, block["edge_keys"])
        best_sensor_id = None
        best_dist = None
        for sp in sensor_points:
            dist = Point(sp["x"], sp["y"]).distance(geom)
            if best_dist is None or dist < best_dist:
                best_dist = dist
                best_sensor_id = sp["sensor_id"]

        if best_sensor_id is not None and best_dist <= catchment_radius_m:
            rows.append(
                {
                    "sensor_id": best_sensor_id,
                    "segment_id": block["segment_id"],
                    "snap_m": float(best_dist),
                    "snap_reliable": True,
                }
            )
        else:
            rows.append(
                {
                    "sensor_id": None,
                    "segment_id": block["segment_id"],
                    "snap_m": float(best_dist) if best_dist is not None else None,
                    "snap_reliable": False,
                }
            )
    return pd.DataFrame(rows)


def snap_sensors_to_blocks(
    graph,
    blocks: list[dict],
    sensors_df: pd.DataFrame,
    lat_col: str = "latitude",
    lon_col: str = "longitude",
    id_col: str = "sensor_id",
    catchment_radius_m: float = DEFAULT_CATCHMENT_RADIUS_M,
) -> pd.DataFrame:
    """
    Real-world entry point: projects graph + sensor coordinates into a
    metric CRS (same approach as snap_sensors_to_graph -- see that
    function's docstring for why this matters), then delegates to
    match_blocks_to_projected_sensors for the actual geometry matching.
    """
    import osmnx as ox
    from pyproj import Transformer

    graph_proj = ox.project_graph(graph)
    transformer = Transformer.from_crs(
        "EPSG:4326", graph_proj.graph["crs"], always_xy=True
    )

    sensor_points = []
    for _, row in sensors_df.iterrows():
        x_proj, y_proj = transformer.transform(row[lon_col], row[lat_col])
        sensor_points.append({"sensor_id": row[id_col], "x": x_proj, "y": y_proj})

    return match_blocks_to_projected_sensors(
        graph_proj, blocks, sensor_points, catchment_radius_m
    )


# ---------------------------------------------------------------------------
# Freshness / observation lookup
# ---------------------------------------------------------------------------

def get_latest_observation(
    pedestrian_df: pd.DataFrame,
    sensor_id: int,
    reference_time: datetime,
    freshness_hours: float = FRESHNESS_HOURS,
    sensor_col: str = "sensor_id",
    ts_col: str = "timestamp",
    value_col: str = "count",
) -> Optional[tuple[float, datetime]]:
    """
    Return (count, obs_ts) for the most recent observation at sensor_id
    that falls within freshness_hours of reference_time, or None if no
    such observation exists (missing or stale -- both resolve to Unknown
    upstream, per Data Integrity).

    Only considers observations AT OR BEFORE reference_time. This matters:
    every prior real run in this project used
    reference_time=pedestrian_df["timestamp"].max(), so nothing in the
    dataframe was ever "in the future" relative to reference_time -- an
    assumption that quietly held by coincidence, not by design. It broke
    the first time reference_time was set earlier than the dataset's true
    latest row (e.g. simulating "what would this have said at some
    earlier hour" while still holding the full dataset) -- without this
    filter, this function would grab the sensor's single latest row
    REGARDLESS of reference_time, compute a negative "age", and wrongly
    report Unknown even when a perfectly fresh observation existed right
    at reference_time.

    reference_time is an explicit parameter, never datetime.now(), so that
    identical inputs always produce identical classifications (Consistency
    acceptance criterion).
    """
    if sensor_col not in pedestrian_df.columns or pedestrian_df.empty:
        return None

    sub = pedestrian_df.loc[
        (pedestrian_df[sensor_col] == sensor_id) & (pedestrian_df[ts_col] <= reference_time)
    ]
    if sub.empty:
        return None

    sub = sub.sort_values(ts_col)
    latest_ts = sub[ts_col].iloc[-1]
    latest_count = sub[value_col].iloc[-1]

    age = reference_time - latest_ts
    if age < timedelta(0) or age > timedelta(hours=freshness_hours):
        return None

    return float(latest_count), latest_ts


# ---------------------------------------------------------------------------
# Segment classification
# ---------------------------------------------------------------------------

def classify_segment(
    segment_id: str,
    sensor_id: Optional[int],
    snap_reliable: Optional[bool],
    snap_m: Optional[float],
    pedestrian_df: pd.DataFrame,
    base_thresholds: dict[int, float],
    reference_time: datetime,
    user_context: Optional[dict] = None,
    freshness_hours: float = FRESHNESS_HOURS,
    snap_threshold_m: Optional[float] = None,
) -> SegmentClassification:
    """
    Classify a single segment as High / Low / Unknown.

    snap_threshold_m: the ACTUAL distance threshold that produced
    snap_reliable, so the "unreliable_snap" reason text is accurate. Two
    different pipelines can set snap_reliable, with two different
    thresholds -- nearest-edge-only matching (snap_sensors_to_graph, gated
    by MAX_RELIABLE_SNAP_M, default 50m) and block-level catchment
    matching (snap_sensors_to_blocks, gated by whatever catchment_radius_m
    was passed, default DEFAULT_CATCHMENT_RADIUS_M=100m). Passing the
    wrong number here would make the classification correct but the
    stated reason false -- a real bug caught on a live run, where the
    reason claimed "exceeds reliable threshold (50m)" while the pipeline
    had actually applied a 100m catchment radius. If not supplied, falls
    back to MAX_RELIABLE_SNAP_M for backwards compatibility with the
    nearest-edge-only pipeline.

    Refusal pattern (mirrors baseline_model.py): any missing precondition
    -- no sensor mapped, unreliable snap, no fresh observation, no
    threshold available -- resolves to Unknown with an explicit reason,
    never a guessed Low.
    """
    def unknown(reason: str, coverage: str, **kw) -> SegmentClassification:
        return SegmentClassification(
            segment_id=segment_id,
            sensor_id=sensor_id,
            label="Unknown",
            reason=reason,
            observed_count=kw.get("observed_count"),
            threshold=kw.get("threshold"),
            observation_ts=kw.get("observation_ts"),
            coverage=coverage,
            snap_m=snap_m,
        )

    # Order matters here. The catchment pipeline (snap_sensors_to_blocks)
    # deliberately sets sensor_id=None when the nearest candidate was too
    # far, but still populates snap_m with that real distance -- so a
    # "too far, but here's the distance" case must be checked (and
    # reported with its real number) BEFORE the generic "no candidate at
    # all" case, or the more informative reason gets silently discarded.
    # This exact ordering bug shipped once already: comparing two live
    # runs against the same real segment showed the reason regressing
    # from "exceeds reliable threshold (111.4m vs 100m)" to a bare
    # "no sensor mapped", even though the distance data was still there.
    if snap_reliable is False and snap_m is not None:
        threshold_shown = snap_threshold_m if snap_threshold_m is not None else MAX_RELIABLE_SNAP_M
        return unknown(
            f"sensor snap distance ({snap_m:.1f}m) exceeds reliable threshold "
            f"({threshold_shown:.0f}m)",
            "unreliable_snap",
        )

    if sensor_id is None or (isinstance(sensor_id, float) and pd.isna(sensor_id)):
        return unknown("no sensor mapped to this segment", "no_sensor")

    obs = get_latest_observation(
        pedestrian_df, sensor_id, reference_time, freshness_hours
    )
    if obs is None:
        return unknown(
            f"no observation within {freshness_hours:.0f}h freshness window",
            "stale_or_missing",
        )
    observed_count, observation_ts = obs

    thresholds = get_alert_thresholds(
        [sensor_id], user_context=user_context, base_thresholds=base_thresholds
    )
    threshold = thresholds.get(sensor_id)
    if threshold is None:
        return unknown(
            "no base threshold available for this sensor",
            "no_threshold",
            observed_count=observed_count,
            observation_ts=observation_ts,
        )

    label = "High" if observed_count >= threshold else "Low"
    comparator = ">=" if label == "High" else "<"
    reason = (
        f"observed count {observed_count:g} {comparator} threshold "
        f"{threshold:g} (as of {observation_ts})"
    )

    return SegmentClassification(
        segment_id=segment_id,
        sensor_id=sensor_id,
        label=label,
        reason=reason,
        observed_count=observed_count,
        threshold=threshold,
        observation_ts=observation_ts,
        coverage="matched",
        snap_m=snap_m,
    )


# ---------------------------------------------------------------------------
# Route aggregation
# ---------------------------------------------------------------------------

def aggregate_route(
    route_id: str,
    segment_scores: list[SegmentClassification],
    rule: str = AGGREGATION_RULE,
) -> RouteClassification:
    """
    Combine segment-level scores into one route-level score.

    worst_segment_wins:
      - High if any segment is High (always, regardless of coverage --
        one confirmed High segment is a directly measured fact).
      - Else Unknown if coverage < MIN_COVERAGE_FOR_LOW_PCT (10%) --
        genuinely insufficient data to support any claim.
      - Else Low, tagged with a confidence tier reflecting how much of
        the route was actually resolved (see CONFIDENCE_TIERS).

    See the AGGREGATION_RULE / MIN_COVERAGE_FOR_LOW_PCT / CONFIDENCE_TIERS
    module-level comments for why these specific numbers, backed by a
    real 50-route sample rather than guessed.
    """
    if not segment_scores:
        return RouteClassification(
            route_id=route_id,
            label="Unknown",
            reason="route has no segments",
            aggregation_rule=rule,
            coverage="0/0 segments resolved",
            segment_scores=[],
            confidence=None,
            coverage_pct=0.0,
        )

    if rule != "worst_segment_wins":
        raise ValueError(f"unsupported aggregation rule: {rule!r}")

    total = len(segment_scores)
    high = [s for s in segment_scores if s.label == "High"]
    unknown = [s for s in segment_scores if s.label == "Unknown"]
    resolved = total - len(unknown)
    coverage_pct = round(100 * resolved / total, 1)

    if high:
        ids = ", ".join(s.segment_id for s in high)
        label = "High"
        confidence = None  # full-confidence fact, not tiered by coverage
        reason = f"{len(high)}/{total} segment(s) High: {ids}"
    elif coverage_pct < MIN_COVERAGE_FOR_LOW_PCT:
        label = "Unknown"
        confidence = None
        reason = (
            f"only {coverage_pct:.0f}% of segments resolved -- below the "
            f"{MIN_COVERAGE_FOR_LOW_PCT:.0f}% minimum needed to support any "
            f"classification"
        )
    else:
        label = "Low"
        confidence = get_confidence_tier(coverage_pct)
        if unknown:
            reason = (
                f"{resolved}/{total} segments resolved and Low "
                f"({confidence} confidence, {coverage_pct:.0f}% coverage); "
                f"{len(unknown)} unresolved segment(s) not counted toward "
                f"the label"
            )
        else:
            reason = (
                f"all {total} segments Low "
                f"({confidence} confidence, {coverage_pct:.0f}% coverage)"
            )

    return RouteClassification(
        route_id=route_id,
        label=label,
        reason=reason,
        aggregation_rule=rule,
        coverage=f"{resolved}/{total} segments resolved",
        segment_scores=segment_scores,
        confidence=confidence,
        coverage_pct=coverage_pct,
    )


# ---------------------------------------------------------------------------
# End-to-end convenience wrapper
# ---------------------------------------------------------------------------

def score_route(
    route_id: str,
    segments: list[dict],
    pedestrian_df: pd.DataFrame,
    base_thresholds: dict[int, float],
    reference_time: datetime,
    user_context: Optional[dict] = None,
    freshness_hours: float = FRESHNESS_HOURS,
    snap_threshold_m: Optional[float] = None,
) -> RouteClassification:
    """
    segments: list of dicts, each with segment_id, sensor_id (or None),
    snap_reliable (or None), snap_m (or None) -- i.e. rows from
    snap_sensors_to_graph() or snap_sensors_to_blocks() joined onto a
    route's ordered segment list.

    snap_threshold_m: pass the ACTUAL threshold your pipeline used to set
    snap_reliable (e.g. the catchment_radius_m you gave
    snap_sensors_to_blocks), so unreliable-snap reasons state the real
    number rather than falling back to MAX_RELIABLE_SNAP_M by default.
    """
    scored = [
        classify_segment(
            segment_id=seg["segment_id"],
            sensor_id=seg.get("sensor_id"),
            snap_reliable=seg.get("snap_reliable"),
            snap_m=seg.get("snap_m"),
            pedestrian_df=pedestrian_df,
            base_thresholds=base_thresholds,
            reference_time=reference_time,
            user_context=user_context,
            freshness_hours=freshness_hours,
            snap_threshold_m=snap_threshold_m,
        )
        for seg in segments
    ]
    return aggregate_route(route_id, scored)