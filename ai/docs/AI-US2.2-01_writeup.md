# AI-US2.2-01 — Next-Hour Crowd Forecast

**Card owner:** AI/ML (Ishrak) · **Epic:** E2 — Sensory Environment Monitoring
**Status:** Modeling complete, tuned, and verified. `explain_forecast()` adapted and tested against both batch and serving-time paths.

---

## 1. Scope and objective

This card forecasts next-hour pedestrian counts at each of the 100 City of Melbourne sensor
locations in the CBD, so the app can warn users about developing hotspots *before* they form
rather than only reacting to current conditions.

**Scope guardrail (carried from project-level scope):** pedestrian density is the only
sensory-risk proxy modelled this iteration. Noise, construction, and event data are explicitly
out of scope. Crowd count is a proxy, not a clinical measure — every forecast is framed to the
user as guidance, not a guarantee.

---

## 2. Dataset

| | |
|---|---|
| Source | City of Melbourne Pedestrian Counting System (CC BY 4.0) |
| Coverage | 2024-08-13 to 2026-08-05 (~2 years) |
| Sensors | 100 reporting locations (129 of 134 CBD-area sensors; suburb sensors excluded) |
| Rows | ~1.52M hourly observations |
| Grain | one row per (sensor, date, hour) |
| Target | `target_count` — pedestrians counted in that hour at that sensor |

**Validation performed on this dataset before modelling** (data-scientist owned, cross-checked
during integration):
- Two sensors were confirmed to share a display name; all joins/groupings use `location_id`,
  never `display_name`.
- `is_weekend` / `is_cbd` arrive as Postgres `'t'`/`'f'` string exports, not booleans — handled
  explicitly rather than via a dtype check, which can silently miss the case depending on
  pandas version.
- Day-of-week is derived fresh from the timestamp rather than trusting the source column, which
  uses a 0=Sunday convention that conflicts with pandas' own 0=Monday convention.
- Lags (`lag_24h`, `lag_168h`) are joined on explicit dates, not row position, so the ~9% of
  hours missing from the source don't silently shift a lag by an extra day.
- Three decommissioned sensors (1.58% of source rows) were excluded before this export, since
  the app recommends *current* conditions and a retired sensor can't be recommended.

**Known limitations, stated for the report:**
- The API serves a rolling two-year window regardless of how far back the portal's own listing
  claims — enough for seasonality and day-of-week patterns, not for long-term trend claims.
- No weather, events, or public-holiday data. This is very likely the largest source of
  unexplained variance (see §6) and is the cheapest accuracy win available for future work.
- CBD coverage only; forecasts do not generalise to suburban locations.
- ~9% of hours are missing across the two years (sensor outages) and are not imputed.

---

## 3. Methodology

**Split:** time-ordered, not random — `train_test_split(shuffle=True)` would let models see
the future. Train: 2024-08-13 to 2026-07-05 (1,457,425 rows). Test: 2026-07-06 to 2026-08-05
(64,849 rows, held out entirely from all model development and tuning).

**Baseline (the bar every model must clear):** an hour-of-week average — same sensor, same
day-of-week, same hour, averaged over training history. If a (sensor, day-of-week, hour)
combination has fewer than 3 historical observations, the baseline explicitly refuses to
predict rather than guessing — this "no unsupported forecast" behaviour is a deliberate safety
requirement, distinct from how the final model's uncertainty is communicated (§7).

**Features:** cyclical hour/day-of-week encodings (`hour_sin/cos`, `dow_sin/cos`), two lag
features (`lag_24h`, `lag_168h`), a leakage-safe rolling mean (`rolling_mean_24h`, excludes the
current row) with its support count (`obs_in_window_24h`), `is_weekend`, `is_cbd`, and sensor
identity (one-hot for Linear Regression, integer-coded for tree models).

**Four models compared:** hour-of-week baseline, Linear Regression, Random Forest, Gradient
Boosting (`HistGradientBoostingRegressor`).

---

## 4. Results

