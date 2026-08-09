"""
multi_seed_coverage_validation.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data).

The confidence tier boundaries (10/40/70) were derived from ONE random
sample of 50 routes with a fixed seed (42). This runs the same sampling
process across SEVERAL different seeds and reports whether the
distribution shape -- and specifically the floor/tier split -- holds up
consistently, or whether it was a one-off artifact of that particular
random draw.

HOW TO RUN:
    python multi_seed_coverage_validation.py
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
    MIN_COVERAGE_FOR_LOW_PCT,
    get_confidence_tier,
)

DATA_PATH = "../../data/raw/training_20260807.csv"
N_PER_SEED = 30          # routes sampled per seed (kept smaller than the original 50 since we're running this several times)
MIN_RAW_EDGES = 5
SEEDS = [1, 7, 42, 100, 2024]  # 42 is the original seed already tested; the rest are new


def run_one_route(graph, orig_lat, orig_lon, dest_lat, dest_lon, sensors_df, pedestrian_df, base_thresholds, reference_time):
    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None or len(route_segments) < MIN_RAW_EDGES:
        return None
    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    joined = join_sensor_mapping(blocks, sensor_mapping)
    result = score_route(
        route_id="SAMPLE", segments=joined, pedestrian_df=pedestrian_df,
        base_thresholds=base_thresholds, reference_time=reference_time,
        snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
    )
    matched = sum(1 for s in result.segment_scores if s.coverage == "matched")
    total = len(result.segment_scores)
    return round(100 * matched / total, 1) if total else 0.0


def sample_one_seed(graph, seed, sensors_df, df, base_thresholds, reference_time):
    random.seed(seed)
    nodes = list(graph.nodes(data=True))
    coverages = []
    attempts, max_attempts = 0, N_PER_SEED * 5
    while len(coverages) < N_PER_SEED and attempts < max_attempts:
        attempts += 1
        n1, d1 = random.choice(nodes)
        n2, d2 = random.choice(nodes)
        if n1 == n2:
            continue
        cov = run_one_route(graph, d1["y"], d1["x"], d2["y"], d2["x"], sensors_df, df, base_thresholds, reference_time)
        if cov is not None:
            coverages.append(cov)
    return coverages


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()
    reference_time = df["timestamp"].max()

    print("Fetching Melbourne CBD walking graph from OSM (10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    all_rows = []
    for seed in SEEDS:
        print(f"\nSampling {N_PER_SEED} routes with seed={seed}...")
        coverages = sample_one_seed(graph, seed, sensors_df, df, base_thresholds, reference_time)
        below_floor = sum(1 for c in coverages if c < MIN_COVERAGE_FOR_LOW_PCT)
        tiers = [get_confidence_tier(c) for c in coverages if c >= MIN_COVERAGE_FOR_LOW_PCT]
        low_n = tiers.count("low")
        med_n = tiers.count("medium")
        high_n = tiers.count("high")
        row = {
            "seed": seed,
            "n_routes": len(coverages),
            "mean_coverage": round(sum(coverages) / len(coverages), 1) if coverages else None,
            "below_floor_pct": round(100 * below_floor / len(coverages), 1) if coverages else None,
            "low_tier_pct": round(100 * low_n / len(coverages), 1) if coverages else None,
            "medium_tier_pct": round(100 * med_n / len(coverages), 1) if coverages else None,
            "high_tier_pct": round(100 * high_n / len(coverages), 1) if coverages else None,
        }
        all_rows.append(row)
        print(f"  -> {row}")

    report = pd.DataFrame(all_rows)
    print("\n--- Cross-seed comparison ---")
    print(report.to_string(index=False))

    print("\n--- Stability check ---")
    for col in ["mean_coverage", "below_floor_pct", "low_tier_pct", "medium_tier_pct", "high_tier_pct"]:
        vals = report[col].dropna()
        if len(vals) > 1:
            print(f"  {col}: range {vals.min()}-{vals.max()} (spread of {vals.max()-vals.min():.1f} points across seeds)")

    out_path = "multi_seed_coverage_validation.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull results saved to {out_path}")
    print(
        "\nA small spread across seeds supports the current floor/tier "
        "numbers as stable. A large spread would mean the original "
        "single-seed sample wasn't representative, and the boundaries "
        "should be reconsidered against the combined data instead."
    )


if __name__ == "__main__":
    main()