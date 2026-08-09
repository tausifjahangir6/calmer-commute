"""
test_block_matching.py

Tests for the Option A + B sparsity fix: merge_segments_by_street_name and
match_blocks_to_projected_sensors. Both are pure-geometry / pure-logic --
no OSM network access needed, unlike snap_sensors_to_blocks (the real-world
wrapper that does projection, covered by an integration test instead).
"""

from __future__ import annotations

import sys
from pathlib import Path

import networkx as nx
import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))

from route_scoring import (
    merge_segments_by_street_name,
    match_blocks_to_projected_sensors,
)


# ---------------------------------------------------------------------------
# merge_segments_by_street_name
# ---------------------------------------------------------------------------

def make_route_graph():
    """
    A -- B -- C -- D -- E, all on "Test St" except D-E which is "Other St".
    F -- G is a separate unnamed edge (no 'name' tag at all).
    """
    G = nx.MultiDiGraph()
    G.add_edge("A", "B", key=0, name="Test St")
    G.add_edge("B", "C", key=0, name="Test St")
    G.add_edge("C", "D", key=0, name="Test St")
    G.add_edge("D", "E", key=0, name="Other St")
    G.add_edge("F", "G", key=0)  # no name attribute at all
    G.add_edge("G", "H", key=0)  # also no name attribute
    return G


def route_segments_from(pairs):
    return [{"segment_id": f"{u}_{v}_0", "u": u, "v": v, "key": 0} for u, v in pairs]


def test_merge_consecutive_same_name_into_one_block():
    graph = make_route_graph()
    segments = route_segments_from([("A", "B"), ("B", "C"), ("C", "D")])
    blocks = merge_segments_by_street_name(graph, segments)
    assert len(blocks) == 1
    assert blocks[0]["street_name"] == "Test St"
    assert blocks[0]["constituent_segment_ids"] == ["A_B_0", "B_C_0", "C_D_0"]


def test_merge_splits_on_name_change():
    graph = make_route_graph()
    segments = route_segments_from([("A", "B"), ("B", "C"), ("C", "D"), ("D", "E")])
    blocks = merge_segments_by_street_name(graph, segments)
    assert len(blocks) == 2
    assert blocks[0]["street_name"] == "Test St"
    assert blocks[1]["street_name"] == "Other St"
    assert blocks[1]["constituent_segment_ids"] == ["D_E_0"]


def test_merge_unnamed_edges_stay_singleton_not_merged_together():
    graph = make_route_graph()
    segments = route_segments_from([("F", "G"), ("G", "H")])
    blocks = merge_segments_by_street_name(graph, segments)
    # two unnamed edges must NOT be silently merged into one block --
    # there's no shared name to justify it
    assert len(blocks) == 2
    assert all(b["street_name"] is None for b in blocks)


def test_merge_empty_segments_returns_empty():
    graph = make_route_graph()
    assert merge_segments_by_street_name(graph, []) == []


def test_merge_preserves_edge_keys_for_geometry_lookup():
    graph = make_route_graph()
    segments = route_segments_from([("A", "B"), ("B", "C")])
    blocks = merge_segments_by_street_name(graph, segments)
    assert blocks[0]["edge_keys"] == [("A", "B", 0), ("B", "C", 0)]


# ---------------------------------------------------------------------------
# match_blocks_to_projected_sensors
# ---------------------------------------------------------------------------

def make_planar_graph():
    """
    A simple synthetic graph on a flat, already-"projected" (metric)
    coordinate plane -- no real CRS involved, just plain floats standing
    in for metres. A---B---C, a straight line 100m long (A at x=0, C at
    x=100).
    """
    G = nx.MultiDiGraph()
    G.add_node("A", x=0.0, y=0.0)
    G.add_node("B", x=50.0, y=0.0)
    G.add_node("C", x=100.0, y=0.0)
    G.add_edge("A", "B", key=0)
    G.add_edge("B", "C", key=0)
    return G


def make_block(segment_id, edge_keys):
    return {"segment_id": segment_id, "street_name": "Test St", "edge_keys": edge_keys}


def test_match_sensor_within_radius():
    graph = make_planar_graph()
    blocks = [make_block("BLOCK-1", [("A", "B", 0)])]
    # sensor 20m directly above the midpoint of A-B (x=25, y=20)
    sensors = [{"sensor_id": 1, "x": 25.0, "y": 20.0}]
    result = match_blocks_to_projected_sensors(graph, blocks, sensors, catchment_radius_m=100.0)
    assert len(result) == 1
    row = result.iloc[0]
    assert row["sensor_id"] == 1
    assert row["snap_reliable"] == True
    assert row["snap_m"] == pytest.approx(20.0, abs=0.01)


def test_match_sensor_outside_radius_resolves_to_no_match():
    graph = make_planar_graph()
    blocks = [make_block("BLOCK-1", [("A", "B", 0)])]
    # sensor 500m away -- well outside a 100m catchment
    sensors = [{"sensor_id": 1, "x": 25.0, "y": 500.0}]
    result = match_blocks_to_projected_sensors(graph, blocks, sensors, catchment_radius_m=100.0)
    row = result.iloc[0]
    assert row["sensor_id"] is None
    assert row["snap_reliable"] == False


def test_match_picks_closest_of_multiple_sensors():
    graph = make_planar_graph()
    blocks = [make_block("BLOCK-1", [("A", "B", 0)])]
    sensors = [
        {"sensor_id": 1, "x": 25.0, "y": 80.0},  # far
        {"sensor_id": 2, "x": 25.0, "y": 10.0},  # close
    ]
    result = match_blocks_to_projected_sensors(graph, blocks, sensors, catchment_radius_m=100.0)
    row = result.iloc[0]
    assert row["sensor_id"] == 2


def test_match_multi_edge_block_uses_combined_geometry():
    graph = make_planar_graph()
    # block spans both A-B and B-C (the full 100m line)
    blocks = [make_block("BLOCK-1", [("A", "B", 0), ("B", "C", 0)])]
    # sensor near the C end (x=95), should still match within radius even
    # though it's far from A
    sensors = [{"sensor_id": 1, "x": 95.0, "y": 10.0}]
    result = match_blocks_to_projected_sensors(graph, blocks, sensors, catchment_radius_m=20.0)
    row = result.iloc[0]
    assert row["sensor_id"] == 1
    assert row["snap_m"] == pytest.approx(10.0, abs=0.01)


def test_match_no_sensors_all_unmatched():
    graph = make_planar_graph()
    blocks = [make_block("BLOCK-1", [("A", "B", 0)])]
    result = match_blocks_to_projected_sensors(graph, blocks, [], catchment_radius_m=100.0)
    row = result.iloc[0]
    assert row["sensor_id"] is None
    assert row["snap_m"] is None