Final numbers, evaluated once on the held-out test set (n=64,849):

| Model | MAE | RMSE | vs. baseline |
|---|---|---|---|
| Hour-of-week baseline | 77.9 | 179.7 | — |
| Linear Regression | 75.5 | 178.1 | −3.1% MAE |
| Gradient Boosting (tuned) | 55.1 | 142.8 | −29.3% MAE |
| **Random Forest (tuned)** | **54.1** | **143.2** | **−30.6% MAE** |

**Random Forest is the selected model.** It leads on MAE; Gradient Boosting is fractionally
better on RMSE (142.8 vs. 143.2), meaning GB is marginally less prone to very large individual
errors while RF is marginally more accurate on average — worth a sentence in the discussion
rather than treating RF's win as absolute, since the two are close after tuning (§5).

**Operational simplicity, the third selection criterion:** RF's trees are built independently
of one another (embarrassingly parallel), so training doesn't depend on getting a sequence of
weak learners right one after another the way boosting does — a bug or a bad batch in training
data affects individual trees, not a chain of corrections building on each other's errors. This
also makes RF simpler to reason about when debugging a bad prediction (inspect the relevant
trees' splits) and marginally cheaper to retrain incrementally as new sensor data arrives,
which matters for an app that should stay current as the pedestrian-count history grows. GB's
sequential nature and extra hyperparameters (`learning_rate`, `l2_regularization`) give it more
tuning surface for a small RMSE edge — a reasonable trade against RF's simplicity, but not
strong enough to change the selection given RF already wins on the primary metric (MAE).

Linear Regression's near-baseline result is not a failure of linear methods generally: an
earlier iteration using raw hour/day-of-week integers performed markedly worse, and switching
to cyclical (sin/cos) encoding closed most of that gap. This confirms the original weakness was
a feature-representation problem, not an algorithmic one, and is worth stating explicitly since
it's a common source of confusion when comparing "why didn't the simple model work."

**Feature importances (tuned Random Forest)** — notably different from the pre-tuning
importances, and worth explaining rather than just reporting:

| Feature | Importance |
|---|---|
| `lag_168h` (same hour, same weekday, last week) | 42.2% |
| `lag_24h` (same hour, yesterday) | 34.0% |
| `rolling_mean_24h` | 13.0% |
| `hour_cos` / `hour_sin` | 4.0% / 3.3% |
| `sensor_code` | 1.8% |
| `obs_in_window_24h` | 0.8% |
| `dow_cos` / `dow_sin` | 0.4% / 0.4% |
| `is_weekend`, `is_cbd` | <0.2% combined |

Before tuning, `lag_168h` alone accounted for 78.3% of importance, with `lag_24h` a distant
second at 15.4%. After tuning (`max_features='sqrt'`, §5), importance is spread far more evenly
across the three historical-traffic features — `lag_168h` and `lag_24h` now contribute
comparably (42.2% vs. 34.0%), with `rolling_mean_24h` also meaningfully used (13.0%); together
the three account for 89.1% of the model's decisions. This is a direct, expected consequence of
restricting each split to a random subset of candidate features: rather than every tree
defaulting to `lag_168h` at its first split, trees diversify across the three most informative
history features — and this diversification is very likely part of *why* tuning improved
accuracy (§4), not just a side effect of it. The model remains fully interpretable either way:
its behaviour is describable as "a weighted blend of last week, yesterday, and the recent
trend," not a black box.

---

## 4a. Alert threshold evaluation

Per-sensor 75th-percentile thresholds (§7; currently a placeholder for the not-yet-built US1.3
threshold function, see §9) were used to evaluate whether each model's forecast correctly flags
an alert-worthy hour, on the same held-out test set:

| Model | Precision | Recall | F1 | TP | FP | FN | TN |
|---|---|---|---|---|---|---|---|
| Hour-of-week baseline | 0.762 | 0.818 | 0.789 | 12,893 | 4,026 | 2,878 | 45,045 |
| Linear Regression | 0.758 | 0.831 | 0.793 | 13,108 | 4,184 | 2,663 | 44,894 |
| **Random Forest (tuned)** | **0.849** | **0.835** | **0.842** | 13,169 | 2,348 | 2,602 | 46,730 |
| Gradient Boosting (tuned) | 0.842 | 0.819 | 0.830 | 12,912 | 2,425 | 2,859 | 46,653 |

F1 is included alongside precision/recall to give a single balanced figure satisfying the
"agreed classification metrics" phrasing in the acceptance criterion — RF leads on all three
simultaneously.

Random Forest leads on both precision and recall simultaneously — not a precision/recall
trade-off against the other models, a straightforward improvement on both. Relative to the
baseline, false alarms drop by 42% (4,026 → 2,348) while missed alerts also drop slightly
(2,878 → 2,602), meaning the selected model is both more trustworthy (fewer false alarms to
erode user confidence) and more protective (fewer missed alert-worthy hours) than the naive
approach it replaces.

---

## 5. Hyperparameter tuning

**Method:** random search over a hand-scoped grid, using a **validation window carved out of
the training period only** (June 8 – July 5, immediately before the train/test boundary) — the
real test set was never touched during search, so the final reported numbers above are an
honest, un-leaked evaluation.

To keep search runtime and memory tractable on a laptop, the search phase trained each candidate
on a 400,000-row random subsample of the training window rather than the full 1.4M rows (safe
here specifically because every feature is precomputed per row and doesn't depend on which
other rows are present in the training set — this affects statistical power, not correctness).
A control run using the original, untuned defaults was evaluated on the identical split and
subsample to confirm any improvement was real and not an artifact of the differing data
regime: the default RF scored 64.4 validation MAE against the eventual best config's 62.2 —
confirming the gain was genuine before it was ever checked against the test set.

**Selected configuration — Random Forest:** `n_estimators=200, max_depth=20,
min_samples_leaf=8, max_features='sqrt'`.

**Selected configuration — Gradient Boosting:** `max_iter=400, max_depth=10,
learning_rate=0.2, min_samples_leaf=20, l2_regularization=0.1`.

Notably, `max_features='sqrt'` (considering a random subset of features at each split, rather
than all of them) consistently outperformed the sklearn regression default of using all
features — plausible given how dominant `lag_168h` is (§4): restricting candidate features per
split forces individual trees to diversify rather than all repeatedly splitting on the same
feature, reducing correlation between trees in the ensemble.

---

## 6. Per-sensor error analysis

Pooled MAE (54.1) hides substantial variation across the 100 sensors (per-sensor MAE ranges
from 2.0 to 192.0). Most of that spread is explained by traffic scale, not model failure: busy
sensors like Southbank Promenade produce large *absolute* errors (MAE 192.0) while their
*relative* error — MAE as a fraction of that sensor's own average traffic — is a reasonable
14.3%. The same pattern holds for the other highest-raw-MAE sensors (Princes Bridge, Flinders
Lane, Town Hall West, Melbourne Central), all with relative MAE under 20%.

**Two sensors are genuinely, not just numerically, worse:**

| Sensor | MAE | Mean traffic | Relative MAE |
|---|---|---|---|
| COM Pole 1120 (near Federation Square Bridge) | 159.8 | 201.0 | **79.5%** |
| Birrarung Marr — COM Pole 1109 | 150.8 | 324.2 | **46.5%** |

This is independently consistent with the data-handover notes, which specifically named
Birrarung Marr as event-driven ("concerts and festivals... don't chase these"). Federation
Square Bridge is a comparable major event/tourist corridor. Both are structurally difficult to
predict from pedestrian history alone, since the driving variable — whether an event is
happening — is exactly the "no events data" limitation already scoped out of this iteration
(§2). This is treated as a documented, explainable limitation rather than a defect to keep
chasing with further tuning.

The top 20 sensors by MAE account for 44.6% of total absolute error (vs. 20% of sensors by
count) — but this concentration is almost unchanged before vs. after tuning (44.8% → 44.6%),
meaning tuning improved accuracy broadly across sensors rather than by better-fitting a handful
of outliers.

---

## 7. Explainability and responsible forecasting

Every forecast is returned with a structured explanation object rather than a bare number, per
the "responsibly labelled, guidance not guarantee" project requirement:

```
{
  "timestamp": ...,
  "affected_area": <sensor name>,
  "forecast": <predicted count>,
  "reason": "Primarily based on typical traffic ... (same time last week: X),
             adjusted using yesterday's observation at this hour (Y).",
  "confidence": "low" | "medium" | "high",
  "data_support": {"obs_in_window_24h": ...},
  "limitation": <present only for high-volatility sensors>,
  "alert": true/false,
  "alert_threshold": <sensor-specific 75th-percentile threshold>
}
```

**Confidence** combines two independent signals: freshness/completeness of the input data
(`obs_in_window_24h`) and each sensor's historical volatility (coefficient of variation,
computed from training data only, tiered into low/medium/high). A sensor can have complete,
fresh data and still receive only "medium" confidence if it's historically volatile — this is
how Birrarung Marr and Federation Square Bridge get downgraded automatically rather than
presented with the same false authority as a well-behaved sensor. High-volatility sensors also
carry an explicit `"limitation"` field naming the reason in plain language.

