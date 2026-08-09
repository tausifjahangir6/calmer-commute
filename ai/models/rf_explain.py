"""
rf_explain.py
Adapts baseline_model.py's explain_forecast() to:
  (a) the validated-data pipeline shape -- target_count is already the
      value for the row's own hour, so the forecast timestamp is just
      row["timestamp"], with no shift(-1)/target_timestamp needed (that
      was the old raw-API pipeline shape; dead in this pipeline), and
  (b) Random Forest's predictions specifically -- reason text cites the
      features RF actually leans on (lag_168h 78%, lag_24h 15%, per the
      feature-importance output), and confidence factors in each sensor's
      historical volatility, not just data freshness.

WHY VOLATILITY MATTERS HERE (from per_sensor_mae.py findings):
Two sensors -- Birrarung Marr (COM Pole 1109) and Federation Square
Bridge (COM Pole 1120) -- have relative MAE of 0.47 and 0.83 despite
moderate traffic, consistent with Peter's handover note that Birrarung
Marr is event-driven ("concerts and festivals... don't chase these").
A forecast for these sensors with normal-looking obs_in_window_24h would
otherwise get the same "medium/high confidence" label as a well-behaved
sensor like Flinders Lane, which is misleading. Volatility is computed
from TRAINING data only, so it's not test-set leakage, and it's a
per-sensor constant (not row-dependent), so it can be precomputed once
and reused across every forecast for that sensor.
"""

from __future__ import annotations
import numpy as np
import pandas as pd


def calc_sensor_volatility(train_df: pd.DataFrame, count_col: str = "count") -> pd.DataFrame:
    """
    Coefficient of variation (std/mean) per sensor, computed on TRAINING
    data only. High CV = traffic swings a lot relative to its own average
    (event-driven), independent of how busy the sensor is overall -- which
    is exactly why relative MAE (not raw MAE) was the useful lens earlier.

    Returns a DataFrame indexed by sensor_id with columns: cv, volatility_tier.
    Tiering uses quartiles of CV across sensors: top quartile -> "high",
    next -> "medium", rest -> "low". Thresholds are data-driven (recomputed
    from whatever training set is passed in), not hardcoded, so they stay
    valid if the sensor roster or data window changes.
    """
    stats = train_df.groupby("sensor_id")[count_col].agg(["mean", "std"])
    stats["cv"] = stats["std"] / stats["mean"].clip(lower=1.0)

    q_hi = stats["cv"].quantile(0.75)
    q_mid = stats["cv"].quantile(0.50)

    def tier(cv):
        if cv >= q_hi:
            return "high"
        if cv >= q_mid:
            return "medium"
        return "low"

    stats["volatility_tier"] = stats["cv"].apply(tier)
    return stats[["cv", "volatility_tier"]]


def _confidence_label(obs_in_window_24h, volatility_tier: str) -> str:
    """
    Confidence combines TWO independent things that can each degrade trust:
      - freshness/support of the input data (obs_in_window_24h -- how many
        observations rolling_mean_24h and the recent-history features are
        actually built from)
      - how inherently unpredictable this sensor is (volatility_tier, a
        fixed property of the sensor, from calc_sensor_volatility)
    Either one downgrades confidence; both together downgrade it further.
    """
    if pd.isna(obs_in_window_24h) or obs_in_window_24h < 12:
        data_ok = "poor"
    elif obs_in_window_24h < 20:
        data_ok = "partial"
    else:
        data_ok = "good"

    if data_ok == "poor":
        return "low"
    if volatility_tier == "high":
        return "low" if data_ok == "partial" else "medium"
    if volatility_tier == "medium" and data_ok == "partial":
        return "medium"
    if data_ok == "good" and volatility_tier == "low":
        return "high"
    return "medium"


