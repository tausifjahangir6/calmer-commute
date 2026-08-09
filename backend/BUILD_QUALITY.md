# Calmer Commute build-quality standard

## 1. Status and enforcement

This is the minimum quality gate for every Calmer Commute component. “Must” is mandatory for merge. “Should” may be waived only when the pull request records the reason, impact and follow-up owner.

A feature is not Done merely because it runs locally. It is Done only when its code, tests, contract, documentation, limitations and integration evidence satisfy this standard.

## 2. Clean deliverable rule

Final code must read like a reviewed team deliverable, not an experiment dump.

Every pull request must contain:

- no dead code, unused imports or unused variables;
- no copy-pasted logic that should be one helper;
- no repeated experimental blocks or manual patches;
- no hidden dependency on execution order or developer machine state;
- consistent and descriptive names;
- one clear responsibility per module and function;
- no generated caches, temporary outputs, credentials or local environment files.

Commented-out abandoned implementations are prohibited. A short commented **suggested replacement block** is allowed only at an agreed integration boundary, clearly labelled with its owner and removal condition.

## 3. Architecture rule

The backend must remain one Flask application. Internal components communicate by Python import statements and function calls.

Required pattern:

```python
from .services.route_service import compare_routes

result = compare_routes(normalised_request, sensors, data_mode)
```

Prohibited for internal component integration:

- service-to-service HTTP calls;
- one container per internal component;
- internal service URLs;
- message queues introduced solely to connect team components;
- duplicating data/scoring logic in Flask route handlers or the frontend.

Flask Blueprints and Python modules are organisational boundaries, not microservices.

## 4. Responsibility boundaries

Code must be placed according to responsibility:

| Layer | Permitted responsibility |
|---|---|
| `routes.py` | HTTP input, validation calls, orchestration and JSON response |
| `validation.py` | Boundary validation and normalisation |
| `errors.py` | Stable, safe client-facing errors |
| `sensor_service.py` / data adapter | External schema normalisation, timestamps and availability |
| `route_service.py` | Candidate-route orchestration, scoring and recommendation |
| `prediction_service.py` | Forecast adapter and forecast disclosure |
| `refuge_service.py` | Candidate retrieval, deduplication and walking-time ranking |
| frontend | Presentation and interaction; no authoritative scoring |

If a function mixes two layers, split it before review.

## 5. Parameterisation rule

Every tunable value must be a named configuration entry, constant or function argument. Do not scatter magic numbers through functions.

This includes:

- API/provider URLs and dataset identifiers;
- file paths;
- crowd thresholds and allowed ranges;
- stale-data limit;
- route-to-sensor match radius;
- forecast horizon;
- search radius and result limit;
- network timeout and retry count;
- walking-speed assumptions;
- model version, seed and evaluation settings.

Each parameter must be documented with:

1. what it controls;
2. its unit and valid range;
3. why the current value was selected;
4. the effect of increasing or decreasing it;
5. whether it is a requirement, evidence-based choice or temporary assumption.

Example:

```python
# Observations older than this limit cannot support a current crowd label.
# A lower value improves freshness but increases Unknown results; a higher
# value improves coverage but increases the risk of presenting old conditions.
STALE_AFTER_MINUTES = 15
```

## 6. Comment and documentation rule

Do not comment obvious syntax. Explain non-trivial logic so a teammate familiar with the unit and project requirements can answer:

- What does this block do?
- Why is it required?
- What does each important variable represent?
- How does the mechanism work?
- Which acceptance criterion or integration contract does it implement?
- What happens when its key parameter changes?
- What uncertainty or limitation remains?

Use project terminology consistently: candidate route, pedestrian observation, personal crowd threshold, `High`/`Low`/`Unknown`, freshness, coverage, hotspot, prediction horizon and candidate refuge.

Avoid vague claims such as “works well,” “accurate,” “safe” or “better” without a requirement, measurement or evidence.

## 7. Data-quality rule

All external data must be normalised at one adapter boundary. Downstream modules must not depend on City of Melbourne or provider-specific column names.

Every observation used for current scoring must include:

- sensor identity and coordinates;
- count and unit;
- observation timestamp;
- calculated freshness;
- availability status;
- source/provenance where available.

Mandatory semantics:

- missing is not zero;
- stale is not current;
- unsupported is not Low;
- minute granularity is not minute freshness;
- partial route coverage must be disclosed;
- data outside City of Melbourne coverage must be `Unknown`.

Parsing errors, missing columns, invalid coordinates and provider failures must be handled explicitly and tested.

## 8. Scoring and recommendation rule

The user's threshold is the comparison boundary and must not be silently replaced by a global frontend value.

Mandatory outcomes:

- count greater than threshold: `High`;
- count equal to or below threshold: `Low`;
- no supported current evidence: `Unknown`;
- High result includes supporting hotspot evidence;
- recommendation includes reason and time trade-off;
- no supported Low alternative is reported explicitly;
- an Unknown route is never described as low crowd.

