"""
per_sensor_mae.py
Breaks down Random Forest's overall MAE (56.1) into per-sensor error, to
check whether it's roughly uniform across the 100 sensors or dominated by
a handful of high-traffic / event-driven ones (per Peter's warning that a
single global model "will fit the busy sensors and ignore the rest").

Reports both:
  - raw MAE per sensor (absolute error, in pedestrians/hour)
  - relative MAE per sensor (MAE / that sensor's mean training count)
    since Flinders Lane (~3,600/hr peak) and Errol St (~300/hr peak) are
    not comparable on raw error alone.

Usage:
    python per_sensor_mae.py
Writes per_sensor_mae.csv next to this script and prints a summary.
"""
import sys
from pathlib import Path
import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data, time_ordered_split
from run_models_validated import run_random_forest_v2, DATA_PATH, TRAIN_END, TEST_START

OUT_CSV = Path(__file__).resolve().parent / "per_sensor_mae.csv"


def per_sensor_errors(train_df: pd.DataFrame, preds_df: pd.DataFrame) -> pd.DataFrame:
    """
    preds_df must have columns: sensor_id, count (actual), prediction.
    train_df used only to get each sensor's mean training count, for the
    relative-MAE calculation (mean count is a training-time quantity, not
    computed from test data, to avoid leaking test info into the metric).
    """
    df = preds_df.dropna(subset=["count", "prediction"]).copy()
    df["abs_err"] = (df["count"] - df["prediction"]).abs()
    df["sq_err"] = (df["count"] - df["prediction"]) ** 2

    per_sensor = (
        df.groupby(["sensor_id", "sensor_name"])
        .agg(
            n_test_rows=("abs_err", "size"),
            mae=("abs_err", "mean"),
            rmse=("sq_err", lambda s: np.sqrt(s.mean())),
            mean_actual_test=("count", "mean"),
            max_actual_test=("count", "max"),
        )
        .reset_index()
    )

    train_mean = train_df.groupby("sensor_id")["count"].mean().rename("mean_train_count")
    per_sensor = per_sensor.merge(train_mean, on="sensor_id", how="left")

    # relative MAE: guard against near-zero-traffic sensors blowing up the ratio
    per_sensor["relative_mae"] = per_sensor["mae"] / per_sensor["mean_train_count"].clip(lower=1.0)

    return per_sensor.sort_values("mae", ascending=False).reset_index(drop=True)


def print_summary(per_sensor: pd.DataFrame, overall_mae: float):
    print(f"\nOverall RF MAE (all sensors pooled): {overall_mae:.1f}")
    print(f"Sensors evaluated: {len(per_sensor)}")

    print("\n--- Per-sensor MAE distribution ---")
    desc = per_sensor["mae"].describe(percentiles=[0.1, 0.25, 0.5, 0.75, 0.9])
    print(desc.to_string())

    print("\n--- 10 worst sensors by raw MAE ---")
    cols = ["sensor_id", "sensor_name", "mae", "rmse", "mean_train_count", "relative_mae", "n_test_rows"]
    print(per_sensor.sort_values("mae", ascending=False)[cols].head(10).to_string(index=False))

    print("\n--- 10 worst sensors by relative MAE (error as % of that sensor's traffic) ---")
    print(per_sensor.sort_values("relative_mae", ascending=False)[cols].head(10).to_string(index=False))

    print("\n--- 10 best sensors by raw MAE ---")
    print(per_sensor.sort_values("mae", ascending=True)[cols].head(10).to_string(index=False))

    # how much of total absolute error do the worst N sensors account for?
    total_abs_err = (per_sensor["mae"] * per_sensor["n_test_rows"]).sum()
    for top_n in [5, 10, 20]:
        worst = per_sensor.sort_values("mae", ascending=False).head(top_n)
        share = (worst["mae"] * worst["n_test_rows"]).sum() / total_abs_err
        print(f"\nTop {top_n} sensors by MAE account for {share:.1%} of total absolute error "
              f"(vs {top_n/len(per_sensor):.1%} of sensors)")


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)
    train, test = time_ordered_split(df, TRAIN_END, TEST_START)

    print("\nTraining Random Forest...")
    rf_result = run_random_forest_v2(train, test)
    print("Overall MAE/RMSE:", rf_result["metrics"])

    preds = rf_result["predictions"]  # has sensor_id, sensor_name, count, prediction
    per_sensor = per_sensor_errors(train, preds)

    print_summary(per_sensor, rf_result["metrics"]["mae"])

    per_sensor.to_csv(OUT_CSV, index=False)
    print(f"\nFull per-sensor table written to {OUT_CSV}")


if __name__ == "__main__":
    main()
