from __future__ import annotations
 
import sys
from pathlib import Path

from app.ai.route_scoring import decode_polyline, score_candidate_routes 

GOOGLE_EXAMPLE_POLYLINE = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
GOOGLE_EXAMPLE_POINTS = [(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)]
ENCODED_EQUATOR_LINE = "???o}@"  # (0, 0) to (0, 0.01) -- matches Vince's original test fixtures
 
 
def make_route(route_id="route-1", duration=22, polyline=GOOGLE_EXAMPLE_POLYLINE):
    """
    Realistic default: a single WALK step covering the whole polyline --
    matches the real Google contract shape (legs[].steps[].travelMode),
    which score_candidate_routes() now requires to find any walkable
    geometry at all. Use make_route_no_walk_steps() below to specifically
    test the "no usable walk segments" case.
    """
    return {
        "route_id": route_id,
        "duration_minutes": duration,
        "distance_metres": 2400,
        "legs": [{"steps": [{"travelMode": "WALK", "polyline": {"encodedPolyline": polyline}}]}],
        "geometry": {"encoding": "google_encoded_polyline", "value": polyline},
    }
 
 
def make_route_no_walk_steps(route_id="route-1", duration=22, polyline=GOOGLE_EXAMPLE_POLYLINE):
    """A route whose only step is TRANSIT -- no walking at all."""
    return {
        "route_id": route_id,
        "duration_minutes": duration,
        "distance_metres": 2400,
        "legs": [{"steps": [{"travelMode": "TRANSIT", "polyline": {"encodedPolyline": polyline}}]}],
        "geometry": {"encoding": "google_encoded_polyline", "value": polyline},
    }
 
 
def make_sensor(sensor_id=5, lat=38.5, lon=-120.2, count=40.0, availability="available"):
    return {
        "sensor_id": sensor_id,
        "name": f"Sensor {sensor_id}",
        "latitude": lat,
        "longitude": lon,
        "pedestrian_count_per_minute": count,
        "observed_at": "2026-08-09T12:00:00Z",
        "freshness_minutes": 2,
        "availability": availability,
    }
 
 
def test_decode_polyline_matches_google_canonical_example():
    # Verified against Google's OWN documented example -- if this ever
    # fails, the decoder itself is broken, not the logic built on it.
    result = decode_polyline(GOOGLE_EXAMPLE_POLYLINE)
    assert len(result) == len(GOOGLE_EXAMPLE_POINTS)
    for (lat, lon), (exp_lat, exp_lon) in zip(result, GOOGLE_EXAMPLE_POINTS):
        assert abs(lat - exp_lat) < 0.001
        assert abs(lon - exp_lon) < 0.001
 
 