Scoring logic must be deterministic for the same inputs. Any aggregation choice must be documented and tested against boundary values.

## 9. AI-quality rule

The AI component must not be merged as “validated” until it provides:

- defined input features and target;
- documented aggregation interval and forecast horizon;
- time-ordered train/validation/test handling that avoids future-data leakage;
- baseline comparison;
- MAE and RMSE on held-out data;
- model version and reproducible configuration;
- missing-data behaviour;
- supported uncertainty or an explicit `confidence: null`;
- evidence that the chosen model improves meaningfully over the baseline.

Until these conditions pass, responses must remain `not_validated`, `mock` or `placeholder`. A deterministic placeholder must never be called an AI prediction in user-facing copy.

## 10. Refuge-quality rule

Refuge search must use the actual selected arrival coordinates. It must:

- search the agreed candidate categories;
- use an independent fallback if typed search produces no usable candidates;
- deduplicate provider results;
- rank by actual walking time when routing is available;
- identify straight-line estimates when actual walking routes are unavailable;
- preserve provider ID and provenance;
- label every result `candidate_not_verified` unless a separate verification process exists.

The product must not claim that a candidate is quiet, open, accessible or sensory-safe without evidence for that claim.

## 11. API-quality rule

Public request and response fields are governed by `API_CONTRACT.md`.

Every endpoint must:

- validate required fields, types, ranges and paired coordinates;
- return JSON consistently;
- use stable status codes and error codes;
- avoid stack traces, secrets and provider internals in client errors;
- expose timestamp, mode, provenance and limitation fields where relevant;
- preserve backward compatibility unless the coordinated contract-change process is followed.

Expected failure mapping:

| Condition | Status |
|---|---:|
| Invalid JSON, field or range | `400` |
| Valid request for absent resource | `404` |
| Semantically unusable input | `422` |
| Required upstream component unavailable | `503` |

Do not fabricate a successful live result when an upstream provider fails.

## 12. Testing rule

Every component change must include automated tests at the lowest useful level and an integration test at its boundary.

Minimum backend suite:

- health endpoint;
- valid route comparison;
- deterministic repeated request;
- threshold equality and just-above-threshold boundaries;
- High, Low and Unknown;
- missing, stale and partial coverage;
- High route with Low alternative;
- High route without Low alternative;
- malformed JSON and missing required fields;
- invalid coordinates, threshold and limit;
- prediction available, unavailable and not validated;
- refuge results, empty results, deduplication and fallback;
- routing/data/AI/places timeout or failure;
- consistent `400`, `404`, `405`, `422` and `503` error shapes.

A bug fix must first add a test that reproduces the bug, then change the implementation.

Tests must be deterministic, independent and free of live network dependency. External APIs should be replaced with fixtures or mocks during automated tests.

## 13. Security and privacy rule

- Store keys and tokens in environment variables; never commit them.
- Maintain a safe `.env.example` containing names only, not values.
- Apply timeouts and bounded result sizes to external calls.
- Keep backend Google credentials server-side; the frontend must consume the backend autocomplete, route and refuge contracts rather than receive that key.
- Restrict Google keys by platform and API. Never reuse an unrestricted key across browser and server contexts.
- Validate all external responses before use.
- Return sanitised client errors and record diagnostic detail only in controlled logs.
- Do not log personal origin/destination data unnecessarily.
- Pin genuine dependencies and justify new packages.
- Run dependency and secret scanning before integration.

## 14. Review and merge gates

Before requesting review, the contributor must provide:

```text
[ ] Code is in the assigned branch and permitted folders
[ ] Public contract is unchanged or coordinated
[ ] No dead/duplicate/experimental code
[ ] Configurable values are parameterised and documented
[ ] Non-trivial logic explains what, why and mechanism
[ ] Missing/stale/unavailable behaviour is explicit
[ ] Unit and boundary tests pass from a clean environment
[ ] No live network dependency in automated tests
[ ] No secret, cache, generated output or local path is committed
[ ] README/contract/limitations are updated
[ ] Integration owner and downstream consumer have reviewed examples
[ ] Evidence is attached to the task/card
```

The pull request must not merge if any mandatory item fails. A reviewer should request a change rather than accept an undocumented future fix.

## 15. Definition of Done

A component is Done only when:

1. it implements its agreed contract;
2. it can be imported into the single Flask application;
3. its normal, boundary and failure tests pass;
4. its configurable values and assumptions are documented;
5. its limitations and uncertainty are visible in its output;
6. it has no secrets, dead code or hidden state;
7. its consumer successfully integrates against the same fixture;
8. the full Docker application starts from a clean checkout;
9. frontend behaviour matches the current prototype requirements;
10. review and test evidence is recorded before merge to `development`.

Passing local execution alone does not satisfy this Definition of Done.
