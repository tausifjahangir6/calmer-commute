"""
tune_models.py
Random-search hyperparameter tuning for Random Forest and Gradient
Boosting, using a time-ordered VALIDATION window carved out of the
training period only. The real test set (>= 2026-07-06) is never touched
during search -- it's reserved for one final, honest evaluation with the
winning config, exactly like the existing train/test boundary already
protects against leakage.

Split layout:
    [ ... tune_train ... ) [ tune_val ) [ ------- untouched test ------- )
    < TUNE_VAL_START        TUNE_VAL_START to TRAIN_END      TEST_START >

TUNE_VAL_START gives ~4 weeks of validation data immediately before the
existing train/test boundary -- close enough in time to be representative
of the test period's conditions, without being the test period itself.

Usage:
    python tune_models.py
Prints the best config per model (by validation MAE) and, once found,
refits on the FULL training set (train_df, same as run_models_validated.py
uses) and reports final test MAE/RMSE for comparison against the current
56.1 / 58.0 baseline numbers.
"""
import sys
from pathlib import Path
import itertools
import random
import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here

from load_validated_data import load_pedestrian_data, time_ordered_split
from run_models_validated import (
    run_random_forest_v2, run_gradient_boosting_v2,
    DATA_PATH, TRAIN_END, TEST_START,
)

TUNE_VAL_START = "2026-06-08"  # ~4 weeks of validation before the train/test boundary
N_SEARCH_ITERS = 10            # random samples per model; raise if you have time to spare
RANDOM_STATE = 42
RF_N_JOBS = 1                  # sequential, not parallel: parallel tree-building was
                                # still OOMing even with capped depth. Raise once you've
                                # confirmed things run cleanly.
SEARCH_SAMPLE_ROWS = 400_000   # subsample tune_train to this many rows FOR SEARCH ONLY.
                                # Safe because lag_24h/lag_168h/rolling_mean_24h are
                                # precomputed per row already (not row-order dependent),
                                # so a random row sample doesn't leak or bias the relative
                                # ranking of configs -- it just reduces memory/runtime.
                                # The final refit below uses the FULL training set.

# NOTE: min_samples_leaf=1 combined with max_depth=None was dropped from the grid --
# that combo lets trees grow essentially unbounded on 1.4M rows and is what caused the
# MemoryError on the first run. It also wasn't winning: config 6 from run 1
# (max_depth=20, min_samples_leaf=5, max_features='sqrt') was the best result so far at
# val MAE 59.95, all with bounded depth.
RF_GRID = {
    "n_estimators": [150, 200],
    "max_depth": [15, 20, 25],
    "min_samples_leaf": [3, 5, 8],
    "max_features": [1.0, 0.6, "sqrt"],  # 1.0 added back in -- now that search trains on
                                          # a 400K subsample instead of 1.4M rows, memory
                                          # pressure is much lower, so it's safe to let the
                                          # search actually compare against your original
                                          # default rather than assume it loses.
}

GB_GRID = {
    "max_iter": [200, 400],
    "max_depth": [None, 10, 20],
    "learning_rate": [0.05, 0.1, 0.2],
    "min_samples_leaf": [20, 50],
    "l2_regularization": [0.0, 0.1, 1.0],
}


def sample_configs(grid: dict, n: int, seed: int) -> list[dict]:
    keys = list(grid.keys())
    all_combos = list(itertools.product(*[grid[k] for k in keys]))
    rng = random.Random(seed)
    rng.shuffle(all_combos)
    picked = all_combos[:n]
    return [dict(zip(keys, combo)) for combo in picked]


def subsample_rows(df: pd.DataFrame, max_rows: int, seed: int) -> pd.DataFrame:
    """
    Row-level subsample for the search phase only. Safe here specifically
    because every feature used (lags, rolling means, cyclical encodings) is
    already precomputed per row and doesn't depend on which other rows are
    present in the training set -- so this changes statistical power, not
    correctness or leakage.
    """
    if len(df) <= max_rows:
        return df
    return df.sample(n=max_rows, random_state=seed)


def tune_random_forest(tune_train, tune_val):
    import gc
    tune_train_sample = subsample_rows(tune_train, SEARCH_SAMPLE_ROWS, RANDOM_STATE)
    print(f"  (RF search using {len(tune_train_sample)}-row subsample of {len(tune_train)}-row tune_train)")
    configs = sample_configs(RF_GRID, N_SEARCH_ITERS, RANDOM_STATE)
    results = []
    for i, cfg in enumerate(configs, 1):
        try:
            r = run_random_forest_v2(tune_train_sample, tune_val, **cfg, random_state=RANDOM_STATE, n_jobs=RF_N_JOBS)
            mae = r["metrics"]["mae"]
            results.append({**cfg, "val_mae": mae, "val_rmse": r["metrics"]["rmse"]})
            print(f"  [RF {i}/{len(configs)}] {cfg} -> val MAE {mae:.2f}")
            del r
        except MemoryError:
            print(f"  [RF {i}/{len(configs)}] {cfg} -> SKIPPED (MemoryError, config too heavy for this machine)")
        finally:
            gc.collect()
    if not results:
        raise RuntimeError("Every RF config ran out of memory -- lower SEARCH_SAMPLE_ROWS or RF_GRID further.")
    results_df = pd.DataFrame(results).sort_values("val_mae").reset_index(drop=True)
    return results_df


