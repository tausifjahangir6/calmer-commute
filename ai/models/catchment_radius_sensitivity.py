"""
catchment_radius_sensitivity.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data).

DEFAULT_CATCHMENT_RADIUS_M (100m) was never data-validated the way the
confidence tier boundaries were -- it's still the original assumption.
This holds a FIXED set of sampled routes constant and varies only the
catchment radius, to see how sensitive real coverage results actually are
to that choice. If coverage changes gently across a reasonable range,
100m is a defensible middle-of-the-road choice. If it swings wildly, that
radius needs more careful justification (or team sign-off) before
trusting it.

HOW TO RUN:
    python catchment_radius_sensitivity.py
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
    MIN_COVERAGE_FOR_LOW_PCT,
)

DATA_PATH = "../../data/raw/training_20260807.csv"
N_ROUTES = 25                     # fixed route set, reused across every radius tested
MIN_RAW_EDGES = 5
FIXED_SEED = 42                   # same seed as the original distribution study, for a like-for-like route set
CANDIDATE_RADII = [50, 75, 100, 125, 150, 200]


def build_fixed_route_set(graph, seed, n_routes):
    random.seed(seed)
    nodes = list(graph.nodes(data=True))
    pairs = []
    attempts, max_attempts = 0, n_routes * 5
    while len(pairs) < n_routes and attempts < max_attempts:
        attempts += 1
        n1, d1 = random.choice(nodes)
        n2, d2 = random.choice(nodes)
        if n1 == n2:
            continue
        node_path, route_segments = build_route_segments(graph, d1["y"], d1["x"], d2["y"], d2["x"])
        if node_path is not None and len(route_segments) >= MIN_RAW_EDGES:
            pairs.append((d1["y"], d1["x"], d2["y"], d2["x"], route_segments))
    return pairs


def score_at_radius(graph, route_segments, sensors_df, df, base_thresholds, reference_time, radius_m):
    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df, catchment_radius_m=radius_m)
    joined = join_sensor_mapping(blocks, sensor_mapping)
    result = score_route(
        route_id="SAMPLE", segments=joined, pedestrian_df=df,
        base_thresholds=base_thresholds, reference_time=reference_time,
        snap_threshold_m=radius_m,
    )
    return result.coverage_pct if result.coverage_pct is not None else 0.0


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()
    reference_time = df["timestamp"].max()

    print("Fetching Melbourne CBD walking graph from OSM (10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    print(f"\nBuilding a FIXED set of {N_ROUTES} routes (seed={FIXED_SEED}), held constant across all radii...")
    fixed_routes = build_fixed_route_set(graph, FIXED_SEED, N_ROUTES)
    print(f"Got {len(fixed_routes)} valid routes.")

    rows = []
    for radius in CANDIDATE_RADII:
        print(f"\nScoring all {len(fixed_routes)} routes at catchment_radius_m={radius}...")
        coverages = [
            score_at_radius(graph, seg, sensors_df, df, base_thresholds, reference_time, radius)
            for (_, _, _, _, seg) in fixed_routes
        ]
        below_floor = sum(1 for c in coverages if c < MIN_COVERAGE_FOR_LOW_PCT)
        row = {
            "radius_m": radius,
            "mean_coverage_pct": round(sum(coverages) / len(coverages), 1),
            "min_coverage_pct": round(min(coverages), 1),
            "max_coverage_pct": round(max(coverages), 1),
            "below_floor_pct": round(100 * below_floor / len(coverages), 1),
        }
        rows.append(row)
        print(f"  -> {row}")

    report = pd.DataFrame(rows)
    print("\n--- Sensitivity to catchment radius (SAME routes, radius varied) ---")
    print(report.to_string(index=False))

    out_path = "catchment_radius_sensitivity.csv"
    report.to_csv(out_path, index=False)
    print(f"\nFull results saved to {out_path}")
    print(
        "\nLook at how mean_coverage_pct changes as radius increases. A "
        "smooth, gradual increase supports 100m as a reasonable "
        "middle-of-the-road choice. A sharp jump right around 100m would "
        "mean results are sensitive to this exact number and it deserves "
        "more scrutiny (or team sign-off) before being trusted as-is."
    )


if __name__ == "__main__":
    main()