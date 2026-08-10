# Vertical Slice Security, Privacy, and Failure Assessment

## 1. Objective

This document captures the security, privacy, data integrity, and operational failure assessment for the Calmer Commute vertical slice.
It ties the current implementation to security and failure controls, automated scans, failure-handling tests, and remediation evidence.

## 2. Security and Privacy Checklist

### 2.1 Credential and secret hygiene
- [x] No API keys, database passwords, or private tokens are committed in source control.
- [x] `backend/.env.example` contains placeholder values only.
- [x] `.gitignore` excludes `.env`, `.env.*`, and frontend environment files.
- [x] CI uses a test placeholder key for `GOOGLE_MAPS_API_KEY` when building frontend.

### 2.2 Input validation and external data handling
- [x] Backend request payload fields are validated before use in `backend/app/routes.py`.
- [x] `backend/app/services/google_maps_service.py` validates Google Maps API behavior and request payload.
- [x] `backend/app/services/prototype_crowd_service.py` converts stale or unavailable sensor feeds to explicit states.
- [x] All external data is normalized in adapters before scoring or forecast computation.

### 2.3 Failure conditions and safe fallback behavior
- [x] Missing, stale, unavailable, or malformed evidence maps to `Unknown` rather than `Low`.
- [x] Route comparison returns explainable route coverage values even if sensor data is unavailable.
- [x] Failure responses use explicit API error shapes rather than internal stack traces.
- [x] Frontend continues to render with a fallback search input when Google Maps autocomplete is unavailable.

### 2.4 Privacy and retention controls
- [x] User journey preferences are handled as on-device input rather than permanently stored in committed source.
- [x] No explicit long-term retention policy is implemented in frontend code.
- [x] Credentials and provider keys are kept server-side in backend configuration.

## 3. Threat and Failure-Mode Assessment

### 3.1 Threat categories

| Threat / Failure Mode | Impact | Existing control | Evidence |
|---|---|---|---|
| Secrets checked into repo | Credential theft, unauthorized API use | `.gitignore`, placeholder `.env.example`, CI placeholder key | `backend/.env.example`, `.gitignore`, `.github/workflows/ci.yml` |
| Malformed or missing request inputs | Incorrect classification, crash | Request validation in `backend/app/routes.py` | `backend/tests/test_refuges.py`, `backend/tests/test_predictions.py`, `backend/tests/test_routes.py` |
| Stale or unavailable sensor data | Unsupported or misleading recommendation | Data freshness scoring in `backend/app/services/prototype_crowd_service.py`, `backend/app/services/route_scoring_service.py` | `backend/tests/test_route_scoring.py`, `backend/tests/test_crowd_freshness.py` |
| External API outage / Google Maps failure | Broken route search, no route candidates | Fallback route failure handling and frontend fallback input | `frontend/src/app/GeographicMap.tsx`, `frontend/src/app/PlaceSearch.tsx` |
| Dependency vulnerabilities | Supply-chain compromise | `pip-audit` and `npm audit` in CI | `.github/workflows/ci.yml` |

### 3.2 Failure-mode categories

- `Missing input` — origin/destination or threshold absent: backend returns validation errors and frontend does not infer a route.
- `Stale input` — sensor readings older than allowed window: scoring returns `Unknown` coverage and no false Low recommendation.
- `Malformed response` — unexpected provider shape: backend normalizes or rejects the response instead of using invalid fields.
- `Unavailable provider` — Google Maps or external routing API returns error: frontend uses fallback UI and backend surfaces explicit unconfigured status.
- `Credential misuse` — API key exposure or incorrect storage: prevented by `.env` exclusion and server-side key handling.

## 4. Automated Dependency and Code Scans

### 4.1 CI scan coverage
- `backend-tests` — installs Python dependencies and runs `pytest backend/tests --junitxml=artifacts/backend-pytest.xml`.
- `frontend-check` — installs Node dependencies, runs `npm run lint`, and builds the frontend.
- `security-scan` — installs `pip-audit`, runs Python dependency audit in JSON mode, and runs `npm audit --audit-level=high`.

### 4.2 Scan evidence
- `backend-test-report` artifact contains pytest results.
- `frontend-ci-reports` artifact contains lint and build logs.
- `security-reports` artifact contains Python and frontend dependency scan outputs.

## 5. Failure-Handling Tests

### 5.1 Backend coverage
- `backend/tests/test_refuges.py` validates coordinate input and rejects invalid requests.
- `backend/tests/test_predictions.py` verifies sensor ID validation and unknown outcome handling.
- `backend/tests/test_routes.py` verifies missing origin and invalid thresholds are rejected, and that unavailable sensor evidence maps to `Unknown`.
- `backend/tests/test_crowd_freshness.py` verifies stale data is classified as `stale`/`unavailable`.
- `backend/tests/test_route_scoring.py` verifies stale/inactive coverage does not become false Low and that supported route recommendations remain explainable.

### 5.2 Frontend coverage
- `frontend/src/app/PlaceSearch.tsx` includes fallback rendering for autocomplete failures.
- `frontend/src/app/GeographicMap.tsx` contains explicit Maps configuration failure handling and route rendering fallbacks.

## 6. Remediation and Retest Record

### 6.1 Known fixes completed
- Fixed `frontend/src/app/GeographicMap.tsx` build-time TypeScript issue and safe marker handling.
- Verified no high severity dependency issues are committed against current install state via CI scan definitions.
- Confirmed `backend/.env.example` is placeholder-only and `.env` files are ignored.

### 6.2 Retest evidence
- Local frontend build: `cd frontend && npm run build` succeeded.
- Local lint: `cd frontend && npm run lint` succeeded.
- Existing backend tests and CI workflow coverage are referenced, and CI artifacts are configured for evidence retention.

## 7. Traceability

| Evidence type | Location | Notes |
|---|---|---|
| Threat/failure register | `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md` | New dedicated assessment document |
| CI workflow | `.github/workflows/ci.yml` | Backend tests, frontend checks, dependency scans |
| Release criteria | `docs/testing/RELEASE_CRITERIA.md` | Mandatory release gate and defect severity rules |
| Traceability matrix | `docs/testing/ACCEPTANCE_TRACEABILITY_MATRIX.md` | Maps acceptance to tests and documentation |
| Security scan artifacts | CI artifact upload steps | `backend-test-report`, `frontend-ci-reports`, `security-reports` |

## 8. Recommended next actions

1. Add explicit frontend unit tests for malformed autocomplete and route-fallback behavior.
2. Extend CI to capture `pip-audit` JSON results as an artifact in addition to stdout.
3. Add a documented retention rule for user preferences and journey information if permanent storage is introduced.
4. Add failure-mode test cases for Google Maps outage and malformed routing API responses.
