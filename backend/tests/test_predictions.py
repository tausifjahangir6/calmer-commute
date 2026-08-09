def test_prediction_is_transparently_unvalidated(client):
    response = client.get("/api/predictions?sensor_id=5&crowd_threshold=25")
    body = response.get_json()

    assert response.status_code == 200
    assert body["forecast_horizon_minutes"] == 60
    assert body["data_mode"] == "mock"
    assert body["validation_status"] == "not_validated"
    assert body["confidence"] is None


def test_prediction_requires_sensor_id(client):
    response = client.get("/api/predictions")

    assert response.status_code == 400
    assert response.get_json()["error"]["details"]["field"] == "sensor_id"

