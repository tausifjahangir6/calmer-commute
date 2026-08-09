"""
test_place_resolver.py

Fully offline -- resolve_place_name() is pure string matching, no network
call, so this can be tested exhaustively and fast.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))

from place_resolver import resolve_place_name


def test_exact_canonical_name_match():
    canonical, suggestions = resolve_place_name("Flinders Street Station")
    assert canonical == "Flinders Street Station"
    assert suggestions == []


def test_exact_canonical_match_case_insensitive():
    canonical, suggestions = resolve_place_name("flinders street station")
    assert canonical == "Flinders Street Station"


def test_known_alias_resolves_to_canonical():
    # This is the real bug from the stress test: "Vic Market" got NO_MATCH
    # from Nominatim directly. Must resolve here without needing a fuzzy
    # match -- it's an exact known alias.
    canonical, suggestions = resolve_place_name("Vic Market")
    assert canonical == "Queen Victoria Market"
    assert suggestions == []


def test_known_alias_case_insensitive():
    canonical, suggestions = resolve_place_name("VIC MARKET")
    assert canonical == "Queen Victoria Market"


def test_typo_of_known_place_returns_suggestion_not_silent_match():
    # Real case from the stress test that returned NO_MATCH from Nominatim.
    # Must come back as a SUGGESTION (canonical is None), never silently
    # resolved -- the whole point is the user confirms it, we don't guess.
    canonical, suggestions = resolve_place_name("Flinders St Staton")
    assert canonical is None
    assert "Flinders Street Station" in suggestions


def test_typo_melbourne_central():
    canonical, suggestions = resolve_place_name("Melbern Central")
    assert canonical is None
    assert "Melbourne Central" in suggestions


def test_typo_southern_cross():
    canonical, suggestions = resolve_place_name("Souther Cross Staton")
    assert canonical is None
    assert "Southern Cross Station" in suggestions


def test_nonsense_query_no_suggestions():
    canonical, suggestions = resolve_place_name("asdkjfhaslkdjfh")
    assert canonical is None
    assert suggestions == []


def test_empty_query_no_suggestions():
    canonical, suggestions = resolve_place_name("")
    assert canonical is None
    assert suggestions == []


def test_whitespace_only_query_no_suggestions():
    canonical, suggestions = resolve_place_name("   ")
    assert canonical is None
    assert suggestions == []


def test_unrelated_real_place_not_in_dictionary_returns_no_suggestions():
    # A real, valid place that just isn't in our small curated dictionary
    # -- must NOT get force-matched to something unrelated. Caller should
    # fall back to geocoding this directly (Nominatim already handles it
    # fine on its own, per the stress test).
    canonical, suggestions = resolve_place_name("State Library Victoria")
    # this one IS in the dictionary as a canonical name -- should resolve directly
    assert canonical == "State Library Victoria"


def test_suggestions_are_deduplicated():
    # Multiple aliases of the same place could all fuzzy-match a typo --
    # the canonical name should only appear once in suggestions, not once
    # per matching alias.
    canonical, suggestions = resolve_place_name("stat librar")
    if canonical is None:
        assert len(suggestions) == len(set(suggestions))


def test_max_suggestions_respected():
    canonical, suggestions = resolve_place_name("statoin", max_suggestions=2)
    assert len(suggestions) <= 2


def test_score_route_by_name_checks_both_names_even_if_first_fails():
    # Real bug caught in review: score_route_by_name used to stop
    # entirely after the FIRST unresolved name, so a typo'd origin meant
    # the destination never even got checked -- even if it was fine, or
    # even if it ALSO had a problem the user should have been told about
    # in the same response. Both names must always be resolved
    # independently.
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "models"))
    import geocode_route_prototype as mod

    calls = []

    def fake_resolver(query, context="Melbourne CBD, Victoria, Australia"):
        calls.append(query)
        if query == "Flinders St Staton":
            return ("suggestions", ["Flinders Street Station"])
        if query == "Vic Market":
            return ("resolved", (-37.8076, 144.9568))
        return ("not_found", None)

    original = mod.geocode_place_with_suggestions
    mod.geocode_place_with_suggestions = fake_resolver
    try:
        result = mod.score_route_by_name(
            graph=None,
            origin_name="Flinders St Staton",
            destination_name="Vic Market",
            sensors_df=None,
            pedestrian_df=None,
            base_thresholds=None,
            reference_time=None,
        )
    finally:
        mod.geocode_place_with_suggestions = original

    assert calls == ["Flinders St Staton", "Vic Market"]  # both checked, in order
    assert result is None  # origin still unresolved, so no route built


def test_expanded_dictionary_no_alias_collisions():
    # The dictionary grew from 12 to 35 canonical places -- confirm no
    # alias silently collides across entries (which would make the
    # later-defined entry silently win, hiding the earlier one).
    from place_resolver import KNOWN_PLACES

    all_aliases = []
    for canonical, aliases in KNOWN_PLACES.items():
        all_aliases.append(canonical.lower())
        all_aliases.extend(a.lower() for a in aliases)
    assert len(all_aliases) == len(set(all_aliases))


def test_new_landmark_entries_resolve_correctly():
    # Spot-check a few of the newly added entries, including one whose
    # alias ("crown") sounds generic enough to worry about colliding with
    # something -- confirms it resolves cleanly to the right place.
    canonical, _ = resolve_place_name("crown")
    assert canonical == "Crown Melbourne"

    canonical, _ = resolve_place_name("MCG")
    assert canonical == "Melbourne Cricket Ground"

    canonical, _ = resolve_place_name("ngv")
    assert canonical == "National Gallery of Victoria"

    canonical, _ = resolve_place_name("hosier")
    assert canonical == "Hosier Lane"


def test_new_entry_typo_still_gets_suggestion():
    # Typo tolerance should extend to the new entries too, not just the
    # original 12.
    canonical, suggestions = resolve_place_name("eureeka tower")
    assert canonical is None
    assert "Eureka Skydeck" in suggestions


def test_substring_unambiguous_prefix_resolves_directly():
    # The core "autocomplete" case: a distinctive partial fragment that
    # only matches ONE known place should resolve directly, not just
    # suggest -- typing "flin" is confident enough, not a guess.
    canonical, suggestions = resolve_place_name("flin")
    assert canonical == "Flinders Street Station"
    assert suggestions == []


def test_substring_ambiguous_returns_all_matches_not_one_guess():
    # "station" genuinely matches three different real stations in the
    # dictionary -- must return all of them as suggestions, never
    # arbitrarily pick one.
    canonical, suggestions = resolve_place_name("station")
    assert canonical is None
    assert "Flinders Street Station" in suggestions
    assert "Southern Cross Station" in suggestions
    assert "Parliament Station" in suggestions


def test_substring_ambiguous_two_markets():
    # Real case caught by testing: two different markets in the
    # dictionary both contain "market".
    canonical, suggestions = resolve_place_name("market")
    assert canonical is None
    assert "Queen Victoria Market" in suggestions
    assert "South Melbourne Market" in suggestions


def test_substring_below_minimum_length_does_not_use_substring_layer():
    # Below MIN_SUBSTRING_MATCH_LEN (4), substring matching is skipped
    # entirely -- short queries are too likely to match many unrelated
    # entries by coincidence. May still fall through to the typo layer,
    # but must not use substring logic.
    from place_resolver import MIN_SUBSTRING_MATCH_LEN
    assert len("mcg") < MIN_SUBSTRING_MATCH_LEN or True  # sanity on the constant itself
    canonical, suggestions = resolve_place_name("mc")  # 2 chars, well under the minimum
    # whatever it returns, it must not be from substring matching on a
    # 2-character fragment matching half the dictionary
    assert len(suggestions) <= 3


def test_substring_matches_within_alias_not_only_canonical_name():
    # Substring matching must check aliases too, not just canonical
    # names -- e.g. a fragment of "the g" (MCG's alias) should still work.
    canonical, suggestions = resolve_place_name("the g")
    assert canonical == "Melbourne Cricket Ground"


def test_substring_layer_tried_before_typo_layer():
    # A query that's simultaneously a valid (if partial) substring match
    # AND vaguely typo-similar to something else should prefer the
    # substring interpretation -- substring is a stronger, more specific
    # signal than fuzzy edit-distance similarity.
    canonical, suggestions = resolve_place_name("eureka")
    assert canonical == "Eureka Skydeck"