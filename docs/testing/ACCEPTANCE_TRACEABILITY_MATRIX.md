# Acceptance Traceability Matrix

This matrix maps **Parent Cards E1 and E2**, their user stories, and QA / security release controls to verification methods and repository evidence.

Column definitions follow the team traceability template:

| Column | Meaning |
|---|---|
| **Module** | Epic, workstream, or parent card |
| **User Story ID** | Backlog user story identifier |
| **User Story** | Short functional description |
| **AC ID** | Acceptance criterion identifier |
| **Acceptance Title** | Short criterion name |
| **Acceptance Criteria** | Condition that must be met |
| **Test Type** | Manual, Unit Test, Integration Test, UI/API, Automation, Security Scan |
| **Expected Result / Evidence** | Test case, command, artifact, or review record |
| **Priority** | P1 = release-blocking, P2 = should pass, P3 = documented deferral |
| **Status** | Pass / Partial / Fail / N/A at time of matrix update |

**Matrix updated:** 10 August 2026 · Branch: `integration`

---

## Epic E1 — Onboarding & Sensory Journey

### US1.1 — Display High/Low Route Sensory Indicator

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E1 | US1.1 | Display High/Low route sensory indicator | US1.1-AC1 | Route classification | Supported routes are classified as **High**, **Low**, or **Unknown** using pedestrian crowd evidence matched to route geometry. | Unit Test | `ai/tests/test_route_scoring.py` — segment and route aggregation cases; `backend/tests/test_route_scoring.py` — direct/proxy/stale coverage | P1 | Pass |
| E1 | US1.1 | Display High/Low route sensory indicator | US1.1-AC2 | Safe Unknown handling | **Unknown** is never treated as **Low** and is never recommended as a lower-crowd alternative. | Unit Test | `backend/tests/test_route_scoring.py::test_recommendation_is_shortest_supported_low_and_never_unknown`; `backend/tests/test_routes.py::test_route_service_maps_unavailable_sensor_evidence_to_unknown` | P1 | Pass |
| E1 | US1.1 | Display High/Low route sensory indicator | US1.1-AC3 | Explainability | Classification output includes sensor evidence, coverage basis (direct ≤75 m / proxy ≤150 m), and limitation messaging when evidence is partial or unavailable. | Integration Test | `backend/tests/test_routes.py::test_route_comparison_returns_two_explainable_routes`; `backend/API_CONTRACT.md`; frontend route cards in `frontend/src/app/page.tsx` | P1 | Pass |
| E1 | US1.1 | Display High/Low route sensory indicator | US1.1-AC4 | Threshold sensitivity | User sensitivity / crowd limit changes the effective threshold and can change High/Low outcome where supported. | Unit Test | `ai/models/sensitivity_multiplier_test.py`; `ai/docs/DEV-US1.1-01_writeup.md` §5; `ai/models/alert_thresholds.py` | P1 | Pass |
| E1 | US1.1 | Display High/Low route sensory indicator | US1.1-AC5 | Interface evidence | Frontend displays High/Low/Unknown on route cards and map overlays for the selected journey. | UI/API | `docs/testing/screenshots/compare.png`; `frontend/src/app/page.tsx` RoutesScreen; `frontend/src/app/GeographicMap.tsx` sensor markers | P1 | Pass |

