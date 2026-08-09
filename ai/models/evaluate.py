"""
evaluate.py
Shared metrics for all four forecasting approaches, so comparisons in the
final report are apples-to-apples.
"""

from __future__ import annotations
import numpy as np
import pandas as pd


def mae_rmse(y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    mask = ~np.isnan(y_true) & ~np.isnan(y_pred)
    if mask.sum() == 0:
        return {"mae": np.nan, "rmse": np.nan, "n": 0}
    err = y_true[mask] - y_pred[mask]
    mae = np.mean(np.abs(err))
    rmse = np.sqrt(np.mean(err ** 2))
    return {"mae": float(mae), "rmse": float(rmse), "n": int(mask.sum())}


def threshold_alert_confusion(
    y_true: np.ndarray, y_pred: np.ndarray, threshold: float
) -> dict:
    """
    Treat "count >= threshold" as an alert-worthy period (High crowd risk).
    Compares predicted-alert vs actual-alert, i.e. does the *forecast*
    crossing the threshold correctly flag an *actual* alert-worthy hour.

    Returns confusion matrix counts + precision/recall/f1.
    Precision: of the hours we flagged, how many were really alert-worthy
               (matters because false alarms erode user trust in the app).
    Recall:    of the hours that really were alert-worthy, how many did we
               catch (matters because missed alerts defeat the app's purpose).
    """
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    mask = ~np.isnan(y_true) & ~np.isnan(y_pred)
    yt = y_true[mask] >= threshold
    yp = y_pred[mask] >= threshold

    tp = int(np.sum(yt & yp))
    fp = int(np.sum(~yt & yp))
    fn = int(np.sum(yt & ~yp))
    tn = int(np.sum(~yt & ~yp))

    precision = tp / (tp + fp) if (tp + fp) > 0 else float("nan")
    recall = tp / (tp + fn) if (tp + fn) > 0 else float("nan")
    f1 = (
        2 * precision * recall / (precision + recall)
        if (precision + recall) > 0 and not np.isnan(precision) and not np.isnan(recall)
        else float("nan")
    )

    return {
        "threshold": threshold,
        "tp": tp, "fp": fp, "fn": fn, "tn": tn,
        "precision": precision, "recall": recall, "f1": f1,
        "n_evaluated": int(mask.sum()),
    }


def sensor_alert_threshold(train_df: pd.DataFrame, quantile: float = 0.75) -> pd.Series:
    """
    Per-sensor alert threshold = a quantile of that sensor's TRAINING count
    distribution. Computed per sensor (not globally) because a quiet laneway
    and a busy Bourke St corner have very different baselines — a single
    global threshold would either never fire for quiet sensors or always
    fire for busy ones.
    """
    return train_df.groupby("sensor_id")["count"].quantile(quantile)


def summarize_model_comparison(results: dict) -> pd.DataFrame:
    """results: {model_name: {"mae":..., "rmse":..., ...}}"""
    return pd.DataFrame(results).T[["mae", "rmse", "n"]]
