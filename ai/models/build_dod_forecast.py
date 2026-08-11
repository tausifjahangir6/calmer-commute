"""
build_dod_forecast.py
ONE-TIME script, run LOCALLY (not on the EC2 instance -- training_20260807.csv
lives on your own machine, not the server).

Computes an HONEST 4 Aug 2026 08:00 forecast for EVERY sensor that has real
data at the 07:00 snapshot moment -- the exact moment _historical_payload()
already uses for the "current" DoD reading -- run through the ALREADY-
TRAINED, deployed model. Not a re-derived estimate, not today's live
forecast mislabeled as 4 Aug's. Covers every sensor, not just a fixed few,
since which sensor ends up being the DoD hotspot depends on the route the
user picks and can be different every demo run.

Run this from ai/models/ locally, where the model + sensor_map already
exist from training. Produces a small JSON file to copy to the EC2
instance -- no need to move the large training CSV to the server.
"""
import json
import sys
from pathlib import Path

import joblib
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data

DATA_PATH = Path(__file__).resolve().parents[2] / "data" / "raw" / "training_20260807.csv"
MODEL_PATH = Path(__file__).resolve().parent / "rf_model.joblib"
SENSOR_MAP_PATH = Path(__file__).resolve().parent / "sensor_map.json"
OUTPUT_PATH = Path(__file__).resolve().parent / "dod_forecast.json"

# Matches _historical_payload()'s existing hardcoded snapshot moment exactly
# (sensing_date=2026-08-04, hourday=7) -- the forecast target is the NEXT
# hour, 08:00, computed from real data as of 07:00.
TARGET_SNAPSHOT = pd.Timestamp("2026-08-04 07:00:00")

# Same column set, same order, as run_models_validated.py's _tree_features()
# -- must match exactly what the deployed model was actually trained on.
FEATURE_COLS = [
    "is_weekend", "is_cbd", "obs_in_window_24h",
    "hour_sin", "hour_cos", "dow_sin", "dow_cos",
    "lag_24h", "lag_168h", "rolling_mean_24h",
]


def main():
    print(f"Loading model: {MODEL_PATH}")
    model = joblib.load(MODEL_PATH)

    print(f"Loading sensor map: {SENSOR_MAP_PATH}")
    with open(SENSOR_MAP_PATH) as f:
        sensor_map = json.load(f)
    print("sensor_map sample:", dict(list(sensor_map.items())[:5]))

    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(str(DATA_PATH))

    # Every sensor with a real row at this exact moment -- not a fixed
    # list. Whichever sensor ends up being the DoD hotspot on any given
    # demo run, its real forecast is already here.
    all_sensors_at_snapshot = sorted(df[df["timestamp"] == TARGET_SNAPSHOT]["sensor_id"].unique())
    print(f"Found {len(all_sensors_at_snapshot)} sensors with real data at {TARGET_SNAPSHOT}")

    results = {}
    skipped = []
    for sensor_id in all_sensors_at_snapshot:
        row = df[(df["sensor_id"] == sensor_id) & (df["timestamp"] == TARGET_SNAPSHOT)]
        if row.empty:
            skipped.append((sensor_id, "no row"))
            continue
        row = row.iloc[0]

        # sensor_map.json's key type isn't 100% certain from memory -- try
        # both string and int keys rather than assume, so this fails loudly
        # instead of silently using the wrong sensor code.
        sensor_code = sensor_map.get(str(sensor_id), sensor_map.get(sensor_id))
        if sensor_code is None:
            skipped.append((sensor_id, "not in sensor_map"))
            continue

        features = pd.DataFrame([{**{col: row[col] for col in FEATURE_COLS}, "sensor_code": sensor_code}])
        features = features[FEATURE_COLS + ["sensor_code"]]  # enforce exact training column order

        prediction = model.predict(features)[0]
        predicted_count_per_minute = round(max(0.0, prediction) / 60, 2)
        results[str(sensor_id)] = predicted_count_per_minute
        print(f"Sensor {sensor_id}: raw hourly forecast={prediction:.1f} -> per-minute={predicted_count_per_minute}")

    if skipped:
        print(f"\nSkipped {len(skipped)} sensors (left out of the file, not guessed):")
        for sensor_id, reason in skipped:
            print(f"  {sensor_id}: {reason}")

    with open(OUTPUT_PATH, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nSaved {len(results)} sensor forecasts to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()