### US1.2 — Compare Supported Route Alternatives

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E1 | US1.2 | Compare supported public-transport alternatives | US1.2-AC1 | Route alternatives | The journey presents multiple genuine public-transport alternatives for the entered origin and destination. | UI/API | `frontend/src/app/GeographicMap.tsx` — Google Routes API (`requestRoutesApi`); `docs/testing/screenshots/compare.png` | P1 | Pass |
| E1 | US1.2 | Compare supported public-transport alternatives | US1.2-AC2 | Backend compare contract | Backend `/api/routes/compare` returns stable route IDs, legs, classification, recommendation, and trade-off fields. | Integration Test | `backend/tests/test_routes.py`; `backend/API_CONTRACT.md` § `POST /api/routes/compare` | P1 | Pass |
| E1 | US1.2 | Compare supported public-transport alternatives | US1.2-AC3 | Hotspot identification | A supported High-crowd corridor can be identified and surfaced with sensor ID, count, and timestamp. | UI/API | `frontend/src/app/page.tsx` hotspot-avoidance panel; `backend/tests/test_routes.py::test_high_route_exposes_hotspot_evidence` | P1 | Pass |
| E1 | US1.2 | Compare supported public-transport alternatives | US1.2-AC4 | Verified avoidance | When a supported lower-crowd alternative avoids a High hotspot, the UI states verified avoidance and explicit trade-offs (time / walking). | Manual / UI | `frontend/src/app/page.tsx` verifiedAvoidance copy; manual demo on routes screen | P1 | Partial |
| E1 | US1.2 | Compare supported public-transport alternatives | US1.2-AC5 | No false avoidance claim | When no verified lower-crowd alternative avoids the hotspot, the UI does **not** claim corridor avoidance. | Manual / UI | `frontend/src/app/page.tsx` explicit-tradeoff / no-low-route messaging | P1 | Pass |

### US1.3 — Threshold Response & Reroute Interaction

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E1 | US1.3 | Respond to user crowd threshold | US1.3-AC1 | Threshold control | User can set a crowd limit / threshold during route selection. | UI/API | `frontend/src/app/page.tsx` crowd-limit slider; `docs/testing/screenshots/compare.png` | P1 | Pass |
| E1 | US1.3 | Respond to user crowd threshold | US1.3-AC2 | Live reclassification | Changing the threshold updates route High/Low labels, recommendation, and map sensor colouring without requiring a new address search. | Manual / UI | `frontend/src/app/page.tsx` + `GeographicMap.tsx`; manual slider test | P1 | Pass |
| E1 | US1.3 | Respond to user crowd threshold | US1.3-AC3 | Threshold validation | Invalid threshold values are rejected at the API boundary. | Integration Test | `backend/tests/test_routes.py::test_invalid_threshold_is_rejected` | P1 | Pass |
| E1 | US1.3 | Respond to user crowd threshold | US1.3-AC4 | Forecast threshold integration | User threshold function is connected to next-hour alert evaluation via a documented contract. | Integration Test | `ai/models/alert_thresholds.py`; `ai/docs/US1.3_HANDOFF.md`; `GET /api/forecast/<sensor_id>?sensitivity=...` evidence in `ai/docs/AI-US2.2-01_writeup.md` | P1 | Partial |
| E1 | US1.3 | Reroute / continue choice | US1.3-AC5 | Non-blocking choice | When no route is within the limit, the user can still continue; the app withholds recommendation rather than blocking travel. | Manual / UI | `frontend/src/app/page.tsx` no-low-route messaging; journey continue button remains available | P2 | Pass |

### US1.4 — Onboarding Entry & Refuge Support *(vertical-slice journey)*

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E1 | US1.4 | Enter origin and destination | US1.4-AC1 | Onboarding entry | User can enter origin and destination and proceed to route comparison. | UI/API | `docs/testing/screenshots/onboarding.png`; `frontend/src/app/page.tsx` PlanScreen; `frontend/src/app/PlaceSearch.tsx` | P1 | Pass |
| E1 | US1.4 | Enter origin and destination | US1.4-AC2 | Address fallback | If Google autocomplete is unavailable, a fallback address input still allows journey planning. | Manual / UI | `frontend/src/app/PlaceSearch.tsx` fallback textarea branch | P2 | Partial |
| E1 | US1.4 | Locate candidate refuge | US1.4-AC3 | Refuge lookup | Backend returns ranked candidate refuges for arrival coordinates with transparent crowd proxy wording. | Integration Test | `backend/tests/test_refuges.py`; `GET /api/refuges` in `backend/API_CONTRACT.md` | P1 | Pass |
| E1 | US1.4 | Locate candidate refuge | US1.4-AC4 | Refuge UI | Frontend quiet-spot / refuge flow presents candidates and walking route preview. | UI/API | `docs/testing/screenshots/refuge.png`; `frontend/src/app/page.tsx` QuietSpotScreen | P1 | Pass |

---

## Epic E2 — Sensory Environment Monitoring

