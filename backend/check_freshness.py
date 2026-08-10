"""Standalone freshness check against a running Calmer Commute backend.
Usage: python check_freshness.py [base_url]
Default base_url: http://localhost:5000
"""
import sys
import json
from datetime import datetime, timezone
from urllib.request import urlopen

base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5000"

with urlopen(f"{base_url}/api/crowd", timeout=10) as response:
    payload = json.loads(response.read().decode("utf-8"))

def age_minutes(iso_str):
    if not iso_str:
        return None
    dt = datetime.fromisoformat(str(iso_str).replace("Z", "+00:00"))
    return round((datetime.now(timezone.utc) - dt.astimezone(timezone.utc)).total_seconds() / 60, 1)

top_level_age = age_minutes(payload.get("latestObservation"))
print(f"Top-level dataStatus: {payload.get('dataStatus')}")
print(f"Top-level latestObservation: {payload.get('latestObservation')}  (age: {top_level_age} min)")
print(f"limitation: {payload.get('limitation')}")
print()

sensors = payload.get("mapSensors", [])
by_freshness = {}
for s in sensors:
    by_freshness.setdefault(s.get("freshness"), []).append(s)

print(f"Total mapSensors: {len(sensors)}")
for status, group in sorted(by_freshness.items(), key=lambda kv: -len(kv[1])):
    print(f"  {status}: {len(group)}")

print()
print("Per-sensor age sample (first 10 with a latestObservation):")
shown = 0
for s in sensors:
    if s.get("latestObservation") and shown < 10:
        print(f"  id={s['id']:<4} freshness={s['freshness']:<12} age={age_minutes(s['latestObservation'])} min  operationalStatus={s.get('operationalStatus')}")
        shown += 1