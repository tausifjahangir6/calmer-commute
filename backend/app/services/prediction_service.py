"""Live forecast integration, backed by the AI team's validated Random
Forest model where available; falls back to the original deterministic
placeholder when model artifacts haven't been generated in this
environment (see app/ai/forecast.py).

See ai/docs/AI-US2.2-01_writeup.md for model selection, tuning
methodology, and full validated results (MAE 54.1, RMSE 143.2,
time-ordered holdout).
"""

from datetime import datetime
from zoneinfo import ZoneInfo

from app.ai.forecast import predict_count

MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")


def get_prediction(sensor_id: str, threshold: float, horizon_minutes: int) -> dict:
    """Same function signature and response keys as the original
    placeholder, per API_CONTRACT.md's component replacement boundary rules.
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

    return {
        "sensor_id": sensor_id,
        "forecast_horizon_minutes": horizon_minutes,
        "predicted_count_per_minute": predicted_count,
        "predicted_level": predicted_level,
        "crowd_threshold": threshold,
        "model_version": prediction.model_version,
        "confidence": prediction.confidence,
        "validation_status": prediction.validation_status,
        "generated_at": datetime.now(MELBOURNE_TZ).isoformat(),
        "data_mode": prediction.data_mode,
        "limitation": prediction.limitation or (
            "Forecast reflects hourly pedestrian density trained on City of "
            "Melbourne open data; it is a proxy for one aspect of sensory "
            "load, not a safety or accessibility guarantee. See "
            "ai/docs/AI-US2.2-01_writeup.md for full methodology and limitations."
        ),
    }