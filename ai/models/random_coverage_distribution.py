"""
random_coverage_distribution.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data).

Answers the actual open question: should there be a minimum coverage
floor below which a route is always Unknown, or does confidence alone
carry the nuance? One route, or even five hand-picked ones, can't answer
that -- this samples MANY random origin/destination pairs across the real
Melbourne CBD graph, computes segment coverage for each (using the same
merge + catchment pipeline as coverage_report.py), and reports the full
distribution: how many routes fall into each coverage bucket, and how
many would be "usable" under a range of candidate floor values.

HOW TO RUN:
    python random_coverage_distribution.py

Trivially short routes (fewer than MIN_RAW_EDGES) are skipped -- they're
not representative of a real commute and would artificially inflate the
coverage stats (a 2-segment route trivially has better odds of both
segments having a sensor than a 50-segment one).
"""

from __future__ import annotations

import random
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

DATA_PATH = "../../data/raw/training_20260807.csv"
N_SAMPLES = 50          # how many random route pairs to test
MIN_RAW_EDGES = 5       # skip trivially short routes -- not representative of a real commute
RANDOM_SEED = 42        # fixed seed: reproducible, so re-running gives the same sample set
CANDIDATE_FLOORS = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60]


def run_one_route(graph, orig_lat, orig_lon, dest_lat, dest_lon, sensors_df, pedestrian_df, base_thresholds, reference_time):
    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None or len(route_segments) < MIN_RAW_EDGES:
        return None

    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    joined = join_sensor_mapping(blocks, sensor_mapping)

    result = score_route(
        route_id="SAMPLE",
        segments=joined,
        pedestrian_df=pedestrian_df,
        base_thresholds=base_thresholds,
        reference_time=reference_time,
        snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
    )
    matched = sum(1 for s in result.segment_scores if s.coverage == "matched")
    total = len(result.segment_scores)
    return {
        "raw_edges": len(route_segments),
        "merged_blocks": len(blocks),
        "route_label": result.label,
        "coverage_pct": round(100 * matched / total, 1) if total else 0.0,
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

    random.seed(RANDOM_SEED)
    nodes = list(graph.nodes(data=True))

    results = []
    attempts = 0
    max_attempts = N_SAMPLES * 5  # allow retries for skipped/too-short/no-path samples
    while len(results) < N_SAMPLES and attempts < max_attempts:
        attempts += 1
        n1, d1 = random.choice(nodes)
        n2, d2 = random.choice(nodes)
        if n1 == n2:
            continue
        r = run_one_route(
            graph, d1["y"], d1["x"], d2["y"], d2["x"],
            sensors_df, df, base_thresholds, reference_time,
        )
        if r is not None:
            results.append(r)
        if len(results) % 10 == 0 and len(results) > 0:
            print(f"  ...{len(results)}/{N_SAMPLES} sampled")

    report = pd.DataFrame(results)
    print(f"\n--- Distribution over {len(report)} real random routes ---")
    print(report["coverage_pct"].describe())

    print("\n--- Coverage bucket breakdown ---")
    bins = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100.01]
    labels = ["0-10%", "10-20%", "20-30%", "30-40%", "40-50%", "50-60%", "60-70%", "70-80%", "80-90%", "90-100%"]
    report["bucket"] = pd.cut(report["coverage_pct"], bins=bins, labels=labels, right=False)
    print(report["bucket"].value_counts().sort_index())

    print("\n--- Routes usable (Low/High resolvable) at each candidate floor ---")
    for floor in CANDIDATE_FLOORS:
        usable = (report["coverage_pct"] >= floor).sum()
        print(f"  floor={floor:>3}%: {usable}/{len(report)} routes would clear it "
              f"({100*usable/len(report):.0f}%)")

    print(f"\nCurrent strict behaviour (floor=100%, i.e. no Unknown segments at all): "
          f"{(report['coverage_pct'] >= 100).sum()}/{len(report)} routes")

    out_path = "random_coverage_distribution.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull per-route data saved to {out_path}")


if __name__ == "__main__":
    main()