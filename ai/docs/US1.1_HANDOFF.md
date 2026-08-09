# US1.1/US1.2 Handoff — Route Comparison & Crowd Scoring

**For:** frontend team (Qing) and anyone consuming this endpoint
**From:** Ibwd (AI/ML)
**Status:** COMPLETE and LIVE-VERIFIED — this document supersedes the earlier `US1.1_HANDOFF.md`, which described a different, now-superseded API design (`api_route_score_example.py`) that was never the real integration path. Everything below is confirmed against a real HTTP request to the actual running endpoint.

---

## 1. The real endpoint

```
POST /api/routes/compare
```

This single endpoint serves both US1.1 (crowd indicator per route) and US1.2 (comparison, hotspot, recommendation) — the real backend combined both cards into one response, not two separate calls.

## 2. Request shape

```json
{
  "origin": "Flinders Street Station, Melbourne",
  "destination": "State Library Victoria, Melbourne",
  "crowd_threshold": 25,
  "origin_coordinates": null,
  "destination_coordinates": null,
  "departure_time": null
}
```

| Field | Required | Notes |
|---|---|---|
| `origin` | yes | free-text address/place name |
| `destination` | yes | free-text address/place name |
| `crowd_threshold` | no | defaults to `25` (`DEFAULT_CROWD_THRESHOLD` in config) |
| `origin_coordinates` / `destination_coordinates` | no | optional `{lat, lng}`, skips geocoding if provided |
| `departure_time` | no | optional, passed to Google Routes |

## 3. Response shape — confirmed from a real live call

```json
{
  "request": { "...the request you sent, echoed back..." },
  "routes": [
    {
      "route_id": "route-4",
      "duration_minutes": 15,
      "distance_metres": 1442,
      "legs": [ "...raw Google legs/steps, includes travelMode, polylines, transit details..." ],
      "geometry": {
        "encoding": "google_encoded_polyline",
        "value": "bgyeFa}xsZo@P~BzL..."
      },
      "sensory_level": "Low",
      "coverage": "direct",
      "data_mode": "live",
      "recommended": false,
      "hotspot": null,
      "sensor_evidence": [
        {
          "sensor_id": "4",
          "name": "Town Hall (West)",
          "latitude": -37.81488,
          "longitude": 144.966088,
          "pedestrian_count_per_minute": 4,
          "observed_at": "2026-08-09T13:25:00+00:00",
          "freshness": "fresh",
          "evidence": "observed",
          "distance_to_route_metres": 4.0,
          "match_type": "direct"
        }
      ]
    }
  ],
  "recommendation": {
    "route_id": "route-5",
    "reason": "Shortest route with supported crowd exposure below the user's threshold.",
    "trade_off": "2 additional minutes compared with the fastest route.",
    "lower_crowd_alternative_available": true
  },
  "metadata": {
    "data_mode": "mixed",
    "generated_at": "2026-08-09T13:52:06+00:00",
    "limitations": [
      "Route geometry and travel estimates are supplied by Google Routes.",
      "Pedestrian counts are a partial proxy for sensory load and only cover sensors within 150 metres of a route."
    ]
  }
}
```

## 4. Field meanings — the important ones

- **`sensory_level`**: `"High"` | `"Low"` | `"Unknown"` — the US1.1 indicator, per route.
- **`coverage`**: `"direct"` | `"proxy"` | `"unavailable"` — whether the classification rests on close-range (≤75m) or wider (≤150m) sensor evidence, or none at all. `"unavailable"` means the route resolved to `"Unknown"`.
- **`hotspot`**: non-null only when `sensory_level` is `"High"` — the specific sensor that triggered it, plus `exceeds_threshold_by`. This is the US1.2 "identify the hotspot being avoided" requirement.
- **`sensor_evidence`**: every sensor that actually supported the classification — real names, real counts, real distances. Empty when nothing usable was nearby.
- **`match_type`** (inside each evidence item): `"direct"` (≤75m, always trusted first) or `"proxy"` (≤150m, only used when no direct evidence exists — never blended with direct evidence, even if the proxy reading looks worse).
- **`recommendation`**: top-level, one per response, not per route. `route_id: null` with `lower_crowd_alternative_available: false` means **no route could be confidently recommended** — this is the correct, honest Failure Handling behaviour, not a bug. Don't treat a null recommendation as an error state; display the limitation message instead.

**No `confidence` field exists in the real response.** An earlier design included one; it did not make it into the final merged implementation. If confidence-level display is wanted later, that's a fresh conversation, not something already built.

## 5. What this means for the UI

- **Show multiple routes side by side** — `routes` is always a list, potentially several real Google alternatives (transit, walking-heavy, etc.), each independently scored.
- **Highlight `recommendation.route_id`** among the list, when non-null.
- **When `recommendation.route_id` is null**, show `recommendation.reason` and `trade_off` as an honest "we can't recommend one right now" message — don't hide this state or treat it as a loading/error condition.
- **For a `"High"` route, surface `hotspot`** directly — that's literally the point being avoided, worth calling out specifically, e.g. on a map or in route details.
- **`legs`** is raw Google data — real transit line names, real stop names, real departure times are already in there if you want to show journey detail beyond just the crowd indicator.

## 6. Known limitations, stated plainly

- `sensor_evidence` only ever covers sensors within 150m of a route's **walked** portions — transit-only sections (train, tram) intentionally have no sensor coverage, since pedestrian crowd data doesn't apply to time spent on a vehicle.
- `crowd_threshold` is one flat number applied identically to every sensor — a naturally busy location (e.g. Melbourne Central) and a naturally quiet one are judged by the same bar. This is a known, documented product trade-off, not an oversight.
- Live-tested and confirmed working, but pedestrian counts can occasionally be `"stale"` or `"missing"` depending on the real City of Melbourne feed's health at request time — this shows up as fewer/no `sensor_evidence` entries and possibly `"Unknown"` routes, not an error.

## 7. Status

Backend fully live, tested (25 automated tests), and verified with a real HTTP call through this exact endpoint in this session — real Google transit journeys, real sensor data, correct route-level classification. Ready for frontend integration now.
