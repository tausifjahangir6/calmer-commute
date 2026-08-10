# Calmer Commute direct-root replacement

Copy every source file in this folder into:

`frontend/src/app/`

This intentionally replaces the legacy root layout and home page. The result is:

- `/` opens the Calmer Commute journey planner directly.
- No Welcome/Continue screen.
- No Home, Profile, Quiet Spot, or Emergency navbar.
- No dependency on separate legacy routes.
- The planner's route, sensor, forecast, journey, and nearby-refuge flow remains intact.

After copying, rebuild from the repository root:

```powershell
docker compose down
docker compose build --no-cache frontend
docker compose up -d
```

Then open `http://localhost:3000/` and hard-refresh with `Ctrl + Shift + R`.

The old route folders can remain temporarily; they are no longer linked or used by the root flow. Delete them later only after confirming the direct planner works.