def explain_forecast_rf(row: pd.Series, volatility_lookup: pd.DataFrame, alert_threshold: float | None = None) -> dict:
    """
    row must come from run_random_forest_v2's predictions df: needs
    sensor_id, sensor_name (or falls back to sensor_id), timestamp,
    prediction, lag_24h, lag_168h, obs_in_window_24h.

    SAFETY BEHAVIOUR (Data Integrity acceptance criterion): if prediction,
    lag_24h, or lag_168h is missing/NaN -- whether because next_hour_forecast
    couldn't build a complete feature vector, or because a row reaches this
    function some other way with incomplete data -- this returns an explicit
    "insufficient data" refusal (forecast=None, confidence="none") instead of
    a number. This mirrors the baseline model's own refusal behaviour, so
    both models in the pipeline satisfy "missing/stale/insufficient inputs
    do not produce an unsupported forecast" the same way. Beyond that
    refusal case, RF's safety behaviour is expressed through the confidence
    label and, for high-volatility sensors, an explicit limitation note.
    """
    area = row.get("sensor_name", row["sensor_id"])

    prediction = row.get("prediction")
    lag_24h = row.get("lag_24h")
    lag_168h = row.get("lag_168h")
    missing_fields = [
        name for name, val in [("prediction", prediction), ("lag_24h", lag_24h), ("lag_168h", lag_168h)]
        if pd.isna(val)
    ]
    if missing_fields:
        return {
            "timestamp": row.get("timestamp"),
            "affected_area": area,
            "forecast": None,
            "reason": (
                "Insufficient or incomplete input data to generate a forecast for this "
                f"location and hour (missing: {', '.join(missing_fields)}). No forecast is "
                "shown rather than an unsupported guess."
            ),
            "confidence": "none",
            "data_support": {
                "obs_in_window_24h": None if pd.isna(row.get("obs_in_window_24h")) else int(row["obs_in_window_24h"]),
            },
        }

    vol_row = volatility_lookup.loc[row["sensor_id"]] if row["sensor_id"] in volatility_lookup.index else None
    volatility_tier = vol_row["volatility_tier"] if vol_row is not None else "unknown"

    confidence = _confidence_label(row.get("obs_in_window_24h"), volatility_tier)

    reason = (
        f"Primarily based on typical traffic at this location for "
        f"{row['timestamp'].strftime('%A')}s around {row['timestamp'].strftime('%H:%M')} "
        f"(same time last week: {int(row['lag_168h'])}), adjusted using yesterday's "
        f"observation at this hour ({int(row['lag_24h'])})."
    )

    result = {
        "timestamp": row["timestamp"],
        "affected_area": area,
        "forecast": round(float(row["prediction"]), 1),
        "reason": reason,
        "confidence": confidence,
        "data_support": {
            "obs_in_window_24h": None if pd.isna(row.get("obs_in_window_24h")) else int(row["obs_in_window_24h"]),
        },
    }

    if volatility_tier == "high":
        result["limitation"] = (
            "This location has historically shown large, event-driven swings "
            "in pedestrian traffic (e.g. concerts, festivals). The forecast is "
            "an estimate based on typical patterns and may be substantially "
            "wrong during unscheduled or unusually busy periods."
        )

    if alert_threshold is not None:
        result["alert"] = bool(row["prediction"] >= alert_threshold)
        result["alert_threshold"] = round(float(alert_threshold), 1)

    return result


def explain_batch(preds_df: pd.DataFrame, train_df: pd.DataFrame, alert_thresholds: pd.Series | None = None) -> list[dict]:
    """
    Convenience wrapper: computes volatility once from train_df, then
    builds an explanation dict for every row in preds_df (RF's output
    from run_random_forest_v2).
    """
    volatility_lookup = calc_sensor_volatility(train_df)
    explanations = []
    for _, row in preds_df.iterrows():
        thr = alert_thresholds.get(row["sensor_id"]) if alert_thresholds is not None else None
        explanations.append(explain_forecast_rf(row, volatility_lookup, alert_threshold=thr))
    return explanations


def next_hour_forecast(sensor_id, model, sensor_map: dict, latest_row: pd.Series,
                        volatility_lookup: pd.DataFrame, alert_threshold: float | None = None,
                        user_context: dict | None = None, base_thresholds: dict | None = None,
                        feature_cols: list[str] | None = None) -> dict:
    """
    THE function DEV-US1.1/UX-E1E2 should actually call: given a fitted RF
    model and the most recent known row of features for a sensor (i.e. the
    latest hour's lag_24h/lag_168h/rolling_mean_24h/etc -- produced by
    whatever ingestion job is keeping the feature table current), returns
    one explanation dict for that sensor's next-hour forecast.

    latest_row must already contain: sensor_id, sensor_name, timestamp
    (the hour BEING FORECAST -- i.e. the ingestion job should have already
    advanced this by one hour from the last observed row, since RF's
    training target is "this row's own hour", not a future one), and every
    column in feature_cols (defaults to the same NUMERIC_COLS + CYCLICAL_COLS
    + LAG_COLS + sensor_code set run_models_validated.py trains on).

    THRESHOLD RESOLUTION (Integration acceptance criterion): pass EITHER
      - alert_threshold directly (a precomputed float) -- for eval/batch use
        where the threshold was already resolved elsewhere, OR
      - user_context + base_thresholds -- for serving-time use, which routes
        through alert_thresholds.get_alert_thresholds() to apply the user's
        sensitivity setting. This is the actual "connected to the user
        threshold function" integration point.
    If both are omitted, no alert is computed (matches existing behaviour).

    This is a thin wrapper around explain_forecast_rf -- it exists
    separately so callers don't need to know about run_random_forest_v2's
    internal DataFrame plumbing (test_df, _tree_features, etc.) to get one
    forecast for one sensor at serving time.

    SAFETY: if any required feature is missing/NaN (e.g. a live feature row
    from a sensor outage), this does NOT call model.predict() -- sklearn's
    RandomForestRegressor raises on NaN input rather than degrading
    gracefully, so the check has to happen before the predict call, not
    after. Instead, row["prediction"] is left as NaN and control passes to
    explain_forecast_rf, which returns the same "insufficient data" refusal
    used elsewhere in the pipeline.
    """
    if feature_cols is None:
        feature_cols = ["is_weekend", "is_cbd", "obs_in_window_24h",
                         "hour_sin", "hour_cos", "dow_sin", "dow_cos",
                         "lag_24h", "lag_168h", "rolling_mean_24h", "sensor_code"]

    row = latest_row.copy()
    if "sensor_code" not in row or pd.isna(row.get("sensor_code")):
        row["sensor_code"] = sensor_map.get(sensor_id, -1)

    missing_inputs = [c for c in feature_cols if c not in row or pd.isna(row.get(c))]
    if missing_inputs:
        row["prediction"] = np.nan
    else:
        X = pd.DataFrame([row[feature_cols].to_dict()])
        pred = float(np.clip(model.predict(X)[0], 0, None))
        row["prediction"] = pred

    if alert_threshold is None and base_thresholds is not None:
        from alert_thresholds import get_alert_thresholds
        alert_threshold = get_alert_thresholds([sensor_id], user_context, base_thresholds).get(sensor_id)

    return explain_forecast_rf(row, volatility_lookup, alert_threshold=alert_threshold)



