# US1.1 Handoff — Crowd-Based Route Scoring

**For:** frontend team (Qing) and anyone wiring this into the backend
**From:** Ibwd (AI/ML — DEV-US1.1-01)
**Status:** Scoring logic complete and tested against real data. The API
endpoint below is a working example, not yet deployed — see §6.

**Who actually depends on this, per the project board:** not just the
US1.1 High/Low display itself. Both **DEV-US1.2-01** (route comparison
and hotspot avoidance) and, through it, **DEV-US1.3-01** (threshold and
reroute interaction) explicitly list "US1.1 crowd-based route scoring" /
"US1.1 route score" as a stated dependency. In practice, whoever builds
route comparison will call the same `/api/route-score` endpoint multiple
times — once per candidate route — rather than needing a separate
contract. This document is the shared foundation for all three, not
US1.1-only.

**Note on ownership:** this project board doesn't appear to have a
separate frontend-specific ticket for building the display UI itself —
interface work is listed as completion evidence *inside* DEV-US1.1-01
("US1.1 interface evidence") and DEV-US1.2-01 ("Hotspot display") rather
than its own card. Worth confirming with the team whether that's
intentional or whether a dedicated FE card exists outside this board
excerpt.

---

## 1. What this does, in one sentence

You give it two place names (or two coordinates), it tells you whether
that walk is currently **High**, **Low**, or **Unknown** crowd risk —
with an honest confidence level attached when it says Low, because
sometimes we only have partial data.

## 2. The three possible outcomes — design this for all three

This is the most important thing to get right on the frontend. A search
for a route can come back in three genuinely different shapes:

| Outcome | What it means | What the UI should do |
|---|---|---|
| **Resolved** | Both place names were understood, route was scored | Show the route result |
| **Needs clarification** | One or both names were typos, ambiguous, or partial (e.g. "station" matches 3 real places) | Show a "did you mean...?" picker with the suggested options |
| **Not found** | Genuinely no match for that name at all | Ask the user to try a different search term |

This is deliberate: the backend **never silently guesses** which place
you meant. If there's real ambiguity, you get a list to choose from, not
a possibly-wrong answer.

## 3. Request shape

```
GET /api/route-score?origin=<text>&destination=<text>&sensitivity=<level>
```

| Param | Required | Values |
|---|---|---|
| `origin` | yes | any typed place name, e.g. `"Flinders Street Station"`, `"the library"`, `"flin"` |
| `destination` | yes | same as above |
| `sensitivity` | no (defaults to `"default"`) | `"cautious"` \| `"default"` \| `"relaxed"` |

## 4. Response shapes — all three outcomes, real examples

**Resolved successfully:**
```json
{
  "resolved": true,
  "route": {
    "route_id": "Flinders Street Station -> State Library Victoria",
    "label": "Low",
    "confidence": "high",
    "coverage_pct": 70.4,
    "reason": "33/47 segments resolved and Low (high confidence, 70% coverage); 14 unresolved segment(s) not counted toward the label",
    "aggregation_rule": "worst_segment_wins",
    "coverage": "33/47 segments resolved",
    "scoring_version": "DEV-US1.1-01-v1.0",
    "segments": [
      {
        "segment_id": "BLOCK_123_456",
        "sensor_id": 5,
        "label": "Low",
        "reason": "observed count 13 < threshold 1774.8 (as of 2026-08-05 03:00:00)",
        "observed_count": 13.0,
        "threshold": 1774.8,
        "observation_ts": "2026-08-05T03:00:00",
        "coverage": "matched",
        "snap_m": 8.6,
        "scoring_version": "DEV-US1.1-01-v1.0"
      }
    ]
  }
}
```

**`label`** is always one of `"High"`, `"Low"`, `"Unknown"`.
**`confidence`** is `"low"`, `"medium"`, `"high"`, or `null` — it's only ever set when `label` is `"Low"`. A `"High"` result is always shown with `confidence: null`, deliberately — one confirmed crowded segment is a fact, not something that needs a confidence qualifier.

**Needs clarification** (this is a normal `200`, not an error):
```json
{
  "resolved": false,
  "problems": {
    "origin": {
      "status": "suggestions",
      "suggestions": ["Flinders Street Station"]
    }
  }
}
```
`status` is `"suggestions"` (show a picker) or `"not_found"` (ask them to retype). Only the field(s) that had a problem appear under `"problems"` — if only `destination` was wrong, `origin` won't be present at all.

**Bad request** (missing params entirely):
```json
{"error": "origin and destination query params are required"}
```
`400` status code.

## 5. Suggested UI behaviour for the "did you mean?" case

- If `suggestions` has exactly one entry, consider showing it as a soft auto-correct prompt ("Did you mean **Flinders Street Station**?") rather than a full list.
- If there are multiple entries (e.g. searching "station" returns 3 real stations), show them as a proper picker — don't auto-pick the first one.
- Re-submit the search with the chosen suggestion as the new `origin`/`destination` value — it will resolve directly on the next call.

## 6. Current deployment status — please read before wiring this up

The endpoint above is **real, working code** (`ai/models/api_route_score_example.py`), tested with Flask's test client — but it is a **reference example, not the live app**. It is **not yet wired into the actual running backend** (`backend/app/__init__.py`), unlike the forecast endpoint. Before this can be called from a real deployed app, someone (likely Ibwd, via C7) needs to:

1. Load the real graph (`get_walk_graph_cached()`), sensors, and pedestrian data once at app startup (same pattern as the forecast endpoint's model-loading).
2. Copy the `/api/route-score` route logic into `backend/app/__init__.py` alongside the existing forecast route — **not** run `api_route_score_example.py`'s `create_app()` as a second, separate Flask server.

**You can start building the frontend against this contract now** — the shapes above won't change — but the actual live URL isn't available yet. Confirm timing with Ibwd.

## 7. What routes can this actually score?

**Any walk between two real points in the Melbourne CBD** — there is no
fixed list. This was a deliberate design choice specifically so it
doesn't block on a frontend decision about search-vs-map-tap-vs-fixed-list
(see open item in the main write-up). Whatever input method you build —
a search box, a map with two tap points, or a fixed dropdown — it just
needs to produce two place names or two coordinates and call this
endpoint the same way.

## 8. Known limitations, honestly

- The place-name dictionary (nicknames like "Vic Market", "QV", "MCG") currently covers ~35 well-known CBD landmarks — not exhaustive. Real official addresses generally still work fine via the underlying geocoder even if they're not in this list.
- Typos are only caught if they're close to a *known* place name. A typo of an address not in the dictionary may not be corrected.
- `coverage_pct` and `confidence` reflect **how much of the route we actually had fresh sensor data for**, not how "long" or "short" the route is — a short route with full coverage and a long route with partial coverage can both legitimately say "high confidence."

## 9. Questions / changes

Ping directly — this contract is stable, but the underlying catchment radius (100m) and confidence-tier boundaries are still pending final team sign-off (see main write-up §7), so minor behavioural tuning (not shape changes) may still happen.