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
- [x] Documented retention rule: journey preferences and journey information are session-only (browser memory), not persisted and not uploaded as personal profile data. See `docs/testing/PRIVACY_RETENTION.md`.
- [x] User journey preferences are handled as on-device React state rather than permanent storage.
- [x] No long-term preference profile, journey history, or account store is implemented in the vertical slice.
- [x] Credentials and provider keys are kept server-side in backend / environment configuration.

## 3. Threat and Failure-Mode Assessment

### 3.1 Threat categories

| Threat / Failure Mode | Impact | Existing control | Evidence |
|---|---|---|---|
| Secrets checked into repo | Credential theft, unauthorized API use | `.gitignore`, placeholder `.env.example`, CI placeholder key | `backend/.env.example`, `.gitignore`, `.github/workflows/ci.yml` |
| Malformed or missing request inputs | Incorrect classification, crash | Request validation in `backend/app/routes.py` | `backend/tests/test_refuges.py`, `backend/tests/test_predictions.py`, `backend/tests/test_routes.py` |
| Stale or unavailable sensor data | Unsupported or misleading recommendation | Data freshness scoring in `backend/app/services/prototype_crowd_service.py`, `backend/app/services/route_scoring_service.py` | `backend/tests/test_route_scoring.py`, `backend/tests/test_crowd_freshness.py` |
| External API outage / Google Maps failure | Broken route search, no route candidates | Fallback route failure handling and frontend fallback input | `frontend/src/app/GeographicMap.tsx`, `frontend/src/app/PlaceSearch.tsx` |
| Dependency vulnerabilities | Supply-chain compromise | `pip-audit` and `npm audit` in CI, retained scan artifacts | `.github/workflows/ci.yml`, `docs/testing/security-scans/` |
| Unintended retention of journey preferences | Privacy over-collection | Session-only retention rule | `docs/testing/PRIVACY_RETENTION.md` |

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
- `security-scan` — installs backend requirements, runs `pip-audit -r backend/requirements.txt` to JSON, runs `npm audit --audit-level=high`, and uploads both reports as the `security-reports` artifact (`if: always()`, 30-day retention).

### 4.2 Scan evidence
- Repository baseline (10 August 2026):
  - `docs/testing/security-scans/python-security-report.json` — `pip-audit` result: no known vulnerabilities.
  - `docs/testing/security-scans/frontend-security-report.txt` — `npm audit --audit-level=high` result: `found 0 vulnerabilities`.
  - Index: `docs/testing/security-scans/README.md`.
- CI retention:
  - GitHub Actions job: `security-scan` in `.github/workflows/ci.yml`.
  - Artifact name: `security-reports`.
  - Contents: `python-security-report.json` and `frontend-security-report.txt`.
  - Retrieval: GitHub → Actions → Continuous integration → successful run → Artifacts → `security-reports`.

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
- Confirmed `backend/.env.example` is placeholder-only and `.env` files are ignored.
- Fixed CI `security-reports` upload so `pip-audit` JSON is retained alongside the npm audit text report.
- Documented the session-only privacy retention rule in `docs/testing/PRIVACY_RETENTION.md`.

### 6.2 Retest evidence
- Local frontend build: `cd frontend && npm run build` succeeded.
- Local lint: `cd frontend && npm run lint` succeeded.
- Local dependency retest (10 August 2026):
  - `pip-audit -r backend/requirements.txt` → no known vulnerabilities.
  - `npm audit --audit-level=high` → `found 0 vulnerabilities`.
- CI workflow now uploads both Python and frontend security reports on every `security-scan` run, including failed runs (`if: always()`), for completion evidence.

## 7. Traceability

| Evidence type | Location | Notes |
|---|---|---|
| Threat/failure register | `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md` | This assessment document |
| Privacy retention rule | `docs/testing/PRIVACY_RETENTION.md` | Session-only journey preference rule |
| Local scan baseline | `docs/testing/security-scans/` | Captured `pip-audit` + `npm audit` outputs |
| CI workflow | `.github/workflows/ci.yml` | Backend tests, frontend checks, dependency scans |
| CI scan artifact | GitHub Actions `security-reports` | JSON + text reports, 30-day retention |
| Release criteria | `docs/testing/RELEASE_CRITERIA.md` | Mandatory release gate and defect severity rules |
| Traceability matrix | `docs/testing/ACCEPTANCE_TRACEABILITY_MATRIX.md` | Maps acceptance to tests and documentation |

## 8. Recommended next actions

1. Add explicit frontend unit tests for malformed autocomplete and route-fallback behavior.
2. Add failure-mode test cases for Google Maps outage and malformed routing API responses.
3. After the next push to `integration`, attach the GitHub Actions run URL for the green `security-scan` job to the parent card as live CI evidence.
