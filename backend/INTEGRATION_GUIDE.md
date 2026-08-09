# Calmer Commute prototype integration guide

## 1. Purpose and fixed architecture

This guide prescribes how the current Calmer Commute prototype is reproduced in the team repository. It defines stable boundaries so frontend, routing, data, AI, refuge and QA work can proceed independently and integrate without redesigning the public API.

All contributors must also comply with `BUILD_QUALITY.md`. That document is the merge-quality gate; this guide defines how the parts connect.

The backend is one Flask application. Internal components are ordinary Python modules connected with import statements. They are **not** microservices and must not call one another over HTTP.

```text
Next.js frontend
      |
      | HTTP: /api/* only
      v
Flask routes.py (validation and orchestration)
      |
      | direct Python imports
      +-- route_service.py
      +-- sensor_service.py
      +-- prediction_service.py
      +-- refuge_service.py
```

Only the browser-to-Flask boundary uses HTTP. Inside Flask, use imports such as:

```python
from .services.route_service import compare_routes
from .services.sensor_service import load_sensor_locations
```

Do not add separate component servers, service URLs, message queues or component-specific containers for this prototype.

## 2. User-visible prototype flow

The integrated version must support this exact journey:

1. The user enters an origin, a destination within Melbourne CBD, a departure time and a personal crowd threshold.
2. The frontend sends one `POST /api/routes/compare` request.
3. Routing supplies at least two candidate routes with stable IDs, geometry, duration, distance and transport legs.
4. Data supplies pedestrian observations near each route.
5. Scoring compares supported observations with the user's threshold.
6. Each route is labelled `High`, `Low` or `Unknown`, with evidence and coverage shown.
7. The backend recommends the shortest supported Low route. If no Low route exists, it clearly reports that no lower-crowd alternative is available. Unknown must never be recommended as if it were Low.
8. A hotspot can trigger the next-hour prediction display.
9. The user can choose rerouting or request candidate refuges near the selected route's arrival point.
10. Refuge results are candidates only; the product must not claim that they are verified quiet or sensory-safe locations.

The St Kilda East–Flinders Street journey may contain `Unknown` sections outside City of Melbourne sensor coverage. A CBD-only journey such as Docklands–Flinders Street may be used to demonstrate fuller sensor coverage. The API contract is the same for both.

## 3. Ownership and required implementation

| Component owner | Implement inside | Must provide | Must not do |
|---|---|---|---|
| Backend/integration | `routes.py`, validation, errors, app factory | Stable endpoints, orchestration, validation, consistent errors | Put model/data algorithms in route handlers |
| Routing | imported routing module used by `route_service.py` | 2+ candidate routes, IDs, legs, duration, distance, geometry | Assign crowd level without sensor evidence |
| Data | imported adapter used by `sensor_service.py` | Normalised count, timestamp, freshness, availability and sensor location | Treat no row as zero crowd |
| Scoring | imported function used by `route_service.py` | Route-sensor matching, coverage, High/Low/Unknown, hotspot evidence | Convert missing/stale data to Low |
| AI | imported forecast function used by `prediction_service.py` | 60-minute prediction, model version and validation status | Claim accuracy/confidence without evidence |
| Places/refuge | imported adapter used by `refuge_service.py` | Arrival-based candidates, deduplication, actual walking time when available | Call candidates verified sensory-safe refuges |
| Frontend | Next.js API client and views | Render contract fields and all loading/error/Unknown states | Recalculate official classification client-side |
| QA | `backend/tests/` plus integration tests | Contract, boundary, missing/stale and failure tests | Test only happy paths |

## 4. Internal component contracts

### 4.1 Routing output

The routing implementation returns candidate route dictionaries before sensory scoring:

```python
{
    "route_id": "route-1",
    "duration_minutes": 24,
    "distance_metres": 3100,
    "legs": [
        {"mode": "walk", "duration_minutes": 5},
        {"mode": "tram", "service": "Tram 3", "duration_minutes": 19}
    ],
    "geometry": [[144.9671, -37.8183], [144.9652, -37.8175]]
}
```

Coordinate ordering inside `geometry` must be agreed once and documented. GeoJSON convention `[longitude, latitude]` is recommended. The frontend must not guess or swap it.