def test_sensor_over_threshold_produces_high_with_hotspot():
    result = score_candidate_routes(
        [make_route()], [make_sensor(count=40.0)], crowd_threshold=25.0
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "High"
    assert route["hotspot"] is not None
    assert route["hotspot"]["sensor_id"] == 5
    assert route["hotspot"]["exceeds_threshold_by"] == 15.0
 
 
def test_sensor_under_threshold_produces_low():
    result = score_candidate_routes(
        [make_route()], [make_sensor(count=10.0)], crowd_threshold=25.0
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "Low"
    assert route["hotspot"] is None
 
 
def test_high_result_has_no_confidence_tier_since_its_a_confirmed_fact():
    result = score_candidate_routes(
        [make_route()], [make_sensor(count=40.0)], crowd_threshold=25.0
    )
    assert result["routes"][0]["sensory_level"] == "High"
    assert result["routes"][0]["confidence"] is None
 
 
def test_low_confidence_tier_one_usable_sensor():
    result = score_candidate_routes(
        [make_route()], [make_sensor(sensor_id=1, count=10.0)], crowd_threshold=25.0
    )
    assert result["routes"][0]["sensory_level"] == "Low"
    assert result["routes"][0]["confidence"] == "low"
 
 
def test_medium_confidence_tier_two_usable_sensors():
    sensors = [
        make_sensor(sensor_id=1, lat=38.5, lon=-120.2, count=10.0),
        make_sensor(sensor_id=2, lat=38.5, lon=-120.2, count=8.0),
    ]
    result = score_candidate_routes([make_route()], sensors, crowd_threshold=25.0)
    assert result["routes"][0]["confidence"] == "medium"
 
 
def test_high_confidence_tier_three_or_more_usable_sensors():
    sensors = [
        make_sensor(sensor_id=1, lat=38.5, lon=-120.2, count=10.0),
        make_sensor(sensor_id=2, lat=38.5, lon=-120.2, count=8.0),
        make_sensor(sensor_id=3, lat=38.5, lon=-120.2, count=6.0),
    ]
    result = score_candidate_routes([make_route()], sensors, crowd_threshold=25.0)
    assert result["routes"][0]["confidence"] == "high"
 
 
def test_unknown_result_has_no_confidence_tier():
    result = score_candidate_routes([make_route()], [], crowd_threshold=25.0)
    assert result["routes"][0]["sensory_level"] == "Unknown"
    assert result["routes"][0]["confidence"] is None
 
 
def test_no_sensors_at_all_produces_unknown():
    result = score_candidate_routes([make_route()], [], crowd_threshold=25.0)
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"
    assert route["coverage"] == "no_available_sensor_evidence"
 
 
def test_stale_sensor_never_produces_high_even_with_extreme_count():
    # The most important test: a stale sensor reading 999 (way over any
    # threshold) must NOT be trusted -- Data Integrity holds even when
    # ignoring stale data means discarding a dramatic-looking number.
    result = score_candidate_routes(
        [make_route()],
        [make_sensor(count=999.0, availability="stale")],
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"
    assert route["hotspot"] is None
 
 
def test_missing_sensor_availability_never_produces_high():
    result = score_candidate_routes(
        [make_route()],
        [make_sensor(count=999.0, availability="missing")],
        crowd_threshold=25.0,
    )
    assert result["routes"][0]["sensory_level"] == "Unknown"
 
 
def test_far_away_sensor_excluded_from_catchment():
    far_sensor = make_sensor(lat=-37.8136, lon=144.9631, count=999.0)  # real Melbourne, thousands of km from the test polyline's US coordinates
    result = score_candidate_routes([make_route()], [far_sensor], crowd_threshold=25.0)
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"  # far sensor never counted as evidence
    assert route["coverage"] == "no_available_sensor_evidence"
 
 
def test_missing_geometry_produces_unknown_not_crash():
    bad_route = {"route_id": "route-x", "duration_minutes": 10, "distance_metres": 100, "legs": [], "geometry": None}
    result = score_candidate_routes([bad_route], [], crowd_threshold=25.0)
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"
    assert route["coverage"] == "geometry_unavailable"
 
 
def test_recommendation_selects_fastest_among_low_routes():
    routes = [make_route("route-1", duration=28), make_route("route-2", duration=22)]
    sensors = [make_sensor(count=10.0)]  # Low for both, since both share the same test polyline
    result = score_candidate_routes(routes, sensors, crowd_threshold=25.0)
    assert result["recommendation"]["route_id"] == "route-2"  # the faster of the two Low routes
    assert result["recommendation"]["lower_crowd_alternative_available"] is True
    assert result["recommendation"]["trade_off"] is not None
 
 
def test_no_low_routes_produces_honest_no_recommendation_not_forced_fallback():
    # Regression test for a real design fix: the original route_service.py
    # MOCK fell back to recommending the fastest route even when none were
    # confirmed Low -- that would violate DEV-US1.2-01's own Failure
    # Handling acceptance criterion. This must NOT happen.
    routes = [make_route("route-1"), make_route("route-2")]
    sensors = [make_sensor(count=999.0)]  # High for both
    result = score_candidate_routes(routes, sensors, crowd_threshold=25.0)
    assert result["recommendation"]["route_id"] is None
    assert result["recommendation"]["lower_crowd_alternative_available"] is False
    assert result["recommendation"]["trade_off"] is None
    assert "No route has sufficient" in result["recommendation"]["reason"]
    for route in result["routes"]:
        assert route["recommended"] is False
 
 
def test_response_shape_matches_contract_keys():
    result = score_candidate_routes([make_route()], [make_sensor()], crowd_threshold=25.0)
    assert set(result.keys()) == {"routes", "recommendation", "metadata"}
    route = result["routes"][0]
    for key in ["route_id", "duration_minutes", "distance_metres", "legs", "geometry",
                "sensory_level", "sensor_evidence", "hotspot", "coverage", "confidence", "recommended", "data_mode"]:
        assert key in route
 
 
# ---------------------------------------------------------------------------
# Direct/proxy evidence hierarchy (Vince's design, adopted into this file
# after a real parallel-build merge conflict -- see module docstring).
# These three replay Vince's own original test scenarios, translated into
# this file's sensor_observations field shape, to prove the hybrid
# genuinely preserves his evidence-hierarchy behaviour, not just claims to.
# ---------------------------------------------------------------------------
 
def test_direct_evidence_takes_precedence_over_higher_proxy_count():
    # A close (direct-tier) sensor reading LOW must win over a farther
    # (proxy-tier) sensor reading HIGH -- proxy is never blended in or
    # allowed to override direct evidence, even when its count is worse.
    result = score_candidate_routes(
        [make_route(polyline=ENCODED_EQUATOR_LINE)],
        [
            make_sensor(sensor_id=1, lat=0.00045, lon=0.005, count=20.0),  # direct, Low
            make_sensor(sensor_id=2, lat=0.001, lon=0.005, count=80.0),    # proxy, would be High
        ],
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["coverage"] == "direct"
    assert route["sensory_level"] == "Low"
    assert [e["sensor_id"] for e in route["sensor_evidence"]] == [1]
 
 
def test_direct_tier_high_count_sets_high_with_correct_hotspot():
    result = score_candidate_routes(
        [make_route(polyline=ENCODED_EQUATOR_LINE)],
        [
            make_sensor(sensor_id=1, lat=0.0003, lon=0.005, count=20.0),  # direct, under threshold
            make_sensor(sensor_id=2, lat=0.0005, lon=0.005, count=31.0),  # direct, over threshold
        ],
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "High"
    assert route["hotspot"]["sensor_id"] == 2
    assert route["hotspot"]["exceeds_threshold_by"] == 6.0
 
 
def test_proxy_tier_used_only_when_no_direct_evidence_exists():
    # No direct-tier sensor at all -- proxy tier should be used as a
    # genuine fallback, not ignored entirely.
    result = score_candidate_routes(
        [make_route(polyline=ENCODED_EQUATOR_LINE)],
        [make_sensor(sensor_id=1, lat=0.0012, lon=0.005, count=10.0)],  # proxy only
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["coverage"] == "proxy"
    assert route["sensory_level"] == "Low"
 
 
def test_stale_and_outside_proxy_radius_both_resolve_unknown():
    result = score_candidate_routes(
        [make_route(polyline=ENCODED_EQUATOR_LINE)],
        [
            make_sensor(sensor_id=1, lat=0.0003, lon=0.005, count=10.0, availability="stale"),  # direct but stale
            make_sensor(sensor_id=2, lat=0.002, lon=0.005, count=10.0),  # available but outside proxy radius entirely
        ],
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"
 
 
# ---------------------------------------------------------------------------
# Walk-only geometry matching -- real bug caught on a live run: sensors
# near a TRANSIT segment's geometric path (e.g. an underground train
# swinging near Docklands) were being matched even though the commuter
# was never actually walking there. Only WALK-mode steps should count.
# ---------------------------------------------------------------------------
 
def test_transit_only_route_has_no_walkable_geometry():
    result = score_candidate_routes(
        [make_route_no_walk_steps(polyline=ENCODED_EQUATOR_LINE)],
        [make_sensor(lat=0.00045, lon=0.005, count=10.0)],
        crowd_threshold=25.0,
    )
    route = result["routes"][0]
    assert route["sensory_level"] == "Unknown"
    assert route["coverage"] == "geometry_unavailable"
 
 
def test_sensor_near_transit_segment_not_walk_segment_is_excluded():
    # A route with a real WALK step near the equator AND a TRANSIT step
    # whose geometry happens to swing near a totally different location
    # (the Google canonical example coordinates, ~40N/120W). A sensor
    # sitting at that transit-only location must NOT be matched, even
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
    sensors = [
        make_sensor(sensor_id=1, lat=0.00045, lon=0.005, count=10.0),      # near the WALK step -- should match
        make_sensor(sensor_id=2, lat=40.7, lon=-120.95, count=999.0),      # near the TRANSIT step only -- must NOT match
    ]
    result = score_candidate_routes([route], sensors, crowd_threshold=25.0)
    route_result = result["routes"][0]
    evidence_ids = [e["sensor_id"] for e in route_result["sensor_evidence"]]
    assert 1 in evidence_ids
    assert 2 not in evidence_ids
    assert route_result["sensory_level"] == "Low"  # not High, since the 999-count sensor was correctly excluded
 
 
def test_ref_lat_consistent_across_route_and_sensor_projection():
    # Regression test for the projection-consistency bug: route geometry
    # and every sensor checked against it must be projected using the
    # SAME reference latitude, not each deriving their own. This doesn't
    # assert exact distance values (that would overfit to the specific
    # projection math) -- it asserts that a sensor placed virtually AT a
    # point on the route line measures as very close to zero distance,
    # which would silently drift if route and sensor used different
    # reference latitudes.
    route = make_route(polyline=ENCODED_EQUATOR_LINE)
    sensor_at_route_start = make_sensor(sensor_id=1, lat=0.0, lon=0.0, count=10.0)
    result = score_candidate_routes([route], [sensor_at_route_start], crowd_threshold=25.0)
    route_result = result["routes"][0]
    assert route_result["sensor_evidence"][0]["_distance_m"] < 1.0
 