### US2.2 — Next-Hour Crowd Forecast & Alert

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E2 | US2.2 | Forecast next-hour crowd level | US2.2-AC1 | Forecast output | System produces a next-hour crowd forecast per supported sensor using the approved RF model. | Unit Test / Review | `ai/docs/AI-US2.2-01_writeup.md` §4–§6; `ai/models/rf_explain.py`; MAE 54.1 vs baseline | P1 | Pass |
| E2 | US2.2 | Forecast next-hour crowd level | US2.2-AC2 | No unsupported forecast | Missing, stale, or insufficient inputs do **not** produce an unsupported forecast presented as fact. | Unit Test | `ai/docs/AI-US2.2-01_writeup.md` Data Integrity row; sensor-outage test in `rf_explain.py` | P1 | Pass |
| E2 | US2.2 | Forecast next-hour crowd level | US2.2-AC3 | Explainability | Forecast response includes timestamp, area/sensor context, confidence, and limitation notes where applicable. | Integration Test | `backend/tests/test_predictions.py`; `GET /api/predictions` / forecast route responses | P1 | Pass |
| E2 | US2.2 | Forecast next-hour crowd level | US2.2-AC4 | Alert evaluation | Alert threshold comparison uses user sensitivity and can change alert boolean across sensitivity levels. | Integration Test | `ai/docs/AI-US2.2-01_writeup.md` Integration row; verified HTTP examples for sensor 161 | P1 | Partial |
| E2 | US2.2 | Forecast next-hour crowd level | US2.2-AC5 | Journey alert UI | Journey screen shows next-hour warning messaging when forecast exceeds the user limit, with withheld messaging when unavailable. | UI/API | `frontend/src/app/page.tsx` JourneyScreen forecast panel; manual journey demo | P1 | Pass |

### US2.1 — *(not evidenced in repository)*

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| E2 | US2.1 | — | US2.1-AC0 | Story coverage | User Story **US2.1** acceptance criteria are mapped to tests or documented review. | Review | No `US2.1` implementation or card write-up found under `docs/` or `ai/docs/` | P1 | Fail |

---

## QA — Release Gate & Test Automation

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| QA | QA-RG | Establish repeatable release checks | QA-AC1 | Acceptance traceability | Every in-scope user story acceptance criterion maps to a test or documented review in this matrix. | Review | This document | P1 | Partial |
| QA | QA-RG | Establish repeatable release checks | QA-AC2 | Test reproducibility | Unit and integration tests run consistently from documented instructions. | Automation | `docs/testing/RELEASE_CRITERIA.md` §1; `cd backend && pytest tests` (25 passing locally) | P1 | Pass |
| QA | QA-RG | Establish repeatable release checks | QA-AC3 | CI automation | Required automated checks run on approved repository changes. | Automation | `.github/workflows/ci.yml` — `backend-tests`, `frontend-check`, `security-scan` | P1 | Pass |
| QA | QA-RG | Establish repeatable release checks | QA-AC4 | Release gate | A failed mandatory test prevents the build from being treated as releasable. | Automation | Failed jobs block merge per `RELEASE_CRITERIA.md`; branch protection recommended | P1 | Partial |
| QA | QA-RG | Establish repeatable release checks | QA-AC5 | Evidence retention | Test results and build status are retained as completion evidence. | Automation | CI artifacts: `backend-test-report`, `frontend-ci-reports`, `security-reports` | P1 | Pass |
| QA | QA-RG | Establish repeatable release checks | QA-AC6 | Frontend automation gap | Browser end-to-end coverage for onboarding journey is automated. | Automation | Not implemented; listed as future improvement in `RELEASE_CRITERIA.md` | P2 | Fail |

---

