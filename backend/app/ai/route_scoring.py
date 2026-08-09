from __future__ import annotations

from datetime import datetime, timezone

DEFAULT_DIRECT_RADIUS_M = 75.0   # Vince's "direct" evidence tier -- close enough to trust as strong evidence
DEFAULT_PROXY_RADIUS_M = 150.0   # Vince's "proxy" tier -- usable ONLY when no direct evidence exists


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


def _project_points(points_latlon: list[tuple[float, float]], ref_lat: float | None = None):
    """
    Projects a list of (lat, lon) points into a metric CRS, using the same
    lesson learned in route_scoring.py: comparing raw lat/lon degrees as
    if they were metres silently produces meaningless "reliable" checks.
    Uses a simple local equirectangular projection (accurate enough for
    CBD-scale distances, no external graph/CRS machinery needed here
    since there's no OSMnx graph in this path to borrow a projection
    from).

    ref_lat: pass an EXPLICIT shared reference latitude when projecting
    multiple related point sets (e.g. a route's geometry AND every sensor
    being matched against it) so they land in the SAME local metric grid.
    A real, if small, inaccuracy was caught here: the original version
    always derived its own ref_lat from whatever points it was given,
    meaning the route line and every individual sensor each got a
    slightly different projection -- close enough to rarely matter, but
    real error sitting right at the boundary of a 75m/150m tiered radius
    system, where a few metres can flip a classification. Defaults to
    the old self-derived behaviour ONLY when ref_lat isn't supplied, for
    any caller that genuinely doesn't need cross-consistency.
    """
    import math

    if not points_latlon:
        return []
    if ref_lat is None:
        ref_lat = points_latlon[0][0]
    ref_lat_rad = math.radians(ref_lat)
    m_per_deg_lat = 111_320.0
    m_per_deg_lon = 111_320.0 * math.cos(ref_lat_rad)
    return [(lon * m_per_deg_lon, lat * m_per_deg_lat) for lat, lon in points_latlon]


def _walk_only_route_geometry(candidate_route: dict):
    """
    Extracts ONLY the WALK-mode step polylines from Google's route legs,
    building a shapely (Multi)LineString of just the segments a
    pedestrian is actually exposed to at street level.

    REAL BUG THIS FIXES: the previous version decoded the route's single
    TOP-LEVEL combined polyline, which includes transit segments (e.g. a
    train travelling underground through the City Loop). A live test
    matched sensors near Docklands against a route whose only actual
    walking was near Flinders Street, purely because the train's
    underground path geometrically swings near Docklands -- the commuter
    was never anywhere near those sensors. Only WALK-mode steps represent
    real pedestrian exposure.

    Returns (geometry, ref_lat) -- ref_lat is the shared reference
    latitude used to project every walk segment consistently, meant to
    be reused for sensor projection too (see _match_sensors_to_route).
    Returns (None, None) if there are no usable walk segments at all (a
    fully-transit "route" with no walking, or missing/malformed leg
    data) -- correctly resolves to Unknown downstream, not a guess.
    """
    from shapely.geometry import LineString, MultiLineString

    legs = candidate_route.get("legs") or []
    walk_points_per_segment: list[list[tuple[float, float]]] = []
    for leg in legs:
        for step in leg.get("steps", []):
            if step.get("travelMode") != "WALK":
                continue
            encoded = (step.get("polyline") or {}).get("encodedPolyline")
            if not encoded:
                continue
            points_latlon = decode_polyline(encoded)
            if len(points_latlon) >= 2:
                walk_points_per_segment.append(points_latlon)

    if not walk_points_per_segment:
        return None, None

    # One shared reference latitude for the WHOLE route (first point of
    # the first walk segment) -- every segment and every sensor checked
    # against this route project into the same consistent metric grid.
    ref_lat = walk_points_per_segment[0][0][0]

    lines = [LineString(_project_points(pts, ref_lat=ref_lat)) for pts in walk_points_per_segment]
    geometry = lines[0] if len(lines) == 1 else MultiLineString(lines)
    return geometry, ref_lat


