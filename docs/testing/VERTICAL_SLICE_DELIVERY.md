# Onboarding Vertical Slice Delivery Notes

## 1. Deployment / Build Evidence

### Verified build commands

- Frontend production build:
  - `npm run build`
  - Result: succeeded
- Backend regression tests:
  - `pytest tests/test_health.py tests/test_routes.py tests/test_refuges.py tests/test_predictions.py`
  - Result: 14 tests passed
- Local service health checks:
  - Backend: `http://localhost:5000/api/health`
  - Frontend: `http://localhost:3000`

### Verified runtime evidence

- Backend health endpoint returned `200 OK` with JSON:
  - `{"service": "calmer-commute-backend", "status": "healthy"}`
- Frontend home page returned `200 OK`
- Local deployment evidence:
  - Frontend: `http://localhost:3000`
  - Backend: `http://localhost:5000`
  - No hosted deployment URL is available for this local proof-of-concept build
  - Recommended production deployment options: Vercel for frontend, Docker host for backend

## 2. Repository Version

- Current branch: `integration`
- Current commit: `8ba5499`
- Release tag: `v0.1.0`
- Remote: `origin`

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

The onboarding vertical slice was exercised through the working local flow:

1. Backend route comparison API
2. Backend prediction API
3. Backend refuge API
4. Frontend onboarding and quiet-spot flow

### Observed outcomes

- Route comparison returned two explainable routes and a recommended low-crowd option.
- Prediction endpoint returned transparent placeholder / not-validated output with a clear limitation message.
- Refuge endpoint returned candidate refuge results for the selected arrival coordinates.
- Frontend build completed successfully and the local UI responded at `http://localhost:3000`.

### Evidence commands

```bash
# Backend route comparison
Invoke-RestMethod -Method Post -Uri 'http://localhost:5000/api/routes/compare' -ContentType 'application/json' -Body '{"origin":"903/8 Pearl River Rd, Docklands VIC 3008","destination":"Growth Factory, 3/292 Flinders St, Melbourne VIC 3000","crowd_threshold":25}'

# Backend prediction
Invoke-RestMethod -Uri 'http://localhost:5000/api/predictions?sensor_id=5&crowd_threshold=25'

# Backend refuge lookup
Invoke-RestMethod -Uri 'http://localhost:5000/api/refuges?latitude=-37.8183&longitude=144.9671&limit=3'
```

## 5. Demonstration Evidence

Suggested evidence to attach for mentor review:

- Screenshot of the onboarding page
- Screenshot of the route comparison results
- Screenshot of the quiet-spot / refuge flow
- Short screen recording of the end-to-end journey

Stored location:

- `docs/testing/screenshots/`

### Recommended demo flow

1. Open the onboarding page.
2. Enter origin and destination.
3. Set a crowd threshold.
4. Review route comparison.
5. Review prediction / alert messaging.
6. Continue to refuge support.

## 6. Mentor Review Record

Use this section to record mentor feedback:

- Review date:
- Reviewer:
- Result:
- Follow-up actions:
- Outstanding limitations:
