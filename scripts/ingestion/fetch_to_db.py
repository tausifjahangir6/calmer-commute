#!/usr/bin/env python3
"""Fetch City of Melbourne open data straight into PostgreSQL. No CSV files.

This script is deliberately dumb: it pulls JSON from the API and drops each
record, untouched, into hush.raw_ingest as JSONB. All cleaning and mapping
happens afterwards in sql/07_load_from_raw.sql, where you can read it.

That split is the point. Because the raw JSON lands in the database first,
you can ask PostgreSQL what fields actually exist instead of trusting a guess.

USAGE
    pip3 install requests psycopg2-binary

    export DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/onboarding_project"

    python3 fetch_to_db.py --list                    # show dataset keys
    python3 fetch_to_db.py --probe                   # print field names, load nothing
    python3 fetch_to_db.py --all --max-records 500   # smoke test
    python3 fetch_to_db.py --all                     # full pull
    python3 fetch_to_db.py --datasets hourly minute  # just the count datasets

NOTE: in zsh, do NOT put "# comments" after a command -- zsh passes them
through as arguments and argparse rejects them.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time

try:
    import requests
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")

try:
    import psycopg2
    from psycopg2.extras import Json, execute_values
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")


API_BASE = "https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
PAGE_LIMIT = 100        # Opendatasoft caps `limit` at 100 per request
MAX_OFFSET = 10_000     # ODS refuses offset+limit beyond this
TIMEOUT = 30
RETRIES = 4

DATASETS = {
    "sensors":   "pedestrian-counting-system-sensor-locations",
    "minute":    "pedestrian-counting-system-past-hour-counts-per-minute",
    "hourly":    "pedestrian-counting-system-monthly-counts-per-hour",
    "landmarks": ("landmarks-and-places-of-interest-including-schools-"
                  "theatres-health-services-spor"),
}

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/onboarding_project")


def get(url: str, params: dict) -> dict:
    """GET with exponential backoff and a readable error on failure."""
    last = None
    for attempt in range(RETRIES):
        try:
            r = requests.get(url, params=params, timeout=TIMEOUT,
                             headers={"Accept": "application/json"})
            if r.status_code == 429:
                wait = int(r.headers.get("Retry-After", 2 ** attempt))
                print(f"    rate limited, waiting {wait}s")
                time.sleep(wait)
                continue
            if r.status_code == 404:
                raise RuntimeError(
                    "Dataset not found (404). The ID may have changed. Open the "
                    "dataset page and copy the value under 'Dataset Identifier'.")
            r.raise_for_status()
            return r.json()
        except Exception as exc:                       # noqa: BLE001
            last = exc
            if attempt < RETRIES - 1:
                time.sleep(2 ** attempt)
    raise RuntimeError(f"Failed after {RETRIES} attempts: {last}")


def probe(key: str, dataset_id: str) -> None:
    """Print the field names the API is serving right now."""
    data = get(f"{API_BASE}/{dataset_id}/records", {"limit": 1})
    results = data.get("results", [])
    print(f"\n=== {key} ===")
    print(f"    dataset : {dataset_id}")
    print(f"    records : {data.get('total_count', '?')}")
    if not results:
        print("    !! no records returned")
        return
    print("    fields  :")
    for k, v in sorted(results[0].items()):
        print(f"        {k:26} = {json.dumps(v)[:60] if v is not None else 'null'}")


def fetch(dataset_id: str, max_records: int | None) -> list[dict]:
    records: list[dict] = []
    offset = 0
    while True:
        payload = get(f"{API_BASE}/{dataset_id}/records",
                      {"limit": PAGE_LIMIT, "offset": offset})
        batch = payload.get("results", [])
        records.extend(batch)
        total = payload.get("total_count", len(records))
        offset += PAGE_LIMIT
        print(f"    {len(records)} / {total}", end="\r", flush=True)

        if not batch or len(records) >= total:
            break
        if max_records and len(records) >= max_records:
            records = records[:max_records]
            break
        if offset >= MAX_OFFSET:
            print(f"\n    note: stopped at the API's {MAX_OFFSET}-row offset "
                  f"ceiling -- plenty for this assignment.")
            break
    print(f"    fetched {len(records)} records          ")
    return records


def store(conn, dataset_id: str, records: list[dict]) -> None:
    """Insert raw JSON, replacing any previous pull of the same dataset."""
    with conn.cursor() as cur:
        cur.execute("SET search_path TO hush, public")
        cur.execute("DELETE FROM raw_ingest WHERE dataset_id = %s", (dataset_id,))
        execute_values(
            cur,
            "INSERT INTO raw_ingest (dataset_id, payload, source_url) VALUES %s",
            [(dataset_id, Json(r), f"{API_BASE}/{dataset_id}/records")
             for r in records],
            page_size=500)
    conn.commit()
    print(f"    stored {len(records)} rows in raw_ingest")


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--datasets", nargs="+", choices=list(DATASETS))
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--probe", action="store_true",
                    help="print field names only, write nothing")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--max-records", type=int, default=None)
    args = ap.parse_args()

    if args.list:
        for k, v in DATASETS.items():
            print(f"  {k:10} {v}")
        return 0

    keys = list(DATASETS) if (args.all or args.probe) else (args.datasets or [])
    if not keys:
        ap.error("give --datasets, --all, --probe or --list")

    if args.probe:
        for key in keys:
            try:
                probe(key, DATASETS[key])
            except Exception as exc:                   # noqa: BLE001
                print(f"\n=== {key} ===\n    !! {exc}")
        print("\nPaste this into Appendix A of your report -- it is your "
              "evidence that you inspected the sources.")
        return 0

    # sensors must load before the count datasets (foreign keys)
    order = ["sensors", "landmarks", "hourly", "minute"]
    keys.sort(key=order.index)

    try:
        conn = psycopg2.connect(DATABASE_URL)
    except Exception as exc:                           # noqa: BLE001
        print(f"Cannot connect to PostgreSQL: {exc}")
        print(f"DATABASE_URL is currently: {DATABASE_URL}")
        return 1

    failures = 0
    try:
        for key in keys:
            dataset_id = DATASETS[key]
            print(f"\n[{key}] {dataset_id}")
            try:
                records = fetch(dataset_id, args.max_records)
                if not records:
                    print("    !! no records returned -- check the dataset ID")
                    failures += 1
                    continue
                store(conn, dataset_id, records)
            except Exception as exc:                   # noqa: BLE001
                print(f"    !! {exc}")
                conn.rollback()
                failures += 1
    finally:
        conn.close()

    print("\nDone. Next step:")
    print("  Run sql/07_load_from_raw.sql in pgAdmin to clean and load "
          "raw_ingest into your normalised tables.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
