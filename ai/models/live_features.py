"""
live_features.py
Live counterpart to export_latest_features.py's static snapshot. Builds
next_hour_forecast()'s required feature row for one sensor by querying the
City of Melbourne "pedestrian-counting-system-monthly-counts-per-hour"
dataset directly, instead of reading a file exported once and never
refreshed.

DELIBERATE ACCURACY TRADE-OFF (2026-08-12): the target hour here is
anchored to real wall-clock now (the next hour boundary), NOT to the
latest hour this sensor's data actually covers. The source dataset has
its own ingestion latency (observed ~35h behind "now" during testing),
so lag_24h/lag_168h/rolling_mean_24h can't be exact same-hour lookups
for a genuinely current target hour -- the exact hours they'd need
haven't been published yet. Instead they use the NEAREST available
historical reading to each lag point, and rolling_mean_24h uses the most
recently available 24 hourly readings on file rather than requiring them
to immediately precede the target hour. This means forecasts now reflect
today's real hour-of-day/day-of-week pattern (hour_sin/cos, dow_sin/cos
are exact), traded against lag features that are approximations rather
than the exact historical counts the model was trained to expect. An
earlier version anchored the target hour to the latest available row
instead (exact lag features, but the target hour itself could be a day
or more stale) -- this file supersedes that approach by explicit
decision, not oversight: see conversation history for the trade-off.
next_hour_forecast's own confidence labelling (obs_in_window_24h-driven)
naturally downgrades confidence when the rolling window is thin, so the
degraded-accuracy case is still surfaced, not hidden.

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
from zoneinfo import ZoneInfo

API = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
HOURLY_DATASET = "pedestrian-counting-system-monthly-counts-per-hour"
MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")
LOOKBACK_ROWS = 250  # generous history for nearest-match lookups + rolling mean
PAGE_SIZE = 100  # the API's own hard cap on the limit parameter
REQUEST_TIMEOUT_SECONDS = 8
CACHE_TTL_SECONDS = 300  # short: target hour tracks wall-clock, so cache shouldn't outlive an hour boundary by much

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

    # Real wall-clock "next hour", not "latest available row + 1" -- see
    # the DELIBERATE ACCURACY TRADE-OFF note above.
    now_local = datetime.now(MELBOURNE_TZ).replace(tzinfo=None, minute=0, second=0, microsecond=0)
    target_dt = now_local + timedelta(hours=1)

    def _nearest(target: datetime) -> int:
        closest_dt = min(hour_map, key=lambda dt: abs((dt - target).total_seconds()))
        return hour_map[closest_dt]

    lag_24h = _nearest(target_dt - timedelta(hours=24))
    lag_168h = _nearest(target_dt - timedelta(hours=168))

    # Most recently PUBLISHED 24 readings on file, not the 24 hours
    # immediately preceding target_dt -- those don't exist yet for a
    # genuinely current target hour, same reason lag_* uses nearest-match
    # above. obs_in_window_24h still reports how many real points fed
    # this, so next_hour_forecast's confidence labelling correctly
    # downgrades trust when that's thin.
    recent_dts = sorted(hour_map, reverse=True)[:24]
    window_values = [hour_map[dt] for dt in recent_dts]
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
    None if live data couldn't be fetched at all (network failure, or the
    sensor has no published history whatsoever) -- callers should fall
    back to the frozen snapshot in that case, not fail the request. If
    ANY history exists, lag_24h/lag_168h/rolling_mean_24h are always
    populated (nearest-available approximations, see module docstring),
    so this only returns None on a genuine total data outage now.

    Cached in-process for CACHE_TTL_SECONDS to avoid a network round trip
    per prediction request; kept short since the target hour advances on
    every wall-clock hour boundary.
    """
    now = time.time()
    cached = _live_cache.get(sensor_id)
    if cached and now - cached[0] < CACHE_TTL_SECONDS:
        return cached[1]
    result = _compute_live_features(sensor_id)
    _live_cache[sensor_id] = (now, result)
    return result
