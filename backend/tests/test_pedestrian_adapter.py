from __future__ import annotations

import csv
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

import pytest


@pytest.fixture
def fake_sensor_csv(tmp_path):
    path = tmp_path / "sensors.csv"
    path.write_text(
        "Sensor ID,Name,Latitude,Longitude\n"
        "5,Bourke Street Mall,-37.8136,144.9648\n"
        "6,Flinders Street,-37.8184,144.9665\n"
    )
    return str(path)


def test_fresh_sensor_marked_available(fake_sensor_csv):
    from app.data.pedestrian_adapter import fetch_observations

    fresh_time = (datetime.now(timezone.utc) - timedelta(minutes=5)).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": "5", "status": "A"}, {"location_id": "6", "status": "A"}]
        return [{"location_id": "5", "sensing_datetime": fresh_time, "total_of_directions": "42"}]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    by_id = {obs["sensor_id"]: obs for obs in result}
    assert by_id["5"]["availability"] == "available"
    assert by_id["5"]["pedestrian_count_per_minute"] == 42


def test_stale_sensor_marked_stale_not_available_even_with_high_count(fake_sensor_csv):
    from app.data.pedestrian_adapter import fetch_observations

    stale_time = (datetime.now(timezone.utc) - timedelta(minutes=90)).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": "5", "status": "A"}]
        return [{"location_id": "5", "sensing_datetime": stale_time, "total_of_directions": "999"}]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    assert result[0]["availability"] == "stale"


def test_sensor_with_no_feed_data_marked_missing(fake_sensor_csv):
    from app.data.pedestrian_adapter import fetch_observations

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": "5", "status": "A"}, {"location_id": "6", "status": "A"}]
        return []

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    assert all(obs["availability"] == "missing" for obs in result)
    assert all(obs["pedestrian_count_per_minute"] is None for obs in result)


def test_inactive_sensor_marked_missing_even_with_recent_data(fake_sensor_csv):
    from app.data.pedestrian_adapter import fetch_observations

    fresh_time = (datetime.now(timezone.utc) - timedelta(minutes=2)).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": "5", "status": "I"}]  # Inactive
        return [{"location_id": "5", "sensing_datetime": fresh_time, "total_of_directions": "42"}]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    assert result[0]["availability"] == "missing"


def test_feed_unreachable_produces_all_missing_not_a_crash(fake_sensor_csv):
    from app.data.pedestrian_adapter import fetch_observations

    def fake_read_json_raises(dataset, **params):
        raise ConnectionError("simulated network failure")

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json_raises):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    assert len(result) == 2
    assert all(obs["availability"] == "missing" for obs in result)


def test_no_sensor_locations_returns_empty_tuple_not_a_crash():
    from app.data.pedestrian_adapter import fetch_observations

    # A genuinely nonexistent CSV path -- not None, since None now
    # correctly means "use the default file next to this module", not
    # "no data available". load_sensor_locations() already handles a
    # missing file gracefully (returns ()), so this should cascade the
    # same way.
    result = fetch_observations(sensor_csv_path="/tmp/definitely_does_not_exist.csv")
    assert result == ()


def test_many_sensors_batched_not_one_giant_query(tmp_path):
    # Regression test for a real production bug: fetch_observations()
    # originally queried ALL sensor IDs in a single request, which
    # silently failed for a realistic ~10+ sensor set (worked fine in
    # smaller isolated tests, which is exactly why it wasn't caught
    # sooner). Must batch, matching prototype_crowd_service.py's own
    # proven BATCH_SIZE, so one oversized query can't blank every sensor.
    from app.data.pedestrian_adapter import fetch_observations, BATCH_SIZE

    path = tmp_path / "many_sensors.csv"
    lines = ["Sensor ID,Name,Latitude,Longitude"]
    for i in range(1, 11):  # 10 sensors -- more than BATCH_SIZE
        lines.append(f"{i},Sensor {i},-37.81{i},144.96{i}")
    path.write_text("\n".join(lines))

    fresh_time = (datetime.now(timezone.utc) - timedelta(minutes=5)).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": str(i), "status": "A"} for i in range(1, 11)]
        where = params.get("where", "")
        ids_in_query = where.count(",") + 1 if "in (" in where else 0
        if ids_in_query > BATCH_SIZE:
            raise Exception("simulated API rejection: too many IDs in one query")
        return [
            {"location_id": str(i), "sensing_datetime": fresh_time, "total_of_directions": "10"}
            for i in range(1, 11) if str(i) in where
        ]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=str(path))

    available = [o for o in result if o["availability"] == "available"]
    assert len(available) == 10  # every sensor got real data, none silently blanked


def test_real_world_publishing_lag_now_counts_as_available(fake_sensor_csv):
    # Regression test for the exact live scenario that prompted widening
    # the threshold: real observed lag of ~35 minutes past the OLD 30-min
    # cutoff (would have been "stale") should now be "available" under
    # the widened 60-min threshold.
    from app.data.pedestrian_adapter import fetch_observations

    lagged_time = (datetime.now(timezone.utc) - timedelta(minutes=35)).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def fake_read_json(dataset, **params):
        if "sensor-locations" in dataset:
            return [{"location_id": "5", "status": "A"}]
        return [{"location_id": "5", "sensing_datetime": lagged_time, "total_of_directions": "25"}]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        result = fetch_observations(sensor_csv_path=fake_sensor_csv)

    assert result[0]["availability"] == "available"


def test_active_sensor_status_paginated_beyond_first_page():
    # Regression test for a real production bug: _read_active_sensor_ids()
    # originally fetched only ONE page (limit=100, no offset) of the
    # sensor-locations dataset. Confirmed live: exactly 100 rows came
    # back, and 9 real, currently-reporting sensors were entirely absent
    # from that page -- wrongly treated as inactive ("missing") despite
    # having perfectly good fresh data. Must paginate through the whole
    # dataset, not assume one page is everything.
    from app.data.pedestrian_adapter import _read_active_sensor_ids

    def fake_read_json(dataset, **params):
        offset = params.get("offset", 0)
        limit = params.get("limit", 100)
        all_rows = [{"location_id": str(i), "status": "A"} for i in range(1, 151)]  # 150 total, 2 pages
        return all_rows[offset:offset + limit]

    with patch("app.data.pedestrian_adapter._read_json", side_effect=fake_read_json):
        active = _read_active_sensor_ids()

    assert len(active) == 150
    assert 121 in active  # only reachable if pagination actually continued past the first 100