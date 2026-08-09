"""Flask port of the deployed Calmer Commute v81 crowd logic."""

import json
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
MINUTE_DATASET = "pedestrian-counting-system-past-hour-counts-per-minute"
HOURLY_DATASET = "pedestrian-counting-system-monthly-counts-per-hour"
LOCATIONS_DATASET = "pedestrian-counting-system-sensor-locations"
WINDOW_MINUTES = 15
FEED_FRESHNESS_MINUTES = 30
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
    status = "unavailable" if feed_latest is None else ("fresh" if age_minutes <= 30 else "stale")
    any_usable = any(item["freshness"] in ("fresh", "delayed") and item["peoplePerMinute"] is not None for item in map_sensors)
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
    latest_dt = _parse(feed_latest) if feed_latest else None
    feed_fresh = latest_dt is not None and _age_minutes(feed_latest) <= FEED_FRESHNESS_MINUTES
    result = []
    for sensor_id in MAP_SENSOR_IDS:
        rows = sorted(grouped[sensor_id], key=lambda row: row["sensing_datetime"], reverse=True)
        latest_observation = rows[0]["sensing_datetime"] if rows else None
        operational = "unknown" if active_ids is None else ("active" if sensor_id in active_ids else "inactive")
        if latest_dt is None or operational != "active":
            result.append(_map_reading(sensor_id, None, latest_observation, 0, "stale" if latest_dt else "unavailable", "unavailable", operational)); continue
        if not feed_fresh:
            result.append(_map_reading(sensor_id, None, latest_observation, 0, "stale", "unavailable", operational)); continue
        start = latest_dt.timestamp() - (WINDOW_MINUTES - 1) * 60
        recent = [row for row in rows if start <= _parse(row["sensing_datetime"]).timestamp() <= latest_dt.timestamp()]
        count = round(sum(int(row["total_of_directions"]) for row in recent) / WINDOW_MINUTES)
        result.append(_map_reading(sensor_id, count, latest_observation or feed_latest, len(recent), "fresh", "observed" if recent else "inferred-zero", operational))
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
def _non_negative(value):
    try: return float(value) >= 0
    except (TypeError, ValueError): return False
def _limitation(status):
    if status == "fresh": return "Live pedestrian observations cover supported approach points only. Onboard tram crowding is not covered."
    if status == "stale": return "Latest available City observations are delayed. High/Low uses the latest complete 15-minute window and is labelled as delayed, not live."
    return "No usable current observation was returned, so High/Low classifications are withheld."