"""
save_model.py
Serializes the exact tuned Random Forest model evaluated in
run_models_validated.py (MAE 54.1, RMSE 143.2 on the real held-out test
set) so the Flask backend can LOAD a pre-trained model at startup instead
of retraining on 1.4M rows on every container start or every request.

Also saves two auxiliary lookups the forecast/explanation functions need
at inference time and that would otherwise be expensive or awkward to
recompute per request:
  - sensor_map.json       -- sensor_id -> integer code (needed to build
                              feature vectors the same way training did)
  - volatility_lookup.csv -- per-sensor coefficient of variation + tier
                              (needed by explain_forecast_rf's confidence
                              labelling)

Run this ONCE (or whenever the model is retrained/retuned), not per
request and not automatically on every container start -- it's a build
step, not a runtime step.

Usage:
    python save_model.py
Writes rf_model.joblib, sensor_map.json, and volatility_lookup.csv into
this script's own folder (ai/models/).
"""
import sys
from pathlib import Path
import json
import joblib

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data, time_ordered_split
from run_models_validated import run_random_forest_v2, DATA_PATH, TRAIN_END, TEST_START
from rf_explain import calc_sensor_volatility

MODEL_PATH = Path(__file__).resolve().parent / "rf_model.joblib"
SENSOR_MAP_PATH = Path(__file__).resolve().parent / "sensor_map.json"
VOLATILITY_PATH = Path(__file__).resolve().parent / "volatility_lookup.csv"


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)
    train, test = time_ordered_split(df, TRAIN_END, TEST_START)

    print("Training tuned Random Forest (same config as run_models_validated.py)...")
    rf_result = run_random_forest_v2(train, test)
    print("Confirmed MAE/RMSE:", rf_result["metrics"],
          " (expected: MAE ~54.1, RMSE ~143.2 -- if this drifts, don't ship the artifact yet)")

    joblib.dump(rf_result["model"], MODEL_PATH)
    print(f"Saved model to {MODEL_PATH}")

    sensor_map = {int(k): int(v) for k, v in rf_result["sensor_map"].items()}
    SENSOR_MAP_PATH.write_text(json.dumps(sensor_map))
    print(f"Saved sensor map ({len(sensor_map)} sensors) to {SENSOR_MAP_PATH}")

    volatility = calc_sensor_volatility(train)
    volatility.to_csv(VOLATILITY_PATH)
    print(f"Saved volatility lookup to {VOLATILITY_PATH}")

    print("\nDone. These 3 files are what the backend loads at startup -- "
          "not the training data, not run_models_validated.py's training path.")


if __name__ == "__main__":
    main()
