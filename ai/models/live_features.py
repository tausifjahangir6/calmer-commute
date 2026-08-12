"""
live_features.py
Live counterpart to export_latest_features.py's static snapshot. Builds
next_hour_forecast()'s required feature row for one sensor by querying the
City of Melbourne "pedestrian-counting-system-monthly-counts-per-hour"
dataset directly, instead of reading a file exported once and never
refreshed.

CAVEAT, not swept under the rug: this dataset has its own ingestion
latency (observed ~1 day behind wall-clock "now" during testing), so
"the hour being forecast" here is one hour after the LATEST row this
sensor actually has -- not one hour after real-time now. That's still a
meaningful improvement over export_latest_features.py's permanently
frozen 2026-08-05 snapshot: this value advances every day as the city's
own data catches up, instead of never moving. A truly real-time feed
would need the per-minute dataset aggregated into rolling hourly buckets,
which is separate, larger scope.

CYCLICAL ENCODING CONVENTION: reverse-engineered from latest_features.json
since the upstream training CSV's own generation code isn't in this repo.
  hour_sin/cos = sin/cos(2*pi*hour/24), hour in 0..23
  dow_sin/cos  = sin/cos(2*pi*dow/7), dow = Sunday=0 .. Saturday=6
Verified against sensor 84's frozen row (timestamp 2026-08-05T03:00, a
Wednesday): dow=3 reproduces its dow_sin/dow_cos to full float precision.
"""
from __future__ import annotations
import json
import math
import time
from datetime import datetime, timedelta
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
HOURLY_DATASET = "pedestrian-counting-system-monthly-counts-per-hour"
LOOKBACK_ROWS = 250  # > 168h lag + 24h window (192h), with slack for gaps
PAGE_SIZE = 100  # the API's own hard cap on the limit parameter
REQUEST_TIMEOUT_SECONDS = 8
CACHE_TTL_SECONDS = 900  # hourly-granularity data doesn't need per-request refetching

_STATIC_ATTRS_PATH = Path(__file__).resolve().parent / "latest_features.json"
_static_attrs_cache: dict | None = None
_live_cache: dict[int, tuple[float, dict | None]] = {}


def _static_attrs(sensor_id: int) -> dict:
    """is_cbd / sensor_name are fixed per-sensor properties, not
    time-dependent -- safe to source from the existing snapshot file even
    though ITS time-varying fields (lag_24h etc) are stale."""
    global _static_attrs_cache
    if _static_attrs_cache is None:
        try:
            _static_attrs_cache = json.loads(_STATIC_ATTRS_PATH.read_text())
        except (FileNotFoundError, json.JSONDecodeError):
            _static_attrs_cache = {}
    entry = _static_attrs_cache.get(str(sensor_id), {})
    return {"is_cbd": entry.get("is_cbd", 0), "sensor_name": entry.get("sensor_name", str(sensor_id))}


def _fetch_hourly_rows(sensor_id: int) -> list[dict]:
    """Paginates in PAGE_SIZE batches -- the API hard-caps `limit` at 100
    (InvalidRESTParameterError above that), so LOOKBACK_ROWS worth of
    history needs multiple requests, same pattern as
    prototype_crowd_service.py's _read_active_sensor_ids."""
    rows: list[dict] = []
    offset = 0
    while len(rows) < LOOKBACK_ROWS:
        params = {
            "limit": PAGE_SIZE,
            "offset": offset,
            "where": f"location_id={sensor_id}",
            "order_by": "sensing_date desc,hourday desc",
        }
        url = f"{API}/{HOURLY_DATASET}/records?{urlencode(params)}"
        request = Request(url, headers={"Accept": "application/json"})
        with urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            page = json.loads(response.read().decode("utf-8")).get("results", [])
        if not page:
            break
        rows.extend(page)
        if len(page) < PAGE_SIZE:
            break  # last page was partial -- nothing more to fetch
        offset += PAGE_SIZE
    return rows


def _compute_live_features(sensor_id: int) -> dict | None:
    try:
        rows = _fetch_hourly_rows(sensor_id)
    except Exception:
        # Network error, timeout, malformed response, dataset unreachable
        # -- never raise; caller falls back to the frozen snapshot.
        return None
    if not rows:
        return None

    hour_map: dict[datetime, int] = {}
    for row in rows:
        if row.get("pedestriancount") is None:
            continue
        try:
            dt = datetime.fromisoformat(row["sensing_date"]) + timedelta(hours=int(row["hourday"]))
        except (KeyError, TypeError, ValueError):
            continue
        hour_map[dt] = int(row["pedestriancount"])

    if not hour_map:
        return None

    latest_dt = max(hour_map)
    target_dt = latest_dt + timedelta(hours=1)

    lag_24h = hour_map.get(target_dt - timedelta(hours=24))
    lag_168h = hour_map.get(target_dt - timedelta(hours=168))
    if lag_24h is None or lag_168h is None:
        # Same "no forecast rather than a wrong one" rule as
        # export_latest_features.py / next_hour_forecast's own missing-
        # input handling -- an incomplete live row is worse than falling
        # back to the (complete, if stale) static snapshot.
        return None

    window_values = [
        hour_map[target_dt - timedelta(hours=h)]
        for h in range(1, 25)
        if (target_dt - timedelta(hours=h)) in hour_map
    ]
    if not window_values:
        return None
    rolling_mean_24h = sum(window_values) / len(window_values)

    dow = target_dt.isoweekday() % 7  # Sunday=0 .. Saturday=6
    hour = target_dt.hour
    attrs = _static_attrs(sensor_id)

    return {
        "is_weekend": 1 if dow in (0, 6) else 0,
        "is_cbd": attrs["is_cbd"],
        "sensor_name": attrs["sensor_name"],
        "obs_in_window_24h": len(window_values),
        "hour_sin": math.sin(2 * math.pi * hour / 24),
        "hour_cos": math.cos(2 * math.pi * hour / 24),
        "dow_sin": math.sin(2 * math.pi * dow / 7),
        "dow_cos": math.cos(2 * math.pi * dow / 7),
        "lag_24h": lag_24h,
        "lag_168h": lag_168h,
        "rolling_mean_24h": rolling_mean_24h,
        "timestamp": target_dt.isoformat(),
    }


def get_live_features(sensor_id: int) -> dict | None:
    """
    Returns a next_hour_forecast()-ready feature dict for sensor_id, or
    None if live data couldn't be fetched or didn't have enough recent
    history to compute lag_24h/lag_168h -- callers should fall back to
    the frozen snapshot in that case, not fail the request.

    Cached in-process for CACHE_TTL_SECONDS: this is hourly-granularity
    data that itself only advances once a day, so refetching on every
    single prediction request would be pure overhead, not freshness.
    """
    now = time.time()
    cached = _live_cache.get(sensor_id)
    if cached and now - cached[0] < CACHE_TTL_SECONDS:
        return cached[1]
    result = _compute_live_features(sensor_id)
    _live_cache[sensor_id] = (now, result)
    return result
