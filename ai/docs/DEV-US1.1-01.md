# DEV-US1.1-01 — Crowd-Based Route Scoring: Final Completion Evidence

**Parent:** [US1.1] Display High/Low Route Sensory Indicator
**Owner:** Ibwd
**Status:** COMPLETE — verified against the real, live, merged backend, including a real HTTP request through the actual production endpoint.

This supersedes all prior write-ups for this card. Earlier versions described an OSMnx-based design that was ultimately not the sanctioned integration path — this document reflects what's actually built, tested, and running.

---

## 1. What actually shipped, and why it differs from earlier plans

Initial work on this card (see `ai/models/route_scoring.py`, kept for historical reference) built a self-contained OSMnx-based routing and scoring pipeline. Partway through, the real backend architecture was discovered: a contract-driven Flask app (`API_CONTRACT.md`, `BUILD_QUALITY.md`, `INTEGRATION_GUIDE.md`) with a specific, named replacement point already defined in `route_service.py`. The OSMnx approach was not the sanctioned integration path.

**A teammate (Vince) independently built a real, working implementation of the same replacement point** (`backend/app/services/route_scoring_service.py`) in parallel, unaware of this card's work. This was discovered as a genuine `git` merge conflict — twice — as both branches evolved independently before being reconciled.

## 2. The real, current architecture

```
routes.py (POST /api/routes/compare)
  → route_service.py :: compare_routes()
      → mock mode: deterministic hash-based routes (demo/frontend/QA)
      → live mode: route_service.py :: _score_live_candidates()
          → google_maps_service.py :: generate_candidate_routes()  — real Google Routes API
          → prototype_crowd_service.py :: get_crowd_payload()      — real City of Melbourne live feed
          → route_scoring_service.py :: score_candidate_routes()   — scoring logic (see below)
          → route_scoring_service.py :: recommend_route()          — picks shortest confirmed-Low route
```

Key confirmed facts:
- No microservices — everything is Python imports inside one Flask app.
- `crowd_threshold` is a single client-supplied value (`DEFAULT_CROWD_THRESHOLD = 25.0`), compared directly against raw sensor counts — not a per-sensor percentile system.
- `prototype_crowd_service.py`'s `get_crowd_payload()` is the SAME function powering the unrelated `/api/crowd` endpoint — route scoring has no separate data adapter of its own.
- Missing/stale/uncovered evidence → `"Unknown"`, never a guessed `"Low"` — enforced consistently.

## 3. The merge resolution — a genuine hybrid, not a unilateral choice

Two independent implementations of the same function existed. Resolved by keeping the best of each, not picking a side:

- **Kept from Vince's version:** the two-tier evidence hierarchy — sensors within 75m ("direct") always take exclusive precedence over sensors within 150m ("proxy"), never blended, even when the proxy reading is worse. Config-driven radii (`DIRECT_SENSOR_RADIUS_METRES`, `PROXY_SENSOR_RADIUS_METRES` in `config.py`). `recommend_route()` as a clean, separate function.
- **Kept from this side:** the Failure Handling fix — never force a route recommendation when none are confirmed Low (the original mock did this, which would have violated this card's own Failure Handling criterion).
- **Field-shape discrepancy resolved by evidence, not preference:** an earlier design assumed a different `sensor_observations` shape than what `prototype_crowd_service.py` actually outputs. Confirmed live that Vince's raw field names (`peoplePerMinute`, `latestObservation`, `freshness`, `evidence`, `operationalStatus`) are correct, since that's what the real, already-wired data source produces.

## 4. Real bugs found and fixed, each verified against live data

**Bug 1 — Transit-geometry contamination (route_scoring_service.py).**
The original scoring matched sensors against a route's single combined polyline, which includes TRANSIT segments (e.g. a train travelling underground). Live-confirmed: sensors near Docklands were matched to a route whose only actual walking was near Flinders Street, purely because the train's underground path geometrically passes near Docklands. Fixed by extracting and matching only `WALK`-mode step polylines, each kept as its own separate path (not concatenated, to avoid fake "bridging" segments between disjoint walk chunks — e.g. walk-to-station and walk-from-a-different-station). Verified against a real live multi-modal Google Routes response (train via City Loop, tram to East Coburg) — all matched sensor evidence was genuinely adjacent to the real walking portions.

**Bug 2 — Sensor-status pagination (prototype_crowd_service.py, shared with `/api/crowd`).**
`_read_active_sensor_ids()` fetched only ONE page (limit=100, no offset) of the sensor-locations dataset. Live-confirmed: exactly 100 rows returned, and 9 real, currently-reporting sensors were entirely absent from that page — wrongly treated as inactive despite having perfectly good fresh data. Fixed by paginating through the full dataset. This fix benefits both `/api/crowd` and route scoring, since they share this function.

Both fixes are covered by regression tests reproducing the exact failure conditions found live, not just the corrected behaviour.

## 5. Final live verification (this session)

- **Docker rebuild:** clean, after the full merge (including Peter's new database/ETL layer, unrelated to this card).
- **Freshness check, live:** all 65 sensors reporting `fresh` at test time — the 30-minute `FEED_FRESHNESS_MINUTES` threshold is not currently a problem in practice (worth re-checking periodically, since real feed timing can vary).
- **Real HTTP request** to `POST /api/routes/compare` (not a direct Python function call): returned multiple real routes, including genuine Google multi-modal journeys (a real Hurstbridge Line train, a real Tram 1 to East Coburg), with real sensor evidence — correct names, real counts, all `match_type: "direct"`, all genuinely adjacent to the walked portions of each route, confirming the walk-only fix holds under real conditions, not just synthetic tests.

## 6. Test coverage

**25 backend tests passing**, including:
- `test_route_scoring.py` (7): Vince's 4 original evidence-hierarchy tests (still passing, unmodified in intent) + 3 new tests for the walk-only fix, including the disjoint-segment "fake bridging" edge case.
- `test_routes.py`, `test_predictions.py`, `test_places.py`, `test_refuges.py`, `test_health.py`, `test_crowd_freshness.py` — all unaffected, still passing.

Redundant/superseded files removed: the original OSMnx-integration `backend/app/ai/route_scoring.py`, the now-unnecessary `pedestrian_adapter.py` (duplicated `prototype_crowd_service.py`, which was already the real, wired data source), and their associated test file.

## 7. Genuinely open items — not blocking, but not silently resolved either

1. **`crowd_threshold` Option A (current, live) vs Option B (per-sensor-relative)** — real product question, unresolved.
2. **`confidence: null` vs a real value** — open for the forecast card; route scoring doesn't currently expose a confidence field at all in the merged version.
3. **Message to Vince** about both fixes — should be sent if not already, so he's aware of what changed in code he originally authored.
4. **"US1.1 interface evidence"** completion-checklist item — not built, likely frontend/Qing's ownership, not fully confirmed.
5. **Freshness threshold (30 min)** — currently fine, but worth periodic re-checking given real feed timing varies.

## 8. Interface for downstream consumers

`POST /api/routes/compare` — the real, live, tested endpoint. Request/response shape confirmed directly against a real call in this session (see §5). This is also the entry point DEV-US1.2-01 (Route Comparison and Hotspot Avoidance) will build on — `recommend_route()` and the `recommendation` object already in the response may satisfy much of that card's acceptance criteria as a direct consequence of this implementation.
