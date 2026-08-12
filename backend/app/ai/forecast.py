"""
app/ai/forecast.py
THE "AI TEAM REPLACEMENT POINT" named in prediction_service.py's original
placeholder comment. Wraps the tuned Random Forest forecast
(ai/models/rf_explain.py) behind the exact contract INTEGRATION_GUIDE.md
section 4.4 specifies.

See ai/docs/AI-US2.2-01_writeup.md for model selection, tuning methodology,
and full validated results: MAE 54.1, RMSE 143.2 on a real time-ordered
holdout (baseline 77.9), never touched during hyperparameter search.

WHY THIS LOADS LAZILY, NOT AT IMPORT TIME:
Model artifacts (rf_model.joblib, sensor_map.json, volatility_lookup.csv --
see ai/models/save_model.py) are gitignored (the model file alone is
~1.3GB, over GitHub's 100MB limit) and must be generated locally. A clean
checkout or CI environment will not have them. Per BUILD_QUALITY.md's
Definition of Done ("the full Docker application starts from a clean
checkout") and section 9 ("responses must remain not_validated, mock or
placeholder" until validated), this module must not crash the whole Flask
app -- or test collection -- if the artifacts simply aren't there yet. It
falls back to the SAME deterministic shape the original placeholder used.
"""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
from zoneinfo import ZoneInfo
import sys
import pandas as pd

MODEL_VERSION = "crowd-forecast-rf-v1"  # confirm naming convention with the team
MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")

# Make ai/models and ai/features importable regardless of HOW this module is
# run -- Docker's PYTHONPATH env var (compose.yaml) covers the container
# case, but running pytest locally has no such env var, so this module must
# not depend on it. backend/app/ai/forecast.py -> parents[3] is the repo
# root (ai/ -> app/ -> backend/ -> root).
_REPO_ROOT = Path(__file__).resolve().parents[3]
for _p in (_REPO_ROOT / "ai" / "models", _REPO_ROOT / "ai" / "features"):
    if str(_p) not in sys.path:
        sys.path.insert(0, str(_p))

_artifacts_loaded = False
_load_error: str | None = None
_model = None
_sensor_map: dict = {}
_volatility_lookup = None
_latest_features: dict = {}
_base_thresholds: dict = {}


def _ensure_artifacts_loaded() -> bool:
    """
    Lazy, one-time load attempt on first real use. Returns True if the real
    model is available, False if we're in placeholder fallback. Never
    raises -- a missing model is an expected, documented state, not an
    application error.
    """
    global _artifacts_loaded, _load_error, _model, _sensor_map, _volatility_lookup
    global _latest_features, _base_thresholds

    if _artifacts_loaded or _load_error is not None:
        return _artifacts_loaded

    try:
        from load_artifacts import (
            load_forecast_artifacts, load_latest_features, load_base_thresholds_optional,
        )
        _model, _sensor_map, _volatility_lookup = load_forecast_artifacts()
        _latest_features = load_latest_features()
        _base_thresholds = load_base_thresholds_optional()
        _artifacts_loaded = True
    except FileNotFoundError as error:
        _load_error = str(error)
        _artifacts_loaded = False

    return _artifacts_loaded


@dataclass
class Prediction:
    predicted_count_per_minute: float | None
    model_version: str
    confidence: str | None
    validation_status: str
    data_mode: str
    limitation: str | None = None


def predict_count(sensor_id: str, horizon_minutes: int) -> Prediction:
    """
    sensor_id arrives as a STRING (the API contract's type); our pipeline
    keys on int location_id -- this function is the conversion boundary.

    NEVER returns a number it can't support: no trained model available,
    an unmappable sensor_id, or a sensor with no feature snapshot all
    return predicted_count_per_minute=None with validation_status/data_mode
    set accordingly -- missing evidence is not Low (INTEGRATION_GUIDE.md
    section 4.3), applied here for the same reason.
    """
    if not _ensure_artifacts_loaded():
        # Same shape the ORIGINAL placeholder used, deliberately -- the
        # expected state until `python save_model.py` has been run in this
        # environment.
        return Prediction(
            predicted_count_per_minute=None,
            model_version="placeholder-v1",
            confidence=None,
            validation_status="not_validated",
            data_mode="mock",
            limitation=(
                "AI model artifacts are not present in this environment; "
                "run save_model.py to enable live forecasts."
            ),
        )

    try:
        sid = int(sensor_id)
    except (TypeError, ValueError):
        return Prediction(
            predicted_count_per_minute=None,
            model_version=MODEL_VERSION,
            confidence=None,
            validation_status="invalid_sensor_id",
            data_mode="unavailable",
        )

    from live_features import get_live_features
    try:
        latest = get_live_features(sid)
    except Exception:
        # Never let a live-fetch failure take down a request that the
        # frozen snapshot could still have served.
        latest = None
    if latest is None:
        latest = _latest_features.get(sid)
    if latest is None:
        return Prediction(
            predicted_count_per_minute=None,
            model_version=MODEL_VERSION,
            confidence=None,
            validation_status="insufficient_data",
            data_mode="unavailable",
        )

    row = pd.Series(latest)
    row["sensor_id"] = sid
    row["timestamp"] = pd.to_datetime(latest["timestamp"])

    from rf_explain import next_hour_forecast
    result = next_hour_forecast(
        sensor_id=sid, model=_model, sensor_map=_sensor_map,
        latest_row=row, volatility_lookup=_volatility_lookup,
        user_context=None, base_thresholds=_base_thresholds,
    )

    if result.get("forecast") is None:
        return Prediction(
            predicted_count_per_minute=None,
            model_version=MODEL_VERSION,
            confidence=None,
            validation_status="insufficient_data",
            data_mode="unavailable",
            limitation=result.get("reason"),
        )

    # HORIZON CAVEAT: the model forecasts the NEXT HOUR ONLY. Every call
    # through routes.py currently passes horizon_minutes=60
    # (Config.FORECAST_HORIZON_MINUTES), so this branch is defensive, not
    # yet exercised in practice via the real endpoint.
    validation_status = "validated" if horizon_minutes == 60 else "validated_horizon_approximated"

    # UNIT CONVERSION CAVEAT: our model predicts an HOURLY count; the
    # contract wants per-minute. Dividing by 60 assumes uniform
    # distribution across the hour -- an approximation, not a measured
    # per-minute rate.
    predicted_count_per_minute = round(result["forecast"] / 60, 2)

    return Prediction(
        predicted_count_per_minute=predicted_count_per_minute,
        model_version=MODEL_VERSION,
        confidence=result.get("confidence"),  # CONFIRM: contract's own example shows null even when validated -- see note below
        validation_status=validation_status,
        data_mode="live",
        limitation=result.get("limitation"),
    )