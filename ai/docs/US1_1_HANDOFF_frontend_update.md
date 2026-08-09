# US1.1/US1.2 Handoff Update — New Sensor Evidence States

**For:** frontend team (Qing) and anyone consuming `/api/crowd` or `/api/routes/compare`
**From:** Ibwd (AI/ML)
**Status:** LIVE-VERIFIED. This is an addendum to the existing `US1.1_HANDOFF.md` — everything there still holds. This document only covers what's NEW: two additional evidence states that didn't exist before, both real and both tested against the live City of Melbourne feed tonight.

---

## 1. Why this exists

The live feed has real reporting gaps — a sensor can simply not report for a stretch of time, for entirely normal reasons (it isn't broken, it just hasn't phoned in yet). The system used to treat "no data in the last few minutes" the same as "confirmed zero people," which is dishonest — silence isn't evidence of an empty street.

Two new states now handle this honestly: one that gives a real, evidence-backed estimate when reasonable, and one that plainly says "we don't know" when there isn't enough to go on.

## 2. The two new values

### `"freshness": "estimated"`, `"evidence": "hourly-estimate"`

**What it means:** this sensor has a genuine live reporting gap. Instead of guessing zero, the system looked at this sensor's own history — the same hour of day, the same day of the week, over the last 4 weeks — and used that average, but ONLY because those 4 samples reasonably agreed with each other.

**How to treat it:** as real, usable evidence — it already flows into route scoring exactly like a live reading (High/Low classification, hotspot detection, all of it). But it is not a live measurement. **Show it differently from a live reading in the UI** — e.g. a small "estimated from recent history" label or icon distinct from a live dot/pulse indicator. Don't present it as "currently observed."

**Live example, captured tonight:**
```json
{
  "id": 11,
  "peoplePerMinute": 0,
  "latestObservation": "2026-08-09T16:20:00+00:00",
  "freshness": "estimated",
  "evidence": "hourly-estimate",
  "operationalStatus": "active"
}
```
This sensor's own last real reading was 74 minutes old — too old to treat as live — but its typical pattern at this hour was consistently near-zero across the last 4 weeks, so the estimate is trustworthy enough to use.

### `"freshness": "unavailable"` or `"stale"`, `"evidence": "insufficient-history"`

**What it means:** this sensor has a gap AND there isn't enough reliable history to estimate from either — either too few historical samples exist, or the samples that do exist disagree with each other too much to trust an average.

**How to treat it:** as `Unknown` — `peoplePerMinute` will be `null`. Do not display a number. Show the existing "insufficient data" / limitation messaging already used for `Unknown` classifications elsewhere.

**Live example, captured tonight:**
```json
{
  "id": 39,
  "peoplePerMinute": null,
  "latestObservation": "2026-08-09T16:17:00+00:00",
  "freshness": "stale",
  "evidence": "insufficient-history",
  "operationalStatus": "active"
}
```

### `"evidence": "sensor-inactive-suspected"` (defined, not yet seen live)

**What it means:** a sensor has read zero at every one of 168 checkpoints (6 times a day, spread across quiet hours and both commute peaks, over 4 weeks) — a pattern more consistent with a dead or removed sensor than a genuinely always-empty one. This is a backup signal alongside the existing active/inactive sensor status field, in case that field is out of date.

**How to treat it:** same as `Unknown` — `peoplePerMinute` will be `null`. This did not occur in tonight's live test (no sensor tripped it), so treat it as a rare, defensive case rather than something you'll see often.

## 3. What did NOT change

- Every existing field, value, and meaning from `US1_1_HANDOFF.md` is unchanged. `"observed"`, `"fresh"`, `"proxy"`, `"direct"`, `hotspot`, `recommendation` — all identical to before.
- `sensor_evidence` inside `/api/routes/compare` route objects already carries the same `freshness`/`evidence` fields per sensor — the two new values will appear there too, not just in `/api/crowd`'s `mapSensors`.

## 4. Live confirmation, tonight's actual numbers

Out of 65 sensors in one real request: 30 were live (`observed`), 30 fell back to a reliable estimate (`estimated`), 5 correctly had no usable answer (`insufficient-history`, `null`). All 65 were accounted for — nothing silently disappeared or crashed.

## 5. Suggested UI treatment (not prescriptive — your call on exact design)

| State | Suggested treatment |
|---|---|
| `observed` / `fresh` | Live indicator (e.g. solid dot, "just now") |
| `estimated` / `hourly-estimate` | Distinct from live — e.g. outlined dot, "typical for this time" |
| `null` + `insufficient-history` or `sensor-inactive-suspected` | Same as existing Unknown treatment — no number shown, existing limitation copy |

## 6. Questions worth raising back to AI/ML if anything looks off

- If `estimated` values look implausible for the actual time of day, flag it — the underlying consistency check may need tuning.
- If `sensor-inactive-suspected` starts appearing regularly for sensors you know are fine, that's worth a look too — it's meant to be rare.
