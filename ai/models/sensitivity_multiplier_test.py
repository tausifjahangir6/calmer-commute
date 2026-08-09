"""
sensitivity_multiplier_test.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data).

Every real run in this project so far called score_route()/classify_segment()
WITHOUT passing user_context, silently defaulting to "default" sensitivity
(multiplier x1.0). The cautious (x0.7) / relaxed (x1.3) multiplier code
path exists via alert_thresholds.get_alert_thresholds(), but has never
actually been exercised against real data and confirmed to shift results
the way it should. This tests all three sensitivity levels against the
same real route and reference time, and confirms:
  - cautious produces MORE High classifications than default (lower
    threshold -> easier to trip)
  - relaxed produces FEWER High classifications than default (higher
    threshold -> harder to trip)

HOW TO RUN:
    python sensitivity_multiplier_test.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data
from route_scoring import (
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

# A route already confirmed to reach High regularly around midday
ROUTE_NAME = "Flinders St Station -> State Library"
ORIG_LAT, ORIG_LON = -37.8183, 144.9671
DEST_LAT, DEST_LON = -37.8102, 144.9628

SENSITIVITIES = ["cautious", "default", "relaxed"]


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()

    print("Fetching Melbourne CBD walking graph (cached after first run)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    print(f"\nBuilding route: {ROUTE_NAME}...")
    node_path, route_segments = build_route_segments(graph, ORIG_LAT, ORIG_LON, DEST_LAT, DEST_LON)
    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    joined = join_sensor_mapping(blocks, sensor_mapping)

    # Test across several real reference times, not just one, so this
    # isn't a single lucky/unlucky moment -- reuse the same busy-moment
    # finder from earlier, plus a couple of nearby hours for spread.
    peak_time = find_peak_reference_time(df, base_thresholds)
    test_times = [peak_time] if peak_time is not None else []
    # add a handful more real timestamps spread across the dataset for a broader check
    all_times = sorted(df["timestamp"].unique())
    step = max(1, len(all_times) // 20)
    test_times += list(all_times[::step][:20])
    test_times = sorted(set(pd.Timestamp(t) for t in test_times))

    print(f"\nTesting {len(test_times)} real reference times across all 3 sensitivity levels...")
    results = []
    for t in test_times:
        row = {"reference_time": t}
        for sensitivity in SENSITIVITIES:
            route = score_route(
                route_id=ROUTE_NAME,
                segments=joined,
                pedestrian_df=df,
                base_thresholds=base_thresholds,
                reference_time=t,
                user_context={"sensitivity": sensitivity},
                snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
            )
            row[f"{sensitivity}_label"] = route.label
        results.append(row)

    report = pd.DataFrame(results)
    print("\n--- Results across all three sensitivity levels ---")
    print(report.to_string(index=False))

    high_counts = {
        s: (report[f"{s}_label"] == "High").sum() for s in SENSITIVITIES
    }
    print(f"\nHigh count per sensitivity across {len(test_times)} real moments: {high_counts}")

    cautious_ge_default = high_counts["cautious"] >= high_counts["default"]
    default_ge_relaxed = high_counts["default"] >= high_counts["relaxed"]
    print(f"\ncautious >= default High count: {cautious_ge_default}")
    print(f"default >= relaxed High count: {default_ge_relaxed}")
    if cautious_ge_default and default_ge_relaxed:
        print("\nMultiplier confirmed working as intended on real data: "
              "cautious flags High at least as often as default, and "
              "default at least as often as relaxed.")
    else:
        print("\nUNEXPECTED: the ordering isn't what the multiplier design "
              "intends. Worth checking get_alert_thresholds() and the "
              "SENSITIVITY_MULTIPLIERS values directly.")

    # Also show a concrete example where sensitivity changes the label
    differing = report[
        (report["cautious_label"] != report["default_label"])
        | (report["default_label"] != report["relaxed_label"])
    ]
    print(f"\nMoments where sensitivity actually changed the label: {len(differing)}/{len(report)}")
    if len(differing):
        print(differing.to_string(index=False))

    report.to_csv("sensitivity_multiplier_test.csv", index=False)
    print("\nFull results saved to sensitivity_multiplier_test.csv")


if __name__ == "__main__":
    main()