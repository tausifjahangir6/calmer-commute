"""Read and normalise the supplied City of Melbourne sensor-location data."""

import csv
from functools import lru_cache
from pathlib import Path


@lru_cache(maxsize=1)
def load_sensor_locations(csv_path: str) -> tuple[dict, ...]:
    """Load immutable sensor records once; the CSV contains locations, not live counts."""

    path = Path(csv_path)
    if not path.exists():
        return ()
    valid_sensors = []
    with path.open(encoding="utf-8-sig", newline="") as sensor_file:
        for row in csv.DictReader(sensor_file):
            latitude = (row.get("Latitude") or "").strip()
            longitude = (row.get("Longitude") or "").strip()
            if not latitude or not longitude:
                continue
            try:
                valid_sensors.append(
                    {
                        "sensor_id": row.get("Sensor ID") or row.get("Sensor_location_ID"),
                        "name": (row.get("Name") or "").strip(),
                        "latitude": float(latitude),
                        "longitude": float(longitude),
                    }
                )
            except ValueError:
                # A malformed location cannot support geographic matching.
                continue
    return tuple(valid_sensors)


# DATA TEAM REPLACEMENT POINT (suggested imported adapter):
#
# def load_sensor_observations(at_time: str | None) -> tuple[dict, ...]:
#     """Return normalised observations for route scoring.
#
#     Every record should contain sensor_id, name, latitude, longitude,
#     pedestrian_count_per_minute, observed_at, freshness_minutes and
#     availability (available, stale, missing). This function should hide the
#     City of Melbourne API/file format from the rest of the application.
#     """
#     from app.data.pedestrian_adapter import fetch_observations
#     return fetch_observations(at_time=at_time)
