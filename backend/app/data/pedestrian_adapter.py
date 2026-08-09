"""
pedestrian_adapter.py

THE "DATA TEAM REPLACEMENT POINT" named in sensor_service.py's own
comment:

    # DATA TEAM REPLACEMENT POINT (suggested imported adapter):
    #
    # def load_sensor_observations(at_time: str | None) -> tuple[dict, ...]:
    #     from app.data.pedestrian_adapter import fetch_observations
    #     return fetch_observations(at_time=at_time)

WHY THIS ISN'T WRITTEN FROM SCRATCH: prototype_crowd_service.py already
has real, working logic reading the exact same City of Melbourne live
per-minute feed (MINUTE_DATASET) that score_candidate_routes() needs.
Rather than duplicate that logic, this reuses its proven read/parse
functions directly and reshapes the output into the sensor_observations
contract shape (sensor_id, name, latitude, longitude,
pedestrian_count_per_minute, observed_at, freshness_minutes,
availability) that sensor_service.py's docstring specifies.

HONEST LIMITATION, stated plainly: this file's logic was written and
tested here against realistic FAKE data (see test suite), reusing
prototype_crowd_service.py's already-proven read/parse functions
directly rather than duplicating them untested. It has NOT been run
against the live data.melbourne.vic.gov.au feed from this environment --
that network isn't reachable here (same restriction that applied to
every OSM-dependent script earlier in this project). Confirm it actually
pulls real data by running it in the real backend environment before
relying on it for a demo.
"""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from ..services.prototype_crowd_service import _read_json, _age_minutes, _non_negative, MINUTE_DATASET, LOCATIONS_DATASET
from ..services.sensor_service import load_sensor_locations

FRESHNESS_STALE_THRESHOLD_MINUTES = 30  # matches prototype_crowd_service.py's own FEED_FRESHNESS_MINUTES

# Defaults to the CSV that already lives right next to this file
# (backend/app/data/sensor_locations.csv), rather than depending on a
# config key this module never saw confirmed -- avoids the exact "quietly
# returns nothing" failure mode this whole project has been careful to
# catch elsewhere.
_DEFAULT_SENSOR_CSV_PATH = str(Path(__file__).resolve().parent / "sensor_locations.csv")


def fetch_observations(at_time: str | None = None, sensor_csv_path: str | None = None) -> tuple[dict, ...]:
    """
    Returns normalised, current pedestrian observations for every sensor
    with a known location, in the exact shape route_service.py's
    sensor_observations contract expects.

    at_time is currently unused (accepted for contract-signature
    compatibility) -- this always returns the LATEST available reading
    per sensor, same as prototype_crowd_service.py's own live-feed
    behaviour. Historical point-in-time lookup would need a different
    dataset query (HOURLY_DATASET, per prototype_crowd_service.py's own
    _historical_payload precedent) -- not built here, flagged as a real
    gap if historical replay is ever needed for this specific path.
    """
    locations = load_sensor_locations(sensor_csv_path or _DEFAULT_SENSOR_CSV_PATH)
    locations_by_id = {str(loc["sensor_id"]): loc for loc in locations if loc.get("sensor_id")}

    if not locations_by_id:
        # No known sensor locations at all -- nothing to observe.
        # Empty tuple, not an error: this correctly cascades into every
        # downstream route resolving to Unknown (Data Integrity), not a crash.
        return ()

    try:
        active_ids = _read_active_sensor_ids()
    except Exception:
        active_ids = None  # unknown, not a crash -- treated as "can't confirm active" below

    try:
        rows = _read_json(
            MINUTE_DATASET,
            limit=400,
            where=f"location_id in ({','.join(locations_by_id.keys())})",
            order_by="sensing_datetime desc",
        )
    except Exception:
        # Live feed unreachable -- every sensor becomes "missing", which
        # correctly cascades to Unknown downstream, never a guessed value.
        rows = []

    latest_by_sensor: dict[str, dict] = {}
    for row in rows:
        sensor_id = str(row.get("location_id", ""))
        if sensor_id not in locations_by_id:
            continue
        if not row.get("sensing_datetime") or not _non_negative(row.get("total_of_directions")):
            continue
        existing = latest_by_sensor.get(sensor_id)
        if existing is None or row["sensing_datetime"] > existing["sensing_datetime"]:
            latest_by_sensor[sensor_id] = row

    observations = []
    now = datetime.now(timezone.utc)
    for sensor_id, location in locations_by_id.items():
        row = latest_by_sensor.get(sensor_id)
        is_active = True if active_ids is None else (int(sensor_id) in active_ids if sensor_id.isdigit() else False)

        if row is None:
            observations.append(_build_observation(location, count=None, observed_at=None, freshness_minutes=None, availability="missing"))
            continue

        observed_at = row["sensing_datetime"]
        freshness_minutes = _age_minutes(observed_at)
        if not is_active:
            availability = "missing"
        elif freshness_minutes <= FRESHNESS_STALE_THRESHOLD_MINUTES:
            availability = "available"
        else:
            availability = "stale"

        count = int(row["total_of_directions"]) if availability != "missing" else None
        observations.append(_build_observation(location, count=count, observed_at=observed_at, freshness_minutes=round(freshness_minutes, 1) if freshness_minutes != float("inf") else None, availability=availability))

    return tuple(observations)


def _read_active_sensor_ids() -> set[int]:
    rows = _read_json(LOCATIONS_DATASET, limit=100, select="location_id,status")
    return {int(row["location_id"]) for row in rows if str(row.get("status", "")).upper() == "A"}


def _build_observation(location: dict, count, observed_at, freshness_minutes, availability) -> dict:
    return {
        "sensor_id": location["sensor_id"],
        "name": location.get("name", ""),
        "latitude": location["latitude"],
        "longitude": location["longitude"],
        "pedestrian_count_per_minute": count,
        "observed_at": observed_at,
        "freshness_minutes": freshness_minutes,
        "availability": availability,
    }