def _route_line_geometry(candidate_route: dict):
    """
    Decodes a candidate route's polyline and returns a projected shapely
    LineString, or None if geometry is missing/unusable (must resolve to
    Unknown downstream, not a crash or a guess).

    SUPERSEDED for real scoring by _walk_only_route_geometry() above --
    kept here only because it's still exercised by
    test_decode_polyline_matches_google_canonical_example and similar
    geometry-decoding tests that don't need the walk-only distinction.
    Not called from score_candidate_routes()'s real scoring path anymore.
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


def _match_sensors_to_route(
    route_line,
    sensor_observations: list[dict],
    direct_radius_m: float,
    proxy_radius_m: float,
    ref_lat: float,
):
    """
    Finds every sensor within proxy_radius_m of the route's line (Vince's
    two-tier evidence model), tagging each with match_type "direct" or
    "proxy" depending on how close it actually is. Direct evidence is
    close enough to trust on its own; proxy evidence is a wider,
    weaker signal used only when nothing direct is available -- see
    _score_one_route's evidence-hierarchy logic below.

    ref_lat MUST be the same reference latitude the route_line itself was
    projected with (see _walk_only_route_geometry / _project_points) --
    projecting sensors with a different reference would put them in a
    subtly different local metric grid than the route line, producing
    real (if small) distance errors.
    """
    from shapely.geometry import Point

    if route_line is None:
        return []

    matches = []
    for obs in sensor_observations:
        lat, lon = obs.get("latitude"), obs.get("longitude")
        if lat is None or lon is None:
            continue
        projected = _project_points([(lat, lon)], ref_lat=ref_lat)[0]
        dist_m = Point(projected).distance(route_line)
        if dist_m <= proxy_radius_m:
            match_type = "direct" if dist_m <= direct_radius_m else "proxy"
            matches.append({**obs, "_distance_m": round(dist_m, 1), "match_type": match_type})
    return matches


def score_candidate_routes(
    candidate_routes: list[dict],
    sensor_observations: list[dict],
    crowd_threshold: float,
    direct_radius_m: float = DEFAULT_DIRECT_RADIUS_M,
    proxy_radius_m: float = DEFAULT_PROXY_RADIUS_M,
) -> dict:
    """
    THE replacement-point function. See module docstring for design notes.

    Returns the exact response shape route_service.py's mock already
    produces (routes, recommendation, metadata), so frontend integration
    stays stable regardless of the internal implementation change.
    """
    scored_routes = [
        _score_one_route(route, sensor_observations, crowd_threshold, direct_radius_m, proxy_radius_m)
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
    direct_radius_m: float,
    proxy_radius_m: float,
) -> dict:
    route_line, ref_lat = _walk_only_route_geometry(candidate_route)

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

    nearby = _match_sensors_to_route(route_line, sensor_observations, direct_radius_m, proxy_radius_m, ref_lat)
    usable_direct = [obs for obs in nearby if obs["match_type"] == "direct" and obs.get("availability") == "available"]
    usable_proxy = [obs for obs in nearby if obs["match_type"] == "proxy" and obs.get("availability") == "available"]

    # Evidence hierarchy (Vince's v81 design): direct evidence, if any
    # exists, is used EXCLUSIVELY -- proxy evidence is not blended in,
    # not even to corroborate. Proxy is only consulted as a fallback when
    # there's no direct evidence at all. A closer, more specific reading
    # should never be diluted or overridden by a farther, less specific one.
    if usable_direct:
        evidence, coverage = usable_direct, "direct"
    elif usable_proxy:
        evidence, coverage = usable_proxy, "proxy"
    else:
        evidence, coverage = [], None

    if not evidence:
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
        obs for obs in evidence
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
        confidence = _confidence_tier(len(evidence))  # how many independent sensors support this "calm" call

    return {
        **candidate_route,
        "sensory_level": sensory_level,
        "sensor_evidence": evidence,
        "hotspot": hotspot,
        "coverage": coverage,  # "direct" or "proxy", per the evidence hierarchy above
        "confidence": confidence,
        "recommended": False,
        "data_mode": "live",
    }