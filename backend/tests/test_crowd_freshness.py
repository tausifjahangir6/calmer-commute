from datetime import datetime, timedelta, timezone

from app.services import prototype_crowd_service as crowd


def test_feed_older_than_60_minutes_cannot_support_route_scoring(monkeypatch):
    stale_time = (datetime.now(timezone.utc) - timedelta(minutes=61)).isoformat()
    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1,))
    monkeypatch.setattr(crowd, "_sensor_appears_decommissioned", lambda *a, **k: False)
    monkeypatch.setattr(crowd, "_historical_estimate", lambda *a, **k: (None, False))
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
    assert result[0]["evidence"] == "insufficient-history"


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
    monkeypatch.setattr(crowd, "_sensor_appears_decommissioned", lambda *a, **k: False)
    monkeypatch.setattr(crowd, "_historical_estimate", lambda *a, **k: (None, False))
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
    assert by_id[2]["evidence"] == "insufficient-history"


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
    """Regression test for the window-anchoring issue found while
    building the historical-estimate fallback (2026-08-10). Even after
    the per-sensor FRESHNESS fix, the 15-minute WINDOW itself must be
    built from the sensor's own latest reading -- not a different
    sensor's -- or a sensor that individually reported 12 minutes ago
    can still miss its own window and wrongly fall through to the
    historical fallback.
    """
    now = datetime.now(timezone.utc)
    sensor_1_time = now.isoformat()  # the globally freshest reading
    sensor_2_time = (now - timedelta(minutes=12)).isoformat()  # its own recent reading

    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1, 2))
    monkeypatch.setattr(crowd, "_sensor_appears_decommissioned", lambda *a, **k: False)
    monkeypatch.setattr(crowd, "_historical_estimate", lambda *a, **k: (999, True))  # would prove a bug if used
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

    # sensor 2's own reading (12 min ago) is well inside its OWN 15-min
    # window -- it must be "observed" from real data, never fall through
    # to the (mocked, obviously-wrong) historical estimate of 999.
    assert by_id[2]["freshness"] == "fresh"
    assert by_id[2]["evidence"] == "observed"
    assert by_id[2]["peoplePerMinute"] != 999


def test_historical_estimate_reliable_when_samples_agree(monkeypatch):
    monkeypatch.setattr(
        crowd,
        "_fetch_same_weekday_hour_history",
        lambda *a, **k: [0.0, 0.0, 1.0, 0.0],
    )
    estimate, reliable = crowd._historical_estimate(1, datetime(2026, 8, 10, 2, 0, tzinfo=crowd.MELBOURNE_TZ))
    assert reliable is True
    assert estimate is not None


def test_historical_estimate_unreliable_when_samples_disagree(monkeypatch):
    """20/90/45/88 has far too wide a spread relative to its own average
    to trust as a single number -- must not be silently averaged into a
    fake middle-ground estimate.
    """
    monkeypatch.setattr(
        crowd,
        "_fetch_same_weekday_hour_history",
        lambda *a, **k: [20.0, 90.0, 45.0, 88.0],
    )
    estimate, reliable = crowd._historical_estimate(1, datetime(2026, 8, 10, 17, 0, tzinfo=crowd.MELBOURNE_TZ))
    assert reliable is False


def test_historical_estimate_insufficient_when_too_few_samples(monkeypatch):
    monkeypatch.setattr(crowd, "_fetch_same_weekday_hour_history", lambda *a, **k: [0.0, 1.0])
    estimate, reliable = crowd._historical_estimate(1, datetime(2026, 8, 10, 2, 0, tzinfo=crowd.MELBOURNE_TZ))
    assert reliable is False
    assert estimate is None


def test_sensor_appears_decommissioned_when_all_checkpoints_zero(monkeypatch):
    expected = crowd.DECOMMISSIONED_CHECK_DAYS * len(crowd.DECOMMISSIONED_CHECK_HOURS)
    hours = crowd.DECOMMISSIONED_CHECK_HOURS
    rows = [{"pedestriancount": 0, "hourday": hours[i % len(hours)]} for i in range(expected)]
    monkeypatch.setattr(crowd, "_read_json", lambda *args, **kwargs: rows)
    assert crowd._sensor_appears_decommissioned(1) is True


def test_sensor_not_decommissioned_if_any_checkpoint_nonzero(monkeypatch):
    expected = crowd.DECOMMISSIONED_CHECK_DAYS * len(crowd.DECOMMISSIONED_CHECK_HOURS)
    hours = crowd.DECOMMISSIONED_CHECK_HOURS
    rows = [{"pedestriancount": 0, "hourday": hours[i % len(hours)]} for i in range(expected - 1)]
    rows.append({"pedestriancount": 5, "hourday": hours[0]})
    monkeypatch.setattr(crowd, "_read_json", lambda *args, **kwargs: rows)
    assert crowd._sensor_appears_decommissioned(1) is False


def test_sensor_not_decommissioned_when_insufficient_history(monkeypatch):
    """Too little history to judge must NOT default to "decommissioned"
    -- that would be its own kind of unsupported guess.
    """
    hours = crowd.DECOMMISSIONED_CHECK_HOURS
    rows = [{"pedestriancount": 0, "hourday": hours[i % len(hours)]} for i in range(5)]
    monkeypatch.setattr(crowd, "_read_json", lambda *args, **kwargs: rows)
    assert crowd._sensor_appears_decommissioned(1) is False


def test_gap_sensor_uses_reliable_historical_estimate_not_zero(monkeypatch):
    """End-to-end: a sensor with NO minute-level rows at all (a genuine
    reporting gap -- not just an old single reading, since Step 1's
    per-sensor window means any row a sensor DOES have always falls
    inside its own window) must fall back to a reliable historical
    estimate rather than being silently treated as a confirmed zero
    (the original inferred-zero problem this fallback chain exists to
    fix).
    """
    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1,))
    monkeypatch.setattr(crowd, "_sensor_appears_decommissioned", lambda *a, **k: False)
    monkeypatch.setattr(crowd, "_historical_estimate", lambda *a, **k: (12.0, True))
    monkeypatch.setattr(crowd, "_read_json", lambda *args, **kwargs: [])  # no rows at all for this sensor

    result = crowd._read_map_sensors(None, {1})

    assert result[0]["freshness"] == "estimated"
    assert result[0]["evidence"] == "hourly-estimate"
    assert result[0]["peoplePerMinute"] == 12


def test_gap_sensor_with_unreliable_history_stays_unknown_not_zero(monkeypatch):
    """The core Data Integrity guarantee: when a sensor has no rows at
    all AND no reliable historical estimate exists, the result must be
    a genuine "don't know" -- never a guessed zero and never a guessed
    Low.
    """
    monkeypatch.setattr(crowd, "MAP_SENSOR_IDS", (1,))
    monkeypatch.setattr(crowd, "_sensor_appears_decommissioned", lambda *a, **k: False)
    monkeypatch.setattr(crowd, "_historical_estimate", lambda *a, **k: (None, False))
    monkeypatch.setattr(crowd, "_read_json", lambda *args, **kwargs: [])

    result = crowd._read_map_sensors(None, {1})

    assert result[0]["peoplePerMinute"] is None
    assert result[0]["freshness"] == "unavailable"
    assert result[0]["evidence"] == "insufficient-history"