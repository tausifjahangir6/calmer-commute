#!/usr/bin/env python3
"""Load the Pedestrian Network CSV into hush.stg_network.

The file is ~13MB / 85,326 rows. pgAdmin's importer handles it, but COPY is
faster and won't choke on the BOM the portal writes at the start of the file.

USAGE
    export DATABASE_URL="postgresql://postgres:PASS@localhost:5432/onboarding_project"
    python3 load_network_csv.py --file ~/Downloads/pedestrian-network.csv

Run sql/12_pedestrian_network.sql PART 1 first to create the staging table,
then this, then PARTS 2-6.
"""
from __future__ import annotations

import argparse
import os
import sys

try:
    import psycopg2
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install psycopg2-binary")

DATABASE_URL = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/onboarding_project")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", required=True, help="path to pedestrian-network.csv")
    args = ap.parse_args()

    if not os.path.exists(args.file):
        print(f"!! not found: {args.file}")
        return 1

    # utf-8-sig strips the byte-order mark the portal writes; without it the
    # first column name becomes "﻿Geo Point" and nothing matches.
    with open(args.file, "r", encoding="utf-8-sig") as fh:
        header = fh.readline().strip()
    print(f"header: {header}")
    if "Geo Shape" not in header:
        print("!! unexpected header -- expected: Geo Point,Geo Shape,OBJECTID,NeworkID")
        return 1

    try:
        conn = psycopg2.connect(DATABASE_URL)
    except Exception as exc:                           # noqa: BLE001
        print(f"!! cannot connect: {exc}")
        return 1

    try:
        with conn.cursor() as cur:
            cur.execute("SET search_path TO hush, public")
            cur.execute("SELECT to_regclass('hush.stg_network')")
            if cur.fetchone()[0] is None:
                print("!! hush.stg_network does not exist.")
                print("   Run PART 1 of sql/12_pedestrian_network.sql first.")
                return 1

            cur.execute("TRUNCATE stg_network")
            print("copying...")
            with open(args.file, "r", encoding="utf-8-sig") as fh:
                cur.copy_expert(
                    "COPY stg_network (geo_point, geo_shape, objectid, networkid) "
                    "FROM STDIN WITH (FORMAT csv, HEADER true)", fh)

            cur.execute("""
                SELECT geo_shape::jsonb ->> 'type' AS geom_type, COUNT(*)
                FROM stg_network GROUP BY 1 ORDER BY 2 DESC""")
            rows = cur.fetchall()
        conn.commit()
    except Exception as exc:                           # noqa: BLE001
        print(f"!! load failed: {exc}")
        conn.rollback()
        return 1
    finally:
        conn.close()

    total = sum(n for _, n in rows)
    print(f"\nstaged {total:,} rows:")
    for t, n in rows:
        print(f"    {t or '(null)':12} {n:,}")
    print("\nExpect roughly: LineString 71,060 / Point 14,266")
    print("Next: run PARTS 2-6 of sql/12_pedestrian_network.sql")
    return 0


if __name__ == "__main__":
    sys.exit(main())
