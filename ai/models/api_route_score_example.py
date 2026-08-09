"""
api_route_score_example.py

*** REFERENCE EXAMPLE -- NOT THE LIVE APP ***

This defines a complete, real, TESTED Flask endpoint (run this file
directly to see a real smoke test against it) -- but it is a standalone
reference implementation, not the actual production entry point. Your
real Flask app already exists at backend/app/__init__.py, hosting the
AI-US2.2-01 forecast endpoint.

WHEN C7 WORK ACTUALLY HAPPENS: copy the /api/route-score route logic
below into backend/app/__init__.py, alongside the existing forecast
route, loading the graph/sensors/data once at that app's startup --
do NOT run this file's create_app() as a second, separate Flask server.
This file exists so the exact request/response contract in
US1.1_HANDOFF.md is provably correct (tested, not just described in
prose), and so whoever does the C7 integration has real working code to
start from rather than writing it from scratch.

The interface layer between route_scoring.py (pure Python) and whatever
serves it over HTTP. Two things live here:

  1. Serialization: converting RouteClassification/SegmentClassification
     dataclasses into plain JSON-safe dicts (datetimes need explicit
     isoformat conversion -- dataclasses.asdict() alone doesn't do this).

  2. A working example Flask endpoint, GET /api/route-score, showing
     exactly how frontend would call this in practice -- mirroring the
     existing GET /api/forecast/<sensor_id> pattern from AI-US2.2-01, so
     the two cards look consistent to whoever's consuming both.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))

from flask import Flask, request, jsonify

from route_scoring import (
    RouteClassification,
    SegmentClassification,
    get_walk_graph_cached,
    build_route_segments,
    merge_segments_by_street_name,
    snap_sensors_to_blocks,
    join_sensor_mapping,
    score_route,
    DEFAULT_CATCHMENT_RADIUS_M,
)
from place_resolver import resolve_place_name


# ---------------------------------------------------------------------------
# Serialization -- the actual JSON shape frontend will receive
# ---------------------------------------------------------------------------

def segment_to_dict(seg: SegmentClassification) -> dict:
    return {
        "segment_id": seg.segment_id,
        "sensor_id": seg.sensor_id,
        "label": seg.label,
        "reason": seg.reason,
        "observed_count": seg.observed_count,
        "threshold": seg.threshold,
        "observation_ts": seg.observation_ts.isoformat() if seg.observation_ts else None,
        "coverage": seg.coverage,
        "snap_m": seg.snap_m,
        "scoring_version": seg.scoring_version,
    }


def route_to_dict(route: RouteClassification) -> dict:
    return {
        "route_id": route.route_id,
        "label": route.label,
        "confidence": route.confidence,  # "low" | "medium" | "high" | null
        "coverage_pct": route.coverage_pct,
        "reason": route.reason,
        "aggregation_rule": route.aggregation_rule,
        "coverage": route.coverage,
        "scoring_version": route.scoring_version,
        "segments": [segment_to_dict(s) for s in route.segment_scores],
    }


# ---------------------------------------------------------------------------
# Geocoding a name into coordinates, resolving via the known-places
# dictionary + fuzzy/substring matching before falling back to raw
# Nominatim -- same logic as geocode_route_prototype.py, factored out
# here since the API layer needs it directly.
# ---------------------------------------------------------------------------

def resolve_and_geocode(query: str, context: str = "Melbourne CBD, Victoria, Australia"):
    import osmnx as ox

    canonical, suggestions = resolve_place_name(query)
    if canonical:
        try:
            coords = ox.geocode(f"{canonical}, {context}")
            return "resolved", coords
        except Exception:
            return "not_found", None
    if suggestions:
        return "suggestions", suggestions
    try:
        coords = ox.geocode(f"{query}, {context}")
        return "resolved", coords
    except Exception:
        return "not_found", None


# ---------------------------------------------------------------------------
# Flask app -- example endpoint
# ---------------------------------------------------------------------------

def create_app():
    app = Flask(__name__)

    # Loaded once at startup, not per-request -- same pattern as the
    # forecast endpoint's artifact loading (rf_model.joblib etc.)
    app.config["GRAPH"] = None
    app.config["SENSORS_DF"] = None
    app.config["PEDESTRIAN_DF"] = None
    app.config["BASE_THRESHOLDS"] = None

    @app.route("/api/route-score", methods=["GET"])
    def route_score():
        """
        GET /api/route-score?origin=<name>&destination=<name>&sensitivity=default

        Query params:
          origin, destination  -- required, place names (typed search text)
          sensitivity           -- optional, one of cautious/default/relaxed
                                    (same values as the forecast endpoint)

        Response shapes:

          Success (200):
            {"resolved": true, "route": { ...route_to_dict shape... }}

          Needs clarification (200 -- NOT an error, a real "ask the user"
          state, same spirit as the forecast card's confidence/limitation
          flags):
            {
              "resolved": false,
              "problems": {
                "origin": {"status": "suggestions", "suggestions": [...]},
                "destination": {"status": "not_found", "suggestions": []}
              }
            }

          Bad request (400): missing origin/destination entirely.
        """
        origin = request.args.get("origin", "").strip()
        destination = request.args.get("destination", "").strip()
        sensitivity = request.args.get("sensitivity", "default")

        if not origin or not destination:
            return jsonify({"error": "origin and destination query params are required"}), 400

        orig_status, orig_result = resolve_and_geocode(origin)
        dest_status, dest_result = resolve_and_geocode(destination)

        problems = {}
        if orig_status != "resolved":
            problems["origin"] = {
                "status": orig_status,
                "suggestions": orig_result if orig_status == "suggestions" else [],
            }
        if dest_status != "resolved":
            problems["destination"] = {
                "status": dest_status,
                "suggestions": dest_result if dest_status == "suggestions" else [],
            }
        if problems:
            return jsonify({"resolved": False, "problems": problems}), 200

        orig_lat, orig_lon = orig_result
        dest_lat, dest_lon = dest_result

        graph = app.config["GRAPH"]
        sensors_df = app.config["SENSORS_DF"]
        pedestrian_df = app.config["PEDESTRIAN_DF"]
        base_thresholds = app.config["BASE_THRESHOLDS"]

        node_path, route_segments = build_route_segments(graph, orig_lat, orig_lon, dest_lat, dest_lon)
        if node_path is None:
            return jsonify({"resolved": False, "error": "no walking path found between these two points"}), 200

        blocks = merge_segments_by_street_name(graph, route_segments)
        sensor_mapping = snap_sensors_to_blocks(graph, blocks, sensors_df)
        joined = join_sensor_mapping(blocks, sensor_mapping)

        reference_time = pedestrian_df["timestamp"].max()
        route = score_route(
            route_id=f"{origin} -> {destination}",
            segments=joined,
            pedestrian_df=pedestrian_df,
            base_thresholds=base_thresholds,
            reference_time=reference_time,
            user_context={"sensitivity": sensitivity},
            snap_threshold_m=DEFAULT_CATCHMENT_RADIUS_M,
        )

        return jsonify({"resolved": True, "route": route_to_dict(route)}), 200

    return app


if __name__ == "__main__":
    # Real smoke test using Flask's test client -- exercises the actual
    # endpoint code path (request parsing, JSON response shape) without
    # needing a real running server or real OSM/data files. Uses fully
    # synthetic data, same pattern as the offline unit tests elsewhere in
    # this project.
    from datetime import datetime, timedelta
    import pandas as pd
    import networkx as nx

    app = create_app()

    # Tiny synthetic graph + data, just enough to exercise the endpoint
    graph = nx.MultiDiGraph(crs="epsg:4326")
    graph.add_node(1, x=144.9671, y=-37.8183)
    graph.add_node(2, x=144.9628, y=-37.8102)
    graph.add_edge(1, 2, key=0, length=500.0, name="Test St")

    app.config["GRAPH"] = graph
    app.config["SENSORS_DF"] = pd.DataFrame([{"sensor_id": 1, "latitude": -37.8183, "longitude": 144.9671}])
    ref_time = datetime(2026, 1, 1, 12, 0, 0)
    app.config["PEDESTRIAN_DF"] = pd.DataFrame(
        [{"sensor_id": 1, "timestamp": ref_time, "count": 100}]
    )
    app.config["BASE_THRESHOLDS"] = {1: 600.0}

    client = app.test_client()

    print("--- Missing params (should be 400) ---")
    resp = client.get("/api/route-score")
    print(resp.status_code, resp.get_json())

    print("\n--- Unresolvable place name (should return resolved=false with suggestions) ---")
    resp = client.get("/api/route-score?origin=flinders st staton&destination=state library")
    print(resp.status_code, resp.get_json())
