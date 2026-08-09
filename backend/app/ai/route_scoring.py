"""
score_candidate_routes.py

THE "DATA/SCORING TEAM REPLACEMENT POINT" named in route_service.py's own
comment:

    scored_routes = score_candidate_routes(
        candidate_routes, sensor_observations, request_data["crowd_threshold"]
    )

Combines DEV-US1.1-01 (High/Low classification) and DEV-US1.2-01 (route
comparison, hotspot avoidance, trade-off) into one function, per team
decision -- the real contract's response shape (sensory_level + hotspot +
recommendation all on one call) doesn't cleanly separate the two cards,
so this is one implementation serving both, with each card's acceptance
criteria still traceable to specific parts of it (see the writeup).

HOW THIS DIFFERS FROM route_scoring.py (the original DEV-US1.1-01 build):
  - Geometry comes from Google Routes (decoded polyline), not OSMnx --
    no more building the walking graph ourselves. The catchment-matching
    TECHNIQUE (distance from a sensor point to a route line, in real
    metres) is the same one already validated in route_scoring.py; only
    the geometry source changed.
  - sensor_observations arrive with freshness/availability ALREADY
    computed by the data adapter (sensor_service.py's replacement point)
    -- this does not recompute freshness from raw timestamps the way
    get_latest_observation() did.
  - No street-block sub-segmentation. The real contract wants one
    sensory_level and one hotspot per whole route, not per segment --
    coarser than the original block-merging design. The catchment-radius
    matching and "never unsupported Low" refusal pattern still apply,
    just at whole-route granularity.
  - Threshold: Option A (client-supplied single value, compared directly)
    per team decision on 2026-08-09. See _exceeds_threshold() -- isolated
    into one small function specifically so this is a one-line swap if
    the team later confirms Option B (per-sensor-relative) instead.
    KNOWN LIMITATION, documented deliberately rather than hidden: a
    single global threshold can't account for different sensors having
    very different normal foot-traffic levels. See
    ai/docs/DEV-US1.1-01_writeup.md for the full discussion.
"""

from __future__ import annotations

from datetime import datetime, timezone

DEFAULT_CATCHMENT_RADIUS_M = 100.0  # same constant/value as route_scoring.py, kept in sync deliberately


def decode_polyline(encoded: str) -> list[tuple[float, float]]:
    """
    Standard Google encoded-polyline decoding. Verified against Google's
    own canonical documented example before use (see test suite).
    Returns [(lat, lon), ...].
    """
    points = []
    index = lat = lng = 0
    while index < len(encoded):
        for is_lat in (True, False):
            shift = result = 0
            while True:
                b = ord(encoded[index]) - 63
                index += 1
                result |= (b & 0x1F) << shift
                shift += 5
                if b < 0x20:
                    break
            delta = ~(result >> 1) if result & 1 else (result >> 1)
            if is_lat:
                lat += delta
            else:
                lng += delta
        points.append((lat / 1e5, lng / 1e5))
    return points


def _project_points(points_latlon: list[tuple[float, float]]):
    """
    Projects a list of (lat, lon) points into a metric CRS, using the same
    lesson learned in route_scoring.py: comparing raw lat/lon degrees as
    if they were metres silently produces meaningless "reliable" checks.
    Uses a simple local equirectangular projection (accurate enough for
    CBD-scale distances, no external graph/CRS machinery needed here
    since there's no OSMnx graph in this path to borrow a projection
    from).
    """
    import math

    if not points_latlon:
        return []
    ref_lat = points_latlon[0][0]
    ref_lat_rad = math.radians(ref_lat)
    m_per_deg_lat = 111_320.0
    m_per_deg_lon = 111_320.0 * math.cos(ref_lat_rad)
    return [(lon * m_per_deg_lon, lat * m_per_deg_lat) for lat, lon in points_latlon]


def _route_line_geometry(candidate_route: dict):
    """
    Decodes a candidate route's polyline and returns a projected shapely
    LineString, or None if geometry is missing/unusable (must resolve to
    Unknown downstream, not a crash or a guess).
    """
    from shapely.geometry import LineString

    geometry = candidate_route.get("geometry")
    if not geometry or geometry.get("encoding") != "google_encoded_polyline":
        return None
    encoded = geometry.get("value")
    if not encoded:
        return None

    points_latlon = decode_polyline(encoded)
    if len(points_latlon) < 2:
        return None

    projected = _project_points(points_latlon)
    return LineString(projected)


def _confidence_tier(usable_sensor_count: int) -> str:
    """
    How much support backs this route's classification -- based on the
    number of usable (fresh, available) sensors near the route, not a
    ratio against nearby-but-stale ones. A call resting on one fresh
    sensor is just as valid as one resting on five; it's just less
    corroborated. Simple, defensible, easy to explain: more independent
    confirming sensors = higher confidence.

    Kept as its own function so the exact cutoffs (1/2/3+) are a one-line
    change if the team wants different boundaries later.
    """
    if usable_sensor_count >= 3:
        return "high"
    if usable_sensor_count == 2:
        return "medium"
    return "low"  # always >=1 here -- 0 usable sensors is the separate Unknown path


def _exceeds_threshold(count: float, crowd_threshold: float) -> bool:
    """
    Option A (team decision 2026-08-09): direct comparison against the
    single client-supplied threshold. Isolated here deliberately -- swap
    this one function if the team later confirms per-sensor-relative
    (Option B) instead; nothing else in this file needs to change.
    """
    return count > crowd_threshold