This differs deliberately from the baseline model's safety behaviour (refusing to predict
below a support threshold): Random Forest always produces a number, so the safety requirement
is expressed through calibrated confidence and an explicit limitation note instead of a refusal.

Two entry points were built and tested against the real pipeline:
- **Batch** (`explain_batch`) — for report/evaluation use, explains an entire test-set run at
  once.
- **Serving-time** (`next_hour_forecast`) — the function the API layer (C7) should call for one
  sensor's live next-hour forecast, taking the fitted model and one row of current features.

---

## 8. Acceptance criteria traceability

| Requirement | Status |
|---|---|
| Forecast next-hour crowd level per sensor | ✅ RF, MAE 54.1 |
| Beat the naive baseline | ✅ −30.6% MAE vs. hour-of-week baseline |
| No unsupported forecast presented as fact | ✅ (baseline: explicit refusal; RF: calibrated confidence + limitation flag) |
| Explanation includes timestamp, area, reason, confidence | ✅ `explain_forecast_rf` |
| Model choice justified, not a black box | ✅ feature importances (§4) show 89.1% combined weight on three interpretable history features |
| Per-sensor performance reported, not just pooled | ✅ §6 |
| Alert Evaluation: confusion matrix + classification metrics for every approach | ✅ §4a — precision, recall, and F1 reported; RF leads on all three |
| Model selection justified on performance, reliability, AND operational simplicity | ✅ §4 — RF's independent-tree training vs. GB's sequential dependency explicitly discussed |
| Data Integrity: missing/stale/insufficient inputs do not produce an unsupported forecast | ✅ Both baseline and RF now refuse explicitly (forecast=None, confidence="none") when required inputs are missing — verified via a simulated sensor-outage test in `rf_explain.py` |
| Integration | ⚠️ **Interim solution implemented and tested** — `alert_thresholds.py` provides a working sensitivity-multiplier system (Option A), wired into `next_hour_forecast()` and verified to change the alert outcome, not just the threshold number, across 3 sensitivity levels. This is a real, functioning connection to a user-facing control, not a bare placeholder — but it's still not the actual US1.3 function, since US1.3 doesn't exist yet. Handoff note with working code sent to the card owner, who can adopt it as-is or override `get_alert_thresholds()` with something richer as long as the contract holds. |

