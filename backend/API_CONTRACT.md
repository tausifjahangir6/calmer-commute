# Calmer Commute onboarding API contract

This contract supports frontend integration while the data, AI, routing and places components are still being integrated. Responses marked `mock`, `placeholder` or `not_validated` must not be presented as live or validated.

## `GET /api/prototype/defaults`

The frontend calls this endpoint on initial load and uses the response to prefill the prototype. These are defaults, not locked values; the user may change the addresses, day or time.

```json
{
  "origin": "903/8 Pearl River Rd, Docklands VIC 3008",
  "destination": "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000",
  "commute_window": {
    "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    "start": "07:30",
    "end": "08:00",
    "timezone": "Australia/Melbourne"
  },
  "crowd_threshold": 25.0
}
```

The UI displays the window as **Weekdays, 7:30 AM–8:00 AM**. When requesting routes, it converts the selected weekday and time into an ISO 8601 `departure_time` with the Melbourne UTC offset. Unless the user selects another time within the window, use 7:30 AM as the route departure time. Do not hard-code these values again in the frontend.

## `POST /api/places/autocomplete`

The frontend origin and destination search boxes call this backend endpoint after at least two characters. The browser must not call the Google Places web service directly with the backend key.

```json
{
  "query": "Flinders",
  "session_token": "frontend-generated-session-token"
}
```

```json
{
  "query": "Flinders",
  "suggestions": [
    {
      "place_id": "provider-place-id",
      "description": "Flinders Street Station, Melbourne VIC, Australia"
    }
  ],
  "metadata": {"data_mode": "live"}
}
```

The frontend displays `description` and retains `place_id` for the selected result. Search is restricted to Australia and biased toward Melbourne. In mock mode, the endpoint returns the fixed prototype locations.

For implementation ownership, internal Python contracts, replacement order and the test matrix, see `INTEGRATION_GUIDE.md`. For mandatory review and Definition of Done gates, see `BUILD_QUALITY.md`. These documents are prescriptive; this file remains the stable browser/backend contract.

## `POST /api/routes/compare`

Example request:

```json
{
  "origin": "903/8 Pearl River Rd, Docklands VIC 3008",
  "destination": "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000",
  "origin_coordinates": {"latitude": -37.8200, "longitude": 144.9470},
  "destination_coordinates": {"latitude": -37.8177, "longitude": 144.9668},
  "departure_time": "2026-08-10T07:30:00+10:00",
  "crowd_threshold": 25
}
```

The response supplies stable route IDs, legs, `High`/`Low`/`Unknown` classification, sensor evidence, hotspot evidence, a recommendation, its reason, its time trade-off, and data limitations.

In live Google mode, route duration, distance and encoded polyline come from Google Routes. Until timestamped pedestrian observations are integrated, those real routes are correctly labelled `Unknown`; they must not be given mock High/Low labels.

## `GET /api/refuges`

```text
/api/refuges?latitude=-37.8183&longitude=144.9671&limit=5
```

Latitude and longitude are the journey **arrival** coordinates. Results are ranked from that point. They are candidate places only; the service does not claim that they are quiet, sensory-safe, accessible or open.

## `GET /api/predictions`

```text
/api/predictions?sensor_id=5&crowd_threshold=25
```

Until the AI component is integrated, the endpoint returns a deterministic placeholder with `validation_status: not_validated`, `confidence: null`, and `data_mode: mock`.

## Error contract

```json
{
  "error": {
    "code": "validation_error",
    "message": "Human-readable explanation.",
    "details": {"field": "crowd_threshold"}
  }
}
```

## Component replacement boundaries

- Data team replaces mock counts with normalised count, timestamp, freshness and availability fields.
- Routing component replaces placeholder legs and empty geometry with candidate routes.
- AI team replaces the prediction placeholder only after documenting model version and validation results.
- Places provider replaces the curated candidate list and straight-line walking-time estimate.
- Missing or stale evidence must map to `Unknown`, never silently to `Low`.
- Components remain imported Python modules inside the same Flask application. Do not replace these boundaries with service-to-service HTTP or separately deployed microservices.