### 4.2 Data output

The data adapter normalises source-specific fields into:

```python
{
    "sensor_id": "S001",
    "name": "Flinders Street Station Underpass",
    "latitude": -37.8183,
    "longitude": 144.9671,
    "pedestrian_count_per_minute": 18.4,
    "observed_at": "2026-08-09T14:05:00+10:00",
    "freshness_minutes": 4,
    "availability": "available"
}
```

Allowed availability values are `available`, `stale` and `missing`. Minute granularity does not mean minute freshness: quiet sensors may have no new row for 30–45 minutes. Freshness must be calculated from `observed_at`, not inferred from the dataset's nominal granularity.

If the source has no observation:

```python
{
    "sensor_id": "S001",
    "availability": "missing",
    "pedestrian_count_per_minute": None,
    "observed_at": None,
    "freshness_minutes": None
}
```

### 4.3 Scoring rules

The following rules are mandatory:

```text
no matched sensors                     -> Unknown
all matched observations missing/stale -> Unknown
supported maximum count > threshold    -> High
supported maximum count <= threshold   -> Low
mixed covered and uncovered sections   -> High/Low for supported evidence,
                                           plus partial coverage disclosure
```

For the prototype, the conservative route score should use the maximum supported pedestrian count among matched route sensors so a hotspot is not hidden by averaging. If the team later chooses another aggregation, record the decision and update tests and the contract together.

The distance rules used to match route geometry to sensors come from `DIRECT_SENSOR_RADIUS_METRES` (75 m) and `PROXY_SENSOR_RADIUS_METRES` (150 m) in `config.py`. Direct evidence takes precedence; proxy evidence is used only when no usable direct observation exists.

### 4.4 AI forecast output

```python
{
    "sensor_id": "S001",
    "forecast_horizon_minutes": 60,
    "predicted_count_per_minute": 21.7,
    "predicted_level": "Low",
    "crowd_threshold": 25.0,
    "model_version": "crowd-forecast-v1",
    "confidence": None,
    "validation_status": "validated",
    "generated_at": "2026-08-09T14:10:00+10:00",
    "data_mode": "live"
}
```

The AI team must confirm input columns, aggregation interval, missing-value handling, time-ordered train/validation split, MAE/RMSE, baseline comparison, model version and supported uncertainty measure. Until then, retain `placeholder-v1`, `not_validated`, `confidence: null` and `data_mode: mock`.

### 4.5 Refuge output

Search from the selected journey's arrival coordinates. Use typed nearby search first and an independent text-search fallback for libraries, parks, museums and community centres. Deduplicate by provider place ID and rank by actual walking time when a walking-route provider is connected.

Keep these stable result keys: `refuge_id`, `name`, `type`, `latitude`, `longitude`, `distance_metres`, `walking_minutes`, and `verification_status`.

## 5. External API ownership

`API_CONTRACT.md` is the public browser/backend contract. A component may change its internal algorithm without requiring frontend changes if that file's request and response fields remain stable.

If a public field must change:

1. Update `API_CONTRACT.md` first.
2. Obtain frontend, backend and QA agreement.
3. Update producer code and consumer code in coordinated branches.
4. Update contract tests in the same change.
5. Do not silently rename or remove fields.

## 6. Frontend integration requirements

The frontend should have one API client layer rather than scattered `fetch` calls. It should:

- debounce origin/destination input and call `POST /api/places/autocomplete` after at least two characters;
- generate one autocomplete session token per search session and replace it after a place is selected;
- display the returned `description`, retain the selected `place_id`, and send the selected coordinates/address in route comparison;
- never expose or embed the backend Google Maps key;

- send the user-entered threshold unchanged;
- use returned route IDs for selection and map display;
- display only the selected route geometry;
- render icon plus text for `High`, `Low` and `Unknown` rather than colour alone;
- show reason, timestamp, freshness, coverage and limitations;
- show `Unknown` outside supported coverage;
- show `lower_crowd_alternative_available: false` explicitly;
- pass the selected route's arrival latitude/longitude to `/api/refuges`;
- label mock, placeholder and not-validated results in development/demo views;
- handle `400`, `404`, `405`, `422` and `503` using the common error object.

Suggested client-side call (illustrative, not a second source of business logic):

