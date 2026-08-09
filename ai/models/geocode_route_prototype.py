"""
geocode_route_prototype.py

RUN THIS LOCALLY (needs real internet access -- both OSM's routing graph
and OSM's geocoding search).

Prototype for Option C, Version 1: user types two place names, this finds
real coordinates for them and scores the route between them -- no fixed
route list, no map-tapping UI needed. Uses OSM's free Nominatim geocoder
via osmnx.geocode() -- already a dependency you have, no new API key or
billing setup required.

LIMITATIONS, HONESTLY:
- This is a single best-guess match per name, not a Google-style
  autocomplete dropdown with multiple suggestions. Ambiguous names (e.g.
  just "Library") may geocode to the wrong place -- appending a location
  context ("..., Melbourne, Australia") significantly improves accuracy.
- Nominatim's usage policy caps free usage at ~1 request/second -- fine
  for occasional real searches, not for high-traffic production use
  without self-hosting your own instance.
- No fuzzy matching or spelling correction -- a typo may return nothing
  or the wrong place.

HOW TO RUN:
    python geocode_route_prototype.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from load_validated_data import load_pedestrian_data
from place_resolver import resolve_place_name
from route_scoring import (
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
LOCATION_CONTEXT = "Melbourne CBD, Victoria, Australia"


def geocode_place(query: str, context: str = LOCATION_CONTEXT) -> tuple[float, float] | None:
    """
    Converts a typed place name into real (lat, lon) coordinates.

    Resolution order:
      1. Known-places dictionary (place_resolver.py) -- exact alias or
         canonical match, e.g. "Vic Market" -> "Queen Victoria Market".
         Resolved confidently, geocoded directly.
      2. If the query fuzzy-matches a known place closely enough (a
         likely typo) but isn't an exact/alias match, this does NOT
         guess -- see geocode_place_with_suggestions() below for the
         version that surfaces those as suggestions instead.
      3. Otherwise, falls back to geocoding the raw query text directly
         via Nominatim -- handles real places not in the small curated
         dictionary (most official names already work fine on their own,
         per the stress test).

    Returns None if nothing can be resolved or geocoded.
    """
    import osmnx as ox

    canonical, _ = resolve_place_name(query)
    resolved_query = canonical if canonical else query

    full_query = f"{resolved_query}, {context}" if context else resolved_query
    try:
        return ox.geocode(full_query)
    except Exception:
        return None


def geocode_place_with_suggestions(query: str, context: str = LOCATION_CONTEXT):
    """
    Same resolution order as geocode_place(), but when the query is a
    likely typo of a known place (fuzzy match, not exact), this returns
    suggestions instead of silently guessing and geocoding one of them.

    Returns one of:
      ("resolved", (lat, lon))      -- confidently geocoded
      ("suggestions", [name, ...])  -- not confident; caller should ask
                                        the user to pick one (the actual
                                        "did you mean?" popup content)
      ("not_found", None)           -- nothing usable at all
    """
    canonical, suggestions = resolve_place_name(query)

    if canonical:
        coords = geocode_place(canonical, context)
        return ("resolved", coords) if coords else ("not_found", None)

    if suggestions:
        return ("suggestions", suggestions)

    # not in the known dictionary at all -- try geocoding the raw text
    # directly, in case it's a real place Nominatim already handles fine
    coords = geocode_place(query, context)
    if coords:
        return ("resolved", coords)
    return ("not_found", None)


def score_route_by_name(graph, origin_name, destination_name, sensors_df, pedestrian_df, base_thresholds, reference_time):
    # Both names are resolved independently, regardless of whether the
    # first one fails -- so a user who typos both fields gets told about
    # both problems at once, not one at a time across multiple resubmits.
    print(f"Resolving '{origin_name}'...")
    orig_status, orig_result = geocode_place_with_suggestions(origin_name)
    if orig_status == "resolved":
        print(f"  -> ({orig_result[0]:.4f}, {orig_result[1]:.4f})")
    elif orig_status == "suggestions":
        print(f"  Not found directly -- did you mean: {', '.join(orig_result)}?")
    else:
        print(f"  -> COULD NOT RESOLVE '{origin_name}'")

    print(f"Resolving '{destination_name}'...")
    dest_status, dest_result = geocode_place_with_suggestions(destination_name)
    if dest_status == "resolved":
        print(f"  -> ({dest_result[0]:.4f}, {dest_result[1]:.4f})")
    elif dest_status == "suggestions":
        print(f"  Not found directly -- did you mean: {', '.join(dest_result)}?")
    else:
        print(f"  -> COULD NOT RESOLVE '{destination_name}'")

    if orig_status != "resolved" or dest_status != "resolved":
        return None  # any problems were already reported above, for both names

    orig_lat, orig_lon = orig_result
    dest_lat, dest_lon = dest_result

    node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
    if node_path is None:
        print("No path found between these two points.")
        return None

    blocks = merge_segments_by_street_name(graph, route_segments)
    sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
    joined = join_sensor_mapping(blocks, sensor_mapping)

    return score_route(
        route_id=f"{origin_name} -> {destination_name}",
        segments=joined,
        pedestrian_df=pedestrian_df,
        base_thresholds=base_thresholds,
        reference_time=reference_time,
        snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
    )


def main():
    print(f"Loading real pedestrian data from {DATA_PATH}...")
    df = load_pedestrian_data(DATA_PATH)
    validate_pedestrian_columns(df)

    sensors_df = df[["sensor_id", "latitude", "longitude"]].drop_duplicates(subset="sensor_id")
    base_thresholds = df.groupby("sensor_id")["count"].quantile(0.75).to_dict()
    reference_time = df["timestamp"].max()

    print("Fetching Melbourne CBD walking graph (cached after first run)...")
    graph = get_walk_graph_cached(LOCATION_CONTEXT)

    # --- Try it with two typed names, exactly like a search box would send you ---
    origin_name = "Flinders Street Station"
    destination_name = "State Library Victoria"

    print(f"\n--- Scoring: '{origin_name}' -> '{destination_name}' ---")
    result = score_route_by_name(graph, origin_name, destination_name, sensors_df, df, base_thresholds, reference_time)
    if result:
        print(f"\nRoute: {result.label}", f"({result.confidence} confidence)" if result.confidence else "")
        print(f"Reason: {result.reason}")

    # --- Now try it WITH a real typo, to show the suggestion path working ---
    print("\n\n--- Scoring with a typo: 'Flinders St Staton' -> 'Vic Market' ---")
    score_route_by_name(graph, "Flinders St Staton", "Vic Market", sensors_df, df, base_thresholds, reference_time)


if __name__ == "__main__":
    main()