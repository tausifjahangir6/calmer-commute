"""Live forecast integration, backed by the AI team's validated Random
Forest model where available; falls back to the original deterministic
placeholder when model artifacts haven't been generated in this
environment (see app/ai/forecast.py).

See ai/docs/AI-US2.2-01_writeup.md for model selection, tuning
methodology, and full validated results (MAE 54.1, RMSE 143.2,
time-ordered holdout).
"""

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from flask import current_app

from app.ai.forecast import predict_count

MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")


def classify_crowd_level(predicted_count_per_minute: float | None) -> str:
    """
    Absolute LOW/MEDIUM/HIGH/UNKNOWN classification, per
    AI_Team_Route_Scoring_Expectations.docx's explicit request. Bounds
    come from database/schema/01_schema.sql's density_band table,
    converted from hourly to per-minute units (see config.py's
    CROWD_LEVEL_LOW_MAX_PER_MINUTE / CROWD_LEVEL_MEDIUM_MAX_PER_MINUTE for
    the conversion and its documented limitation). Boundaries are
    non-overlapping by construction (<=/<=/else), matching density_band's
    own fix for the overlapping-bounds bug in "the sample" it replaces.

    THIS IS A SEPARATE FIELD FROM predicted_level, not a replacement:
    predicted_level answers "is this above THIS USER's personal
    crowd_threshold" (binary High/Low, the live contract's existing,
    tested behaviour per INTEGRATION_GUIDE.md). crowd_level answers
    "where does this sit on a fixed, documented, four-band scale" (the
    route-scoring team's explicit ask). Both are legitimate, answer
    different questions, and this function changes neither predicted_level
    nor any existing response field.
    """
    if predicted_count_per_minute is None:
        return "Unknown"
    low_max = current_app.config["CROWD_LEVEL_LOW_MAX_PER_MINUTE"]
    medium_max = current_app.config["CROWD_LEVEL_MEDIUM_MAX_PER_MINUTE"]
    if predicted_count_per_minute <= low_max:
        return "Low"
    if predicted_count_per_minute <= medium_max:
        return "Medium"
    return "High"


def get_prediction(sensor_id: str, threshold: float, horizon_minutes: int) -> dict:
    """Same function signature and response keys as the original
    placeholder, per API_CONTRACT.md's component replacement boundary rules
    -- plus forecast_timestamp, added per
    AI_Team_Route_Scoring_Expectations.docx's example output shape.
    """

    prediction = predict_count(sensor_id, horizon_minutes)
    predicted_count = prediction.predicted_count_per_minute

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
        "crowd_level": classify_crowd_level(predicted_count),
        "crowd_threshold": threshold,
        "model_version": prediction.model_version,
        "confidence": prediction.confidence,
        "validation_status": prediction.validation_status,
        "generated_at": generated_at_dt.isoformat(),
        "data_mode": prediction.data_mode,
        "limitation": prediction.limitation or (
            "Forecast reflects hourly pedestrian density trained on City of "
            "Melbourne open data; it is a proxy for one aspect of sensory "
            "load, not a safety or accessibility guarantee. See "
            "ai/docs/AI-US2.2-01_writeup.md for full methodology and limitations."
        ),
    }