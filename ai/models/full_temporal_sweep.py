"""
full_temporal_sweep.py

RUN THIS LOCALLY (needs real internet access to OSM, uses your real data,
and will take longer than other scripts since it's checking every hour in
the dataset -- likely a couple thousand+ hours across your training file).

WHAT THIS DOES: for a fixed set of routes, checks EVERY hour present in
the entire training dataset (not a sample, not a single "peak" moment)
and reports how each route was classified at every single one of those
hours. This directly answers the open question from real_high_case_test.py
-- rather than picking one timestamp and hoping it lines up with these
specific routes, this checks all of them.

WHY IT'S FAST DESPITE CHECKING EVERYTHING: route geometry and
sensor-to-segment matching are purely spatial -- they don't depend on
time, so they're computed ONCE per route, not once per hour. Only the
"is this sensor's reading fresh and high/low right now" part actually
depends on time, and that's done via a vectorized pandas lookup (a wide
sensor-by-hour table) rather than a slow per-hour scan of the full 1.5M+
row dataset. This was cross-checked against the real, already-tested
classify_segment/aggregate_route functions on a small example before
being used here -- see the conversation this script came from for that
verification, or rerun it yourself by comparing a handful of hours from
this script's output against demo_route_scoring.py with matching
reference_time.

HOW TO RUN:
    python full_temporal_sweep.py
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
    validate_pedestrian_columns,
    get_confidence_tier,
    MIN_COVERAGE_FOR_LOW_PCT,
    FRESHNESS_HOURS,
)

DATA_PATH = "../../data/raw/training_20260807.csv"

ROUTE_PAIRS = [
    ("Flinders St Station -> State Library", -37.8183, 144.9671, -37.8102, 144.9628),
    ("Bourke St Mall -> Southern Cross Station", -37.8136, 144.9648, -37.8183, 144.9524),
    ("QV Melbourne -> Chinatown", -37.8103, 144.9648, -37.8117, 144.9686),
    ("Melbourne Central -> Federation Square", -37.8100, 144.9628, -37.8180, 144.9691),
    ("RMIT -> Parliament Station", -37.8079, 144.9634, -37.8107, 144.9735),
]


def build_route_spatial(graph, orig_lat, orig_lon, dest_lat, dest_lon):
    """One-time, time-independent setup for a single route: geometry +
    sensor matching. Returns (total_segments, eligible_segment_to_sensor)
    where eligible = has a real, reliable sensor match at all -- segments
    without one are permanently unresolved regardless of hour."""
    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None:
        return None
    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df_global)
    joined = join_sensor_mapping(blocks, sensor_mapping)
    total_segments = len(joined)
    eligible = {
        seg["segment_id"]: seg["sensor_id"]
        for seg in joined
        if seg["sensor_id"] is not None and seg["snap_reliable"]
    }
    return total_segments, eligible


def sweep_route(pivot_ffilled, total_segments, eligible, base_thresholds):
    """Vectorized classification across every hour in pivot_ffilled's
    index, for one route. Returns a DataFrame indexed by timestamp with
    label/confidence/coverage_pct columns."""
    if not eligible:
        # no sensor ever matched this route at all -- always Unknown, every hour
        idx = pivot_ffilled.index
        return pd.DataFrame(
            {"label": "Unknown", "confidence": None, "coverage_pct": 0.0}, index=idx
        )

    sensor_ids = list(eligible.values())
    seg_ids = list(eligible.keys())
    missing = [sid for sid in sensor_ids if sid not in pivot_ffilled.columns]
    for sid in missing:
        pivot_ffilled[sid] = pd.NA  # sensor never appears in data at all -- always missing

    sub = pivot_ffilled[sensor_ids].copy()
    sub.columns = seg_ids
    thresh_series = pd.Series({seg: base_thresholds.get(sid) for seg, sid in eligible.items()})

    valid_mask = sub.notna() & thresh_series.notna()
    high_mask = valid_mask & (sub >= thresh_series)

    resolved = valid_mask.sum(axis=1)
    coverage_pct = (100 * resolved / total_segments).round(1)
    any_high = high_mask.any(axis=1)

    labels = pd.Series("Unknown", index=sub.index)
    labels[coverage_pct >= MIN_COVERAGE_FOR_LOW_PCT] = "Low"
    labels[any_high] = "High"

    confidence = pd.Series(None, index=sub.index, dtype=object)
    low_mask = labels == "Low"
    confidence[low_mask] = coverage_pct[low_mask].apply(get_confidence_tier)

    return pd.DataFrame({"label": labels, "confidence": confidence, "coverage_pct": coverage_pct})


def main():
    global sensors_df_global

    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df_global = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()

    print("Fetching Melbourne CBD walking graph (cached after first run)...")
    graph = get_walk_graph_cached("Melbourne CBD, Victoria, Australia")

    print("\nBuilding a complete hourly panel from the real dataset (this defines every hour we'll check)...")
    pivot = df.pivot_table(index="timestamp", columns="sensor_id", values="count", aggfunc="last")
    full_index = pd.date_range(pivot.index.min(), pivot.index.max(), freq="h")
    pivot = pivot.reindex(full_index)
    pivot_ffilled = pivot.ffill(limit=int(FRESHNESS_HOURS))
    print(f"Total hours to check: {len(full_index)} (from {full_index.min()} to {full_index.max()})")

    all_summaries = []
    for name, olat, olon, dlat, dlon in ROUTE_PAIRS:
        print(f"\nBuilding route (one-time spatial setup): {name}...")
        spatial = build_route_spatial(graph, olat, olon, dlat, dlon)
        if spatial is None:
            print("  no path found, skipping")
            continue
        total_segments, eligible = spatial
        print(f"  {total_segments} segments, {len(eligible)} with a real sensor match")

        print(f"  Sweeping all {len(full_index)} hours...")
        result_df = sweep_route(pivot_ffilled, total_segments, eligible, base_thresholds)

        label_counts = result_df["label"].value_counts()
        high_hours = result_df[result_df["label"] == "High"]
        summary = {
            "route_name": name,
            "total_hours": len(result_df),
            "pct_high": round(100 * label_counts.get("High", 0) / len(result_df), 2),
            "pct_low": round(100 * label_counts.get("Low", 0) / len(result_df), 2),
            "pct_unknown": round(100 * label_counts.get("Unknown", 0) / len(result_df), 2),
            "first_high_example": str(high_hours.index[0]) if len(high_hours) else None,
        }
        all_summaries.append(summary)
        print(f"  -> {summary}")

        result_df.to_csv(f"sweep_{name.replace(' ', '_').replace('>', '').replace('<', '')}.csv")

    report = pd.DataFrame(all_summaries)
    print("\n--- Full sweep summary across all routes ---")
    print(report.to_string(index=False))

    total_high = report["pct_high"].gt(0).sum()
    print(f"\nRoutes that were High at LEAST ONCE across the entire dataset: {total_high}/{len(report)}")
    if total_high == 0:
        print(
            "Still zero High hours across every single hour in the whole "
            "dataset, for all 5 routes. At this point that's a much "
            "stronger signal than before -- worth checking whether these "
            "specific 5 routes simply never pass near a sensor that goes "
            "over its threshold, vs a genuine gap in the High logic "
            "itself (the unit tests already prove the logic works in "
            "isolation, so if it's still zero here, the next step is "
            "picking a route deliberately through a sensor location "
            "you've directly confirmed goes over-threshold in the raw "
            "data, e.g. Bourke Street Mall)."
        )

    report.to_csv("full_temporal_sweep_summary.csv", index=False)
    print("\nSummary saved to full_temporal_sweep_summary.csv")
    print("Full hour-by-hour results for each route saved to sweep_<route_name>.csv")


if __name__ == "__main__":
    main()