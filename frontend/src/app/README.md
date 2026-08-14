# Calm-panion frontend

Copy every source file in this folder into:

`frontend/src/app/`

This replaces the root journey planner while leaving the repository's legacy routes intact.

- `/` opens the Calm-panion journey planner directly.
- No Welcome/Continue screen.
- No Home, Profile, Quiet Spot, or Emergency navbar.
- No dependency on separate legacy routes.
- The planner's route, sensor, forecast, journey, and nearby-refuge flow remains intact.

## Current structure

- `page.tsx` orchestrates the four-screen journey flow and renders the route and journey screens.
- `useJourneyData.ts` owns crowd and route-forecast requests, cancellation, and loading state.
- `routeAssessment.ts` is the shared source of truth for direct/proxy evidence, maximum counts, risk, and verified route forecasts.
- `journeyTypes.ts` contains the frontend API and domain contracts.
- `QuietSpotScreen.tsx` owns refuge discovery, ranking, and walking-route state.
- `GeographicMap.tsx` owns Google route parsing and map rendering while consuming the shared assessment functions.
- `api/predictions/route.ts` proxies forecast requests to the Flask backend.

## Prediction contract

Prediction fields and placeholders are intentionally retained while the model artifact is supplied separately. A number is displayed only for a validated live `crowd-forecast-rf-v1` response. Loading, null, unavailable, and unsupported responses remain visible as `Checking forecast...` or `Unverified`; the frontend does not invent a forecast value.

`forecastRisk` is intentionally retained in the assessed-route contract for future prediction-owner integration, even though the current cards use the backend `predicted_level` for the alert.

After copying, rebuild from the repository root:

```powershell
docker compose down
docker compose build --no-cache frontend
docker compose up -d
```

Then open `http://localhost:3000/` and hard-refresh with `Ctrl + Shift + R`.

The old route folders are not deleted by this drop-in. Review their ownership and direct URLs before deciding whether to retire them.
