"""Flask port of the deployed Calmer Commute v81 crowd logic."""

import json
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

API = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
MINUTE_DATASET = "pedestrian-counting-system-past-hour-counts-per-minute"
HOURLY_DATASET = "pedestrian-counting-system-monthly-counts-per-hour"
LOCATIONS_DATASET = "pedestrian-counting-system-sensor-locations"
WINDOW_MINUTES = 15
FEED_FRESHNESS_MINUTES = 60
MELBOURNE_TZ = ZoneInfo("Australia/Melbourne")

# Historical-estimate fallback (for sensors with a live reporting gap, not
# a confirmed zero -- see _historical_estimate). 4 weeks stays inside one
# Melbourne season (~13 weeks each), so an estimate never quietly blends
# winter data into a summer reading.
HISTORICAL_LOOKBACK_WEEKS = 4
# Samples for the same weekday/hour must not span more than this
# multiple between busiest and quietest to be trusted; e.g. 20/90/45/88
# is a 4.5x spread (90/20) and is correctly rejected as unreliable,
# while 0/0/1/0 is a 1x spread (using max(min,1) to avoid dividing by
# zero) and is trivially accepted.
HISTORICAL_CONSISTENCY_MAX_RATIO = 3.0

# Decommissioned-sensor safety net (backup to sensor_location.status, in
# case that field lags behind reality). 6 checkpoints spread across quiet
# hours AND both commute peaks, checked every day for 4 weeks -- 168
# checkpoints total. Only flags a sensor if EVERY one of them reads zero;
# any single nonzero reading anywhere proves the sensor is alive.
DECOMMISSIONED_CHECK_HOURS = (2, 6, 9, 12, 17, 21)
DECOMMISSIONED_CHECK_DAYS = 28

MAP_SENSOR_IDS = (1,2,3,4,5,6,8,9,10,11,12,14,17,18,19,20,21,23,24,25,27,29,30,31,35,36,37,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,56,58,59,61,62,63,66,67,68,69,70,71,72,75,76,77,79,84,85,86,87,107)
ROUTE_SENSORS = {
    "train": ({"id": 41, "name": "Flinders Lane-Swanston Street (West)"}, {"id": 53, "name": "Collins Street (North)"}),
    "tram": ({"id": 5, "name": "Princes Bridge"},),
}


def get_crowd_payload(scenario: str | None = None) -> dict:
    if scenario == "2026-08-04T07:00":
        return _historical_payload()
    definitions = (*ROUTE_SENSORS["train"], *ROUTE_SENSORS["tram"])
    with ThreadPoolExecutor(max_workers=8) as pool:
        readings = list(pool.map(_read_sensor, definitions))
        feed_latest_future = pool.submit(_read_feed_latest)
        active_ids_future = pool.submit(_read_active_sensor_ids)
        feed_latest = feed_latest_future.result()
        try:
            active_ids = active_ids_future.result()
        except Exception:
            active_ids = None
    map_sensors = _read_map_sensors(feed_latest, active_ids)
    age_minutes = _age_minutes(feed_latest)
    status = "unavailable" if feed_latest is None else ("fresh" if age_minutes <= FEED_FRESHNESS_MINUTES else "stale")
    any_usable = any(item["freshness"] in ("fresh", "delayed", "estimated") and item["peoplePerMinute"] is not None for item in map_sensors)
    safe_status = status if any_usable else "unavailable"
    return {
        "ok": safe_status == "fresh", "dataStatus": safe_status, "latestObservation": feed_latest,
        "source": {"name": "Latest available minute-level pedestrian counts", "dataset": MINUTE_DATASET,
                   "aggregation": "Latest complete 15-minute mean; absent detection minutes filled as zero only when feed freshness and Active sensor status are verified"},
        "limitation": _limitation(safe_status),
        "routes": {"train": _summarise_route(readings, ROUTE_SENSORS["train"]),
                   "tram": _summarise_route(readings, ROUTE_SENSORS["tram"])},
        "mapSensors": map_sensors,
    }


def _read_json(dataset: str, **params) -> list[dict]:
    url = f"{API}/{dataset}/records?{urlencode(params)}"
    request = Request(url, headers={"Accept": "application/json"})
    with urlopen(request, timeout=8) as response:
        return json.loads(response.read().decode("utf-8")).get("results", [])


def _read_sensor(definition: dict) -> dict:
    rows = _read_json(MINUTE_DATASET, limit=100, where=f'location_id={definition["id"]}', order_by="sensing_datetime desc")
    rows = [row for row in rows if row.get("sensing_datetime") and _non_negative(row.get("total_of_directions"))]
    rows.sort(key=lambda row: row["sensing_datetime"], reverse=True)
    if not rows:
        return _empty_reading(definition)
    latest = _parse(rows[0]["sensing_datetime"])
    by_minute = {}
    for row in rows:
        observed = _parse(row["sensing_datetime"])
        if (latest - observed).total_seconds() > 15 * 60:
            continue
        key = row["sensing_datetime"][:16]
        by_minute[key] = max(by_minute.get(key, 0), int(row["total_of_directions"]))
    counts = list(by_minute.values())
    current = round(sum(counts) / len(counts)) if len(counts) >= 3 else None
    forecast, mae = _forecast(list(reversed(counts)))
    return {**definition, "peoplePerMinute": current, "latestObservation": rows[0]["sensing_datetime"],
            "sampleMinutes": len(counts), "forecastPeoplePerMinute": forecast,
            "forecastMethod": "Recent-minute linear trend - 60-minute horizon", "validationMae": mae}


def _forecast(values: list[int]) -> tuple[int | None, int | None]:
    def fit(items):
        n = len(items)
        if n < 8: return None
        mean_x, mean_y = (n - 1) / 2, sum(items) / n
        denominator = sum((index - mean_x) ** 2 for index in range(n))
        slope = 0 if denominator == 0 else sum((index - mean_x) * (value - mean_y) for index, value in enumerate(items)) / denominator
        return slope, mean_y - slope * mean_x
    holdout = max(2, int(len(values) * .2))
    training, test = values[:-holdout], values[-holdout:]
    model = fit(training)
    mae = round(sum(abs(value - (model[1] + model[0] * (len(training) + offset))) for offset, value in enumerate(test)) / holdout) if model else None
    full = fit(values)
    if not full: return None, mae
    raw = full[1] + full[0] * (len(values) + 59)
    return round(max(0, min(raw, max(25, max(values, default=0) * 2)))), mae


def _read_feed_latest() -> str | None:
    rows = _read_json(MINUTE_DATASET, limit=1, order_by="sensing_datetime desc")
    return rows[0].get("sensing_datetime") if rows else None


