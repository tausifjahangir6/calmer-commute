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


class _ConstantModel:
    """Fake model returning a fixed raw HOURLY forecast value, so we can
    test exact crowd_level boundaries without needing the real 1.3GB
    model or real training data."""
    def __init__(self, value):
        self.value = value

    def predict(self, X):
        return [self.value] * len(X)


def _prepare_live_sensor(monkeypatch, raw_hourly_forecast):
    """Same fake-artifacts pattern as test_prediction_is_validated_when_model_available,
    parameterised on the raw hourly forecast value so boundary tests can
    control it precisely."""
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
    fake_volatility = pd.DataFrame(
        {"cv": [0.1], "volatility_tier": ["low"]},
        index=pd.Index([5], name="sensor_id"),
    )
    monkeypatch.setattr(forecast_module, "_volatility_lookup", fake_volatility)
    monkeypatch.setattr(forecast_module, "_model", _ConstantModel(raw_hourly_forecast))


def test_crowd_level_medium_band(client, monkeypatch):
    """A raw hourly forecast of 100 (100/60 ~= 1.667 people/minute) sits
    inside density_band's Medium range (51-150 hourly, converted to
    ~0.833-2.5 per minute) -- the tier this gap-fix was actually about."""
    _prepare_live_sensor(monkeypatch, raw_hourly_forecast=100.0)

    response = client.get("/api/predictions?sensor_id=5&crowd_threshold=25")
    body = response.get_json()

    assert response.status_code == 200
    assert body["crowd_level"] == "Medium"
    # predicted_level (the existing, unrelated, threshold-relative field)
    # must be untouched by this change -- confirms crowd_level is additive.
    assert "predicted_level" in body


def test_crowd_level_boundaries_match_density_band_exactly(client, monkeypatch):
    """
    Verifies the /60 per-minute conversion reproduces density_band's exact
    integer boundaries (Low <=50, Medium 51-150, High >=151, all hourly)
    at each edge, after rounding predicted_count_per_minute to 2 decimals
    -- the same rounding forecast.py always applies. This is the
    boundary-condition coverage requested against density_band's own
    CHECK-constraint semantics.
    """
    cases = [
        (50.0, "Low"),      # density_band Low upper bound, inclusive
        (51.0, "Medium"),   # density_band Medium lower bound, inclusive
        (150.0, "Medium"),  # density_band Medium upper bound, inclusive
        (151.0, "High"),    # density_band High lower bound, inclusive
    ]
    for raw_hourly, expected_level in cases:
        _prepare_live_sensor(monkeypatch, raw_hourly_forecast=raw_hourly)

        response = client.get("/api/predictions?sensor_id=5&crowd_threshold=25")
        body = response.get_json()

        assert body["crowd_level"] == expected_level, (
            f"raw hourly forecast {raw_hourly} -> expected {expected_level}, "
            f"got {body['crowd_level']} "
            f"(predicted_count_per_minute={body['predicted_count_per_minute']})"
        )


def test_crowd_level_unknown_when_no_forecast(client, monkeypatch):
    """crowd_level must follow the same Unknown rule as predicted_level --
    missing evidence is Unknown, never a guessed band. Same
    AI_Team_Route_Scoring_Expectations.docx requirement ("If there is not
    enough valid data, the result should be UNKNOWN instead of forcing a
    prediction") applied to the new field."""
    monkeypatch.setattr(forecast_module, "_artifacts_loaded", True)
    monkeypatch.setattr(forecast_module, "_load_error", None)
    monkeypatch.setattr(forecast_module, "_latest_features", {})

    response = client.get("/api/predictions?sensor_id=999&crowd_threshold=25")
    body = response.get_json()

    assert body["crowd_level"] == "Unknown"