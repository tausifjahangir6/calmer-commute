"""Transparent forecast placeholder until the AI component supplies a validated model."""

from datetime import datetime, timezone


def get_prediction(sensor_id: str, threshold: float, horizon_minutes: int) -> dict:
    """Return a stable mock value without claiming model validation or confidence."""

    # AI TEAM REPLACEMENT POINT (keep the function signature and response keys):
    #
    # from app.ai.forecast import predict_count
    # prediction = predict_count(sensor_id, horizon_minutes)
    # predicted_count = prediction.predicted_count_per_minute
    # model_version = prediction.model_version
    # confidence = prediction.confidence  # only if the model supports it
    # validation_status = prediction.validation_status
    #
    # Do not expose a model as validated until its time-ordered holdout results
    # and version are recorded. The deterministic value below exists only so
    # frontend and QA can integrate before that implementation arrives.
    predicted_count = float(15 + sum(ord(character) for character in sensor_id) % 24)
    return {
        "sensor_id": sensor_id,
        "forecast_horizon_minutes": horizon_minutes,
        "predicted_count_per_minute": predicted_count,
        "predicted_level": "High" if predicted_count > threshold else "Low",
        "crowd_threshold": threshold,
        "model_version": "placeholder-v1",
        "confidence": None,
        "validation_status": "not_validated",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "data_mode": "mock",
        "limitation": "This deterministic placeholder is not an AI forecast and must not be presented as validated accuracy.",
    }
