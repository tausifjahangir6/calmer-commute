import pandas as pd
from datetime import datetime, timedelta

import app.ai.forecast as forecast_module


def _force_placeholder_mode(monkeypatch):
    """
    Force the mock/placeholder path regardless of whether THIS machine
    happens to have run save_model.py -- tests must not depend on
    developer machine state (BUILD_QUALITY.md section 2). Without this,
    the test below would pass in CI (no model file) but fail on any
    machine that has actually trained the model locally.
    """
    monkeypatch.setattr(forecast_module, "_artifacts_loaded", False)
    monkeypatch.setattr(forecast_module, "_load_error", "forced-for-test")


def test_prediction_is_transparently_unvalidated(client, monkeypatch):
    _force_placeholder_mode(monkeypatch)

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


def test_prediction_is_validated_when_model_available(client, monkeypatch):
    """
    Proves the live path works WITHOUT depending on the real ~1.3GB model
    file being present -- injects a fake model + fake artifacts via
    monkeypatch instead, so this test is fast, deterministic and runs
    identically in CI and on any developer's machine.
    """
    monkeypatch.setattr(forecast_module, "_artifacts_loaded", True)
    monkeypatch.setattr(forecast_module, "_load_error", None)
    monkeypatch.setattr(forecast_module, "_sensor_map", {5: 0})
    monkeypatch.setattr(forecast_module, "_latest_features", {
        5: {
            "is_weekend": 0, "is_cbd": 1, "obs_in_window_24h": 24,
            "hour_sin": 0.0, "hour_cos": 1.0, "dow_sin": 0.0, "dow_cos": 1.0,
            "lag_24h": 100, "lag_168h": 120, "rolling_mean_24h": 110.0,
            "sensor_name": "Test Sensor", "timestamp": "2026-08-09T08:00:00",
        },
    })
    monkeypatch.setattr(forecast_module, "_base_thresholds", {})

    # explain_forecast_rf() needs a DataFrame indexed by sensor_id with a
    # volatility_tier column -- omitting this was the actual bug caught by
    # running this test for real: it's not optional, the real
    # calc_sensor_volatility() output always has this shape.
    fake_volatility = pd.DataFrame(
        {"cv": [0.1], "volatility_tier": ["low"]},
        index=pd.Index([5], name="sensor_id"),
    )
    monkeypatch.setattr(forecast_module, "_volatility_lookup", fake_volatility)

    class FakeModel:
        def predict(self, X):
            return [15.0] * len(X)

    monkeypatch.setattr(forecast_module, "_model", FakeModel())

    response = client.get("/api/predictions?sensor_id=5&crowd_threshold=25")
    body = response.get_json()

    assert response.status_code == 200
    assert body["data_mode"] == "live"
    assert body["validation_status"] == "validated"
    assert body["predicted_count_per_minute"] is not None
    assert body["model_version"] == "crowd-forecast-rf-v1"


def test_prediction_unknown_for_unmapped_sensor(client, monkeypatch):
    """Missing evidence must map to Unknown, never silently to Low --
    exercised here for a sensor_id the model has no feature snapshot for,
    even though the model itself is available."""
    monkeypatch.setattr(forecast_module, "_artifacts_loaded", True)
    monkeypatch.setattr(forecast_module, "_load_error", None)
    monkeypatch.setattr(forecast_module, "_latest_features", {})

    response = client.get("/api/predictions?sensor_id=999&crowd_threshold=25")
    body = response.get_json()

    assert response.status_code == 200
    assert body["predicted_level"] == "Unknown"
    assert body["predicted_count_per_minute"] is None


def test_forecast_timestamp_equals_generated_at_plus_horizon(client, monkeypatch):
    """
    forecast_timestamp must equal generated_at + forecast_horizon_minutes
    exactly -- required by AI_Team_Route_Scoring_Expectations.docx's
    example output shape (forecast_timestamp represents the HOUR BEING
    FORECAST, not when the prediction was computed; generated_at is the
    latter). A consumer previously had to compute this manually.

    Uses the mock/placeholder path (deterministic regardless of local
    machine state, same pattern as the other tests here) since this test
    is about the timestamp arithmetic, not the forecast value itself --
    the arithmetic must hold in every response, live or placeholder.
    """
    _force_placeholder_mode(monkeypatch)

    response = client.get("/api/predictions?sensor_id=5&crowd_threshold=25")
    body = response.get_json()

    assert response.status_code == 200
    assert "forecast_timestamp" in body
    assert "generated_at" in body  # confirm we didn't accidentally remove the existing field

    generated_at = datetime.fromisoformat(body["generated_at"])
    forecast_timestamp = datetime.fromisoformat(body["forecast_timestamp"])

    assert forecast_timestamp - generated_at == timedelta(minutes=body["forecast_horizon_minutes"])
    # Must carry the Melbourne UTC offset, not be a naive datetime --
    # matches generated_at's own existing timezone handling.
    assert forecast_timestamp.tzinfo is not None
    assert forecast_timestamp.utcoffset() == generated_at.utcoffset()