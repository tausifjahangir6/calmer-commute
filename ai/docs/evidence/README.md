# Evidence: historical-estimate fallback, live verification (2026-08-09/10)

Real output from a live `GET /api/crowd` and `POST /api/routes/compare`
call, captured while testing the per-sensor freshness fix and the
historical-estimate fallback described in `DEV-US1.1-01.md` /
`US1_1_HANDOFF_frontend_update.md`.

- `crowd_payload_fallback_check.json` - full `/api/crowd` response.
  Out of 65 sensors: 30 `observed`, 30 `estimated` (real reporting gaps
  resolved via 4-week historical fallback), 5 correctly `insufficient-history`
  (no reliable estimate available, returned Unknown rather than a guess).
- `route_compare_fallback_check.json` - full `/api/routes/compare`
  response from the same window, showing the same evidence states
  flowing through actual route scoring.

Captured overnight (~3:30am Melbourne), so most sensors were in a
genuine live reporting gap -- a good stress test for the fallback path,
not representative of daytime data density.
