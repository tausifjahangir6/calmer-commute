from app.services.route_scoring_service import recommend_route, score_candidate_routes


ENCODED_EQUATOR_LINE = "???o}@"  # (0, 0) to (0, 0.01)


def candidate(route_id="route-1", duration=20):
    return {
        "route_id": route_id,
        "duration_minutes": duration,
        "distance_metres": 1000,
        "legs": [],
        "geometry": {"encoding": "google_encoded_polyline", "value": ENCODED_EQUATOR_LINE},
    }


def location(sensor_id, latitude):
    return {"sensor_id": str(sensor_id), "name": f"Sensor {sensor_id}", "latitude": latitude, "longitude": 0.005}


def reading(sensor_id, count, freshness="fresh", status="active"):
    return {"id": sensor_id, "peoplePerMinute": count, "latestObservation": "2026-08-09T00:00:00Z", "freshness": freshness, "evidence": "observed", "operationalStatus": status}


def test_direct_evidence_takes_precedence_over_higher_proxy_count():
    routes = score_candidate_routes(
        [candidate()],
        (location(1, 0.00045), location(2, 0.001)),
        [reading(1, 20), reading(2, 80)],
        threshold=25,
    )
    route = routes[0]
    assert route["coverage"] == "direct"
    assert route["sensory_level"] == "Low"
    assert [item["sensor_id"] for item in route["sensor_evidence"]] == ["1"]


def test_maximum_direct_count_sets_high_and_hotspot():
    routes = score_candidate_routes(
        [candidate()],
        (location(1, 0.0003), location(2, 0.0005)),
        [reading(1, 20), reading(2, 31)],
        threshold=25,
    )
    route = routes[0]
    assert route["sensory_level"] == "High"
    assert route["hotspot"]["sensor_id"] == "2"
    assert route["hotspot"]["exceeds_threshold_by"] == 6


def test_stale_inactive_and_outside_150m_are_unknown():
    routes = score_candidate_routes(
        [candidate()],
        (location(1, 0.0003), location(2, 0.002)),
        [reading(1, 10, freshness="stale"), reading(2, 10)],
        threshold=25,
    )
    assert routes[0]["sensory_level"] == "Unknown"
    assert routes[0]["sensor_evidence"] == []


def test_recommendation_is_shortest_supported_low_and_never_unknown():
    routes = [
        {"route_id": "unknown", "duration_minutes": 10, "sensory_level": "Unknown"},
        {"route_id": "low-slow", "duration_minutes": 25, "sensory_level": "Low"},
        {"route_id": "low-fast", "duration_minutes": 20, "sensory_level": "Low"},
    ]
    assert recommend_route(routes)["route_id"] == "low-fast"
    assert recommend_route(routes[:1]) is None
