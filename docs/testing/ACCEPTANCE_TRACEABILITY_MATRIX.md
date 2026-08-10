# Acceptance Traceability Matrix

This matrix links the repository's acceptance controls, tests, and review evidence to the project release workflow.

## Acceptance Criteria Mapping

| Acceptance Criterion | Evidence / Test | Location | Release Gate |
|---|---|---|---|
| Acceptance Traceability: every User Story acceptance criterion maps to a test or documented review | User Story acceptance criteria and delivery evidence are documented in `docs/testing/VERTICAL_SLICE_DELIVERY.md` and `docs/testing/RELEASE_CRITERIA.md` | `docs/testing/` | Manual review during PR + CI validation |
| Test Reproducibility: unit and integration tests run consistently from documented instructions | `backend/tests` run with `pytest` and documented in `docs/testing/RELEASE_CRITERIA.md` | `backend/tests/`, `backend/requirements-dev.txt`, `docs/testing/RELEASE_CRITERIA.md` | CI `backend-tests` job |
| Automation: required automated checks run for team-approved repository changes | GitHub Actions workflow `ci.yml` runs backend tests, frontend lint/build, and security scans | `.github/workflows/ci.yml` | CI enforced on PR and push |
| Release Gate: a failed mandatory test prevents the build from being treated as releasable | `ci.yml` jobs fail on lint/build/tests/security failures | `.github/workflows/ci.yml` | branch protection expected on `development`/`main`/`integration` |
| Quality Controls: team-approved code-quality and security checks are included | `npm run lint`, `pytest`, `pip-audit`, `npm audit` | `frontend/package.json`, `backend/requirements-dev.txt`, `.github/workflows/ci.yml` | CI quality checks |
| Security and failure assessment: a documented threat/failure register exists and is mapped to controls, tests, and artifacts | `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md` and `docs/testing/RELEASE_CRITERIA.md` | `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md`, `.github/workflows/ci.yml` | Manual review + CI evidence |
| Defect Control: critical and high-priority unresolved defects block release | Defect severity defined in `docs/testing/RELEASE_CRITERIA.md` | `docs/testing/RELEASE_CRITERIA.md` | Manual acceptance during PR review |
| Evidence Retention: test results and build status are retained as completion evidence | GitHub Actions artifacts and status checks are retained by GitHub | `.github/workflows/ci.yml` | Artifact retention from CI |
| Team Approval: release criteria are documented and approved by the team | Release criteria documented in `docs/testing/RELEASE_CRITERIA.md` | `docs/testing/RELEASE_CRITERIA.md` | Team review of documentation and PR |
| Traceability: each release criterion is linked to its pipeline, test result or approval evidence | This matrix and release criteria document provide the links | `docs/testing/ACCEPTANCE_TRACEABILITY_MATRIX.md`, `docs/testing/RELEASE_CRITERIA.md` | Review and audit trail |

## User Story Acceptance Mapping

The project contains multiple user stories documented in the `docs/` and `ai/docs/` folders. For release readiness, the following test scope is mandatory:

- Backend API behavior and validation coverage: `pytest backend/tests`
- Frontend production readiness: `cd frontend && npm ci && npm run build`
- Code-quality enforcement: `cd frontend && npm run lint`
- Security checks for high-severity dependency issues: `python -m pip_audit --format json > python-security-report.json && python -c "import json,sys; data=json.load(open('python-security-report.json')); sys.exit(1 if any(len(dep.get('vulns', [])) for dep in data.get('dependencies', [])) else 0)"` and `npm audit --audit-level=high`

## Notes

- This matrix is maintained alongside release evidence in `docs/testing/VERTICAL_SLICE_DELIVERY.md`.
- When new user stories are added, the corresponding acceptance criteria must be added to this matrix with a matching test or documented review step.
