"""
export_latest_features.py
INTERIM STAND-IN for a live feature ingestion pipeline, which doesn't
exist yet. Produces a small per-sensor snapshot of the most recent known
feature row (lag_24h, lag_168h, rolling_mean_24h, obs_in_window_24h,
hour_sin/cos, dow_sin/cos, is_weekend, is_cbd, sensor_name, timestamp),
so the Flask route has real feature values to call next_hour_forecast()
with instead of nothing.

IMPORTANT CAVEAT, not swept under the rug: the "latest row" here is the
most recent row that already exists in the historical dataset -- meaning
its target_count is already known/observed. This demonstrates the
prediction MECHANISM working end-to-end, but is not a genuine "predict an
hour that hasn't happened yet" forecast. A real live pipeline would
instead construct a feature row for the NEXT, not-yet-observed hour,
carrying forward the same lag_24h/lag_168h logic (yesterday's and last
week's count at that upcoming hour, both already known) rather than
reusing a fully historical row. That's real, separate work for whenever
DEV-US1.1-01's ingestion job exists -- this script is scaffolding to
unblock the Flask route today, not the final design.

Usage:
    python export_latest_features.py
Writes latest_features.json into this script's own folder (ai/models/).
"""
import sys
from pathlib import Path
import json
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data
from run_models_validated import DATA_PATH

OUT_PATH = Path(__file__).resolve().parent / "latest_features.json"

FEATURE_COLS = ["is_weekend", "is_cbd", "obs_in_window_24h",
                "hour_sin", "hour_cos", "dow_sin", "dow_cos",
                "lag_24h", "lag_168h", "rolling_mean_24h"]


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)

    # Most recent row per sensor across the FULL dataset (not just the
    # training split) -- we want the truest "latest known state", and
    # this is a serving-time snapshot, not a training/evaluation step, so
    # there's no leakage concern in using post-training-cutoff rows here.
    latest = df.sort_values("timestamp").groupby("sensor_id").tail(1)

    snapshot = {}
    for _, row in latest.iterrows():
        entry = {col: (None if pd.isna(row[col]) else row[col]) for col in FEATURE_COLS}
        entry["sensor_name"] = row["sensor_name"]
        entry["timestamp"] = row["timestamp"].isoformat()
        # JSON-safe: numpy scalar types don't serialize directly
        for k, v in entry.items():
            if hasattr(v, "item"):
                entry[k] = v.item()
        snapshot[int(row["sensor_id"])] = entry

    OUT_PATH.write_text(json.dumps(snapshot, indent=2))
    print(f"Saved {len(snapshot)} sensor snapshots to {OUT_PATH}")
    print("\nSample (sensor", next(iter(snapshot)), "):")
    print(json.dumps(snapshot[next(iter(snapshot))], indent=2))


if __name__ == "__main__":
    main()