```ts
// Suggested frontend adapter; keep endpoint and fields aligned with API_CONTRACT.md.
export async function compareRoutes(input: RouteComparisonRequest) {
  const response = await fetch("/api/routes/compare", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  const body = await response.json();
  if (!response.ok) throw body.error;
  return body as RouteComparisonResponse;
}
```

## 7. Replacement sequence

Replace placeholders in this order to reduce rework:

1. Freeze `API_CONTRACT.md` and add shared example JSON fixtures.
2. Connect real route generation while retaining mock sensor counts.
3. Connect normalised current sensor observations.
4. Implement route-sensor matching, freshness and scoring.
5. Connect frontend route comparison and all Unknown/error states.
6. Connect candidate-place search and walking routes.
7. Connect the validated AI forecast behind the existing prediction function.
8. Run contract and end-to-end tests; only then change `data_mode` from `mock`.

Only the relevant imported module changes at each step. Do not rewrite `routes.py` when replacing a placeholder algorithm.

## 7.1 Google Maps/Places activation

The implementation is already wired through direct Python imports in `google_maps_service.py`. It remains mock by default so tests and development do not incur live calls.

1. Enable Routes API and Places API (New) in the team Google Cloud project.
2. Create a server-side key restricted to those APIs. Do not reuse an unrestricted browser key.
3. Copy `.env.example` to `.env` locally and set:

```text
GOOGLE_INTEGRATION_MODE=live
GOOGLE_MAPS_API_KEY=your-local-secret
```

4. Keep `.env` outside Git. Rebuild/restart the backend after changing environment variables.
5. Verify autocomplete, two route searches and candidate refuges using Melbourne test locations.
6. If Google is unavailable, the backend returns a sanitised `503 provider_unavailable`; it does not silently fabricate a live response.

Provider responsibilities are deliberately separated:

```text
Frontend search field -> /api/places/autocomplete -> Google Places Autocomplete
Route comparison      -> /api/routes/compare      -> Google Routes -> crowd scoring
Refuge action         -> /api/refuges             -> Google Nearby Search
Map rendering         -> frontend                 -> selected encoded polyline only
```

## 8. Test and Definition of Done matrix

| Scenario | Required result |
|---|---|
| Valid request with supported low counts | At least two routes; shortest Low route recommended |
| Supported count exceeds threshold | High with hotspot evidence |
| No Low alternative | Explicit `lower_crowd_alternative_available: false` |
| Missing sensor rows | Unknown, not Low |
| Observation older than stale limit | Unknown, not Low |
| Journey partly outside coverage | Partial/Unknown disclosure visible |
| Invalid coordinate or threshold | Consistent `400 validation_error` |
| Routing/data/AI/places unavailable | Safe `503` response; no fabricated live result |
| Prediction placeholder | `not_validated`, null confidence, mock disclosure |
| Refuge candidate | Arrival-based and `candidate_not_verified` |
| Accessibility | High/Low/Unknown communicated with text and icon |

Integration is complete only when producer tests, API contract tests and frontend rendering tests pass, timestamps/limitations are visible, no secrets are committed, and evidence is attached before the relevant card is moved to Done.

## 9. Configuration and code-quality rules

All tunable values belong in `config.py` or environment configuration: thresholds, stale limit, forecast horizon, match radius, search limit, provider URLs, timeouts and dataset identifiers.

Keep functions small and single-purpose. Validate at the HTTP boundary, normalise external data in adapters, score in service logic, and format one stable response. Remove unused imports, duplicated helpers, experimental patches, secrets and generated cache files before commit.

Comments should explain why a rule exists, a limitation, or a replacement boundary. Avoid comments that merely repeat the next line of code.

## 10. Team hand-off checklist

Each component owner must provide:

- module and imported function name;
- input/output example matching this guide;
- error/failure behaviour;
- configuration variables;
- unit tests and one integration fixture;
- data/model/provider provenance and limitations;
- confirmation that no secrets are committed;
- evidence that missing, stale and unavailable cases were tested.

The backend integrator reviews the final imports and response shape. QA checks the full matrix. Frontend verifies the same fixtures. This makes the current prototype reproducible without requiring every person to understand every component's internal implementation.
