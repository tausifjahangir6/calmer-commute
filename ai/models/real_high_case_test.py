"""
real_high_case_test.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data).

Every live run so far in this project used reference_time =
df["timestamp"].max() -- the dataset's most recent row -- which happened
to land overnight (2-3am), when almost nothing is crowded. That means the
High-classification path has NEVER been exercised against real data, only
synthetic unit tests. This finds the actual busiest real moment in your
dataset (using find_peak_reference_time) and reruns the pipeline against
it, to confirm High genuinely triggers correctly on real data.

HOW TO RUN:
    python real_high_case_test.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data
from route_scoring import (
    build_walk_graph,
    get_walk_graph_cached,
    build_route_segments,
    merge_segments_by_street_name,
    snap_sensors_to_blocks,
    join_sensor_mapping,
    score_route,
    validate_pedestrian_columns,
    find_peak_reference_time,
    DEFAULT_CATCHMENT_RADIUS_M,
)

DATA_PATH = "../../data/raw/training_20260807.csv"

# Reuse the same route set as coverage_report.py for a like-for-like
# comparison against the quiet-time results already gathered.
ROUTE_PAIRS = [
    ("Flinders St Station -> State Library", -37.8183, 144.9671, -37.8102, 144.9628),
    ("Bourke St Mall -> Southern Cross Station", -37.8136, 144.9648, -37.8183, 144.9524),
    ("QV Melbourne -> Chinatown", -37.8103, 144.9648, -37.8117, 144.9686),
    ("Melbourne Central -> Federation Square", -37.8100, 144.9628, -37.8180, 144.9691),
    ("RMIT -> Parliament Station", -37.8079, 144.9634, -37.8107, 144.9735),
]


def run_one_route(graph, name, orig_lat, orig_lon, dest_lat, dest_lon, sensors_df, pedestrian_df, base_thresholds, reference_time):
    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None:
        return {"route_name": name, "error": "no path found"}

    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    joined = join_sensor_mapping(blocks, sensor_mapping)

    result = score_route(
        route_id=name,
        segments=joined,
        pedestrian_df=pedestrian_df,
        base_thresholds=base_thresholds,
        reference_time=reference_time,
        snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
    )

    high_segments = [s.segment_id for s in result.segment_scores if s.label == "High"]

    return {
        "route_name": name,
        "route_label": result.label,
        "confidence": result.confidence,
        "coverage_pct": result.coverage_pct,
        "high_segments": high_segments,
    }


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()

    default_time = df["timestamp"].max()
    print(f"Default reference_time (used in every prior run): {default_time}")

    peak_time = find_peak_reference_time(df, base_thresholds)
    if peak_time is None:
        print("\nNo sensor was ever found above its own threshold in the "
              "entire dataset -- this itself would be worth investigating, "
              "since it would mean High can never trigger no matter when "
              "you check.")
        return
    print(f"Busiest real moment found (most sensors simultaneously over threshold): {peak_time}")

    print("\nFetching Melbourne CBD walking graph from OSM (10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    print(f"\n--- Re-scoring the same routes at the BUSIEST real moment ({peak_time}) ---")
    results = []
    for name, olat, olon, dlat, dlon in ROUTE_PAIRS:
        r = run_one_route(graph, name, olat, olon, dlat, dlon, sensors_df, df, base_thresholds, peak_time)
        results.append(r)
        print(f"  -> {r}")

    report = pd.DataFrame(results)
    print("\n--- Summary ---")
    print(report.to_string(index=False))

    high_count = (report["route_label"] == "High").sum() if "route_label" in report.columns else 0
    print(f"\nRoutes classified High at peak time: {high_count}/{len(report)}")
    if high_count == 0:
        print(
            "No route came back High even at the busiest real moment found. "
            "This is worth investigating further -- either these 5 specific "
            "routes genuinely don't pass near any sensor that ever goes "
            "over threshold, or there's a real gap in the High path worth "
            "digging into with a route deliberately chosen through a "
            "known high-traffic sensor location."
        )

    out_path = "real_high_case_test.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull results saved to {out_path}")


if __name__ == "__main__":
    main()