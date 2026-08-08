"""
alert_thresholds.py
Interim implementation of the user-threshold function required by AI-US2.2-01's
"Integration" acceptance criterion, pending US1.3.

DESIGN (Option A from the AI-US2.2-01 writeup): a per-sensor base threshold
(75th percentile of that sensor's training-period traffic, computed once,
offline) scaled by a user sensitivity multiplier at request time. This makes
the alert genuinely user-connected -- a "cautious" user gets flagged earlier
at every sensor, proportionally -- without requiring any new data or a
per-user model.

TWO-STAGE DESIGN, deliberately:
  1. compute_base_thresholds() -- OFFLINE, run once after training, needs the
     full training dataframe. Not something an API request can afford to
     recompute on every call.
  2. get_alert_thresholds() -- RUNTIME, called per-request. Needs only the
     precomputed base thresholds (loaded from disk) and the user's sensitivity
     choice. This is the function matching the interface contract already
     sent to whoever picks up US1.3 -- see the docstring on get_alert_thresholds
     for the exact contract.

THIS IS THE INTENDED SWAP POINT FOR US1.3. Whoever builds US1.3 can either:
  (a) adopt this file as-is / extend SENSITIVITY_MULTIPLIERS, or
  (b) replace get_alert_thresholds() entirely with their own logic, as long
      as the new version matches the same signature and return contract.
Nothing else in the pipeline (rf_explain.py, run_models_validated.py) needs
to change either way -- they only ever call get_alert_thresholds().
"""

from __future__ import annotations
import json
from pathlib import Path
import pandas as pd

from evaluate import sensor_alert_threshold


# Interim sensitivity levels. US1.3 can change these values, add levels, or
# replace the whole lookup with a continuous 0.0-1.0 slider -- as long as
# whatever replaces this still resolves to a single float multiplier (or a
# single float threshold directly) per sensor at call time.
SENSITIVITY_MULTIPLIERS = {
    "cautious": 0.7,   # alerts earlier -- more conservative, more false alarms tolerated
    "default": 1.0,    # current behaviour, unchanged from the original placeholder
    "relaxed": 1.3,    # alerts later -- only genuinely busy hours trigger
}


def compute_base_thresholds(train_df: pd.DataFrame, quantile: float = 0.75) -> pd.Series:
    """
    OFFLINE step. Thin wrapper around evaluate.py's existing
    sensor_alert_threshold() -- kept separate so the "compute once from
    training data" step is clearly distinct from the "apply per request"
    step below.
    """
    return sensor_alert_threshold(train_df, quantile=quantile)


def save_base_thresholds(base_thresholds: pd.Series, path: str) -> None:
    """Persist base thresholds so serving code never needs train_df in memory."""
    Path(path).write_text(json.dumps({int(k): float(v) for k, v in base_thresholds.items()}))


def load_base_thresholds(path: str) -> dict[int, float]:
    return {int(k): float(v) for k, v in json.loads(Path(path).read_text()).items()}


def get_alert_thresholds(
    sensor_ids: list[int],
    user_context: dict | None = None,
    base_thresholds: dict[int, float] | None = None,
) -> dict[int, float]:
    """
    RUNTIME step -- THE INTERFACE CONTRACT for US1.3 integration.

    Signature, input/output types, and edge-case behaviour are FIXED (per
    the spec already sent to whoever picks up US1.3):
      - sensor_ids: list[int], matching location_id (never display_name).
      - user_context: optional dict. This implementation reads
        user_context.get("sensitivity"), one of "cautious"/"default"/"relaxed",
        defaulting to "default" if absent or unrecognised. US1.3 is free to
        read additional/different keys from user_context (e.g. a continuous
        0.0-1.0 value) as long as the return type below doesn't change.
      - Returns: dict[int, float], sensor_id -> threshold in raw
        pedestrians/hour (same units as target_count -- no rescaling).
      - A sensor with no base threshold available returns None for that
        sensor's value, NEVER 0 or NaN -- callers already treat None as
        "skip the alert flag," and 0 would cause a false alert on every
        forecast for that sensor.

    base_thresholds defaults to loading the interim 75th-percentile table if
    not supplied -- callers should normally pass it explicitly (loaded once
    at service startup via load_base_thresholds()) rather than re-loading
    per request.
    """
    if base_thresholds is None:
        raise ValueError(
            "base_thresholds must be supplied (load once via load_base_thresholds() "
            "at service startup) -- recomputing from train_df on every request isn't viable."
        )

    sensitivity = "default"
    if user_context is not None:
        sensitivity = user_context.get("sensitivity", "default")
    multiplier = SENSITIVITY_MULTIPLIERS.get(sensitivity, 1.0)

    result = {}
    for sid in sensor_ids:
        base = base_thresholds.get(sid)
        result[sid] = None if base is None else round(base * multiplier, 1)
    return result


if __name__ == "__main__":
    # smoke-test / demo against the real pipeline
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "features"))  # load_validated_data.py lives here
    from load_validated_data import load_pedestrian_data, time_ordered_split
    from run_models_validated import DATA_PATH, TRAIN_END, TEST_START

    df = load_pedestrian_data(DATA_PATH)
    train, _ = time_ordered_split(df, TRAIN_END, TEST_START)

    base = compute_base_thresholds(train)
    example_ids = [161, 41]  # Birrarung Marr COM Pole 1109, Flinders La-Swanston St (West)

    print("Base (default) thresholds:", {sid: round(base.get(sid), 1) for sid in example_ids})

    base_dict = {int(k): float(v) for k, v in base.items()}
    for sensitivity in ["cautious", "default", "relaxed"]:
        thresholds = get_alert_thresholds(example_ids, {"sensitivity": sensitivity}, base_dict)
        print(f"  sensitivity={sensitivity}: {thresholds}")
