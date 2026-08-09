"""
load_artifacts.py
THE function the Flask backend calls at startup -- loads the pre-trained
model and its two auxiliary lookups from disk in well under a second,
instead of retraining on 1.4M rows (which is what would happen if the
backend imported run_models_validated.py directly).

Usage in the backend, roughly:

    from load_artifacts import load_forecast_artifacts
    from rf_explain import next_hour_forecast

    model, sensor_map, volatility_lookup = load_forecast_artifacts()
    # cache these three at app startup (e.g. as module-level globals or on
    # Flask's `app` object) -- do NOT call load_forecast_artifacts() per
    # request, defeats the point of pre-training.

    # per request:
    result = next_hour_forecast(
        sensor_id=..., model=model, sensor_map=sensor_map,
        latest_row=..., volatility_lookup=volatility_lookup,
        user_context={"sensitivity": ...}, base_thresholds=...,
    )
"""
from __future__ import annotations
from pathlib import Path
import json
import joblib
import pandas as pd

ARTIFACTS_DIR = Path(__file__).resolve().parent  # ai/models/ -- same folder save_model.py writes to


def load_forecast_artifacts(artifacts_dir: Path | None = None):
    """
    Returns (model, sensor_map, volatility_lookup).
    Raises FileNotFoundError with a clear message if save_model.py hasn't
    been run yet -- better than a confusing joblib/pandas error deep in
    Flask's startup logs.
    """
    d = artifacts_dir or ARTIFACTS_DIR
    model_path = d / "rf_model.joblib"
    sensor_map_path = d / "sensor_map.json"
    volatility_path = d / "volatility_lookup.csv"

    for p in (model_path, sensor_map_path, volatility_path):
        if not p.exists():
            raise FileNotFoundError(
                f"{p} not found. Run `python save_model.py` first to produce the "
                "model artifacts -- they're a build step, not generated automatically "
                "when the backend starts."
            )

    model = joblib.load(model_path)
    sensor_map = {int(k): int(v) for k, v in json.loads(sensor_map_path.read_text()).items()}
    volatility_lookup = pd.read_csv(volatility_path, index_col=0)

    return model, sensor_map, volatility_lookup


def load_latest_features(artifacts_dir: Path | None = None) -> dict[int, dict]:
    """
    Returns {sensor_id: {feature_name: value, ...}}, from latest_features.json
    (see export_latest_features.py). Returns an EMPTY dict rather than
    raising if the file doesn't exist yet -- unlike the core model
    artifacts, this is something a route can check per-request and 404
    cleanly for, not something that should crash the whole app at startup.
    """
    d = artifacts_dir or ARTIFACTS_DIR
    path = d / "latest_features.json"
    if not path.exists():
        return {}
    raw = json.loads(path.read_text())
    return {int(k): v for k, v in raw.items()}


def load_base_thresholds_optional(artifacts_dir: Path | None = None) -> dict[int, float]:
    """
    Returns {sensor_id: threshold}, from base_thresholds.json (see
    export_base_thresholds.py). Returns an EMPTY dict, not a raise, if the
    file doesn't exist -- alert thresholds are an enhancement on top of
    the core forecast (Option A / user-threshold integration), not a hard
    requirement to serve a forecast number at all.
    """
    d = artifacts_dir or ARTIFACTS_DIR
    path = d / "base_thresholds.json"
    if not path.exists():
        return {}
    return {int(k): float(v) for k, v in json.loads(path.read_text()).items()}


if __name__ == "__main__":
    import time
    start = time.time()
    model, sensor_map, volatility_lookup = load_forecast_artifacts()
    elapsed = time.time() - start
    print(f"Loaded model + {len(sensor_map)} sensors + volatility lookup in {elapsed:.3f}s")
    print("(compare this to however long `python run_models_validated.py` takes to train from scratch)")