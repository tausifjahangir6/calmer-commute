#!/usr/bin/env python3
"""Export the model-ready feature table to a compressed CSV for your ML team.

WHY NOT JUST USE pgAdmin's DOWNLOAD BUTTON
    It loads all 1.59M rows into the browser first. It will either crawl or
    run out of memory. This streams straight from PostgreSQL to a gzipped
    file using COPY -- constant memory, a few seconds, ~8:1 compression.

USAGE
    export DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/onboarding_project"

    python3 export_training_data.py                      # full feature set
    python3 export_training_data.py --from 2025-01-01    # recent data only
    python3 export_training_data.py --cbd-only           # CBD sensors only
    python3 export_training_data.py --no-compress        # plain .csv

OUTPUT
    exports/training_<range>_<date>.csv.gz

    The filename records the date range and filters, so nobody on your team
    ends up training on a mystery file.
"""
from __future__ import annotations

import argparse
import gzip
import os
import sys
from datetime import datetime

try:
    import psycopg2
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install psycopg2-binary")

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/onboarding_project")
EXPORT_DIR = os.environ.get("EXPORT_DIR", "./exports")


def human(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--from", dest="date_from", default=None,
                    help="earliest sensing_date, e.g. 2025-01-01")
    ap.add_argument("--to", dest="date_to", default=None,
                    help="latest sensing_date, e.g. 2026-06-30")
    ap.add_argument("--cbd-only", action="store_true",
                    help="restrict to sensors inside the CBD bounding box")
    ap.add_argument("--no-compress", action="store_true")
    args = ap.parse_args()

    # mv_model_features already excludes rows with NULL lags, so no warm-up
    # filter is needed here.
    where: list[str] = []
    label = []
    if args.date_from:
        where.append(f"sensing_date >= DATE '{args.date_from}'")
        label.append(args.date_from)
    if args.date_to:
        where.append(f"sensing_date <= DATE '{args.date_to}'")
        label.append(args.date_to)
    if args.cbd_only:
        where.append("is_cbd")
        label.append("cbd")

    # Prefer the materialised view: the plain view does two self-joins over
    # 1.59M rows and recomputes them on every read.
    source = "hush.mv_model_features"
    sql = f"SELECT * FROM {source}"
    if where:
        sql += " WHERE " + " AND ".join(where)
    sql += " ORDER BY location_id, sensing_date, hour_day"

    os.makedirs(EXPORT_DIR, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d")
    name = "training_" + ("_".join(label) + "_" if label else "") + stamp + ".csv"
    path = os.path.join(EXPORT_DIR, name + ("" if args.no_compress else ".gz"))

    print(f"Query : {sql}")
    print(f"Output: {path}")

    try:
        conn = psycopg2.connect(DATABASE_URL)
    except Exception as exc:                           # noqa: BLE001
        print(f"!! cannot connect: {exc}")
        print(f"   DATABASE_URL is: {DATABASE_URL}")
        return 1

    try:
        with conn.cursor() as cur:
            cur.execute(f"SELECT COUNT(*) FROM ({sql}) q")
            n = cur.fetchone()[0]
            print(f"Rows  : {n:,}")
            if n == 0:
                print("!! no rows matched -- check your filters")
                return 1

            copy_sql = f"COPY ({sql}) TO STDOUT WITH (FORMAT csv, HEADER true)"
            opener = open if args.no_compress else \
                (lambda p, m: gzip.open(p, m, compresslevel=6))
            with opener(path, "wt") as fh:             # type: ignore[operator]
                cur.copy_expert(copy_sql, fh)
    except Exception as exc:                           # noqa: BLE001
        print(f"!! export failed: {exc}")
        return 1
    finally:
        conn.close()

    size = os.path.getsize(path)
    print(f"Size  : {human(size)}")
    print("\nShare via Google Drive or OneDrive -- do NOT commit this to GitHub.")
    print("Read it in pandas with:")
    print(f"    df = pd.read_csv('{os.path.basename(path)}')"
          "   # pandas decompresses .gz automatically")
    return 0


if __name__ == "__main__":
    sys.exit(main())
