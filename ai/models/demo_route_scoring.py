"""
demo_route_scoring.py

RUN THIS LOCALLY -- not in a sandboxed/offline environment. It needs live
internet access to OpenStreetMap's Overpass API to fetch the real Melbourne
CBD walking graph.

This is the missing piece from route_scoring.py alone: it shows the full
pipeline end-to-end -- fetch the graph, snap your real sensors to it, build
an actual route between two coordinates, and score it. Everything in
route_scoring.py itself only *scores* a route you hand it; this script is
what actually produces one.

HOW TO RUN:
    pip install osmnx pandas
    python demo_route_scoring.py

Swap in your real training_20260807.csv path and real sensor lat/lon
columns before trusting the output -- the sensor data below is a small
fabricated stand-in so this script runs standalone without your full
dataset.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
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
)


def main():
    print("Fetching Melbourne CBD walking graph from OSM (this can take 10-30s)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")
    print(f"Graph loaded: {len(graph.nodes)} nodes, {len(graph.edges)} edges")

    # --- Load your real dataset via the real loader ---
    DATA_PATH = "../../data/raw/training_20260807.csv"  # adjust to your actual path
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)  # confirmed columns: sensor_id, timestamp, count

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    print(f"\n{len(sensors_df)} unique sensors available.")

    # --- Replace this with a real origin/destination pair you care about ---
    orig_lat, orig_lon = -37.8183, 144.9671
    dest_lat, dest_lon = -37.8142, 144.9632

    print(f"\nBuilding route from ({orig_lat}, {orig_lon}) to ({dest_lat}, {dest_lon})...")
    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None:
        print("No path found between these points -- check coordinates are within the graph.")
        return
    print(f"Raw route: {len(route_segments)} edge-level segments, {len(node_path)} nodes")

    # Merge fine-grained edges into named street blocks (Option B), then
    # match sensors within a catchment radius rather than exact-edge-only
    # (Option A) -- see route_scoring.py's block-matching section for why
    # this replaced the original nearest-edge-only approach: with ~13,000
    # raw edges vs ~100 sensors, nearest-edge-only left almost every
    # segment unmatched on a real run.
    blocks = merge_segments_by_street_name(graph, route_segments)
    print(f"Merged into {len(blocks)} street blocks")

    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    print(sensor_mapping)

    joined_segments = join_sensor_mapping(blocks, sensor_mapping)

    # --- Use your real pedestrian data and real threshold, not fabricated ones ---
    reference_time = df["timestamp"].max()
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()

    route = score_route(
        route_id="DEMO-ROUTE",
        segments=joined_segments,
        pedestrian_df=df,
        base_thresholds=base_thresholds,
        reference_time=reference_time,
        snap_threshold_m=100.0,  # matches the catchment_radius_m used by snap_sensors_to_blocks above
    )

    print(f"\n--- Route classification ---")
    print(f"Route: {route.route_id} -> {route.label}")
    print(f"Reason: {route.reason}")
    print(f"Coverage: {route.coverage}")
    for s in route.segment_scores:
        print(f"  {s.segment_id}: {s.label} | {s.coverage} | {s.reason}")


if __name__ == "__main__":
    main()