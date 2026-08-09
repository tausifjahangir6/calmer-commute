"""
sensor_gap_diagnostic.py

RUN THIS LOCALLY (uses your real data, no OSM/network needed for this one).

Directly checks whether full_temporal_sweep.py's "0.0% Unknown across
17,332 hours" is genuinely because these sensors have near-perfect uptime,
or something less obvious. For every real sensor, reports the longest gap
(in hours) between consecutive readings, and how many gaps exceed the
4-hour freshness window -- if every sensor genuinely has zero gaps over 4
hours across 2 years, that's a real (if surprising) fact about this
dataset. If some sensors DO have real gaps, but the sweep still showed
0% Unknown, that would point to a logic issue worth investigating further.

HOW TO RUN:
    python sensor_gap_diagnostic.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data
from route_scoring import validate_pedestrian_columns, FRESHNESS_HOURS

DATA_PATH = "../../data/raw/training_20260807.csv"


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    rows = []
    for sensor_id, group in df.groupby("sensor_id"):
        ts = group["timestamp"].sort_values()
        gaps_hours = ts.diff().dt.total_seconds().div(3600).dropna()
        max_gap = gaps_hours.max() if len(gaps_hours) else 0.0
        n_gaps_over_freshness = int((gaps_hours > FRESHNESS_HOURS).sum())
        rows.append({
            "sensor_id": sensor_id,
            "n_observations": len(group),
            "first_obs": ts.min(),
            "last_obs": ts.max(),
            "max_gap_hours": round(max_gap, 1),
            "gaps_over_4h": n_gaps_over_freshness,
        })

    report = pd.DataFrame(rows).sort_values("max_gap_hours", ascending=False)
    print("\n--- Per-sensor gap summary (worst gaps first) ---")
    print(report.to_string(index=False))

    total_gaps = report["gaps_over_4h"].sum()
    sensors_with_gaps = (report["gaps_over_4h"] > 0).sum()
    print(f"\nSensors with at least one gap over {FRESHNESS_HOURS:.0f}h: {sensors_with_gaps}/{len(report)}")
    print(f"Total individual gap-events over {FRESHNESS_HOURS:.0f}h across all sensors: {total_gaps}")

    if total_gaps == 0:
        print(
            "\nGenuinely zero gaps over the freshness window, across every "
            "sensor, for the full 2-year span. This actually supports "
            "full_temporal_sweep.py's 0% Unknown result as real, not a "
            "bug -- these sensors really do have near-perfect uptime in "
            "this dataset."
        )
    else:
        print(
            "\nReal gaps DO exist in the raw data. If full_temporal_sweep.py "
            "still reported 0% Unknown despite this, that's worth "
            "investigating -- check whether the specific sensors used by "
            "the 5 tested routes happen to be among the gap-free ones "
            "(plausible with only 20-48 sensors sampled out of 100), or "
            "whether there's a real logic issue to chase down."
        )

    out_path = "sensor_gap_diagnostic.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull report saved to {out_path}")


if __name__ == "__main__":
    main()
