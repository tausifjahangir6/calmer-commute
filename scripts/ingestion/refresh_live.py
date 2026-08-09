#!/usr/bin/env python3
"""Refresh the live minute feed in the hosted Neon serving database.

The only script that writes to production on a schedule. It fetches the City
of Melbourne minute feed and upserts straight into serving.minute_count -- no
staging, because the serving database holds only what the app needs.

CONNECTION
    Reads either DATABASE_URL, or the standard PG* variables you already have
    set (PGHOST / PGUSER / PGPASSWORD / PGDATABASE / PGSSLMODE). If neither is
    present it exits with an explanation rather than a stack trace.

RUN IT ONCE FIRST
    python3 refresh_live.py

THEN SCHEDULE IT
    crontab -e

    PGHOST=ep-lucky-waterfall-a73z113c.ap-southeast-2.aws.neon.tech
    PGUSER=neondb_owner
    PGPASSWORD=your-password
    PGDATABASE=neondb
    PGSSLMODE=require
    */5 * * * * cd /Users/sung/Documents/hush-dmp/etl && /usr/bin/python3 refresh_live.py >> /tmp/calmer_refresh.log 2>&1

    Cron does not inherit your shell environment, so the variables must be set
    inside the crontab. A crontab is not in the repo, which keeps the
    credential off GitHub.

    Check it is working:  tail -f /tmp/calmer_refresh.log

RETENTION
    Rows older than 7 days are deleted each run. The serving database is for
    current conditions; history lives in the local analytics database.
"""
from __future__ import annotations

import os
import sys
from datetime import datetime, timezone

try:
    import requests
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    sys.exit("Missing dependency. Run:  pip3 install requests psycopg2-binary")


API = ("https://data.melbourne.vic.gov.au/api/explore/v2.1/catalog/datasets"
       "/pedestrian-counting-system-past-hour-counts-per-minute/records")
PAGE_LIMIT = 100
MAX_PAGES = 40                     # 4,000 rows is ample for one refresh
RETENTION_DAYS = 7
TIMEOUT = 30

DB_SCHEMA = os.environ.get("DB_SCHEMA", "serving")


def log(msg: str) -> None:
    print(f"{datetime.now(timezone.utc).isoformat(timespec='seconds')} {msg}",
          flush=True)


def connect():
    """Use DATABASE_URL if set, otherwise fall back to the PG* variables."""
    url = os.environ.get("DATABASE_URL")
    if url:
        return psycopg2.connect(url)
    if os.environ.get("PGHOST"):
        return psycopg2.connect()          # libpq reads PG* itself
    sys.exit("No connection settings found.\n"
             "  Set DATABASE_URL, or the PG* variables:\n"
             "    export PGHOST=... PGUSER=... PGPASSWORD=... "
             "PGDATABASE=... PGSSLMODE=require")


def fetch() -> list[dict]:
    """Pull the rolling minute feed, newest first. Stops on a short page."""
    rows: list[dict] = []
    for page in range(MAX_PAGES):
        r = requests.get(API, timeout=TIMEOUT,
                         params={"limit": PAGE_LIMIT,
                                 "offset": page * PAGE_LIMIT,
                                 "order_by": "sensing_datetime DESC"})
        r.raise_for_status()
        batch = r.json().get("results", [])
        rows.extend(batch)
        if len(batch) < PAGE_LIMIT:
            break
    return rows


def to_int(v) -> int | None:
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def shape(records: list[dict]) -> list[tuple]:
    """Map API fields onto serving.minute_count columns.

    Field names confirmed against the live API:
      location_id, sensing_datetime (UTC, +00:00), direction_1,
      direction_2, total_of_directions
    """
    out, seen = [], set()
    for rec in records:
        loc = to_int(rec.get("location_id") or rec.get("sensor_id"))
        ts = rec.get("sensing_datetime")
        if loc is None or not ts:
            continue
        key = (loc, ts)
        if key in seen:                 # the feed re-serves rows across pages
            continue
        seen.add(key)

        d1 = to_int(rec.get("direction_1"))
        d2 = to_int(rec.get("direction_2"))
        total = to_int(rec.get("total_of_directions"))
        if total is None:
            total = (d1 or 0) + (d2 or 0)
        if total < 0:
            continue
        out.append((loc, ts, d1, d2, total))
    return out


def main() -> int:
    try:
        records = fetch()
        log(f"fetched {len(records)} records")
    except Exception as exc:                            # noqa: BLE001
        log(f"ERROR fetching: {exc}")
        return 1

    rows = shape(records)
    if not rows:
        log("ERROR: no usable rows after shaping -- API fields may have changed")
        return 1

    try:
        conn = connect()
    except SystemExit:
        raise
    except Exception as exc:                            # noqa: BLE001
        log(f"ERROR connecting: {exc}")
        return 1

    try:
        with conn.cursor() as cur:
            cur.execute(f"SET search_path TO {DB_SCHEMA}, public")

            # Only sensors present in the serving table. The foreign key would
            # reject the rest anyway; filtering here avoids a failed batch.
            cur.execute("SELECT location_id FROM sensor")
            valid = {r[0] for r in cur.fetchall()}
            rows_ok = [r for r in rows if r[0] in valid]
            skipped = len(rows) - len(rows_ok)

            execute_values(cur, """
                INSERT INTO minute_count
                    (location_id, sensing_datetime, direction_1,
                     direction_2, total_of_direction)
                VALUES %s
                ON CONFLICT (location_id, sensing_datetime) DO UPDATE SET
                    direction_1        = EXCLUDED.direction_1,
                    direction_2        = EXCLUDED.direction_2,
                    total_of_direction = EXCLUDED.total_of_direction
            """, rows_ok, page_size=500)
            written = cur.rowcount

            cur.execute(
                "DELETE FROM minute_count "
                "WHERE sensing_datetime < now() - %s::interval",
                (f"{RETENTION_DAYS} days",))
            pruned = cur.rowcount

            cur.execute("""
                SELECT COUNT(DISTINCT location_id),
                       MAX(sensing_datetime),
                       ROUND(EXTRACT(EPOCH FROM (now() - MAX(sensing_datetime))) / 60)
                FROM minute_count
            """)
            sensors, freshest, age = cur.fetchone()

        conn.commit()
        log(f"upserted {written} | skipped {skipped} unknown sensors | "
            f"pruned {pruned} older than {RETENTION_DAYS}d")
        log(f"live: {sensors} sensors | freshest {freshest} | {age} min old")
        return 0

    except Exception as exc:                            # noqa: BLE001
        conn.rollback()
        log(f"ERROR writing: {exc}")
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
