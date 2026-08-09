VALID_REQUEST = {
    "origin": "903/8 Pearl River Rd, Docklands VIC 3008",
    "destination": "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000",
    "crowd_threshold": 25,
}


def test_prototype_defaults_prescribe_freddys_weekday_commute(client):
    response = client.get("/api/prototype/defaults")
    body = response.get_json()

    assert response.status_code == 200
    assert body["origin"] == "903/8 Pearl River Rd, Docklands VIC 3008"
    assert body["destination"] == "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000"
    assert body["commute_window"]["days"] == ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    assert body["commute_window"]["start"] == "07:30"
    assert body["commute_window"]["end"] == "08:00"
    assert body["commute_window"]["timezone"] == "Australia/Melbourne"


def test_route_service_maps_unavailable_sensor_evidence_to_unknown():
    from app.services.route_service import compare_routes

    result = compare_routes(VALID_REQUEST, sensors=(), data_mode="mock")

    assert all(route["sensory_level"] == "Unknown" for route in result["routes"])
    assert all(route["sensor_evidence"] == [] for route in result["routes"])


def test_route_comparison_returns_two_explainable_routes(client):
    response = client.post("/api/routes/compare", json=VALID_REQUEST)
    body = response.get_json()

    assert response.status_code == 200
    assert len(body["routes"]) == 2
    assert body["metadata"]["data_mode"] == "mock"
    assert all(route["sensory_level"] in {"High", "Low", "Unknown"} for route in body["routes"])
    assert sum(route["recommended"] for route in body["routes"]) == 1


def test_route_comparison_is_deterministic_for_same_request(client):
    first = client.post("/api/routes/compare", json=VALID_REQUEST).get_json()
    second = client.post("/api/routes/compare", json=VALID_REQUEST).get_json()

    first_counts = [route["sensor_evidence"][0]["pedestrian_count_per_minute"] for route in first["routes"]]
    second_counts = [route["sensor_evidence"][0]["pedestrian_count_per_minute"] for route in second["routes"]]
    assert first_counts == second_counts


def test_high_route_exposes_hotspot_evidence(client):
    response = client.post("/api/routes/compare", json={**VALID_REQUEST, "crowd_threshold": 1})
    body = response.get_json()

    assert all(route["sensory_level"] == "High" for route in body["routes"])
    assert all(route["hotspot"] is not None for route in body["routes"])
    assert body["recommendation"]["lower_crowd_alternative_available"] is False


def test_missing_origin_returns_consistent_validation_error(client):
    response = client.post("/api/routes/compare", json={"destination": "City Library"})
    body = response.get_json()

    assert response.status_code == 400
    assert body["error"]["code"] == "validation_error"
    assert body["error"]["details"]["field"] == "origin"


def test_invalid_threshold_is_rejected(client):
    response = client.post("/api/routes/compare", json={**VALID_REQUEST, "crowd_threshold": -1})

    assert response.status_code == 400
    assert response.get_json()["error"]["details"]["field"] == "crowd_threshold"
