"""Live forecast integration, backed by the AI team's validated Random
Forest model where available; falls back to the original deterministic
placeholder when model artifacts haven't been generated in this
environment (see app/ai/forecast.py).

See ai/docs/AI-US2.2-01_writeup.md for model selection, tuning
methodology, and full validated results (MAE 54.1, RMSE 143.2,
time-ordered holdout).
"""

import json
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

from flask import current_app

from app.ai.forecast import predict_count

MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")
DOD_FORECAST_PATH = Path(__file__).resolve().parents[3] / "ai" / "models" / "dod_forecast.json"


def _load_dod_forecast(sensor_id: str) -> float | None:
    try:
        with open(DOD_FORECAST_PATH) as f:
            dod_forecast = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    return dod_forecast.get(str(sensor_id))

def classify_crowd_level(predicted_count_per_minute: float | None, threshold: float) -> str:
    """
    Threshold-RELATIVE LOW/MEDIUM/HIGH/UNKNOWN classification.

    CHANGED 2026-08-11, deliberate decision: this was originally a FIXED
    scale (density_band-derived, same cutoffs for every user). Reworked to
    scale with the caller's own crowd_threshold instead, so the Medium
    tier is meaningful at whatever sensitivity the user actually set,
    rather than a fixed real-world standard that rarely lines up with a
    low, personal threshold. This means crowd_level is no longer an
    objective, user-independent scale -- it is now a three-tier version
    of predicted_level, sharing the same threshold input.

    Low:    predicted_count <= threshold / 2
    Medium: threshold / 2 < predicted_count <= threshold
    High:   predicted_count > threshold
    """
    if predicted_count_per_minute is None:
        return "Unknown"
    half_threshold = threshold / 2
    if predicted_count_per_minute <= half_threshold:
        return "Low"
    if predicted_count_per_minute <= threshold:
        return "Medium"
    return "High"


def get_prediction(sensor_id: str, threshold: float, horizon_minutes: int, scenario: str | None = None) -> dict:
    """Same function signature and response keys as the original
    placeholder, per API_CONTRACT.md's component replacement boundary rules
    -- plus forecast_timestamp, added per
    AI_Team_Route_Scoring_Expectations.docx's example output shape.

    scenario: when set to the DoD scenario id, serves the precomputed
    2026-08-04 07:00 forecast for this sensor instead of calling the live
    model -- keeps the DoD replay internally consistent (same fixed
    moment for both current AND forecast data), and avoids showing
    today's real live number mislabeled as belonging to that fixed demo
    scenario.
    """

    if scenario == "2026-08-04T07:00":
        dod_value = _load_dod_forecast(sensor_id)
        predicted_count = dod_value
        model_version = "crowd-forecast-rf-v1"
        confidence = "high" if dod_value is not None else None
        validation_status = "validated" if dod_value is not None else "not_validated"
        data_mode = "live" if dod_value is not None else "mock"
        limitation = (
            "Precomputed forecast for the fixed 2026-08-04 07:00 DoD scenario "
            "-- see ai/models/build_dod_forecast.py. Not a live recomputation."
        ) if dod_value is not None else "No precomputed DoD forecast available for this sensor."
    else:
        prediction = predict_count(sensor_id, horizon_minutes)
        predicted_count = prediction.predicted_count_per_minute
        model_version = prediction.model_version
        confidence = prediction.confidence
        validation_status = prediction.validation_status
        data_mode = prediction.data_mode
        limitation = prediction.limitation

    if predicted_count is None:
        # Missing/insufficient evidence maps to Unknown, never silently to
        # Low -- INTEGRATION_GUIDE.md section 4.3's rule for route scoring,
        # applied here for the same reason.
        predicted_level = "Unknown"
    else:
        predicted_level = "High" if predicted_count > threshold else "Low"

    # Both timestamps are derived from ONE instant, not two separate
    # datetime.now() calls -- guarantees forecast_timestamp - generated_at
    # is exactly horizon_minutes, not off by however long the request took
    # to process.
    generated_at_dt = datetime.now(MELBOURNE_TZ)
    forecast_timestamp_dt = generated_at_dt + timedelta(minutes=horizon_minutes)

    generic_disclaimer = (
        "Forecast reflects hourly pedestrian density trained on City of "
        "Melbourne open data; it is a proxy for one aspect of sensory "
        "load, not a safety or accessibility guarantee. See "
        "ai/docs/AI-US2.2-01_writeup.md for full methodology and limitations."
    )
    # A real, successful live forecast (not the DoD replay, not a missing-
    # data refusal) may carry its OWN specific note from predict_count --
    # e.g. forecast.py's freshness note, or rf_explain's high-volatility
    # warning -- which is additional context on top of the standard
    # disclaimer, not a replacement for it. Every other path's limitation
    # (DoD replay, insufficient data, no model artifacts) is already a
    # complete, standalone explanation, so it keeps its own either/or
    # fallback instead of always being prefixed with the generic text.
    is_live_forecast = scenario != "2026-08-04T07:00" and predicted_count is not None and data_mode == "live"
    combined_limitation = (
        " ".join(filter(None, [generic_disclaimer, limitation]))
        if is_live_forecast
        else (limitation or generic_disclaimer)
    )

    return {
        "sensor_id": sensor_id,
        "forecast_horizon_minutes": horizon_minutes,
        # forecast_timestamp: the hour this prediction is FOR (e.g. "17:00").
        # generated_at: when the prediction was COMPUTED (e.g. "16:00").
        # Both are legitimate and mean different things -- a consumer
        # previously had to compute generated_at + horizon manually to get
        # what forecast_timestamp now gives directly.
        "forecast_timestamp": forecast_timestamp_dt.isoformat(),
        "predicted_count_per_minute": predicted_count,
        "predicted_level": predicted_level,
        "crowd_level": classify_crowd_level(predicted_count, threshold),
        "crowd_threshold": threshold,
        "model_version": model_version,
        "confidence": confidence,
        "validation_status": validation_status,
        "generated_at": generated_at_dt.isoformat(),
        "data_mode": data_mode,
        "limitation": combined_limitation,
    }
