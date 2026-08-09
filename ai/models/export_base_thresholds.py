"""
export_base_thresholds.py
Produces the ONE artifact US1.3 actually needs from this card: a small
JSON file mapping sensor_id -> base alert threshold (75th percentile of
that sensor's training-period traffic).

Deliberately does NOT require sharing the trained model, run_models_validated.py,
or the full 1.4M-row dataset with whoever builds US1.3 -- thresholding and
forecasting are independent pieces of math that happen to feed the same
alert decision. This script is the only thing that needs the raw training
data; everything downstream (alert_thresholds.get_alert_thresholds) only
needs the small output file below.

Usage:
    python export_base_thresholds.py
Writes base_thresholds.json next to this script -- that file is what gets
handed to US1.3, nothing else.
"""
import sys
from pathlib import Path
import json

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data, time_ordered_split
from alert_thresholds import compute_base_thresholds
from run_models_validated import DATA_PATH, TRAIN_END, TEST_START

OUT_PATH = Path(__file__).resolve().parent / "base_thresholds.json"


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)
    train, _ = time_ordered_split(df, TRAIN_END, TEST_START)

    base = compute_base_thresholds(train, quantile=0.75)
    payload = {int(k): round(float(v), 1) for k, v in base.items()}

    OUT_PATH.write_text(json.dumps(payload, indent=2, sort_keys=True))
    print(f"\nWrote {len(payload)} sensor thresholds to {OUT_PATH}")
    print("This file -- not the model, not the dataset -- is what US1.3 needs.")
    print("\nSample:")
    for sid in list(payload)[:5]:
        print(f"  {sid}: {payload[sid]}")


if __name__ == "__main__":
    main()
