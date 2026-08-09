"""Live test for the historical-estimate fallback and decommissioned-sensor
check, against a real commute-hour target instead of whatever time it
actually is right now.

_fetch_same_weekday_hour_history() only needs an hour-of-day and a
day-of-week -- it doesn't care about today's actual date -- so this can
query genuinely real historical data for a meaningful time (e.g. Tuesday
5pm) regardless of when this script is actually run.

Usage: python check_historical_fallback.py [hour] [weekday]
  hour: 0-23, defaults to 17 (5pm)
  weekday: 0=Monday .. 6=Sunday, defaults to 1 (Tuesday)

Run from backend/ so `app` resolves the same way pytest does:
  PYTHONPATH=. python check_historical_fallback.py
"""
import sys
from datetime import datetime, timedelta

from app.services import prototype_crowd_service as crowd

target_hour = int(sys.argv[1]) if len(sys.argv) > 1 else 17
target_weekday = int(sys.argv[2]) if len(sys.argv) > 2 else 1

# Only .hour and .weekday() are actually used downstream -- the date
# itself is irrelevant, so any date with the right weekday works.
base = datetime(2026, 8, 4, target_hour, 0, tzinfo=crowd.MELBOURNE_TZ)  # a real Tuesday
while base.weekday() != target_weekday:
    base = base + timedelta(days=1)

weekday_name = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][target_weekday]
print(f"Testing against: {weekday_name} {target_hour:02d}:00 (real historical data, live query)\n")

sample_sensors = crowd.MAP_SENSOR_IDS[:10]

print(f"{'sensor':<8}{'samples (ppm)':<28}{'estimate':<12}{'reliable':<10}{'decommissioned?'}")
for sensor_id in sample_sensors:
    samples = crowd._fetch_same_weekday_hour_history(sensor_id, base, crowd.HISTORICAL_LOOKBACK_WEEKS)
    estimate, reliable = crowd._historical_estimate(sensor_id, base)
    decommissioned = crowd._sensor_appears_decommissioned(sensor_id)
    samples_str = ", ".join(f"{s:.1f}" for s in samples) if samples else "(no data)"
    print(f"{sensor_id:<8}{samples_str:<28}{str(estimate):<12}{str(reliable):<10}{decommissioned}")

print("\nWhat to look for:")
print("- 'samples' should show real, plausible commute-hour counts, not near-zero -- if")
print("  they look like nighttime values, the hour/weekday match may not be working.")
print("- 'reliable' should be True for sensors with reasonably consistent samples across")
print("  the 4 weeks, False for sensors with wildly different readings week to week.")
print("- 'decommissioned' should be False for essentially everything -- True would mean")
print("  a sensor read zero at all 168 checkpoints, which is worth a manual look before")
print("  trusting the flag.")