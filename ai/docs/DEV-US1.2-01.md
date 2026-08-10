# DEV-US1.2-01 — Route Comparison and Hotspot Avoidance: Completion Evidence

**Parent:** [US1.2] Avoid Highly Congested Pedestrian Corridors
**Owner:** Ibwd
**Status:** Backend logic complete and live-verified. Frontend explainability ownership unconfirmed (see §6).

This documents what was found, fixed, and verified while closing out DEV-US1.2-01 — including one real, previously-undetected bug in shared infrastructure that was silently blocking every live acceptance-criteria test until fixed.

---

## 1. Starting position

DEV-US1.2-01's own context notes (written at the start of this review) predicted that `_score_live_candidates()` in `route_service.py` — built as a byproduct of DEV-US1.1-01 — might already satisfy most of this card's acceptance criteria without new code. That prediction held. The real work in this pass was verification, one real bug fix, and closing gaps in test coverage and trade-off reporting — not new scoring logic.

## 2. Real bug found and fixed: per-sensor freshness

**Discovery.** Live-testing via a standalone `check_freshness.py` script against `/api/crowd` showed `dataStatus: "unavailable"` with all 65 sensors reporting `"stale"`, despite the freshest sensor being only 23–42 minutes old — inside the real feed's known 34–38 minute publish lag.

**Root cause, in `prototype_crowd_service.py`:**
- `FEED_FRESHNESS_MINUTES = 30` was too tight for the real feed's observed lag.
- Independently, `_read_map_sensors()` computed ONE global `feed_fresh` boolean from the feed's single newest reading across all 65 sensors, then applied that one verdict to every sensor. A sensor whose own last reading was 90+ minutes old could still be labelled `"fresh"` if any other sensor had reported recently — confirmed live: sensor 11 showed `age: 90.3 min` but `freshness: "fresh"` before the fix.
- A second, independent hardcoded `<= 30` existed in `get_crowd_payload()`'s top-level status line, not reading the constant at all — meant a partial fix to one location would not have moved the other.

**Fix applied** (`backend/app/services/prototype_crowd_service.py`):
- `FEED_FRESHNESS_MINUTES` widened to `60`, with margin above the observed 34–38 min lag.
- Top-level status line now reads `FEED_FRESHNESS_MINUTES` instead of a second hardcoded `30`.
- New `_sensor_is_fresh(latest_observation)` helper gates each sensor's freshness against **its own** latest observation, replacing the single global `feed_fresh` boolean.
- Removed a fallback (`latest_observation or feed_latest`) that let a sensor with zero rows of its own borrow the feed's global timestamp to appear fresher than it was.

**Independent confirmation.** `database/migrations/15_realtime_interval_audit.sql`, query 6 ("STALENESS SPREAD"), computes per-sensor age directly from raw Postgres data and was written specifically to answer "if readings span 30 minutes, the live map is not a single moment in time." This audit — built independently by the data team — anticipated the same class of bug, from a completely separate code path, before this review found it live in the Python service.

**Test evidence:**
- `test_crowd_freshness.py`'s existing boundary test updated from 31→61 minutes to match the new threshold.
- New regression test `test_per_sensor_freshness_is_independent_of_other_sensors` added: plants one sensor at 20 min old and one at 90 min old in the same batch, asserts they resolve to different `freshness` values. This test would have failed against the pre-fix code and is the first automated guard against this specific bug class recurring.
- Full backend suite: **26/26 passing** post-fix (was 24/25 with one pre-existing-but-now-outdated assertion, before the test update).

## 3. Acceptance criteria — evidence