if __name__ == "__main__":
    # smoke-test / demo against the real pipeline
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

    from load_validated_data import load_pedestrian_data, time_ordered_split
    from run_models_validated import run_random_forest_v2, DATA_PATH, TRAIN_END, TEST_START
    from evaluate import sensor_alert_threshold

    df = load_pedestrian_data(DATA_PATH)
    train, test = time_ordered_split(df, TRAIN_END, TEST_START)
    rf_result = run_random_forest_v2(train, test)
    preds = rf_result["predictions"]

    thresholds = sensor_alert_threshold(train, quantile=0.75)
    volatility_lookup = calc_sensor_volatility(train)

    print("Volatility tiers:\n", volatility_lookup["volatility_tier"].value_counts())

    # --- Path 1: batch explanations, e.g. for evaluating the report / a
    # dashboard of "here's what we'd have told the user for every test hour"
    example_ids = [161, 41]  # Birrarung Marr COM Pole 1109, Flinders La-Swanston St (West)
    for sid in example_ids:
        row = preds[preds["sensor_id"] == sid].iloc[0]
        thr = thresholds.get(sid)
        print(f"\n--- batch explanation, sensor {sid} ---")
        print(explain_forecast_rf(row, volatility_lookup, alert_threshold=thr))

    # --- Path 2: serving-time single forecast, i.e. what DEV-US1.1-01 /
    # the API layer would actually call for one sensor's next-hour forecast.
    # Simulated here using the last test row's features as a stand-in for
    # "the latest known feature row an ingestion job would hand us" --
    # in production this row comes from the live feature pipeline, not from
    # a held-out test split.
    print("\n--- serving-time single-sensor forecast (simulated) ---")
    sample_row = preds[preds["sensor_id"] == 161].iloc[-1]
    result = next_hour_forecast(
        sensor_id=161,
        model=rf_result["model"],
        sensor_map=rf_result["sensor_map"],
        latest_row=sample_row,
        volatility_lookup=volatility_lookup,
        alert_threshold=thresholds.get(161),
    )
    print(result)

    # --- Path 3: missing-data safety check -- simulate a live feature row
    # from a sensor outage (lag_24h missing) and confirm it refuses cleanly
    # instead of crashing or silently predicting on garbage.
    print("\n--- missing-data safety check (simulated sensor outage) ---")
    broken_row = sample_row.copy()
    broken_row["lag_24h"] = float("nan")
    result_broken = next_hour_forecast(
        sensor_id=161,
        model=rf_result["model"],
        sensor_map=rf_result["sensor_map"],
        latest_row=broken_row,
        volatility_lookup=volatility_lookup,
        alert_threshold=thresholds.get(161),
    )
    print(result_broken)
    assert result_broken["forecast"] is None and result_broken["confidence"] == "none", \
        "Missing-data guard did not refuse as expected"
    print("OK: refused cleanly, no crash, no silent bad prediction.")

    # --- Path 4: user-threshold integration (Option A -- sensitivity
    # multiplier). Same sensor, three sensitivity levels, to confirm the
    # alert flag actually changes based on user_context.
    print("\n--- user-threshold integration (sensitivity levels) ---")
    from alert_thresholds import compute_base_thresholds
    base = compute_base_thresholds(train)
    base_dict = {int(k): float(v) for k, v in base.items()}
    for sensitivity in ["cautious", "default", "relaxed"]:
        r = next_hour_forecast(
            sensor_id=161,
            model=rf_result["model"],
            sensor_map=rf_result["sensor_map"],
            latest_row=sample_row,
            volatility_lookup=volatility_lookup,
            user_context={"sensitivity": sensitivity},
            base_thresholds=base_dict,
        )
        print(f"  sensitivity={sensitivity}: forecast={r['forecast']}, "
              f"threshold={r.get('alert_threshold')}, alert={r.get('alert')}")