def _read_active_sensor_ids() -> set[int]:
    """
    Paginates through the FULL sensor-locations dataset. REAL BUG THIS
    FIXES (2026-08-09): the original single-page call (limit=100, no
    offset) silently truncated the real dataset -- confirmed live:
    exactly 100 rows came back, and 9 real sensors with fresh, currently-
    reporting data were entirely absent from those 100 rows, so they
    were wrongly treated as inactive despite having perfectly good
    current readings. Same root-cause pattern as _read_map_sensors'
    batching just below: assuming one request returns everything.
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


def _fetch_same_weekday_hour_history(location_id: int, target_dt_local: datetime, weeks: int) -> list[float]:
    """
    Returns up to `weeks` historical hourly counts (converted to a
    per-minute rate) for this sensor, matching target_dt_local's hour-of-
    day AND day-of-week, most recent first. Overfetches (weeks * 10 rows)
    and filters client-side, since the Opendatasoft API has no native
    day-of-week filter -- only hourday, not weekday, is queryable
    directly. A 4-week lookback from "now" stays inside one Melbourne
    season (~13 weeks each), so this never quietly blends e.g. winter
    data into a summer estimate.
    """
    hour_day = target_dt_local.hour
    rows = _read_json(
        HOURLY_DATASET,
        limit=weeks * 10,
        where=f"location_id={location_id} and hourday={hour_day}",
        order_by="sensing_date desc",
    )
    target_weekday = target_dt_local.weekday()
    counts = []
    for row in rows:
        sensing_date = row.get("sensing_date")
        total = row.get("pedestriancount")
        if not sensing_date or total is None:
            continue
        try:
            row_date = datetime.fromisoformat(str(sensing_date)[:10]).date()
        except ValueError:
            continue
        if row_date.weekday() != target_weekday:
            continue
        counts.append(float(total) / 60)  # hourly total -> people-per-minute rate
        if len(counts) >= weeks:
            break
    return counts


def _historical_estimate(location_id: int, at_dt_local: datetime) -> tuple[float | None, bool]:
    """
    Returns (estimated_people_per_minute, reliable). `reliable` is False
    when there's fewer than HISTORICAL_LOOKBACK_WEEKS matching samples,
    or when the samples disagree with each other too much to trust an
    average (e.g. 20/90/45/88 -- genuinely inconsistent, not a stable
    pattern -- vs 0/0/1/0, which is trivially consistent). Callers must
    treat an unreliable result as "don't guess", per US1.1's rule that
    missing evidence must never quietly become a Low result.
    """
    samples = _fetch_same_weekday_hour_history(location_id, at_dt_local, HISTORICAL_LOOKBACK_WEEKS)
    if len(samples) < HISTORICAL_LOOKBACK_WEEKS:
        return None, False
    average = sum(samples) / len(samples)
    ratio = max(samples) / max(min(samples), 1.0)
    reliable = ratio <= HISTORICAL_CONSISTENCY_MAX_RATIO
    return round(average, 1), reliable


def _sensor_appears_decommissioned(location_id: int) -> bool:
    """
    A sensor whose live minute-level feed has gone quiet might just have
    a normal reporting gap (see _historical_estimate) -- but a sensor
    that reads zero at EVERY checkpoint, including known commute peaks,
    for weeks on end, is more likely dead or removed than genuinely
    always-empty. Checks DECOMMISSIONED_CHECK_HOURS across the last
    DECOMMISSIONED_CHECK_DAYS days (168 checkpoints total by default).
    Only trips if we see the FULL expected history and every single
    checkpoint is zero; any nonzero reading, or simply not enough
    history to judge, means "not flagged" -- this is a backup safety
    net alongside sensor_location.status, in case that field lags
    behind reality, not the primary active/inactive signal.

    Filters by hour CLIENT-SIDE rather than a `hourday in (...)` where
    clause -- the API rejected that syntax with a 400 when tested live
    (2026-08-10), the same lesson as _read_active_sensor_ids: don't
    assume the API supports a clause just because it looks valid.
    Paginates for the same reason that fix exists -- a single request
    can silently cap below what DECOMMISSIONED_CHECK_DAYS needs.
    """
    expected = DECOMMISSIONED_CHECK_DAYS * len(DECOMMISSIONED_CHECK_HOURS)
    page_size = 100
    offset = 0
    checked = 0
    max_offset = DECOMMISSIONED_CHECK_DAYS * 24 * 2  # safety cap -- never loop indefinitely
    while offset < max_offset:
        rows = _read_json(
            HOURLY_DATASET,
            limit=page_size,
            offset=offset,
            where=f"location_id={location_id}",
            order_by="sensing_date desc",
        )
        if not rows:
            break
        for row in rows:
            hour = row.get("hourday")
            total = row.get("pedestriancount")
            if hour is None or total is None or int(hour) not in DECOMMISSIONED_CHECK_HOURS:
                continue
            if float(total) > 0:
                return False  # proof of life -- not decommissioned
            checked += 1
            if checked >= expected:
                return True
        if len(rows) < page_size:
            break
        offset += page_size
    return checked >= expected


def _read_map_sensors(feed_latest: str | None, active_ids: set[int] | None) -> list[dict]:
    batches = [MAP_SENSOR_IDS[index:index + 4] for index in range(0, len(MAP_SENSOR_IDS), 4)]
    def read_batch(batch):
        return _read_json(MINUTE_DATASET, limit=100, where=f'location_id in ({",".join(map(str, batch))})', order_by="sensing_datetime desc")
    with ThreadPoolExecutor(max_workers=8) as pool:
        pages = list(pool.map(read_batch, batches))
    grouped = {sensor_id: [] for sensor_id in MAP_SENSOR_IDS}
    for row in (item for page in pages for item in page):
        sensor_id = int(row.get("location_id", -1))
        if sensor_id in grouped and row.get("sensing_datetime") and _non_negative(row.get("total_of_directions")):
            grouped[sensor_id].append(row)

    now_local = datetime.now(MELBOURNE_TZ)
    result = []
    for sensor_id in MAP_SENSOR_IDS:
        rows = sorted(grouped[sensor_id], key=lambda row: row["sensing_datetime"], reverse=True)
        latest_observation = rows[0]["sensing_datetime"] if rows else None
        operational = "unknown" if active_ids is None else ("active" if sensor_id in active_ids else "inactive")

        if operational != "active":
            result.append(_map_reading(sensor_id, None, latest_observation, 0, "unavailable", "unavailable", operational))
            continue

        # STEP 1 (fix, 2026-08-10): this sensor's OWN 15-minute window,
        # anchored to ITS OWN latest reading -- not the single freshest
        # sensor across the whole feed. Previously a global window meant
        # a sensor could clear the freshness gate on its own recency but
        # still miss the window entirely because it was built around a
        # DIFFERENT sensor's timestamp.
        recent = []
        if latest_observation and _sensor_is_fresh(latest_observation):
            own_latest_dt = _parse(latest_observation)
            start = own_latest_dt.timestamp() - (WINDOW_MINUTES - 1) * 60
            recent = [row for row in rows if start <= _parse(row["sensing_datetime"]).timestamp() <= own_latest_dt.timestamp()]

        if recent:
            count = round(sum(int(row["total_of_directions"]) for row in recent) / WINDOW_MINUTES)
            result.append(_map_reading(sensor_id, count, latest_observation, len(recent), "fresh", "observed", operational))
            continue

        # STEP 2-5: the sensor's own window came up empty -- either it's
        # stale beyond FEED_FRESHNESS_MINUTES, or it's fresh but simply
        # didn't report inside this exact 15-minute slice. EITHER WAY,
        # this is a reporting gap, not proof of zero pedestrians -- never
        # silently treat an empty window as a confirmed zero.
        #
        # Both live calls below are wrapped: a live-request path (this
        # runs on every /api/routes/compare call) must degrade to Unknown
        # on a transient API failure, never crash the whole endpoint over
        # one background historical lookup.
        try:
            decommissioned = _sensor_appears_decommissioned(sensor_id)
        except Exception:
            decommissioned = False
        if decommissioned:
            result.append(_map_reading(sensor_id, None, latest_observation, 0, "unavailable", "sensor-inactive-suspected", operational))
            continue

        try:
            estimate, reliable = _historical_estimate(sensor_id, now_local)
        except Exception:
            estimate, reliable = None, False
        if reliable:
            result.append(_map_reading(sensor_id, round(estimate), latest_observation, 0, "estimated", "hourly-estimate", operational))
        else:
            result.append(_map_reading(sensor_id, None, latest_observation, 0, "stale" if latest_observation else "unavailable", "insufficient-history", operational))
    return result


def _historical_payload() -> dict:
    rows = _read_json(HOURLY_DATASET, limit=100, where="sensing_date=date'2026-08-04' and hourday=7")
    by_id = {int(row["location_id"]): round(float(row["pedestriancount"]) / 60) for row in rows if row.get("location_id") is not None and row.get("pedestriancount") is not None}
    observed = "2026-08-04T07:00:00+10:00"
    sensors = [_map_reading(sensor_id, by_id.get(sensor_id), observed if sensor_id in by_id else None, 60 if sensor_id in by_id else 0, "fresh" if sensor_id in by_id else "unavailable", "observed" if sensor_id in by_id else "unavailable", "active" if sensor_id in by_id else "unknown") for sensor_id in MAP_SENSOR_IDS]
    def reading(ids):
        values = [by_id[item] for item in ids if item in by_id]
        return {"peoplePerMinute": max(values) if values else None, "forecast": {"peoplePerMinute": None, "horizonMinutes": 60, "method": "Not evaluated in archived current-condition test", "validationMae": None, "confidence": "Unavailable"}, "coverage": {"usableSensors": 1 if values else 0, "supportedSensors": len(ids), "scope": "Archived CBD corridor test"}, "sensors": []}
    return {"ok": bool(by_id), "dataStatus": "fresh" if by_id else "unavailable", "latestObservation": observed,
            "source": {"name": "Historical pedestrian counts per hour", "dataset": HOURLY_DATASET, "aggregation": "07:00-07:59 hourly count converted to an average people-per-minute rate"},
            "limitation": "Acceptance-test replay using archived observations; not a live journey recommendation.",
            "routes": {"train": reading([41, 53]), "tram": reading([5])}, "mapSensors": sensors,
            "scenario": {"id": "dod-2026-08-04-0700", "label": "Tue 4 Aug 2026 - 7:00 am departure", "observationWindow": "Historical 07:00-07:59 hourly observation"}}


def _summarise_route(readings: list[dict], definitions) -> dict:
    selected = [next((reading for reading in readings if reading["id"] == definition["id"]), _empty_reading(definition)) for definition in definitions]
    usable = [item for item in selected if item["peoplePerMinute"] is not None]
    forecasts = [item for item in usable if item["forecastPeoplePerMinute"] is not None]
    maes = [item["validationMae"] for item in forecasts if item["validationMae"] is not None]
    return {"peoplePerMinute": max((item["peoplePerMinute"] for item in usable), default=None),
            "forecast": {"peoplePerMinute": max((item["forecastPeoplePerMinute"] for item in forecasts), default=None), "horizonMinutes": 60, "method": "Recent-minute linear trend", "validationMae": round(sum(maes) / len(maes)) if maes else None, "confidence": "Experimental" if maes else "Unavailable"},
            "coverage": {"usableSensors": len(usable), "supportedSensors": len(definitions), "scope": "CBD approach only"}, "sensors": selected}


def _map_reading(sensor_id, count, observed, samples, freshness, evidence, operational):
    return {"id": sensor_id, "peoplePerMinute": count, "latestObservation": observed, "sampleMinutes": samples, "freshness": freshness, "evidence": evidence, "operationalStatus": operational}


def _empty_reading(definition):
    return {**definition, "peoplePerMinute": None, "latestObservation": None, "sampleMinutes": 0, "forecastPeoplePerMinute": None, "forecastMethod": "Unavailable", "validationMae": None}


def _parse(value): return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
def _age_minutes(value): return (datetime.now(timezone.utc) - _parse(value).astimezone(timezone.utc)).total_seconds() / 60 if value else float("inf")

def _sensor_is_fresh(latest_observation: str | None) -> bool:
    """A sensor's own reading is fresh iff ITS OWN observation is within
    FEED_FRESHNESS_MINUTES of now -- not whether the feed's single newest
    reading across all 65 sensors is recent.
    """
    return latest_observation is not None and _age_minutes(latest_observation) <= FEED_FRESHNESS_MINUTES

def _non_negative(value):
    try: return float(value) >= 0
    except (TypeError, ValueError): return False
def _limitation(status):
    if status == "fresh": return "Live pedestrian observations cover supported approach points only. Onboard tram crowding is not covered."
    if status == "stale": return "Latest available City observations are delayed. High/Low uses the latest complete 15-minute window and is labelled as delayed, not live."
    return "No usable current observation was returned, so High/Low classifications are withheld."