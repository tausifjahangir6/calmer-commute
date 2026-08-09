from __future__ import annotations

import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

from ..services.prototype_crowd_service import _read_json, _age_minutes, _non_negative, MINUTE_DATASET, LOCATIONS_DATASET
from ..services.sensor_service import load_sensor_locations

FRESHNESS_STALE_THRESHOLD_MINUTES = 60  # widened from 30 (2026-08-09), see note below
# NOTE: this used to match prototype_crowd_service.py's own
# FEED_FRESHNESS_MINUTES (30) deliberately. Widened after a live test
# showed the real feed's normal publishing lag (34-37 min) routinely
# exceeded 30, making almost every route resolve to Unknown despite
# genuinely recent data. Real freshness is still shown transparently via
# each observation's freshness_minutes field either way -- this only
# changes the available/stale CUTOFF, not what's disclosed.
# WORTH FLAGGING: this now diverges from prototype_crowd_service.py's own
# threshold -- the same sensor reading could show "fresh" here and
# "stale" on the crowd map. Confirm with whoever owns that file whether
# 60 should become the shared value, or whether these two features are
# meant to have genuinely different freshness policies.

# Matches prototype_crowd_service.py's OWN proven batch size (_read_map_sensors).
# A real bug was caught here: an earlier version of this file queried ALL
# sensor IDs in one request instead of batching, and the request silently
# failed for the full ~67-sensor set (worked fine for a handful of IDs in
# isolated testing, which is exactly why it wasn't caught sooner) --
# almost certainly the same API-side constraint prototype_crowd_service.py's
# author already discovered and batched around.
BATCH_SIZE = 4

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
    behaviour.
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
    except Exception as error:
        print(f"[pedestrian_adapter] WARNING: could not fetch active sensor status: {error}", file=sys.stderr)
        active_ids = None  # unknown, not a crash -- treated as "can't confirm active" below

    rows = _fetch_minute_rows_batched(list(locations_by_id.keys()))

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


def _fetch_minute_rows_batched(sensor_ids: list[str]) -> list[dict]:
    """
    Queries the live feed in small batches (matching
    prototype_crowd_service.py's own proven BATCH_SIZE), run in parallel.
    A batch that fails is logged and treated as empty for just that
    batch -- one bad batch no longer silently blanks EVERY sensor's data,
    which is what happened when the whole sensor set was queried in a
    single request that failed as a whole.
    """
    batches = [sensor_ids[i:i + BATCH_SIZE] for i in range(0, len(sensor_ids), BATCH_SIZE)]

    def read_batch(batch: list[str]) -> list[dict]:
        try:
            return _read_json(
                MINUTE_DATASET,
                limit=100,
                where=f"location_id in ({','.join(batch)})",
                order_by="sensing_datetime desc",
            )
        except Exception as error:
            print(f"[pedestrian_adapter] WARNING: batch {batch} failed: {error}", file=sys.stderr)
            return []

    with ThreadPoolExecutor(max_workers=8) as pool:
        pages = list(pool.map(read_batch, batches))

    return [row for page in pages for row in page]


def _read_active_sensor_ids() -> set[int]:
    """
    Paginates through the FULL sensor-locations dataset, not just the
    first page. REAL BUG THIS FIXES: the original single-page call
    (limit=100, no offset) silently truncated the real dataset --
    confirmed live: exactly 100 rows came back, and 9 real sensors with
    fresh, recent readings were entirely absent from those 100 rows, so
    they were wrongly treated as inactive ("missing") despite having
    perfectly good current data. Same root cause as the earlier
    minute-data batching bug: assuming one request returns everything.
    """
    page_size = 100
    offset = 0
    active_ids: set[int] = set()
    while True:
        rows = _read_json(LOCATIONS_DATASET, limit=page_size, offset=offset, select="location_id,status")
        if not rows:
            break
        active_ids.update(
            int(row["location_id"]) for row in rows if str(row.get("status", "")).upper() == "A"
        )
        if len(rows) < page_size:
            break  # last page was partial -- nothing more to fetch
        offset += page_size
    return active_ids


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