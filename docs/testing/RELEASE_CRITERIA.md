# Release Criteria for Calmer Commute

This document defines the mandatory release gate for repository changes.

## Mandatory Release Checks

### 1. Backend automated test suite

- Run from the repository root:

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
# or
source .venv/bin/activate  # Linux/macOS
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
pytest tests
```

- Expected result: all tests pass.
- Evidence: GitHub Actions `backend-tests` job and uploaded `backend-test-report` artifact.

### 2. Frontend quality and build checks

- Run from the repository root:

```bash
cd frontend
npm ci
npm run lint
npm run build
```

- Expected result: lint passes and production build succeeds.
- Evidence: GitHub Actions `frontend-check` job and uploaded `frontend-ci-reports` artifact.

### 3. Dependency security checks

- Run from the repository root:

```bash
python -m pip install --upgrade pip
pip install pip-audit
python -m pip_audit --format json > python-security-report.json && python -c "import json,sys; data=json.load(open('python-security-report.json')); sys.exit(1 if any(len(dep.get('vulns', [])) for dep in data.get('dependencies', [])) else 0)"
cd frontend
npm ci
npm audit --audit-level=high
```

- Expected result: no high-severity vulnerabilities.
- Evidence: GitHub Actions `security-scan` job and uploaded `security-reports` artifact.

## Release Gate Rules

A release may not proceed if any of the following conditions exist:

- `ci.yml` fails for backend tests, frontend lint/build, or security scans.
- Any unresolved merge conflict remains in the working tree.
- A critical or high-priority defect is open against the target release branch.
- Required delivery evidence is missing from the release documentation.

## Defect Severity Control

For release approvals, use the following defect prioritization:

- Blocker / Critical: must be fixed before release.
- High: must be fixed before release unless a documented mitigation is approved by the team.
- Medium / Low: may be deferred with documented acceptance from the reviewer.

## Release Evidence and Traceability

Track release evidence in the following documents:

- `docs/testing/VERTICAL_SLICE_DELIVERY.md` — build validation, runtime evidence, and demo notes.
- `docs/testing/ACCEPTANCE_TRACEABILITY_MATRIX.md` — acceptance criteria mapping.
- `docs/testing/RELEASE_CRITERIA.md` — release gate and defect control.

## Team Approval

Release criteria are approved when:

- the PR includes this document and the traceability matrix,
- the CI workflow passes on `development`/`integration`/`main`,
- at least one team reviewer confirms the release checklist in PR review comments,
- unresolved critical/high defects are explicitly discussed and accepted in the PR.

## Recommended Branch Protection

For `development`, `integration`, and `main` branches, enforce:

- required status checks for `backend-tests`, `frontend-check`, and `security-scan`
- no direct pushes from feature branches without PR review
- required review from at least one team member

## Future Improvements

- Add dedicated frontend unit and integration tests.
- Add browser-based end-to-end coverage for the onboarding and route experience.
- Extend security scans with SCA tooling or dependency pinning.
