# Onboarding Vertical Slice Delivery Notes

## 1. Deployment / Build Evidence

- Frontend production build verified with:
  - `npm run build`
- Backend test suite verified with:
  - `pytest tests/test_health.py tests/test_routes.py tests/test_refuges.py tests/test_predictions.py`
- Local services verified with:
  - Backend health endpoint: `http://localhost:5000/api/health`
  - Frontend app: `http://localhost:3000`

## 2. Repository Version

- Current branch: `integration`
- Current commit: `8ba5499`

## 3. Setup Instructions

### Backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
python run.py
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## 4. End-to-End Test Evidence

The current onboarding slice was exercised through:

1. Backend route comparison API
2. Backend prediction API
3. Backend refuge API
4. Frontend onboarding and quiet-spot flow

Observed outcomes:

- Route comparison returned two explainable routes with one recommended low-crowd option.
- Prediction endpoint returned transparent placeholder / not-validated output.
- Refuge endpoint returned candidate refuge results.

## 5. Demonstration Evidence

Suggested evidence to attach:

- Screenshot of the onboarding page
- Screenshot of the route comparison results
- Screenshot of the quiet-spot / refuge flow
- Optional short screen recording for mentor review

Stored location:

- `docs/testing/screenshots/`

## 6. Mentor Review Record

Use this section to record mentor feedback:

- Review date:
- Reviewer:
- Result:
- Follow-up actions:
