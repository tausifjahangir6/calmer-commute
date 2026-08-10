# Security Scan Evidence

This folder retains dependency-security scan outputs for the vertical-slice security card.

## Local baseline captured for this release

| Scan | Command | Result | Evidence file |
|---|---|---|---|
| Python dependencies | `python -m pip_audit -r backend/requirements.txt --format json --output docs/testing/security-scans/python-security-report.json` | No known vulnerabilities found (`0` vulns across audited packages) | `python-security-report.json` |
| Frontend dependencies | `cd frontend && npm audit --audit-level=high` | `found 0 vulnerabilities` | `frontend-security-report.txt` |

Capture date: 10 August 2026  
Repository branch at capture: `integration`

## Continuous Integration evidence

Every push and pull request to `main`, `development`, and `integration` runs the `security-scan` job in `.github/workflows/ci.yml`.

How to retrieve the latest successful scan artifact:

1. Open the repository on GitHub → **Actions** → workflow **Continuous integration**.
2. Open a successful run on the target branch.
3. Confirm the `security-scan` job is green.
4. Download the `security-reports` artifact. It contains:
   - `python-security-report.json` (`pip-audit` JSON)
   - `frontend-security-report.txt` (`npm audit --audit-level=high` output)
5. Artifacts are retained for **30 days**.

A failed mandatory security scan blocks release under `docs/testing/RELEASE_CRITERIA.md`.

## Related documents

- `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md` — checklist, threat register, remediation
- `docs/testing/PRIVACY_RETENTION.md` — privacy and retention rule
- `.github/workflows/ci.yml` — automated scan and artifact upload
