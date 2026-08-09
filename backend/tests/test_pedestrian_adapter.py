"""
test_pedestrian_adapter.py

Fully offline -- mocks the City of Melbourne API responses rather than
calling the live feed, so this runs anywhere without network access.
Does NOT prove the live feed itself works (that needs a real run in the
actual backend environment, per pedestrian_adapter.py's own honesty note)
-- it proves the parsing/joining/availability logic is correct given
realistic API response shapes.

Run this from backend/, with app/ as an importable package (matches how
the real Flask app and its own test suite already run).
"""

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