"""
geocode_stress_test.py

RUN THIS LOCALLY (needs real internet access for geocoding).

Tests geocode_place() against realistic messy input -- not just the one
clean example that worked. Categories tested:
  1. Clear, official names (should work reliably)
  2. Ambiguous/generic short names (may match the wrong place, or the
     right one -- worth seeing which)
  3. Local colloquial names people actually type instead of official ones
  4. Misspellings (should either fail cleanly or still find the right
     place -- Nominatim has some typo tolerance, worth seeing how much)
  5. Nonsense / empty input (must fail cleanly, never crash)

For entries where we know roughly where the answer SHOULD be, this also
reports the distance between the geocoded result and that expected point,
so a "technically returned coordinates" success can still be flagged as
probably wrong, not just counted as a pass.

HOW TO RUN:
    python geocode_stress_test.py
"""

from __future__ import annotations

import math

from geocode_route_prototype import geocode_place, LOCATION_CONTEXT


def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


# (query, category, expected_lat_or_None, expected_lon_or_None)
# Expected coordinates are approximate real locations, used only as a
# sanity check on distance -- not exact ground truth.
TEST_CASES = [
    # 1. Clear, official names
    ("Flinders Street Station", "official", -37.8184, 144.9665),
    ("State Library Victoria", "official", -37.8098, 144.9655),
    ("Melbourne Central", "official", -37.8100, 144.9628),
    ("Southern Cross Station", "official", -37.8183, 144.9524),

    # 2. Ambiguous / generic short names
    ("the library", "ambiguous", -37.8098, 144.9655),
    ("the mall", "ambiguous", None, None),
    ("town hall", "ambiguous", -37.8153, 144.9663),
    ("the station", "ambiguous", None, None),
    ("the square", "ambiguous", None, None),

    # 3. Local colloquial names
    ("Vic Market", "colloquial", -37.8076, 144.9568),
    ("QV", "colloquial", -37.8103, 144.9648),
    ("Bourke St Mall", "colloquial", -37.8136, 144.9648),
    ("Fed Square", "colloquial", -37.8180, 144.9691),

    # 4. Misspellings
    ("Flinders St Staton", "misspelled", -37.8184, 144.9665),
    ("Melbern Central", "misspelled", -37.8100, 144.9628),
    ("Souther Cross Staton", "misspelled", -37.8183, 144.9524),

    # 5. Nonsense / empty
    ("asdkjfhaslkdjfh", "nonsense", None, None),
    ("", "empty", None, None),
    ("   ", "whitespace_only", None, None),
]


def main():
    print(f"Location context appended to every query: '{LOCATION_CONTEXT}'\n")
    results = []
    for query, category, exp_lat, exp_lon in TEST_CASES:
        coords = geocode_place(query) if query.strip() else None
        if coords is None:
            print(f"[{category:16}] '{query}' -> NO MATCH")
            results.append({"query": query, "category": category, "status": "no_match"})
            continue

        lat, lon = coords
        line = f"[{category:16}] '{query}' -> ({lat:.4f}, {lon:.4f})"
        status = "matched"
        if exp_lat is not None:
            dist_km = haversine_km(lat, lon, exp_lat, exp_lon)
            line += f"  [{dist_km:.2f}km from expected]"
            if dist_km > 1.0:
                line += "  <-- SUSPICIOUS, far from expected location"
                status = "matched_but_far"
        print(line)
        results.append({"query": query, "category": category, "status": status, "lat": lat, "lon": lon})

    print("\n--- Summary by category ---")
    by_category = {}
    for r in results:
        by_category.setdefault(r["category"], []).append(r["status"])
    for cat, statuses in by_category.items():
        print(f"  {cat}: {len(statuses)} tested -- {statuses}")

    print(
        "\nRead this as: 'official' should be ~all matched cleanly. "
        "'ambiguous'/'colloquial' results are worth eyeballing by hand -- "
        "a 'matched' status doesn't guarantee it's the RIGHT place, only "
        "that Nominatim returned something. 'misspelled' shows how much "
        "typo tolerance you actually get. 'nonsense'/'empty' must all be "
        "no_match -- if any of those return coordinates, that's worth "
        "investigating."
    )


if __name__ == "__main__":
    main()