def _match_sensors_to_route(route_line, sensor_observations: list[dict], catchment_radius_m: float):
    """
    Finds every sensor within catchment_radius_m of the route's line,
    projected into the same metric CRS as the route geometry. Returns all
    matches (not just the closest), since the contract wants a full
    sensor_evidence list per route, not a single nearest match.
    """
    from shapely.geometry import Point

    if route_line is None:
        return []

    matches = []
    ref_lat = None
    for obs in sensor_observations:
        lat, lon = obs.get("latitude"), obs.get("longitude")
        if lat is None or lon is None:
            continue
        if ref_lat is None:
            ref_lat = lat
        projected = _project_points([(lat, lon)])[0]
        dist_m = Point(projected).distance(route_line)
        if dist_m <= catchment_radius_m:
            matches.append({**obs, "_distance_m": round(dist_m, 1)})
    return matches


def score_candidate_routes(
    candidate_routes: list[dict],
    sensor_observations: list[dict],
    crowd_threshold: float,
    catchment_radius_m: float = DEFAULT_CATCHMENT_RADIUS_M,
) -> dict:
    """
    THE replacement-point function. See module docstring for design notes.

    Returns the exact response shape route_service.py's mock already
    produces (routes, recommendation, metadata), so frontend integration
    stays stable regardless of the internal implementation change.
    """
    scored_routes = [
        _score_one_route(route, sensor_observations, crowd_threshold, catchment_radius_m)
        for route in candidate_routes
    ]

    # Data Integrity / Failure Handling: a route only counts as a genuine
    # comparison candidate if it's confidently Low -- NOT falling back to
    # "recommend the fastest regardless" the way the placeholder mock
    # did, since that would violate DEV-US1.2-01's own Failure Handling
    # criterion (a route_service.py mock is a deterministic PLACEHOLDER,
    # not itself the spec for final behaviour).
    low_routes = [r for r in scored_routes if r["sensory_level"] == "Low"]

    if low_routes:
        recommended = min(low_routes, key=lambda r: r["duration_minutes"])
        fastest = min(scored_routes, key=lambda r: r["duration_minutes"])
        extra_minutes = recommended["duration_minutes"] - fastest["duration_minutes"]
        for route in scored_routes:
            route["recommended"] = route["route_id"] == recommended["route_id"]
        recommendation = {
            "route_id": recommended["route_id"],
            "reason": "Lowest supported crowd exposure among the available alternatives.",
            "trade_off": f"{extra_minutes} additional minutes compared with the fastest route.",
            "lower_crowd_alternative_available": True,
        }
    else:
        # Genuine failure-handling case: no route can be confidently
        # recommended. Say so clearly rather than guessing.
        for route in scored_routes:
            route["recommended"] = False
        recommendation = {
            "route_id": None,
            "reason": "No route has sufficient supported evidence to recommend a lower-crowd alternative.",
            "trade_off": None,
            "lower_crowd_alternative_available": False,
        }

    return {
        "routes": scored_routes,
        "recommendation": recommendation,
        "metadata": {
            "data_mode": "live" if sensor_observations else "unavailable",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "limitations": [
                "Crowd comparison uses a single client-supplied threshold applied "
                "identically across all sensors; it does not account for sensors "
                "having different normal foot-traffic baselines.",
                "Sensory level is a crowd-density proxy, not a safety or "
                "accessibility guarantee.",
            ],
        },
    }


def _score_one_route(
    candidate_route: dict,
    sensor_observations: list[dict],
    crowd_threshold: float,
    catchment_radius_m: float,
) -> dict:
    route_line = _route_line_geometry(candidate_route)

    if route_line is None:
        return {
            **candidate_route,
            "sensory_level": "Unknown",
            "sensor_evidence": [],
            "hotspot": None,
            "coverage": "geometry_unavailable",
            "confidence": None,
            "recommended": False,
            "data_mode": "unavailable",
        }

    nearby = _match_sensors_to_route(route_line, sensor_observations, catchment_radius_m)
    usable = [obs for obs in nearby if obs.get("availability") == "available"]

    if not usable:
        return {
            **candidate_route,
            "sensory_level": "Unknown",
            "sensor_evidence": nearby,  # show what WAS nearby but unusable, for transparency
            "hotspot": None,
            "coverage": "no_available_sensor_evidence",
            "confidence": None,
            "recommended": False,
            "data_mode": "mixed" if nearby else "unavailable",
        }

    exceeding = [
        obs for obs in usable
        if obs.get("pedestrian_count_per_minute") is not None
        and _exceeds_threshold(obs["pedestrian_count_per_minute"], crowd_threshold)
    ]

    if exceeding:
        worst = max(exceeding, key=lambda obs: obs["pedestrian_count_per_minute"])
        hotspot = {**worst, "exceeds_threshold_by": round(worst["pedestrian_count_per_minute"] - crowd_threshold, 1)}
        sensory_level = "High"
        confidence = None  # a confirmed over-threshold sensor is a fact, not tiered by how many OTHER sensors agree
    else:
        hotspot = None
        sensory_level = "Low"
        confidence = _confidence_tier(len(usable))  # how many independent sensors support this "calm" call

    return {
        **candidate_route,
        "sensory_level": sensory_level,
        "sensor_evidence": usable,
        "hotspot": hotspot,
        "coverage": "supported",
        "confidence": confidence,
        "recommended": False,
        "data_mode": "live",
    }