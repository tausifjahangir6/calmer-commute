"""Geographic route-to-sensor matching and current crowd-risk scoring."""

from math import cos, hypot, pi


def score_candidate_routes(
    candidates: list[dict],
    sensor_locations: tuple[dict, ...],
    observations: list[dict],
    threshold: float,
    direct_radius_metres: float = 75.0,
    proxy_radius_metres: float = 150.0,
) -> list[dict]:
    """Score candidates using the v81 evidence hierarchy.

    Direct observations take precedence over proxy observations. A route is
    Unknown when its geometry is missing or it has no usable observation.
    """

    locations = {
        str(sensor["sensor_id"]): sensor
        for sensor in sensor_locations
        if sensor.get("sensor_id") is not None
    }
    readings = {
        str(reading.get("id")): reading
        for reading in observations
        if _usable(reading)
    }
    scored = []
    for candidate in candidates:
        # REAL BUG FIX (2026-08-09): this used to decode
        # candidate["geometry"]["value"] -- Google's single TOP-LEVEL
        # polyline for the WHOLE route, including transit segments (e.g.
        # a train travelling underground through the City Loop). Live
        # testing matched sensors near Docklands against a route whose
        # only actual walking was near Flinders Street, purely because
        # the train's underground path geometrically swings near
        # Docklands -- the commuter was never anywhere near those
        # sensors. Only WALK-mode steps represent real pedestrian
        # exposure. walk_paths keeps each WALK step's points as its OWN
        # separate path (not concatenated into one flat list), so a fake
        # "bridging" segment is never introduced between two disjoint
        # walk chunks (e.g. "walk to the station" and "walk from the
        # station", which aren't geographically connected).
        walk_paths = _walk_only_paths(candidate)
        matches = []
        for sensor_id, reading in readings.items():
            location = locations.get(sensor_id)
            if not location or not walk_paths:
                continue
            distance = round(
                _distance_to_walk_paths_metres(
                    {"latitude": location["latitude"], "longitude": location["longitude"]},
                    walk_paths,
                ),
                1,
            )
            if distance <= proxy_radius_metres:
                matches.append(
                    {
                        "sensor_id": sensor_id,
                        "name": location.get("name", ""),
                        "latitude": location["latitude"],
                        "longitude": location["longitude"],
                        "pedestrian_count_per_minute": reading["peoplePerMinute"],
                        "observed_at": reading.get("latestObservation"),
                        "freshness": reading.get("freshness"),
                        "evidence": reading.get("evidence"),
                        "distance_to_route_metres": distance,
                        "match_type": "direct" if distance <= direct_radius_metres else "proxy",
                    }
                )

        direct = [item for item in matches if item["match_type"] == "direct"]
        evidence = direct or [item for item in matches if item["match_type"] == "proxy"]
        hotspot = max(evidence, key=lambda item: item["pedestrian_count_per_minute"], default=None)
        count = hotspot["pedestrian_count_per_minute"] if hotspot else None
        level = "Unknown" if count is None else ("High" if count > threshold else "Low")
        scored.append(
            {
                **candidate,
                "sensory_level": level,
                "sensor_evidence": sorted(evidence, key=lambda item: item["distance_to_route_metres"]),
                "hotspot": (
                    {**hotspot, "exceeds_threshold_by": round(count - threshold, 1)}
                    if hotspot and level == "High"
                    else None
                ),
                "coverage": "direct" if direct else ("proxy" if evidence else "unavailable"),
                "recommended": False,
                "data_mode": "live",
            }
        )
    return scored


def recommend_route(routes: list[dict]) -> dict | None:
    """Recommend only the shortest supported Low route."""

    low_routes = [route for route in routes if route["sensory_level"] == "Low"]
    if not low_routes:
        return None
    return min(low_routes, key=lambda route: route["duration_minutes"])


def _walk_only_paths(candidate: dict) -> list[list[dict]]:
    """
    Returns one path (list of {"latitude","longitude"} points) per
    WALK-mode step in the candidate's legs, kept as SEPARATE paths -- not
    concatenated into a single flat list -- so no fake connecting segment
    is ever introduced between two disjoint walk chunks (e.g. the walk to
    a station and the walk from a different station after alighting).
    Returns an empty list if there are no usable WALK steps at all (a
    fully-transit route, or missing/malformed leg data) -- callers must
    treat this as "no walkable geometry", resolving to Unknown, not a
    fallback guess.
    """
    paths = []
    for leg in candidate.get("legs", []) or []:
        for step in leg.get("steps", []) or []:
            if step.get("travelMode") != "WALK":
                continue
            encoded = (step.get("polyline") or {}).get("encodedPolyline")
            if not encoded:
                continue
            points = decode_google_polyline(encoded)
            if points:
                paths.append(points)
    return paths


def _distance_to_walk_paths_metres(point: dict, walk_paths: list[list[dict]]) -> float:
    """Minimum distance from point to ANY of the separate walk paths."""
    if not walk_paths:
        return float("inf")
    return min(distance_to_route_metres(point, path) for path in walk_paths)


def decode_google_polyline(encoded: str) -> list[dict]:
    points = []
    index = latitude = longitude = 0
    while index < len(encoded):
        latitude_delta, index = _decode_value(encoded, index)
        longitude_delta, index = _decode_value(encoded, index)
        latitude += latitude_delta
        longitude += longitude_delta
        points.append({"latitude": latitude / 100000, "longitude": longitude / 100000})
    return points


def _decode_value(encoded: str, index: int) -> tuple[int, int]:
    shift = result = 0
    while True:
        byte = ord(encoded[index]) - 63
        index += 1
        result |= (byte & 0x1F) << shift
        shift += 5
        if byte < 0x20:
            break
    return (~(result >> 1) if result & 1 else result >> 1), index


def distance_to_route_metres(point: dict, path: list[dict]) -> float:
    if not path:
        return float("inf")
    if len(path) == 1:
        return _point_distance(point, path[0])
    return min(_point_to_segment(point, path[index - 1], path[index]) for index in range(1, len(path)))


def _point_distance(first: dict, second: dict) -> float:
    radians = pi / 180
    delta_latitude = (second["latitude"] - first["latitude"]) * radians
    delta_longitude = (second["longitude"] - first["longitude"]) * radians
    x = delta_longitude * cos((first["latitude"] + second["latitude"]) * radians / 2)
    return 6371000 * hypot(delta_latitude, x)


def _point_to_segment(point: dict, start: dict, end: dict) -> float:
    metres_per_latitude = 111320
    metres_per_longitude = metres_per_latitude * cos(point["latitude"] * pi / 180)
    ax = (start["longitude"] - point["longitude"]) * metres_per_longitude
    ay = (start["latitude"] - point["latitude"]) * metres_per_latitude
    bx = (end["longitude"] - point["longitude"]) * metres_per_longitude
    by = (end["latitude"] - point["latitude"]) * metres_per_latitude
    dx, dy = bx - ax, by - ay
    length_squared = dx * dx + dy * dy
    position = 0 if length_squared == 0 else max(0, min(1, -(ax * dx + ay * dy) / length_squared))
    return hypot(ax + position * dx, ay + position * dy)


def _usable(reading: dict) -> bool:
    return (
        reading.get("freshness") in {"fresh", "delayed"}
        and reading.get("peoplePerMinute") is not None
        and reading.get("operationalStatus") == "active"
    )