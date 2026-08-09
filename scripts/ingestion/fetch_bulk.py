#!/usr/bin/env python3
"""Bulk download the FULL datasets for model training. No 10,000-row cap.

WHY THIS EXISTS
    fetch_to_db.py uses the /records endpoint, which Opendatasoft caps at
    offset 10,000. That is fine for a demo, useless for training a forecaster.
    This script uses the /exports endpoint instead, which streams the entire
    dataset -- all 1.6M+ hourly rows.

HOW IT WORKS
    1. Streams the dataset as CSV to ./archive/  (this is also your "raw
       downloads, monthly archive" evidence for the DMP)
    2. Creates a staging table with one TEXT column per CSV header field
    3. COPYs the file in -- PostgreSQL's bulk loader, orders of magnitude
       faster than row-by-row INSERTs
    4. sql/10_load_bulk.sql then transforms staging into the clean tables

    Nothing is parsed in Python. A malformed value cannot crash the load; it
    lands in staging as text and gets handled by the same SQL cleaning rules
    used everywhere else.

USAGE
    pip3 install requests psycopg2-binary

    export DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/onboarding_project"

    # everything since 2020 -- about 1.1M rows, recommended starting point
    python3 fetch_bulk.py --dataset hourly --where "sensing_date>=date'2020-01-01'"

    # absolutely everything, 2009 to now (~1.6M rows, several hundred MB)
    python3 fetch_bulk.py --dataset hourly

    # the minute feed (rolling window, ~200k rows)
    python3 fetch_bulk.py --dataset minute

    # reuse a file you already downloaded, skip the network
    python3 fetch_bulk.py --dataset hourly --from-file archive/hourly_2026....csv

THEN
    Run sql/10_load_bulk.sql in pgAdmin.

FILTER SYNTAX (ODSQL, for --where)
    sensing_date>=date'2020-01-01'
    sensing_date>=date'2024-01-01' AND sensing_date<date'2025-01-01'
    location_id IN (1,2,3)
"""
from __future__ import annotations

import argparse
import csv
import os
import sys
import time
from datetime import datetime

try:
    import requests
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")

try:
    import psycopg2
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")


API_BASE = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"

DATASETS = {
    "sensors":   ("pedestrian-counting-system-sensor-locations",   "stg_bulk_sensors"),
    "minute":    ("pedestrian-counting-system-past-hour-counts-per-minute",
                                                                   "stg_bulk_minute"),
    "hourly":    ("pedestrian-counting-system-monthly-counts-per-hour",
                                                                   "stg_bulk_hourly"),
    "landmarks": ("landmarks-and-places-of-interest-including-schools-"
                  "theatres-health-services-spor",                 "stg_bulk_landmarks"),
}

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/onboarding_project")
ARCHIVE_DIR = os.environ.get("ARCHIVE_DIR", "./archive")

# Connect timeout stays short; read timeout is generous because the server
# spends a long time generating a 1.6M-row export before the first byte.
CONNECT_TIMEOUT, READ_TIMEOUT = 30, 900


def human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def download(dataset_id: str, key: str, where: str | None) -> str:
    """Stream the export to disk. Returns the file path."""
    os.makedirs(ARCHIVE_DIR, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%dT%H%M%S")
    path = os.path.join(ARCHIVE_DIR, f"{key}_{stamp}.csv")

    params = {"delimiter": ",", "with_bom": "false", "use_labels": "false"}
    if where:
        params["where"] = where

    url = f"{API_BASE}/{dataset_id}/exports/csv"
    print(f"    requesting export (the server may take a minute to start)...")

    with requests.get(url, params=params, stream=True,
                      timeout=(CONNECT_TIMEOUT, READ_TIMEOUT)) as r:
        if r.status_code == 400:
            raise RuntimeError(
                f"Rejected (400). Usually a bad --where filter.\n"
                f"    Server said: {r.text[:300]}")
        r.raise_for_status()

        written = 0
        last_report = time.time()
        with open(path, "wb") as fh:
            for chunk in r.iter_content(chunk_size=1 << 20):
                if not chunk:
                    continue
                fh.write(chunk)
                written += len(chunk)
                if time.time() - last_report > 1.0:
                    print(f"    downloaded {human(written)}", end="\r", flush=True)
                    last_report = time.time()

    print(f"    downloaded {human(written)} -> {path}")
    if written < 100:
        raise RuntimeError("Export is empty. Check the --where filter.")
    return path


def read_header(path: str) -> list[str]:
    with open(path, newline="", encoding="utf-8-sig") as fh:
        header = next(csv.reader(fh))
    cleaned = []
    for i, col in enumerate(header):
        name = col.strip().lower().replace(" ", "_").replace("-", "_")
        name = "".join(c for c in name if c.isalnum() or c == "_")
        cleaned.append(name or f"col_{i}")
    return cleaned


def load(conn, table: str, path: str, columns: list[str]) -> int:
    """Create the staging table and COPY the file into it."""
    cols_ddl = ",\n    ".join(f'"{c}" TEXT' for c in columns)
    with conn.cursor() as cur:
        cur.execute("SET search_path TO hush, public")
        cur.execute(f"DROP TABLE IF EXISTS {table}")
        cur.execute(f"CREATE TABLE {table} (\n    {cols_ddl}\n)")
        conn.commit()

        print("    copying into PostgreSQL...")
        with open(path, "r", encoding="utf-8-sig") as fh:
            cur.copy_expert(
                f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", fh)
        conn.commit()

        cur.execute(f"SELECT COUNT(*) FROM {table}")
        return cur.fetchone()[0]


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dataset", required=True, choices=list(DATASETS))
    ap.add_argument("--where", default=None,
                    help="ODSQL filter, e.g. \"sensing_date>=date'2020-01-01'\"")
    ap.add_argument("--from-file", default=None,
                    help="skip the download, load this CSV instead")
    args = ap.parse_args()

    dataset_id, table = DATASETS[args.dataset]
    print(f"\n[{args.dataset}] {dataset_id}")
    if args.where:
        print(f"    filter: {args.where}")

    try:
        path = args.from_file or download(dataset_id, args.dataset, args.where)
    except Exception as exc:                           # noqa: BLE001
        print(f"    !! download failed: {exc}")
        return 1

    columns = read_header(path)
    print(f"    columns: {', '.join(columns)}")

    try:
        conn = psycopg2.connect(DATABASE_URL)
    except Exception as exc:                           # noqa: BLE001
        print(f"    !! cannot connect to PostgreSQL: {exc}")
        print(f"    DATABASE_URL is: {DATABASE_URL}")
        return 1

    try:
        n = load(conn, table, path, columns)
        print(f"    staged {n:,} rows in hush.{table}")
    except Exception as exc:                           # noqa: BLE001
        print(f"    !! load failed: {exc}")
        conn.rollback()
        return 1
    finally:
        conn.close()

    print("\nDone. Next step:")
    print("  Run sql/10_load_bulk.sql in pgAdmin to transform staging into")
    print("  pedestrian_hour_count / pedestrian_minute_count.")
    print(f"\n  The raw file is kept at {path} -- that is your")
    print("  'raw downloads, monthly archive' evidence for the DMP.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
