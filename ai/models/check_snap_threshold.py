"""
check_snap_threshold.py

RUN THIS LOCALLY (needs real internet access to OSM). Snaps your FULL
sensor set (not just 2-3 test sensors) to the real Melbourne CBD walking
graph, then reports a data-derived reliable-snap distance -- replacing
the guessed 50m default (MAX_RELIABLE_SNAP_M in route_scoring.py) with a
real number based on your actual sensors.

HOW TO RUN:
    python check_snap_threshold.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data
from route_scoring import (
    build_walk_graph,
    get_walk_graph_cached,
    snap_sensors_to_graph,
    suggest_reliable_snap_threshold,
    validate_pedestrian_columns,
    MAX_RELIABLE_SNAP_M,
)

# --- Point this at your real dataset ---
DATA_PATH = "../../data/raw/training_20260807.csv"  # adjust to your actual path


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    print(f"Found {len(sensors_df)} unique sensors.")

    print("\nFetching Melbourne CBD walking graph from OSM (10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    print(f"\nSnapping all {len(sensors_df)} sensors to graph edges...")
    mapping = snap_sensors_to_graph(graph, sensors_df)

    print("\n--- Snap distance summary (metres) ---")
    print(mapping["snap_m"].describe())

    for pct in [75, 90, 95]:
        suggested = suggest_reliable_snap_threshold(mapping, percentile=pct)
        print(f"  {pct}th percentile snap distance: {suggested:.1f}m")

    current_default = MAX_RELIABLE_SNAP_M
    unreliable_at_current = (mapping["snap_m"] > current_default).sum()
    print(f"\nCurrent guessed default (MAX_RELIABLE_SNAP_M): {current_default:.0f}m")
    print(
        f"Sensors that would be marked 'unreliable_snap' at this default: "
        f"{unreliable_at_current}/{len(mapping)}"
    )

    out_path = "snap_distance_report.csv"
    mapping.to_csv(out_path, index=False)
    print(f"\nFull per-sensor snap report saved to {out_path}")


if __name__ == "__main__":
    main()