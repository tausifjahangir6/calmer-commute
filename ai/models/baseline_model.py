"""
baseline_model.py
Hour-of-week baseline: predicts next hour's count as the historical average
count for that sensor at that (day_of_week, hour) combination, learned from
TRAINING data only. This is the benchmark every other model (Linear
Regression, Random Forest, Gradient Boosting) must beat to justify its
added complexity.

Also implements the required safety behaviour: if a (sensor, day_of_week,
hour) combination was never seen in training, the model does NOT guess —
it returns an explicit "insufficient data" result rather than an
unsupported number.
"""

from __future__ import annotations
import numpy as np
import pandas as pd

from evaluate import mae_rmse, threshold_alert_confusion, sensor_alert_threshold


def make_target(df: pd.DataFrame) -> pd.DataFrame:
    """
    Target = next hour's count, per sensor. Also carries forward the
    timestamp of the hour BEING PREDICTED (target_timestamp), separate
    from the timestamp of the row used to make the prediction, since the
    explanation output needs to state which hour the forecast is *for*.
    """
    df = df.sort_values(["sensor_id", "timestamp"]).copy()
    df["target"] = df.groupby("sensor_id")["count"].shift(-1)
    df["target_timestamp"] = df.groupby("sensor_id")["timestamp"].shift(-1)
    return df


class HourOfWeekBaseline:
    def __init__(self):
        self.lookup_: dict[tuple, dict] = {}  # (sensor_id, day_of_week, hour) -> {mean, n}

    def fit(self, train_df: pd.DataFrame):
        """
        train_df must already have target/target_timestamp columns from
        make_target(). We group by the TARGET hour's day-of-week/hour,
        since that's what we're predicting.
        """
        t = train_df.dropna(subset=["target", "target_timestamp"]).copy()
        t["target_dow"] = t["target_timestamp"].dt.dayofweek
        t["target_hour"] = t["target_timestamp"].dt.hour

        grouped = (
            t.groupby(["sensor_id", "target_dow", "target_hour"])["target"]
            .agg(["mean", "count"])
            .reset_index()
        )
        for _, row in grouped.iterrows():
            key = (row["sensor_id"], int(row["target_dow"]), int(row["target_hour"]))
            self.lookup_[key] = {"mean": float(row["mean"]), "n": int(row["count"])}
        return self

    def predict_one(self, sensor_id: str, target_dow: int, target_hour: int, min_support: int = 3):
        """
        Returns (prediction_or_None, n_support). Prediction is None if the
        combination wasn't seen enough times in training — this is the
        "never output an unsupported forecast" safety rule.
        """
        key = (sensor_id, target_dow, target_hour)
        entry = self.lookup_.get(key)
        if entry is None or entry["n"] < min_support:
            return None, 0 if entry is None else entry["n"]
        return entry["mean"], entry["n"]

    def predict(self, df: pd.DataFrame, min_support: int = 3) -> pd.DataFrame:
        df = df.copy()
        df["target_dow"] = df["target_timestamp"].dt.dayofweek
        df["target_hour"] = df["target_timestamp"].dt.hour

        preds, supports = [], []
        for _, row in df.iterrows():
            if pd.isna(row["target_timestamp"]):
                preds.append(np.nan)
                supports.append(0)
                continue
            p, n = self.predict_one(row["sensor_id"], int(row["target_dow"]), int(row["target_hour"]), min_support)
            preds.append(p if p is not None else np.nan)
            supports.append(n)
        df["prediction"] = preds
        df["support_n"] = supports
        return df


def explain_forecast(row: pd.Series, alert_threshold: float | None = None) -> dict:
    """
    Builds the required explanation object: timestamp, affected area,
    reason, confidence/coverage. Returns a clear limitation message instead
    of a forecast when the model couldn't support one.
    """
    area = row.get("sensor_name", row["sensor_id"])

    if pd.isna(row["prediction"]):
        return {
            "timestamp": row["target_timestamp"],
            "affected_area": area,
            "forecast": None,
            "reason": (
                "Insufficient historical data for this sensor at this "
                "day-of-week/hour combination (or an underlying data gap). "
                "No forecast is shown rather than an unsupported guess."
            ),
            "confidence": "none",
            "support_n": int(row["support_n"]),
        }

    confidence = "low" if row["support_n"] < 8 else ("medium" if row["support_n"] < 20 else "high")
    reason = (
        f"Hour-of-week average: based on {int(row['support_n'])} historical "
        f"observations at this sensor for "
        f"{row['target_timestamp'].strftime('%A')}s around "
        f"{row['target_timestamp'].strftime('%H:%M')}."
    )
    result = {
        "timestamp": row["target_timestamp"],
        "affected_area": area,
        "forecast": round(float(row["prediction"]), 1),
        "reason": reason,
        "confidence": confidence,
        "support_n": int(row["support_n"]),
    }
    if alert_threshold is not None:
        result["alert"] = bool(row["prediction"] >= alert_threshold)
        result["alert_threshold"] = round(float(alert_threshold), 1)
    return result


def run_baseline(train_df: pd.DataFrame, test_df: pd.DataFrame, min_support: int = 3):
    """
    End-to-end: fit on train, predict on test, return metrics + predictions
    + a handful of example explanations.
    """
    model = HourOfWeekBaseline().fit(train_df)
    preds = model.predict(test_df, min_support=min_support)

    metrics = mae_rmse(preds["target"], preds["prediction"])

    thresholds = sensor_alert_threshold(train_df, quantile=0.75)
    preds["alert_threshold"] = preds["sensor_id"].map(thresholds)
    # threshold confusion needs a single scalar per call; do it per-sensor
    # then aggregate, since each sensor has its own threshold
    conf_rows = []
    for sensor_id, g in preds.dropna(subset=["alert_threshold"]).groupby("sensor_id"):
        thr = g["alert_threshold"].iloc[0]
        c = threshold_alert_confusion(g["target"], g["prediction"], thr)
        c["sensor_id"] = sensor_id
        conf_rows.append(c)
    conf_df = pd.DataFrame(conf_rows)
    agg_conf = {
        "tp": int(conf_df["tp"].sum()) if len(conf_df) else 0,
        "fp": int(conf_df["fp"].sum()) if len(conf_df) else 0,
        "fn": int(conf_df["fn"].sum()) if len(conf_df) else 0,
        "tn": int(conf_df["tn"].sum()) if len(conf_df) else 0,
    }
    tp, fp, fn = agg_conf["tp"], agg_conf["fp"], agg_conf["fn"]
    agg_conf["precision"] = tp / (tp + fp) if (tp + fp) else float("nan")
    agg_conf["recall"] = tp / (tp + fn) if (tp + fn) else float("nan")

    coverage = preds["prediction"].notna().mean()

    examples = [
        explain_forecast(row, alert_threshold=row.get("alert_threshold"))
        for _, row in preds.head(5).iterrows()
    ]

    return {
        "model": model,
        "predictions": preds,
        "metrics": metrics,
        "coverage": coverage,
        "threshold_confusion_per_sensor": conf_df,
        "threshold_confusion_overall": agg_conf,
        "example_explanations": examples,
    }
