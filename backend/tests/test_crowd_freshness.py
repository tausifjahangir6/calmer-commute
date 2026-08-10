from datetime import datetime, timedelta, timezone

from app.services import prototype_crowd_service as crowd


def test_feed_older_than_60_minutes_cannot_support_route_scoring(monkeypatch):
    stale_time = (datetime.now(timezone.utc) - timedelta(minutes=61)).isoformat()
    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1,))
    monkeypatch.setattr(
        crowd,
        "_read_json",
        lambda *args, **kwargs: [
            {"location_id": 1, "sensing_datetime": stale_time, "total_of_directions": 20}
        ],
    )

    result = crowd._read_map_sensors(stale_time, {1})

    assert result[0]["freshness"] == "stale"
    assert result[0]["peoplePerMinute"] is None
    assert result[0]["evidence"] == "unavailable"


def test_per_sensor_freshness_is_independent_of_other_sensors(monkeypatch):
    """Regression test for the shared-global-timestamp bug (2026-08-10).

    Previously, freshness was gated by ONE `feed_fresh` boolean computed
    from the single newest reading across the entire feed, so a sensor
    that individually hadn't reported in 90+ minutes could still be
    labelled "fresh" as long as some OTHER sensor had reported recently.
    Each sensor's freshness must be judged against its OWN latest
    observation, never the feed's global newest timestamp.
    """
    now = datetime.now(timezone.utc)
    fresh_time = (now - timedelta(minutes=20)).isoformat()
    stale_time = (now - timedelta(minutes=90)).isoformat()

    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1, 2))
    monkeypatch.setattr(
        crowd,
        "_read_json",
        lambda *args, **kwargs: [
            {"location_id": 1, "sensing_datetime": fresh_time, "total_of_directions": 20},
            {"location_id": 2, "sensing_datetime": stale_time, "total_of_directions": 15},
        ],
    )

    result = crowd._read_map_sensors(fresh_time, {1, 2})
    by_id = {item["id"]: item for item in result}

    assert by_id[1]["freshness"] == "fresh"
    assert by_id[1]["peoplePerMinute"] is not None

    assert by_id[2]["freshness"] == "stale"
    assert by_id[2]["peoplePerMinute"] is None
    assert by_id[2]["evidence"] == "unavailable"


def test_sensor_at_exactly_60_minutes_is_still_fresh(monkeypatch):
    """FEED_FRESHNESS_MINUTES uses <=, so a reading exactly at the
    threshold should count as fresh, not stale. Mocks _age_minutes
    directly rather than real timedelta arithmetic so the boundary is
    exact and the test can't flake from wall-clock drift.
    """
    monkeypatch.setattr(crowd, "FEED_FRESHNESS_MINUTES", 60)
    monkeypatch.setattr(crowd, "_age_minutes", lambda value: 60.0)

    assert crowd._sensor_is_fresh("2026-08-10T00:00:00Z") is True


def test_sensor_at_61_minutes_is_stale(monkeypatch):
    """One minute past the threshold must resolve to stale."""
    monkeypatch.setattr(crowd, "FEED_FRESHNESS_MINUTES", 60)
    monkeypatch.setattr(crowd, "_age_minutes", lambda value: 61.0)

    assert crowd._sensor_is_fresh("2026-08-10T00:00:00Z") is False


def test_own_window_not_borrowed_from_a_different_sensor(monkeypatch):
    """The 15-minute WINDOW itself must be built from the sensor's own
    latest reading -- not a different sensor's -- or a sensor that
    individually reported 12 minutes ago could miss its own window
    purely because the window was anchored to a different sensor's
    timestamp.
    """
    now = datetime.now(timezone.utc)
    sensor_1_time = now.isoformat()  # the globally freshest reading
    sensor_2_time = (now - timedelta(minutes=12)).isoformat()  # its own recent reading

    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1, 2))
    monkeypatch.setattr(
        crowd,
        "_read_json",
        lambda *args, **kwargs: [
            {"location_id": 1, "sensing_datetime": sensor_1_time, "total_of_directions": 20},
            {"location_id": 2, "sensing_datetime": sensor_2_time, "total_of_directions": 15},
        ],
    )

    result = crowd._read_map_sensors(sensor_1_time, {1, 2})
    by_id = {item["id"]: item for item in result}

    assert by_id[2]["freshness"] == "fresh"
    assert by_id[2]["evidence"] == "observed"
    assert by_id[2]["peoplePerMinute"] is not None