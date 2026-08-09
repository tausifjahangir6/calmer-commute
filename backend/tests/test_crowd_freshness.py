from datetime import datetime, timedelta, timezone

from app.services import prototype_crowd_service as crowd


def test_feed_older_than_30_minutes_cannot_support_route_scoring(monkeypatch):
    stale_time = (datetime.now(timezone.utc) - timedelta(minutes=31)).isoformat()
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