## SEC — Security, Privacy & Failure Assessment

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC1 | Credential security | No secrets, credentials, or private tokens are committed to the repository. | Security Scan / Review | `.gitignore`; `backend/.env.example`; `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md` §2.1 | P1 | Pass |
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC2 | Input validation | External inputs and API responses are validated before use. | Integration Test | `backend/tests/test_routes.py`, `test_refuges.py`, `test_predictions.py`; `backend/app/routes.py` | P1 | Pass |
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC3 | Failure coverage | Missing, stale, malformed, and unavailable-data conditions are tested. | Integration Test | `backend/tests/test_crowd_freshness.py`, `test_route_scoring.py`, `test_predictions.py` | P1 | Pass |
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC4 | Safe failure | Failure conditions do not produce unsupported classifications, forecasts, or recommendations. | Integration Test | Unknown-not-Low assertions; prediction unknown handling; security assessment §2.3 | P1 | Pass |
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC5 | Privacy retention | Journey preferences follow the documented retention rule. | Review | `docs/testing/PRIVACY_RETENTION.md` — session-only, non-persistent | P1 | Pass |
| SEC | SEC-VS | Test foreseeable failure conditions | SEC-AC6 | Dependency scanning | Team-approved dependency security checks are completed and retained. | Security Scan | `docs/testing/security-scans/` baseline; CI `security-scan` job artifacts | P1 | Pass |

---

## VS — Parent Cards E1 + E2 Vertical Slice Integration

| Module | User Story ID | User Story | AC ID | Acceptance Title | Acceptance Criteria | Test Type | Expected Result / Evidence | Priority | Status |
|---|---|---|---|---|---|---|---|---|---|
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC1 | End-to-end integration | Data, backend, AI, and interface components operate together for one supported journey. | Manual / UI | Local Docker flow; `docs/testing/VERTICAL_SLICE_DELIVERY.md` §4 | P1 | Partial |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC2 | Supported journey | Journey demonstrates PT access → compare → threshold → refuge → next-hour alert. | Manual / UI | Screenshots: `onboarding.png`, `compare.png`, `refuge.png`; demo flow in delivery notes | P1 | Partial |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC3 | Transparency | Data sources, timestamps, coverage, and limitations are visible in the UI. | Manual / UI | Route cards, scenario banner, withheld / unavailable copy in `page.tsx` | P1 | Pass |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC4 | Reproducibility | Local execution can be reproduced from documented instructions. | Review | `README.md`, `DOCKER_SETUP.md`, `backend/SETUP.md`, `frontend/SETUP.md` | P1 | Pass |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC5 | Performance target | Integrated experience meets a team-approved product response-time target under defined test conditions. | Review | **No product-level response-time target is documented**; only implementation timeouts and model MAE exist | P2 | Fail |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC6 | Mentor readiness | Mentor review record is completed with result and follow-ups. | Review | `docs/testing/VERTICAL_SLICE_DELIVERY.md` §6 — blank | P1 | Fail |
| VS | E1+E2 | Deliver onboarding vertical slice | VS-AC7 | Hosted evidence | Deployment/build link or consistent hosted demo is linked to the card. | Review | Delivery notes state no hosted URL; localhost only | P2 | Fail |

---

## Summary

| Status | Count |
|---|---:|
| Pass | 28 |
| Partial | 8 |
| Fail | 5 |
| N/A | 0 |

### Release-blocking gaps (P1 Partial / Fail)

1. **US2.1** — no repository evidence for this user story.
2. **US1.3-AC4 / US2.2-AC4** — threshold integration uses an interim `alert_thresholds.py` implementation; formal US1.3 sign-off still open.
3. **QA-AC1 / QA-AC4** — matrix now exists, but branch protection and full US coverage depend on mentor/process confirmation.
4. **VS-AC1 / VS-AC2 / VS-AC6 / VS-AC7** — vertical slice is demoable locally; mentor review and hosted evidence remain incomplete.

### Mandatory automated commands

```bash
# Backend
cd backend && pytest tests

# Frontend
cd frontend && npm ci && npm run lint && npm run build

# Security baseline
python -m pip_audit -r backend/requirements.txt --format json --output python-security-report.json
cd frontend && npm audit --audit-level=high
```

### Related documents

- `docs/testing/RELEASE_CRITERIA.md`
- `docs/testing/VERTICAL_SLICE_DELIVERY.md`
- `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md`
- `docs/testing/PRIVACY_RETENTION.md`
- `docs/testing/security-scans/README.md`
- `.github/workflows/ci.yml`

### Maintenance rule

When a new user story or acceptance criterion is added to the backlog, append a row to the relevant section with:

1. AC ID and wording from the backlog card
2. Test type and concrete evidence path
3. Priority and current status

Do not mark a card Done until every **P1** row for that story is **Pass**, or an explicit documented deferral is approved in PR review.
