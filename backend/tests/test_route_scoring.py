from app.services.route_scoring_service import recommend_route, score_candidate_routes


ENCODED_EQUATOR_LINE = "???o}@"  # (0, 0) to (0, 0.01)
GOOGLE_EXAMPLE_POLYLINE = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"  # Google's own canonical example, ~40N/120W


def candidate(route_id="route-1", duration=20, polyline=ENCODED_EQUATOR_LINE):
    """
    Realistic default: a single WALK step covering the whole polyline --
    matches the real Google contract shape (legs[].steps[].travelMode),
    which score_candidate_routes() now requires to find any walkable
    geometry at all (see walk-only fix, 2026-08-09).
    """
    return {
        "route_id": route_id,
        "duration_minutes": duration,
        "distance_metres": 1000,
        "legs": [{"steps": [{"travelMode": "WALK", "polyline": {"encodedPolyline": polyline}}]}],
        "geometry": {"encoding": "google_encoded_polyline", "value": polyline},
    }


def candidate_transit_only(route_id="route-1", duration=20, polyline=ENCODED_EQUATOR_LINE):
    return {
        "route_id": route_id,
        "duration_minutes": duration,
        "distance_metres": 1000,
        "legs": [{"steps": [{"travelMode": "TRANSIT", "polyline": {"encodedPolyline": polyline}}]}],
        "geometry": {"encoding": "google_encoded_polyline", "value": polyline},
    }


def location(sensor_id, latitude, longitude=0.005):
    return {"sensor_id": str(sensor_id), "name": f"Sensor {sensor_id}", "latitude": latitude, "longitude": longitude}


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


# ---------------------------------------------------------------------------
# Walk-only geometry matching (added 2026-08-09) -- real bug caught on a
# live run: sensors near a TRANSIT segment's geometric path (e.g. an
# underground train swinging near Docklands) were being matched even
# though the commuter was never actually walking there. Only WALK-mode
# steps should count.
# ---------------------------------------------------------------------------

def test_transit_only_route_has_no_walkable_geometry():
    routes = score_candidate_routes(
        [candidate_transit_only()],
        (location(1, 0.00045),),
        [reading(1, 10)],
        threshold=25,
    )
    assert routes[0]["sensory_level"] == "Unknown"
    assert routes[0]["coverage"] == "unavailable"


def test_sensor_near_transit_segment_not_walk_segment_is_excluded():
    # A route with a real WALK step near the equator AND a TRANSIT step
    # whose geometry happens to swing near a totally different location.
    # A sensor at that transit-only location must NOT be matched, even
    # though it's geometrically close to the FULL route's combined path.
    route = {
        "route_id": "route-1",
        "duration_minutes": 16,
        "distance_metres": 3800,
        "legs": [{
            "steps": [
                {"travelMode": "WALK", "polyline": {"encodedPolyline": ENCODED_EQUATOR_LINE}},
                {"travelMode": "TRANSIT", "polyline": {"encodedPolyline": GOOGLE_EXAMPLE_POLYLINE}},
            ]
        }],
        "geometry": {"encoding": "google_encoded_polyline", "value": GOOGLE_EXAMPLE_POLYLINE},
    }
    sensors = (
        location(1, 0.00045),       # near the WALK step -- should match
        location(2, 40.7, -120.95),  # near the TRANSIT step only -- must NOT match
    )
    readings = [reading(1, 10), reading(2, 999)]
    routes = score_candidate_routes([route], sensors, readings, threshold=25)
    evidence_ids = [item["sensor_id"] for item in routes[0]["sensor_evidence"]]
    assert "1" in evidence_ids
    assert "2" not in evidence_ids
    assert routes[0]["sensory_level"] == "Low"  # not High, since the 999-count sensor was correctly excluded


def test_disjoint_walk_segments_do_not_create_a_fake_bridging_match():
    # Two SEPARATE walk steps (e.g. walk-to-station, then walk-from-a-
    # different-station after alighting) must each be checked as their
    # OWN path, not concatenated into one flat line -- concatenating
    # would create a fake straight-line segment connecting the end of
    # one walk chunk to the start of a totally different one, and a
    # sensor could wrongly appear "close" to that fake bridging line.
    route = {
        "route_id": "route-1",
        "duration_minutes": 20,
        "distance_metres": 1500,
        "legs": [{
            "steps": [
                {"travelMode": "WALK", "polyline": {"encodedPolyline": "???o}@"}},       # (0,0)-(0,0.01)
                {"travelMode": "TRANSIT", "polyline": {"encodedPolyline": "????kJ"}},
                {"travelMode": "WALK", "polyline": {"encodedPolyline": "_ibE_seK"}},     # a separate, distant walk chunk
            ]
        }],
        "geometry": {"encoding": "google_encoded_polyline", "value": "???o}@"},
    }
    # sensor sitting roughly on the fake straight line BETWEEN the two
    # disjoint walk chunks, but not actually near either real walk path
    sensor_on_fake_bridge = (location(1, 0.05, 0.05),)
    routes = score_candidate_routes([route], sensor_on_fake_bridge, [reading(1, 999)], threshold=25)
    # should NOT match (too far from both real walk paths) -- if the old
    # flat-concatenation bug were present, this could wrongly match a
    # fake bridging segment and falsely report High
    assert routes[0]["sensory_level"] == "Unknown"