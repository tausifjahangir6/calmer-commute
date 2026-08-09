"""
run_models_validated.py
Retrains and compares all four models against Tausif's validated dataset.

RF and GB hyperparameters below are the TUNED defaults from tune_models.py
(time-ordered validation search, never touched the test set during search).
Confirmed on the real, untouched test set:
    RF:  MAE 56.1 -> 54.1   (n_estimators=200, max_depth=20, min_samples_leaf=8, max_features='sqrt')
    GB:  MAE 58.0 -> 55.1   (max_iter=400, max_depth=10, learning_rate=0.2, min_samples_leaf=20, l2_regularization=0.1)
The old untuned defaults (n_estimators=200/max_iter=200, everything else
sklearn/original-script defaults) are still reachable by passing them
explicitly, e.g. for reproducing the original comparison table.
"""
import sys
from pathlib import Path
import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data, time_ordered_split
from evaluate import mae_rmse, threshold_alert_confusion, sensor_alert_threshold, summarize_model_comparison
from baseline_model import HourOfWeekBaseline

DATA_PATH = str(Path(__file__).resolve().parents[2] / "data" / "raw" / "training_20260807.csv")
TRAIN_END = "2026-07-06"
TEST_START = "2026-07-06"

LAG_COLS = ["lag_24h", "lag_168h", "rolling_mean_24h"]
NUMERIC_COLS = ["is_weekend", "is_cbd", "obs_in_window_24h"]
CYCLICAL_COLS = ["hour_sin", "hour_cos", "dow_sin", "dow_cos"]