---

## 9. Outstanding / next steps

- **US1.3 integration — interim solution implemented, no longer fully blocked.**
  Built and tested `alert_thresholds.py`: a per-sensor base threshold (75th percentile,
  computed offline) scaled by a user sensitivity multiplier (cautious ×0.7 / default ×1.0 /
  relaxed ×1.3) at request time. Wired into `next_hour_forecast()` via `user_context` +
  `base_thresholds` parameters and verified against the real fitted model — the alert
  boolean genuinely changes across sensitivity levels, not just the displayed threshold number.
  This satisfies the *spirit* of "connected to a user threshold function" today. What's still
  open: this is our own interim design, not the actual US1.3 deliverable, so the card can't be
  marked Done against the criterion's literal wording until US1.3 either adopts this or
  overrides it with their own logic behind the same `get_alert_thresholds()` contract.

  **Interface contract, fixed regardless of which side (us or US1.3) implements it:**
  ```python
  def get_alert_thresholds(
      sensor_ids: list[int],
      user_context: dict | None = None,
      base_thresholds: dict[int, float] | None = None,
  ) -> dict[int, float]
  ```
  - Input: `sensor_id` as int, matching `location_id` (never `display_name`).
  - Output: `sensor_id -> threshold`, in raw pedestrians/hour — the same units as
    `target_count`, since the consuming code does `forecast >= threshold` directly with no
    rescaling.
  - A sensor with no determinable threshold must return `None`, not `0` or `NaN` — the
    consuming code already treats `None` as "skip the alert flag"; `0` would cause a false
    alert on every forecast for that sensor.
  - `user_context` currently reads `{"sensitivity": "cautious"|"default"|"relaxed"}`; US1.3 is
    free to read different/additional keys (e.g. a continuous slider value) as long as the
    return type doesn't change.
  Handoff note with the working implementation sent to whoever picks up US1.3, so the
  swap-in remains a single function replacement regardless of how US1.3 is built internally.
