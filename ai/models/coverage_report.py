"""
coverage_report.py

RUN THIS LOCALLY (needs real internet access to OSM). One route tells you
very little -- this runs the full pipeline (route build -> merge -> 
catchment match -> score) across MANY origin/destination pairs spread
around the CBD, and reports aggregate statistics: how often routes
actually resolve to High/Low vs Unknown, and how coverage looks overall.
This is what "desired results" should be judged against, not a single
example.

HOW TO RUN:
    python coverage_report.py

Edit ROUTE_PAIRS below to add/remove origin-destination pairs relevant to
your app (or generate a larger random sample across the CBD bounding box
if you want a bigger statistical picture).
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
    DEFAULT_CATCHMENT_RADIUS_M,
)

# --- Point this at your real dataset ---
DATA_PATH = "../../data/raw/training_20260807.csv"

# A spread of real CBD origin/destination pairs -- edit to match places
# your app will actually route between. Coordinates are rough CBD
# landmarks; swap in your real ones.
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

    matched = sum(1 for s in result.segment_scores if s.coverage == "matched")
    total = len(result.segment_scores)

    return {
        "route_name": name,
        "raw_edges": len(route_segments),
        "merged_blocks": len(blocks),
        "route_label": result.label,
        "confidence": result.confidence,  # "low"/"medium"/"high", or None for High/Unknown routes
        "coverage_pct": result.coverage_pct,  # raw number, shown alongside the tier
        "segments_resolved": f"{matched}/{total}",
    }


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()
    reference_time = df["timestamp"].max()

    print("Fetching Melbourne CBD walking graph from OSM (10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    results = []
    for name, olat, olon, dlat, dlon in ROUTE_PAIRS:
        print(f"\nScoring: {name}...")
        r = run_one_route(graph, name, olat, olon, dlat, dlon, sensors_df, df, base_thresholds, reference_time)
        results.append(r)
        print(f"  -> {r}")

    report = pd.DataFrame(results)
    print("\n--- Coverage Report ---")
    print(report.to_string(index=False))

    if "coverage_pct" in report.columns:
        print(f"\nMean segment coverage across all routes: {report['coverage_pct'].mean():.1f}%")
        print(f"Routes resolved to High/Low (not Unknown): "
              f"{(report['route_label'] != 'Unknown').sum()}/{len(report)}")

    out_path = "coverage_report.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull report saved to {out_path}")


if __name__ == "__main__":
    main()