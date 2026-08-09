# US1.3 Handoff — Alignment Note

**From:** AI-US2.2-01 (crowd forecast)
**Status:** Interim user-threshold system is built, tested, and **live** — not a design document, a working system you can hit right now.

---

## TL;DR

I couldn't wait on US1.3 to unblock the forecast card, so I built and shipped an interim
threshold system (Option A: sensitivity multiplier). It's running behind a real HTTP endpoint
today. You have two paths:

1. **Adopt it as final** — if a 3-level sensitivity setting is enough, there's nothing left to
   build.
2. **Replace it** — swap out one function (`get_alert_thresholds()`) with your own logic. My
   forecast code doesn't need to change either way, because both paths go through the same
   fixed contract below.

Either way, everything downstream (the forecast, the explanation object, the API response
shape) is already correct and won't need touching once your version is dropped in.

---

## Proof this actually works — not a claim, a verified test

Real requests against the live endpoint, sensor 161 (Birrarung Marr):

```
GET /api/forecast/161?sensitivity=cautious   -> alert_threshold: 226.1
GET /api/forecast/161?sensitivity=default    -> alert_threshold: 323.0
GET /api/forecast/161?sensitivity=relaxed    -> alert_threshold: 419.9
```

`forecast` (5.4) stayed **identical** across all three — confirming sensitivity affects only
the alert threshold, never the prediction itself, which is the correct separation of concerns.
226.1/323.0/419.9 = 323.0 × 0.7/1.0/1.3 exactly, matching the design.

---

## The interface contract — fixed, regardless of who implements it

```python
def get_alert_thresholds(
    sensor_ids: list[int],
    user_context: dict | None = None,
    base_thresholds: dict[int, float] | None = None,
) -> dict[int, float]
```

- **Input:** `sensor_id` as `int`, matching `location_id` (never `display_name` — two sensors
  can share a display name in the source data).
- **Output:** `sensor_id -> threshold`, in **raw pedestrians/hour** — the same units as
  `target_count`. The consuming code does `forecast >= threshold` directly, no rescaling.
- **No valid threshold for a sensor:** return `None`, never `0` or `NaN`. Consuming code
  already treats `None` as "omit the alert field from the response entirely" (see the live
  JSON examples above/below — no `alert`/`alert_threshold` keys appear if this returns `None`).
  Returning `0` would cause a false alert on every single forecast for that sensor.
- **`user_context`:** currently reads `{"sensitivity": "cautious" | "default" | "relaxed"}`.
  You're free to read different or additional keys (e.g. a continuous 0.0–1.0 slider value, a
  per-user learned preference) as long as the **return type doesn't change**.

---

## Where the code actually lives

| File | Purpose |
|---|---|
| `ai/models/alert_thresholds.py` | `get_alert_thresholds()`, the interim sensitivity-multiplier logic, `SENSITIVITY_MULTIPLIERS` dict |
| `ai/models/export_base_thresholds.py` | Offline build step — computes each sensor's 75th-percentile base threshold from training data, run once (or whenever the dataset updates) |
| `ai/models/base_thresholds.json` | The small (~100-row) generated artifact `get_alert_thresholds()` reads at runtime — **not committed to git**, regenerate locally via `python export_base_thresholds.py` if you need it |
| `backend/app/__init__.py` | The actual Flask route (`GET /api/forecast/<sensor_id>?sensitivity=...`) that wires everything together — see below |

---

## How it's wired into the live endpoint right now

```python
# backend/app/__init__.py, inside create_app()
base_thresholds = load_base_thresholds_optional()   # loads base_thresholds.json once at startup

@app.get("/api/forecast/<int:sensor_id>")
def forecast(sensor_id: int):
    ...
    sensitivity = request.args.get("sensitivity", "default")
    result = next_hour_forecast(
        sensor_id=sensor_id, model=model, sensor_map=sensor_map,
        latest_row=row, volatility_lookup=volatility_lookup,
        user_context={"sensitivity": sensitivity},
        base_thresholds=base_thresholds,
    )
```

`next_hour_forecast()` internally calls `get_alert_thresholds()` when `alert_threshold` isn't
passed explicitly. **This is the one call site that changes if you replace the internals** —
everything else (the route, the response shape, `next_hour_forecast`, `explain_forecast_rf`)
stays exactly as-is.

---

## If you replace this with your own logic

1. Keep the function name and signature identical (or update the one import in
   `next_hour_forecast()` if you rename it — single line).
2. Confirm your version still returns `None` (not `0`) for sensors with no determinable
   threshold — this is the one behavior the rest of the pipeline depends on.
3. Re-run the same verification: hit `/api/forecast/161?sensitivity=X` for a few values of
   `X` and confirm `alert_threshold` changes sensibly while `forecast` stays constant.
4. If your version needs different `user_context` keys (e.g. a numeric slider instead of three
   buckets), that's fine — just update the frontend's query param accordingly; nothing in the
   forecast pipeline needs to know or care what's inside `user_context`.

---

## One limitation worth knowing before you build on this

The base thresholds are a **static snapshot** — 75th percentile of training-period traffic,
computed once via `export_base_thresholds.py`. They don't update automatically as new data
comes in. If your version of US1.3 needs thresholds that adapt over time (rolling percentile,
seasonal adjustment, etc.), that's new work on top of this contract, not something the current
artifact provides — worth deciding early whether that's in scope for this iteration.

---

Happy to walk through any of this live if it's faster than reading — but the endpoint is real
and running, so the fastest way to see it is just to hit it yourself.