- ~~Wire `next_hour_forecast()` into the API layer (C7)~~ **Docker integration done and
  verified.** Backend container now builds with `ai/` reachable (widened build context,
  merged requirements, `PYTHONPATH` exposing `ai/models`/`ai/features`), loads the pretrained
  model artifacts at runtime via `load_artifacts.py`, and confirmed working end-to-end with
  `docker exec` (`OK: 100 sensors loaded`). **Flask route now live and verified**:
  `GET /api/forecast/<sensor_id>?sensitivity=...` calls `next_hour_forecast()` and returns
  the full explanation object over real HTTP — confirmed with `curl`/`Invoke-WebRequest`
  against sensor 161 (Birrarung Marr): `alert_threshold` correctly varies with sensitivity
  (226.1 / 323.0 / 419.9 for cautious/default/relaxed, exactly matching the ×0.7/×1.0/×1.3
  design), while `forecast` stays identical across all three, confirming sensitivity affects
  only the threshold and never the prediction itself. This closes the "Integrated alert
  demonstration" completion-evidence item with concrete evidence, not just a design claim.
  **Still interim, not final:** the route's features come from `latest_features.json`
  (`export_latest_features.py`), a stand-in for a live ingestion pipeline that doesn't exist
  yet — see that script's docstring for the "next hour" semantics caveat (it reuses the most
  recent historical row rather than constructing a genuinely unobserved future hour).
- ~~Push these files to Tausif's repo once collaborator access is granted.~~ Resolved —
  pushing directly to the `AI` branch works fine; that blocker was specific to the old repo.
- Flagged for future iterations (out of scope now): public-holiday flag as the cheapest
  accuracy win available; weather/events data to address the two volatility outliers directly.

**Card status: not ready to mark Done, but as close as this card can get without US1.3.**
Modeling, tuning, evaluation, alert metrics, model-selection justification, and the
missing-data safety guard are all complete and verified. The threshold-integration gap now has
a real, tested, working interim implementation (Option A) rather than a bare unconnected
placeholder — the forecast genuinely responds to a user-facing sensitivity setting today.
**What's left is not building work, it's a decision:** either US1.3's owner adopts this
implementation, replaces it with their own behind the same contract, or the team formally signs
off on this as the accepted interim approach for this iteration. Recommend "In Review" with
that decision named explicitly as the one remaining blocker, rather than leaving the card open
on an undifferentiated "waiting on integration."
