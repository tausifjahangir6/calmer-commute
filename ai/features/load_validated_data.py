"""
load_validated_data.py
The single swappable data-loading function referenced in the original card
brief. Loads Tausif's validated export and normalizes column names to what
the rest of the pipeline expects (sensor_id, timestamp, count).

GOTCHA (from Tausif's handover notes): his day_of_week column uses
0=Sunday. Pandas' own .dt.dayofweek uses 0=Monday. To avoid confusion we
ignore his column entirely and always derive day-of-week fresh from
obs_ts using pandas' convention — one convention, used everywhere.
"""

import pandas as pd


def load_pedestrian_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)  # pandas auto-handles .csv.gz via extension

    df = df.rename(columns={
        "location_id": "sensor_id",
        "display_name": "sensor_name",
        "target_count": "count",
    })
    df["timestamp"] = pd.to_datetime(df["obs_ts"])
    df["day_of_week"] = df["timestamp"].dt.dayofweek
    df["hour"] = df["timestamp"].dt.hour

   # is_weekend / is_cbd may arrive as 't'/'f' strings (Postgres boolean
    # export) or as 0/1 numbers — handle both explicitly rather than relying
    # on a dtype check, since pandas sometimes reads string columns as its
    # own StringDtype rather than plain 'object', which a naive dtype==object
    # check silently misses.
    def _to_binary(val):
        if isinstance(val, str):
            v = val.strip().lower()
            if v in ("t", "true", "1", "yes"):
                return 1
            if v in ("f", "false", "0", "no"):
                return 0
            return None
        if isinstance(val, bool):
            return int(val)
        if pd.isna(val):
            return None
        return int(val)

    for col in ["is_weekend", "is_cbd"]:
        df[col] = df[col].apply(_to_binary).astype(int)

    df = df.sort_values(["sensor_id", "timestamp"]).reset_index(drop=True)
    return df


def time_ordered_split(df: pd.DataFrame, train_end: str, test_start: str):
    train = df[df["sensing_date"] < train_end].copy()
    test = df[df["sensing_date"] >= test_start].copy()
    print(f"[split] train: {train['timestamp'].min()} -> {train['timestamp'].max()} ({len(train)} rows)")
    print(f"[split] test:  {test['timestamp'].min()} -> {test['timestamp'].max()} ({len(test)} rows)")
    dropped = len(df) - len(train) - len(test)
    if dropped > 0:
        print(f"[split] {dropped} rows in the validation gap excluded from both sets")
    return train, test