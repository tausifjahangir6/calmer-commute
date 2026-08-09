# DEV-US1.1-01 — Crowd-Based Route Scoring: Completion Evidence (v2)

**Parent:** [US1.1] Display High/Low Route Sensory Indicator
**Owner:** Ibwd
**Scoring version:** `DEV-US1.1-01-v1.0`
**Status:** Functionally complete, tested against real data. Two open items pending team sign-off (see §7).

This supersedes the original v1 write-up, which predated block merging,
catchment matching, confidence tiers, and the real-data validation work
below.

---

## 1. What this card delivers

Given two points (coordinates, or typed place names via the search
layer), produces a route-level **High / Low / Unknown** crowd
classification, with an explicit confidence tier for Low results, full
segment-by-segment explainability, and no dependency on Peter/Tausif's
not-yet-built C3 PostGIS work.

## 2. Architecture

| Stage | What it does | Key function |
|---|---|---|
| Route geometry | Real Melbourne CBD walking network from OSM, cached to disk after first fetch | `get_walk_graph_cached()` |
| Segmentation | Merges raw OSM edges into real street blocks (by shared street name) | `merge_segments_by_street_name()` |
| Sensor matching | Matches sensors to blocks within a 100m catchment radius, not just nearest-edge | `snap_sensors_to_blocks()` |
| Segment classification | High/Low/Unknown per block, using the existing US1.3-placeholder threshold system (`alert_thresholds.py`) | `classify_segment()` |
| Route aggregation | Combines segment scores into one route label + confidence | `aggregate_route()` / `score_route()` |
| Place resolution | Typed name → coordinates, with typo/nickname/partial-match handling | `place_resolver.py` |

## 3. Key design decisions (all data-backed, not guessed)

- **Segments = real street blocks**, not raw OSM node-to-node edges. Raw edges (~13,000 in the CBD graph) vastly outnumber real sensors (~100); a live run showed 31/32 segments unmatched at raw granularity. Merging into named blocks was necessary, not cosmetic.
- **Catchment radius: 100m.** Sensors are matched to any block within this radius, not just their single nearest edge. Still a documented **assumption** — radius sensitivity was tested (50m–200m) and showed a smooth, continuous relationship with no natural "correct" value, meaning this is a genuine coverage-vs-locality trade-off, not something further data alone resolves. **Flagged for team sign-off.**
- **Floor + confidence tiers, replacing the original "any Unknown segment ⇒ whole route Unknown" rule.** That original rule was tested against 50 real random CBD routes and produced Unknown for **0/50** of them — unusably strict. Replaced with:
  - `< 10%` segment coverage → still Unknown (a real, recurring case: 5/50 real routes had literally 0% coverage)
  - `≥ 10%` coverage → Low, tagged **low** (10–40%), **medium** (40–70%), or **high** (70–100%) confidence
  - **High always wins regardless of coverage** — one confirmed High segment is a directly measured fact, never coverage-discounted
  - Tier boundaries were checked for stability across 5 different random seeds; the underlying phenomenon (partial coverage is normal) held up consistently, though the *exact* cut points would benefit from a larger pooled sample if precision matters later. **Flagged for team sign-off**, since this is a real reinterpretation of the card's original Data Integrity wording.
- **Threshold basis reused from `alert_thresholds.py`** (the AI-US2.2-01 US1.3 placeholder), including the cautious/default/relaxed sensitivity multiplier — verified end-to-end against real data (§5).

## 4. Real bugs found and fixed during validation

Listed because each was only caught by testing against real data, not by code review:

1. **Units bug**: sensor-snap distances were silently measured in lat/lon degrees, not metres, making the "reliable snap" check always pass regardless of true distance.
2. **Explanation-accuracy regression**: a fix to one issue accidentally caused "too far" segments to report a generic "no sensor" reason instead of the real, more informative distance-based one — caught by comparing two live runs.
3. **`get_latest_observation` future-row bug**: silently assumed the data handed to it never contained rows after `reference_time`. True in every live run (which always used the dataset's own latest timestamp), but broke the moment historical backtesting needed an earlier reference time.
4. **`join_sensor_mapping` crash**: didn't handle multiple real sensors snapping to the same block; fixed to keep the closer one.
5. **`sensor_id` dtype coercion**: pandas silently converts an int+None column to float+NaN; a `NaN`-vs-`None` check gap was found and hardened before it caused a real failure.

## 5. Real-data validation performed

- **Column names verified** against the real `load_validated_data.py` output (`sensor_id`, `timestamp`, `count`), not assumed.
- **Full temporal sweep**: every one of **17,332 real hours** (the entire ~2-year dataset) checked for 5 real routes — not a sample. Confirmed High genuinely triggers at real, sensible moments (morning commute peak, sustained midday-evening crowding), and confirmed routes move together (0.40–0.92 correlation), consistent with a real shared citywide crowd pattern rather than noise.
- **Sensor gap diagnostic**: confirmed real multi-hour sensor gaps exist (79/100 sensors, 13,172 gap-events over 2 years) but never drag any tested route below the 10% floor, because each route has enough redundant sensors that gaps rarely overlap.
- **Sensitivity multiplier**: tested across 21 real historical moments — cautious ≥ default ≥ relaxed in High-count, confirmed correctly ordered, with 8/21 moments showing a real label change depending on sensitivity.
- **Search-by-name / typo handling**: stress-tested against 18 realistic queries (official names, ambiguous short names, colloquial nicknames, misspellings, nonsense/empty input) — see `place_resolver.py` and its test suite.

## 6. Test coverage

**72 automated tests**, spanning:
- Segment classification (normal, boundary, missing, stale, insufficient-data)
- Route aggregation (floor, all three confidence tiers, boundary values, High-always-wins)
- Block merging and catchment matching (offline, synthetic graphs)
- Place name resolution (exact, alias, substring/autocomplete, typo, nonsense)
- Graph caching (offline, mocked fetch)
- 5 integration tests against the real live OSM graph

All passing as of this write-up.

## 7. Open items — genuinely require a decision, not more code

1. **100m catchment radius** — defensible, tested, but not provably "correct." Needs team sign-off.
2. **Floor (10%) + confidence-tier boundaries (10/40/70)** — data-backed but a real reinterpretation of the original "never unsupported Low" wording. Needs explicit team confirmation this is the intended design, not just a de facto shipped change.
3. **Which real routes the app offers** — a product decision (fixed list vs. map-tap vs. search-by-name), not resolved by this card. See `US1.1_HANDOFF.md` for how the scoring component supports any of these approaches without further backend changes.

## 8. Interface for downstream consumers

See `US1.1_HANDOFF.md` for the full frontend/API integration contract, request/response shapes, and example code.