def tune_gradient_boosting(tune_train, tune_val):
    import gc
    tune_train_sample = subsample_rows(tune_train, SEARCH_SAMPLE_ROWS, RANDOM_STATE)
    print(f"  (GB search using {len(tune_train_sample)}-row subsample of {len(tune_train)}-row tune_train)")
    configs = sample_configs(GB_GRID, N_SEARCH_ITERS, RANDOM_STATE)
    results = []
    for i, cfg in enumerate(configs, 1):
        try:
            r = run_gradient_boosting_v2(tune_train_sample, tune_val, **cfg, random_state=RANDOM_STATE)
            mae = r["metrics"]["mae"]
            results.append({**cfg, "val_mae": mae, "val_rmse": r["metrics"]["rmse"]})
            print(f"  [GB {i}/{len(configs)}] {cfg} -> val MAE {mae:.2f}")
            del r
        except MemoryError:
            print(f"  [GB {i}/{len(configs)}] {cfg} -> SKIPPED (MemoryError, config too heavy for this machine)")
        finally:
            gc.collect()
    if not results:
        raise RuntimeError("Every GB config ran out of memory.")
    results_df = pd.DataFrame(results).sort_values("val_mae").reset_index(drop=True)
    return results_df


def main():
    print(f"Loading: {DATA_PATH}")
    df = load_pedestrian_data(DATA_PATH)
    full_train, test = time_ordered_split(df, TRAIN_END, TEST_START)

    # carve the validation window out of full_train only -- test stays untouched
    tune_train, tune_val = time_ordered_split(full_train, TUNE_VAL_START, TUNE_VAL_START)
    print(f"\n[tune split] tune_train: {len(tune_train)} rows | tune_val: {len(tune_val)} rows")

    print("\n=== Random Forest search ===")
    default_rf = run_random_forest_v2(
        subsample_rows(tune_train, SEARCH_SAMPLE_ROWS, RANDOM_STATE), tune_val,
        n_estimators=200, max_depth=None, min_samples_leaf=3, max_features=1.0,
        random_state=RANDOM_STATE, n_jobs=RF_N_JOBS,
    )
    print(f"  [RF default] n_estimators=200, max_depth=None, min_samples_leaf=3, "
          f"max_features=1.0 -> val MAE {default_rf['metrics']['mae']:.2f}  "
          f"(control point -- same split/subsample as the search below)")
    rf_results = tune_random_forest(tune_train, tune_val)
    print("\nTop 5 RF configs by validation MAE:")
    print(rf_results.head(5).to_string(index=False))
    best_rf_cfg = rf_results.iloc[0].drop(["val_mae", "val_rmse"]).to_dict()
    # int-ify params sample_configs pulled from JSON-like grid (max_depth may be float NaN handling)
    if pd.notna(best_rf_cfg.get("max_depth")):
        best_rf_cfg["max_depth"] = int(best_rf_cfg["max_depth"])
    else:
        best_rf_cfg["max_depth"] = None
    best_rf_cfg["n_estimators"] = int(best_rf_cfg["n_estimators"])
    best_rf_cfg["min_samples_leaf"] = int(best_rf_cfg["min_samples_leaf"])

    print("\n=== Gradient Boosting search ===")
    default_gb = run_gradient_boosting_v2(
        subsample_rows(tune_train, SEARCH_SAMPLE_ROWS, RANDOM_STATE), tune_val,
        max_iter=200, max_depth=None, learning_rate=0.1, min_samples_leaf=20, l2_regularization=0.0,
        random_state=RANDOM_STATE,
    )
    print(f"  [GB default] max_iter=200, max_depth=None, learning_rate=0.1, min_samples_leaf=20, "
          f"l2_regularization=0.0 -> val MAE {default_gb['metrics']['mae']:.2f}  "
          f"(control point -- same split/subsample as the search below)")
    gb_results = tune_gradient_boosting(tune_train, tune_val)
    print("\nTop 5 GB configs by validation MAE:")
    print(gb_results.head(5).to_string(index=False))
    best_gb_cfg = gb_results.iloc[0].drop(["val_mae", "val_rmse"]).to_dict()
    if pd.notna(best_gb_cfg.get("max_depth")):
        best_gb_cfg["max_depth"] = int(best_gb_cfg["max_depth"])
    else:
        best_gb_cfg["max_depth"] = None
    best_gb_cfg["max_iter"] = int(best_gb_cfg["max_iter"])
    best_gb_cfg["min_samples_leaf"] = int(best_gb_cfg["min_samples_leaf"])

    print("\n\n=== Final evaluation on the untouched test set, refit on full train ===")
    print(f"Best RF config: {best_rf_cfg}")
    rf_final = run_random_forest_v2(full_train, test, **best_rf_cfg, random_state=RANDOM_STATE, n_jobs=RF_N_JOBS)
    print("Tuned RF test MAE/RMSE:", rf_final["metrics"], " (previous: MAE 56.1 / RMSE 146.6)")

    print(f"\nBest GB config: {best_gb_cfg}")
    gb_final = run_gradient_boosting_v2(full_train, test, **best_gb_cfg, random_state=RANDOM_STATE)
    print("Tuned GB test MAE/RMSE:", gb_final["metrics"], " (previous: MAE 58.0 / RMSE 146.7)")


if __name__ == "__main__":
    main()