def prep_for_baseline(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["target"] = df["count"]
    df["target_timestamp"] = df["timestamp"]
    return df


def run_baseline_v2(train_df, test_df, min_support=3):
    train_df = prep_for_baseline(train_df)
    test_df = prep_for_baseline(test_df)
    model = HourOfWeekBaseline().fit(train_df)
    preds = model.predict(test_df, min_support=min_support)
    metrics = mae_rmse(preds["target"], preds["prediction"])
    coverage = preds["prediction"].notna().mean()

    thresholds = sensor_alert_threshold(train_df, quantile=0.75)
    preds["alert_threshold"] = preds["sensor_id"].map(thresholds)
    conf_rows = []
    for sid, g in preds.dropna(subset=["alert_threshold"]).groupby("sensor_id"):
        thr = g["alert_threshold"].iloc[0]
        c = threshold_alert_confusion(g["target"], g["prediction"], thr)
        c["sensor_id"] = sid
        conf_rows.append(c)
    conf_df = pd.DataFrame(conf_rows)
    agg = {k: int(conf_df[k].sum()) if len(conf_df) else 0 for k in ["tp", "fp", "fn", "tn"]}
    agg["precision"] = agg["tp"] / (agg["tp"] + agg["fp"]) if (agg["tp"] + agg["fp"]) else float("nan")
    agg["recall"] = agg["tp"] / (agg["tp"] + agg["fn"]) if (agg["tp"] + agg["fn"]) else float("nan")
    return {"predictions": preds, "metrics": metrics, "coverage": coverage, "threshold_confusion_overall": agg}


def _encode_sensor(df, sensor_map=None):
    df = df.copy()
    if sensor_map is None:
        cats = sorted(df["sensor_id"].unique())
        sensor_map = {s: i for i, s in enumerate(cats)}
    df["sensor_code"] = df["sensor_id"].map(sensor_map).fillna(-1).astype(int)
    return df, sensor_map


def run_linear_regression_v2(train_df, test_df):
    from sklearn.linear_model import LinearRegression

    sensor_dummies_train = pd.get_dummies(train_df["sensor_id"], prefix="sensor")
    X_train = pd.concat([
        train_df[NUMERIC_COLS + CYCLICAL_COLS + LAG_COLS].reset_index(drop=True),
        sensor_dummies_train.reset_index(drop=True),
    ], axis=1)
    y_train = train_df["count"].reset_index(drop=True)

    model = LinearRegression()
    model.fit(X_train, y_train)

    sensor_dummies_test = pd.get_dummies(test_df["sensor_id"], prefix="sensor").reindex(
        columns=sensor_dummies_train.columns, fill_value=0
    )
    X_test = pd.concat([
        test_df[NUMERIC_COLS + CYCLICAL_COLS + LAG_COLS].reset_index(drop=True),
        sensor_dummies_test.reset_index(drop=True),
    ], axis=1)

    test_df = test_df.reset_index(drop=True).copy()
    preds = model.predict(X_test)
    test_df["prediction"] = np.clip(preds, 0, None)

    metrics = mae_rmse(test_df["count"], test_df["prediction"])
    thresholds = sensor_alert_threshold(train_df, quantile=0.75)
    test_df["alert_threshold"] = test_df["sensor_id"].map(thresholds)
    conf_rows = []
    for sid, g in test_df.dropna(subset=["alert_threshold"]).groupby("sensor_id"):
        thr = g["alert_threshold"].iloc[0]
        c = threshold_alert_confusion(g["count"], g["prediction"], thr)
        c["sensor_id"] = sid
        conf_rows.append(c)
    conf_df = pd.DataFrame(conf_rows)
    agg = {k: int(conf_df[k].sum()) if len(conf_df) else 0 for k in ["tp", "fp", "fn", "tn"]}
    agg["precision"] = agg["tp"] / (agg["tp"] + agg["fp"]) if (agg["tp"] + agg["fp"]) else float("nan")
    agg["recall"] = agg["tp"] / (agg["tp"] + agg["fn"]) if (agg["tp"] + agg["fn"]) else float("nan")
    return {"predictions": test_df, "metrics": metrics, "threshold_confusion_overall": agg}


def _tree_features(df, sensor_map=None):
    df, sensor_map = _encode_sensor(df, sensor_map)
    cols = NUMERIC_COLS + CYCLICAL_COLS + LAG_COLS + ["sensor_code"]
    return df, sensor_map, cols


def _aggregate_threshold_confusion(df, target_col, train_df):
    thresholds = sensor_alert_threshold(train_df, quantile=0.75)
    df["alert_threshold"] = df["sensor_id"].map(thresholds)
    conf_rows = []
    for sid, g in df.dropna(subset=["alert_threshold"]).groupby("sensor_id"):
        thr = g["alert_threshold"].iloc[0]
        c = threshold_alert_confusion(g[target_col], g["prediction"], thr)
        c["sensor_id"] = sid
        conf_rows.append(c)
    conf_df = pd.DataFrame(conf_rows)
    agg = {k: int(conf_df[k].sum()) if len(conf_df) else 0 for k in ["tp", "fp", "fn", "tn"]}
    agg["precision"] = agg["tp"] / (agg["tp"] + agg["fp"]) if (agg["tp"] + agg["fp"]) else float("nan")
    agg["recall"] = agg["tp"] / (agg["tp"] + agg["fn"]) if (agg["tp"] + agg["fn"]) else float("nan")
    return agg


def run_random_forest_v2(
    train_df, test_df,
    n_estimators=200,
    max_depth=20,
    min_samples_leaf=8,
    max_features="sqrt",
    random_state=42,
    n_jobs=-1,
):
    from sklearn.ensemble import RandomForestRegressor
    train_df, sensor_map, cols = _tree_features(train_df)
    test_df, _, _ = _tree_features(test_df, sensor_map)

    model = RandomForestRegressor(
        n_estimators=n_estimators,
        max_depth=max_depth,
        min_samples_leaf=min_samples_leaf,
        max_features=max_features,
        random_state=random_state,
        n_jobs=n_jobs,
    )
    model.fit(train_df[cols], train_df["count"])

    test_df = test_df.reset_index(drop=True).copy()
    preds = model.predict(test_df[cols])
    test_df["prediction"] = np.clip(preds, 0, None)

    metrics = mae_rmse(test_df["count"], test_df["prediction"])
    agg = _aggregate_threshold_confusion(test_df, "count", train_df)
    importances = pd.Series(model.feature_importances_, index=cols).sort_values(ascending=False)
    return {
        "model": model,
        "sensor_map": sensor_map,
        "predictions": test_df,
        "metrics": metrics,
        "threshold_confusion_overall": agg,
        "feature_importances": importances,
        "params": {
            "n_estimators": n_estimators, "max_depth": max_depth,
            "min_samples_leaf": min_samples_leaf, "max_features": max_features,
        },
    }


def run_gradient_boosting_v2(
    train_df, test_df,
    max_iter=400,
    max_depth=10,
    learning_rate=0.2,
    min_samples_leaf=20,
    l2_regularization=0.1,
    random_state=42,
):
    from sklearn.ensemble import HistGradientBoostingRegressor
    train_df, sensor_map, cols = _tree_features(train_df)
    test_df, _, _ = _tree_features(test_df, sensor_map)

    model = HistGradientBoostingRegressor(
        max_iter=max_iter,
        max_depth=max_depth,
        learning_rate=learning_rate,
        min_samples_leaf=min_samples_leaf,
        l2_regularization=l2_regularization,
        random_state=random_state,
    )
    model.fit(train_df[cols], train_df["count"])

    test_df = test_df.reset_index(drop=True).copy()
    preds = model.predict(test_df[cols])
    test_df["prediction"] = np.clip(preds, 0, None)

    metrics = mae_rmse(test_df["count"], test_df["prediction"])
    agg = _aggregate_threshold_confusion(test_df, "count", train_df)
    return {
        "model": model,
        "predictions": test_df,
        "metrics": metrics,
        "threshold_confusion_overall": agg,
        "params": {
            "max_iter": max_iter, "max_depth": max_depth, "learning_rate": learning_rate,
            "min_samples_leaf": min_samples_leaf, "l2_regularization": l2_regularization,
        },
    }


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)
    print("Shape:", df.shape, "| Sensors:", df["sensor_id"].nunique())
    print("Date range:", df["timestamp"].min(), "to", df["timestamp"].max())

    train, test = time_ordered_split(df, TRAIN_END, TEST_START)

    print("\n--- baseline ---")
    baseline_result = run_baseline_v2(train, test)
    print("MAE/RMSE:", baseline_result["metrics"])
    print("Coverage:", round(baseline_result["coverage"], 3))
    print("Threshold confusion:", baseline_result["threshold_confusion_overall"])

    print("\n--- linear regression ---")
    lr_result = run_linear_regression_v2(train, test)
    print("MAE/RMSE:", lr_result["metrics"])
    print("Threshold confusion:", lr_result["threshold_confusion_overall"])

    print("\n--- random forest ---")
    rf_result = run_random_forest_v2(train, test)
    print("MAE/RMSE:", rf_result["metrics"])
    print("Threshold confusion:", rf_result["threshold_confusion_overall"])
    print("Feature importances:\n", rf_result["feature_importances"])

    print("\n--- gradient boosting ---")
    gb_result = run_gradient_boosting_v2(train, test)
    print("MAE/RMSE:", gb_result["metrics"])
    print("Threshold confusion:", gb_result["threshold_confusion_overall"])

    print("\n--- comparison ---")
    comparison = summarize_model_comparison({
        "hour_of_week_baseline": baseline_result["metrics"],
        "linear_regression": lr_result["metrics"],
        "random_forest": rf_result["metrics"],
        "gradient_boosting": gb_result["metrics"],
    })
    print(comparison)


if __name__ == "__main__":
    main()
