"""Route comparison for deterministic mock mode and live integrated mode."""

from datetime import datetime, timezone
from hashlib import sha256

from .google_maps_service import generate_candidate_routes
from .route_scoring_service import recommend_route, score_candidate_routes


def compare_routes(
    request_data: dict,
    sensors: tuple[dict, ...],
    data_mode: str,
    provider_config: dict | None = None,
    observations: list[dict] | None = None,
) -> dict:
    """Build stable mock alternatives so frontend and QA can integrate reproducibly.

    The hash selects counts from the request text. This is not a prediction or live
    measurement; it provides repeatable contract behaviour until data and routing
    services replace this adapter.
    """

    # ROUTING TEAM REPLACEMENT POINT:
    # candidate_routes = generate_candidate_routes(
    #     request_data["origin"], request_data["destination"],
    #     request_data["origin_coordinates"],
    #     request_data["destination_coordinates"],
    #     request_data["departure_time"],
    # )
    # Each candidate must provide route_id, duration_minutes, distance_metres,
    # legs and geometry. It must not assign sensory_level.
    #
    # Live mode uses the route-scoring service below. Mock mode remains stable
    # for local frontend work and contract tests without external providers.
    if provider_config and provider_config.get("GOOGLE_INTEGRATION_MODE") == "live":
        candidates = generate_candidate_routes(request_data, provider_config)
        if not candidates:
            return _empty_live_result(request_data)
        return _score_live_candidates(request_data, candidates, sensors, observations or [], provider_config)

    threshold = request_data["crowd_threshold"]
    key = f"{request_data['origin']}|{request_data['destination']}"
    seed_value = int(sha256(key.encode("utf-8")).hexdigest()[:8], 16)
    sensor = sensors[seed_value % len(sensors)] if sensors else None
    base_count = float(12 + seed_value % 32)
    counts = (base_count, max(5.0, base_count - 9.0))
    durations = (22, 28)

    routes = [
        _build_route(index + 1, count, durations[index], threshold, sensor, data_mode)
        for index, count in enumerate(counts)
    ]
    low_routes = [route for route in routes if route["sensory_level"] == "Low"]
    recommended = min(low_routes or routes, key=lambda route: route["duration_minutes"])
    fastest = min(routes, key=lambda route: route["duration_minutes"])
    extra_minutes = recommended["duration_minutes"] - fastest["duration_minutes"]

    for route in routes:
        route["recommended"] = route["route_id"] == recommended["route_id"]

    return {
        "request": request_data,
        "routes": routes,
        "recommendation": {
            "route_id": recommended["route_id"],
            "reason": "Lowest supported crowd exposure within the available alternatives.",
            "trade_off": f"{extra_minutes} additional minutes compared with the fastest route.",
            "lower_crowd_alternative_available": bool(low_routes),
        },
        "metadata": _metadata(data_mode),
    }


def _score_live_candidates(request_data, candidates, sensors, observations, provider_config):
    routes = score_candidate_routes(
        candidates,
        sensors,
        observations,
        request_data["crowd_threshold"],
        provider_config.get("DIRECT_SENSOR_RADIUS_METRES", 75),
        provider_config.get("PROXY_SENSOR_RADIUS_METRES", 150),
    )
    recommended = recommend_route(routes)
    fastest = min(routes, key=lambda route: route["duration_minutes"])
    if recommended:
        recommended["recommended"] = True
        extra_minutes = recommended["duration_minutes"] - fastest["duration_minutes"]
        recommendation = {
            "route_id": recommended["route_id"],
            "reason": "Shortest route with supported crowd exposure below the user's threshold.",
            "trade_off": f"{extra_minutes} additional minutes compared with the fastest route.",
            "lower_crowd_alternative_available": True,
        }
    else:
        recommendation = {
            "route_id": None,
            "reason": "No supported Low-crowd route is currently available.",
            "trade_off": "Unknown routes are not treated as Low or recommended.",
            "lower_crowd_alternative_available": False,
        }
    return {
        "request": request_data,
        "routes": routes,
        "recommendation": recommendation,
        "metadata": {
            "data_mode": "mixed",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "limitations": [
                "Route geometry and travel estimates are supplied by Google Routes.",
                "Pedestrian counts are a partial proxy for sensory load and only cover sensors within 150 metres of a route.",
            ],
        },
    }


def _empty_live_result(request_data: dict) -> dict:
    return {
        "request": request_data,
        "routes": [],
        "recommendation": None,
        "metadata": {
            "data_mode": "live",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "limitations": ["The route provider returned no candidate transit routes."],
        },
    }


def _build_route(route_number: int, count: float, duration: int, threshold: float, sensor: dict | None, data_mode: str) -> dict:
    level = "High" if count > threshold else "Low"
    evidence = None
    hotspot = None
    if sensor:
        evidence = {
            **sensor,
            "pedestrian_count_per_minute": count,
            "observed_at": None,
            "freshness_minutes": None,
            "availability": "mock",
        }
        if level == "High":
            hotspot = {**evidence, "exceeds_threshold_by": round(count - threshold, 1)}

    return {
        "route_id": f"route-{route_number}",
        "duration_minutes": duration,
        "distance_metres": 2400 + route_number * 350,
        "legs": [
            {"mode": "walk", "duration_minutes": 6 + route_number},
            {"mode": "public_transport", "service": "placeholder", "duration_minutes": duration - 6 - route_number},
        ],
        "geometry": [],
        "sensory_level": level if evidence else "Unknown",
        "sensor_evidence": [evidence] if evidence else [],
        "hotspot": hotspot,
        "coverage": "mock" if evidence else "unavailable",
        "recommended": False,
        "data_mode": data_mode,
    }


def _metadata(data_mode: str) -> dict:
    return {
        "data_mode": data_mode,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "limitations": [
            "Route geometry, crowd counts and transport legs are deterministic mock values.",
            "The supplied CSV contains sensor locations only and does not provide live counts or observation timestamps.",
            "Pedestrian crowd is a proxy for one aspect of sensory load, not a safety or accessibility guarantee.",
        ],
    }