| Criterion | Status | Evidence |
|---|---|---|
| **Route Comparison** (≥2 routes) | ✅ Met | Live `POST /api/routes/compare` returned 6 real Google-routed alternatives in a single response, `metadata.data_mode: "mixed"` confirming live mode. |
| **Hotspot Identification** | ✅ Met | Live call at `crowd_threshold: 0.5`: routes 1–4 resolved `sensory_level: "High"` with populated `hotspot` (sensor 84, Elizabeth St–Flinders St East, count 1, `exceeds_threshold_by: 0.5`, `freshness: "fresh"`). Also unit-tested (`test_maximum_direct_count_sets_high_and_hotspot`). |
| **Recommendation** | ✅ Met | Same live call: `recommendation.route_id: "route-5"` — correctly the shortest route *among the Low-classified routes*, not shortest overall, despite High routes being present in the same response. `recommend_route()` unit-tested (`test_recommendation_is_shortest_supported_low_and_never_unknown`). |
| **Explainability** (backend) | ✅ Met | `hotspot` object present with sensor name, count, distance, and threshold-exceedance on every High route. |
| **Explainability** (interface) | ⚠️ Unconfirmed | Backend data is fully available; whether the frontend renders it is outstanding, likely Qing's ownership — carried over unresolved from DEV-US1.1-01's own completion notes. |
| **Trade-off** | ⚠️ Partial | `trade_off` string present and correct for duration (e.g. "0 additional minutes compared with the fastest route"), live-confirmed. Distance is not currently included, despite `distance_metres` already existing on every route at no extra cost. Recommended as a small follow-up, not yet implemented. |
| **Data Integrity** | ✅ Met | `recommend_route()` only ever selects from routes confirmed `"Low"`; Unknown/High routes are structurally excluded from consideration, both in code and unit-tested. |
| **Failure Handling** | ✅ Met (unit-tested, not live-reproduced) | `_score_live_candidates()`'s `else` branch returns `route_id: null`, `lower_crowd_alternative_available: false` with an honest reason string when `recommend_route()` returns `None`. Exercised directly in mock mode by `test_high_route_exposes_hotspot_evidence` (`crowd_threshold: 1` → all routes High → recommendation is null). Live reproduction of this exact branch was attempted but not achieved in this session, since every live test window had at least one sensor reading low enough to keep a Low route available — the code path is identical between mock and live, so the mock-mode test is treated as sufficient evidence for this criterion. |
| **Testing** (High/Low/Unknown/incomplete/no-alternative) | ✅ Met | High and Low both confirmed live (see rows above) in addition to existing unit coverage. Unknown was live-confirmed prior to the freshness fix (every route resolved Unknown when the bug was active) and remains unit-tested post-fix (`test_stale_inactive_and_outside_150m_are_unknown`). No-alternative confirmed via the mock-mode test noted above. |
| **Traceability** | ✅ Met by this document | This writeup. |

## 4. Known, deliberately-unresolved gaps

1. **Distance trade-off** not yet surfaced alongside duration — small addition, not done in this pass.
2. **Interface-side explainability** — backend-complete, frontend status unconfirmed.
3. **Live reproduction of Failure Handling** — relied on existing mock-mode test rather than forcing a live all-High scenario, since live pedestrian counts at test time made this impractical to reproduce on demand (see §3).

## 5. Related, not blocking this card

**AI-US2.2-01** (next-hour forecast) was separately reviewed against `AI_Team_Route_Scoring_Expectations.docx` and found to have two real gaps against that handoff spec (missing explicit forecast-target timestamp, missing Medium crowd tier despite `database/schema/01_schema.sql`'s `density_band` already defining one). Both were fixed, tested, and pushed (`c46c9d5`, `df885eb`) as part of AI-US2.2-01, not this card — noted here only because it surfaced during this review.

## 6. Database layer — status, for context

`database/` (schema, migrations, seeds, a `serving` layer) is fully built but **not currently wired into the live request path** — no `db` service exists in `compose.yaml`, and nothing in `routes.py`/`route_service.py`/`prototype_crowd_service.py` queries Postgres. Two migration files (`14_sensor_coverage_audit.sql`, `15_realtime_interval_audit.sql`) are diagnostic audit scripts, not schema — the latter directly informed the freshness fix in §2. Connecting the database is a real, larger architecture decision (see `serving.v_current_density`, which already computes per-row freshness correctly) — out of scope for this card, flagged for a future team decision rather than acted on unilaterally here.