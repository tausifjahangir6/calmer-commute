"""
test_route_scoring.py

Covers DEV-US1.1-01's "Testing" acceptance criterion: normal, boundary,
missing, stale, and insufficient-data conditions for both segment
classification and route aggregation.

Does NOT hit the live OSMnx/Overpass API -- snap_sensors_to_graph() and
build_walk_graph() are integration-level and exercised separately against
the real Melbourne CBD graph. These tests exercise the classification and
aggregation logic directly with hand-built inputs, which is what actually
needs to be deterministic and fast for CI.
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))

from route_scoring import (
    classify_segment,
    aggregate_route,
    get_latest_observation,
    FRESHNESS_HOURS,
)

REF_TIME = datetime(2026, 8, 8, 15, 0, 0)


def make_pedestrian_df(rows: list[dict]) -> pd.DataFrame:
    return pd.DataFrame(rows)


def test_get_latest_observation_normal():
    df = make_pedestrian_df(
        [
            {"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=1), "count": 500},
            {"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=2), "count": 400},
        ]
    )
    result = get_latest_observation(df, 1, REF_TIME)
    assert result is not None
    count, ts = result
    assert count == 500
    assert ts == REF_TIME - timedelta(hours=1)


def test_get_latest_observation_stale():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=FRESHNESS_HOURS + 1), "count": 500}]
    )
    assert get_latest_observation(df, 1, REF_TIME) is None


def test_get_latest_observation_boundary_exact_edge():
    # exactly at the freshness boundary should still count (inclusive)
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=FRESHNESS_HOURS), "count": 500}]
    )
    result = get_latest_observation(df, 1, REF_TIME)
    assert result is not None


def test_get_latest_observation_missing_sensor():
    df = make_pedestrian_df(
        [{"sensor_id": 999, "timestamp": REF_TIME, "count": 500}]
    )
    assert get_latest_observation(df, 1, REF_TIME) is None


def test_get_latest_observation_ignores_rows_after_reference_time():
    # Regression test for a real bug: the dataframe can legitimately
    # contain rows AFTER reference_time (e.g. simulating an earlier
    # moment in time against the full historical dataset, exactly what a
    # full temporal sweep across every hour needs to do). Without
    # filtering to ts <= reference_time first, this would grab the
    # sensor's single latest row regardless of reference_time, compute a
    # negative age, and wrongly report None even with a perfectly fresh
    # observation sitting right at reference_time.
    df = make_pedestrian_df([
        {"sensor_id": 1, "timestamp": REF_TIME, "count": 500},
        {"sensor_id": 1, "timestamp": REF_TIME + timedelta(hours=5), "count": 999},  # "future" row
    ])
    result = get_latest_observation(df, 1, REF_TIME)
    assert result is not None
    count, ts = result
    assert count == 500  # must use the row AT reference_time, not the later "future" one
    assert ts == REF_TIME


def test_classify_segment_normal_high():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=30), "count": 900}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=True,
        snap_m=5.0,
        pedestrian_df=df,
        base_thresholds={1: 600.0},
        reference_time=REF_TIME,
    )
    assert result.label == "High"
    assert result.coverage == "matched"


def test_classify_segment_normal_low():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=30), "count": 300}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=True,
        snap_m=5.0,
        pedestrian_df=df,
        base_thresholds={1: 600.0},
        reference_time=REF_TIME,
    )
    assert result.label == "Low"


def test_classify_segment_boundary_exact_threshold():
    # exactly at threshold should resolve High (>=), per documented rule
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=30), "count": 600}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=True,
        snap_m=5.0,
        pedestrian_df=df,
        base_thresholds={1: 600.0},
        reference_time=REF_TIME,
    )
    assert result.label == "High"


def test_classify_segment_no_sensor_mapped():
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=None,
        snap_reliable=None,
        snap_m=None,
        pedestrian_df=df,
        base_thresholds={},
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "no_sensor"


def test_classify_segment_nan_sensor_id_treated_same_as_none():
    # Real-world case: pandas coerces a sensor_id column to float64/NaN
    # when any row has no match (a mixed None+int column can't stay
    # int64). NaN is a float, not None -- classify_segment must catch
    # this explicitly rather than relying on snap_reliable happening to
    # also be False as a backup.
    import math
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=float("nan"),
        snap_reliable=None,
        snap_m=None,
        pedestrian_df=df,
        base_thresholds={},
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "no_sensor"


def test_classify_segment_unreliable_snap():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=30), "count": 900}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=False,
        snap_m=120.0,
        pedestrian_df=df,
        base_thresholds={1: 600.0},
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "unreliable_snap"


def test_classify_segment_stale_data():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=10), "count": 900}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=True,
        snap_m=5.0,
        pedestrian_df=df,
        base_thresholds={1: 600.0},
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "stale_or_missing"


def test_classify_segment_insufficient_threshold_data():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=30), "count": 900}]
    )
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=1,
        snap_reliable=True,
        snap_m=5.0,
        pedestrian_df=df,
        base_thresholds={},  # no threshold for sensor 1
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "no_threshold"


def test_classify_segment_never_produces_unsupported_low():
    # Sweep every failure mode and assert none of them silently degrade to Low
    df_stale = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(hours=10), "count": 100}]
    )
    cases = [
        dict(sensor_id=None, snap_reliable=None, snap_m=None, pedestrian_df=make_pedestrian_df([]), base_thresholds={}),
        dict(sensor_id=1, snap_reliable=False, snap_m=999, pedestrian_df=df_stale, base_thresholds={1: 600.0}),
        dict(sensor_id=1, snap_reliable=True, snap_m=5.0, pedestrian_df=df_stale, base_thresholds={1: 600.0}),
        dict(sensor_id=1, snap_reliable=True, snap_m=5.0, pedestrian_df=make_pedestrian_df([]), base_thresholds={1: 600.0}),
    ]
    for case in cases:
        result = classify_segment(
            segment_id="SEG-1", reference_time=REF_TIME, **case
        )
        assert result.label != "Low", f"unsupported Low produced for case: {case}"


def test_aggregate_route_all_low():
    segs = [
        classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME),
        classify_segment("SEG-2", 2, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 2, "timestamp": REF_TIME, "count": 200}]), {2: 600.0}, REF_TIME),
    ]
    route = aggregate_route("ROUTE-A", segs)
    assert route.label == "Low"
    assert route.coverage == "2/2 segments resolved"
    assert route.coverage_pct == 100.0
    assert route.confidence == "high"  # 100% coverage lands in the top tier


def test_aggregate_route_worst_segment_wins_high():
    segs = [
        classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME),
        classify_segment("SEG-2", 2, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 2, "timestamp": REF_TIME, "count": 900}]), {2: 600.0}, REF_TIME),
    ]
    route = aggregate_route("ROUTE-A", segs)
    assert route.label == "High"
    assert "SEG-2" in route.reason
    assert route.confidence is None  # High is never tiered by coverage


def test_aggregate_route_partial_coverage_now_returns_low_with_confidence_not_unknown():
    # This is the corrected behaviour, replacing the original all-or-
    # nothing rule: real data (50 random Melbourne CBD routes) showed the
    # old "any Unknown segment -> whole route Unknown" rule produced
    # Unknown for 0/50 routes -- unusably strict. One Low segment + one
    # Unknown segment out of two = 50% coverage, which clears the 10%
    # floor, so this must now resolve to Low with a confidence tier
    # (50% -> "medium"), not Unknown.
    segs = [
        classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME),
        classify_segment("SEG-2", None, None, None, make_pedestrian_df([]), {}, REF_TIME),
    ]
    route = aggregate_route("ROUTE-A", segs)
    assert route.label == "Low"
    assert route.coverage == "1/2 segments resolved"
    assert route.coverage_pct == 50.0
    assert route.confidence == "medium"


def test_aggregate_route_below_floor_stays_unknown():
    # The floor this design DOES keep: genuinely near-zero coverage still
    # resolves to Unknown, not a meaningless "Low, low confidence".
    # Confirmed against real data: 5/50 real random routes came back at
    # literally 0% coverage -- a real recurring case, not a rare edge
    # case. 1 resolved out of 20 = 5% coverage, below the 10% floor.
    resolved_seg = classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME)
    unresolved_segs = [
        classify_segment(f"SEG-U{i}", None, None, None, make_pedestrian_df([]), {}, REF_TIME)
        for i in range(19)
    ]
    segs = [resolved_seg] + unresolved_segs
    route = aggregate_route("ROUTE-A", segs)
    assert route.label == "Unknown"
    assert route.coverage_pct == 5.0
    assert route.confidence is None
    assert "below the" in route.reason


def test_aggregate_route_exactly_at_floor_boundary_is_low_not_unknown():
    # Exactly 10% coverage: floor is left-inclusive, so this should be
    # Low (low confidence), not Unknown -- a real boundary case worth
    # locking in explicitly.
    resolved_seg = classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME)
    unresolved_segs = [
        classify_segment(f"SEG-U{i}", None, None, None, make_pedestrian_df([]), {}, REF_TIME)
        for i in range(9)
    ]
    segs = [resolved_seg] + unresolved_segs
    route = aggregate_route("ROUTE-A", segs)
    assert route.coverage_pct == 10.0
    assert route.label == "Low"
    assert route.confidence == "low"


def test_aggregate_route_confidence_tier_boundaries():
    def make_route_at_coverage(resolved_count, total_count):
        resolved = [
            classify_segment(f"SEG-R{i}", 1, True, 5.0, make_pedestrian_df(
                [{"sensor_id": 1, "timestamp": REF_TIME, "count": 100}]), {1: 600.0}, REF_TIME)
            for i in range(resolved_count)
        ]
        unresolved = [
            classify_segment(f"SEG-U{i}", None, None, None, make_pedestrian_df([]), {}, REF_TIME)
            for i in range(total_count - resolved_count)
        ]
        return aggregate_route("ROUTE-A", resolved + unresolved)

    # 30/100 = 30% -> low tier
    assert make_route_at_coverage(30, 100).confidence == "low"
    # exactly 40% -> boundary, should tip into medium (left-inclusive)
    assert make_route_at_coverage(40, 100).confidence == "medium"
    # 60/100 = 60% -> medium tier
    assert make_route_at_coverage(60, 100).confidence == "medium"
    # exactly 70% -> boundary, should tip into high (left-inclusive)
    assert make_route_at_coverage(70, 100).confidence == "high"
    # 100% -> high tier
    assert make_route_at_coverage(100, 100).confidence == "high"


def test_aggregate_route_no_segments():
    route = aggregate_route("ROUTE-EMPTY", [])
    assert route.label == "Unknown"
    assert route.coverage == "0/0 segments resolved"
    assert route.confidence is None


def test_aggregate_route_high_beats_unknown():
    # High + Unknown -> should still be High, not diluted to Unknown, and
    # NOT coverage-tiered even though overall coverage is only 50%
    segs = [
        classify_segment("SEG-1", 1, True, 5.0, make_pedestrian_df(
            [{"sensor_id": 1, "timestamp": REF_TIME, "count": 900}]), {1: 600.0}, REF_TIME),
        classify_segment("SEG-2", None, None, None, make_pedestrian_df([]), {}, REF_TIME),
    ]
    route = aggregate_route("ROUTE-A", segs)
    assert route.label == "High"
    assert route.confidence is None


def test_consistency_identical_inputs_identical_output():
    df = make_pedestrian_df(
        [{"sensor_id": 1, "timestamp": REF_TIME - timedelta(minutes=15), "count": 750}]
    )
    r1 = classify_segment("SEG-1", 1, True, 5.0, df, {1: 600.0}, REF_TIME)
    r2 = classify_segment("SEG-1", 1, True, 5.0, df, {1: 600.0}, REF_TIME)
    assert r1.label == r2.label == "High"
    assert r1.reason == r2.reason


def test_join_sensor_mapping_multiple_sensors_same_segment():
    # Real-world case observed with the full 100-sensor set: two sensors
    # can legitimately snap to the same nearest edge. Must not crash, and
    # must keep the closer sensor as the segment's representative.
    from route_scoring import join_sensor_mapping

    route_segments = [{"segment_id": "SEG-SHARED"}]
    sensor_mapping = pd.DataFrame(
        [
            {"sensor_id": 10, "segment_id": "SEG-SHARED", "snap_m": 12.0, "snap_reliable": True},
            {"sensor_id": 20, "segment_id": "SEG-SHARED", "snap_m": 4.5, "snap_reliable": True},
        ]
    )
    joined = join_sensor_mapping(route_segments, sensor_mapping)
    assert len(joined) == 1
    assert joined[0]["sensor_id"] == 20  # the closer one (4.5m) wins
    assert joined[0]["snap_m"] == 4.5


def test_join_sensor_mapping_no_match_resolves_to_none():
    from route_scoring import join_sensor_mapping

    route_segments = [{"segment_id": "SEG-NO-SENSOR"}]
    sensor_mapping = pd.DataFrame(
        [{"sensor_id": 10, "segment_id": "SEG-OTHER", "snap_m": 12.0, "snap_reliable": True}]
    )
    joined = join_sensor_mapping(route_segments, sensor_mapping)
    assert joined[0]["sensor_id"] is None


def test_classify_segment_unreliable_snap_reason_uses_actual_threshold_not_hardcoded_default():
    # Regression test for a real bug caught on a live run: the reason text
    # claimed "exceeds reliable threshold (50m)" (the old
    # nearest-edge-only default) even when the pipeline had actually used
    # a 100m catchment radius (snap_sensors_to_blocks). The classification
    # was correct either way, but the stated reason was factually wrong --
    # snap_threshold_m must be threaded through so the reason matches
    # whatever threshold actually produced snap_reliable=False.
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=5,
        snap_reliable=False,
        snap_m=111.4,
        pedestrian_df=df,
        base_thresholds={5: 1774.8},
        reference_time=REF_TIME,
        snap_threshold_m=100.0,  # the ACTUAL threshold used, not the old 50m default
    )
    assert result.label == "Unknown"
    assert "100m" in result.reason
    assert "50m" not in result.reason


def test_classify_segment_unreliable_snap_falls_back_to_default_when_not_specified():
    # Backwards compatibility: callers that don't pass snap_threshold_m
    # (e.g. the original nearest-edge-only pipeline) still get the old
    # MAX_RELIABLE_SNAP_M-based message.
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=5,
        snap_reliable=False,
        snap_m=75.0,
        pedestrian_df=df,
        base_thresholds={5: 1774.8},
        reference_time=REF_TIME,
    )
    assert "50m" in result.reason


def test_classify_segment_catchment_too_far_reports_distance_not_generic_no_sensor():
    # Regression test for a real bug found comparing two live runs: the
    # catchment pipeline sets sensor_id=None when the nearest candidate is
    # outside the radius, but still populates snap_m with the real
    # distance. An earlier fix accidentally checked "sensor_id is None"
    # BEFORE "snap_reliable is False", which discarded that real distance
    # and silently downgraded the reason to a generic "no sensor mapped"
    # message -- less informative than before, even with identical
    # underlying data. This must report the real distance and threshold,
    # not the generic message, whenever snap_m is actually available.
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=None,  # catchment pipeline sets this to None when too far
        snap_reliable=False,
        snap_m=111.353462,  # but still gives us the real distance
        pedestrian_df=df,
        base_thresholds={},
        reference_time=REF_TIME,
        snap_threshold_m=100.0,
    )
    assert result.label == "Unknown"
    assert result.coverage == "unreliable_snap"
    assert "111.4m" in result.reason
    assert "100m" in result.reason
    assert result.reason != "no sensor mapped to this segment"


def test_classify_segment_empty_sensor_set_no_snap_m_falls_back_to_no_sensor_without_crashing():
    # Edge case the reordering fix must not break: if there were literally
    # no sensors to consider (empty sensor set), snap_reliable can still
    # be False but snap_m is None -- there's no real distance to report,
    # so this must fall through to the generic "no_sensor" reason rather
    # than crashing trying to format None as a float.
    df = make_pedestrian_df([])
    result = classify_segment(
        segment_id="SEG-1",
        sensor_id=None,
        snap_reliable=False,
        snap_m=None,
        pedestrian_df=df,
        base_thresholds={},
        reference_time=REF_TIME,
    )
    assert result.label == "Unknown"
    assert result.coverage == "no_sensor"


def test_find_peak_reference_time_picks_moment_with_most_sensors_over_threshold():
    from route_scoring import find_peak_reference_time

    t1 = REF_TIME
    t2 = REF_TIME + timedelta(hours=1)
    df = make_pedestrian_df([
        # t1: only sensor 1 is over its threshold (600)
        {"sensor_id": 1, "timestamp": t1, "count": 900},
        {"sensor_id": 2, "timestamp": t1, "count": 100},
        # t2: both sensors 1 and 2 are over their thresholds -- busier moment
        {"sensor_id": 1, "timestamp": t2, "count": 900},
        {"sensor_id": 2, "timestamp": t2, "count": 700},
    ])
    thresholds = {1: 600.0, 2: 600.0}
    result = find_peak_reference_time(df, thresholds)
    assert result == t2


def test_find_peak_reference_time_no_sensor_ever_over_threshold_returns_none():
    from route_scoring import find_peak_reference_time

    df = make_pedestrian_df([
        {"sensor_id": 1, "timestamp": REF_TIME, "count": 50},
        {"sensor_id": 2, "timestamp": REF_TIME, "count": 30},
    ])
    thresholds = {1: 600.0, 2: 600.0}
    result = find_peak_reference_time(df, thresholds)
    assert result is None


def test_find_peak_reference_time_ignores_sensors_with_no_threshold():
    from route_scoring import find_peak_reference_time

    df = make_pedestrian_df([
        {"sensor_id": 1, "timestamp": REF_TIME, "count": 900},  # no threshold available
        {"sensor_id": 2, "timestamp": REF_TIME, "count": 900},  # has threshold, over it
    ])
    thresholds = {2: 600.0}  # sensor 1 deliberately missing
    result = find_peak_reference_time(df, thresholds)
    assert result == REF_TIME  # still finds the one real over-threshold moment


def test_get_walk_graph_cached_only_fetches_once(tmp_path, monkeypatch):
    # Fully offline: monkeypatches osmnx.graph_from_place so no real
    # network call happens, and uses a tiny synthetic graph so
    # save_graphml/load_graphml round-trip fast. Confirms the actual
    # caching contract: first call fetches + saves, second call loads
    # from disk without fetching again.
    import networkx as nx
    import osmnx as ox
    from route_scoring import get_walk_graph_cached

    call_count = {"n": 0}

    def fake_graph_from_place(place, network_type="walk"):
        call_count["n"] += 1
        G = nx.MultiDiGraph(crs="epsg:4326")
        G.add_node(1, x=144.96, y=-37.81)
        G.add_node(2, x=144.97, y=-37.82)
        G.add_edge(1, 2, key=0, length=100.0)
        return G

    monkeypatch.setattr(ox, "graph_from_place", fake_graph_from_place)

    cache_file = tmp_path / "test_graph.graphml"
    assert not cache_file.exists()

    g1 = get_walk_graph_cached(cache_path=cache_file)
    assert call_count["n"] == 1
    assert cache_file.exists()
    assert len(g1.nodes) == 2

    g2 = get_walk_graph_cached(cache_path=cache_file)
    assert call_count["n"] == 1  # NOT fetched again -- loaded from cache
    assert len(g2.nodes) == 2


def test_get_walk_graph_cached_force_refresh_refetches(tmp_path, monkeypatch):
    import networkx as nx
    import osmnx as ox
    from route_scoring import get_walk_graph_cached

    call_count = {"n": 0}

    def fake_graph_from_place(place, network_type="walk"):
        call_count["n"] += 1
        G = nx.MultiDiGraph(crs="epsg:4326")
        G.add_node(1, x=144.96, y=-37.81)
        return G

    monkeypatch.setattr(ox, "graph_from_place", fake_graph_from_place)

    cache_file = tmp_path / "test_graph.graphml"
    get_walk_graph_cached(cache_path=cache_file)
    assert call_count["n"] == 1

    get_walk_graph_cached(cache_path=cache_file, force_refresh=True)
    assert call_count["n"] == 2  # explicitly refetched despite cache existing