"""
place_resolver.py

Two real problems from geocode_stress_test.py, solved here:
  1. Known local nicknames that Nominatim doesn't recognize at all
     (e.g. "Vic Market" -> no match) -- fixed via a small alias dictionary.
  2. Typos that Nominatim has near-zero tolerance for (e.g. "Flinders St
     Staton" -> no match) -- fixed via fuzzy string matching against the
     same known vocabulary.

WHAT THIS IS: the suggestion LOGIC -- given a typed query, what should we
resolve it to, or what should we suggest? This is real backend work, not
a placeholder.

WHAT THIS IS NOT: a live "suggestions appear as you type" popup UI. That's
a frontend component that would call resolve_place_name() (or an API
wrapping it) on each search submission and render whatever it returns as
a clickable list -- the UI itself isn't built here.

DESIGN PRINCIPLE, consistent with the rest of this project: never
silently guess. A fuzzy match is offered as a SUGGESTION for the user to
confirm, never auto-substituted and geocoded without them choosing it --
same "don't guess, surface uncertainty" instinct as the Unknown/confidence
logic in route_scoring.py.
"""

from __future__ import annotations

import difflib

MIN_SUBSTRING_MATCH_LEN = 4  # per instruction: at least 4 characters to "connect"

# Canonical name -> known aliases/nicknames people actually type.
# The canonical name itself doesn't need to be listed as an alias --
# it's included automatically below.
KNOWN_PLACES: dict[str, list[str]] = {
    "Flinders Street Station": ["flinders st station", "flinders station"],
    "State Library Victoria": ["state library", "the library", "slv"],
    "Melbourne Central": ["melb central"],
    "Southern Cross Station": ["southern cross", "spencer street station"],
    "Queen Victoria Market": ["vic market", "queen vic market", "the market"],
    "QV Melbourne": ["qv"],
    "Bourke Street Mall": ["bourke st mall", "the mall"],
    "Federation Square": ["fed square", "fed sq"],
    "Melbourne Town Hall": ["town hall"],
    "Chinatown Melbourne": ["chinatown"],
    "Royal Melbourne Institute of Technology": ["rmit"],
    "Parliament Station": ["parliament"],
    "Melbourne Museum": ["museum", "melb museum"],
    "Royal Botanic Gardens Victoria": ["botanic gardens", "botanical gardens"],
    "Melbourne Cricket Ground": ["mcg", "the g"],
    "Crown Melbourne": ["crown casino", "crown"],
    "National Gallery of Victoria": ["ngv", "national gallery"],
    "Arts Centre Melbourne": ["arts centre", "the arts centre"],
    "Eureka Skydeck": ["eureka tower", "eureka"],
    "Marvel Stadium": ["docklands stadium", "etihad stadium"],
    "University of Melbourne": ["unimelb", "melbourne uni"],
    "Emporium Melbourne": ["emporium"],
    "Melbourne Convention and Exhibition Centre": ["mcec", "convention centre"],
    "South Melbourne Market": ["sth melb market"],
    "Old Melbourne Gaol": ["the gaol", "old gaol"],
    "St Paul's Cathedral Melbourne": ["st pauls", "st paul's"],
    "St Patrick's Cathedral Melbourne": ["st patricks", "st patrick's"],
    "Her Majesty's Theatre Melbourne": ["her majestys", "her majesty's"],
    "Regent Theatre Melbourne": ["the regent"],
    "Princess Theatre Melbourne": ["the princess theatre"],
    "Hosier Lane": ["hosier"],
    "SEA LIFE Melbourne Aquarium": ["melbourne aquarium", "sea life"],
    "Docklands": ["the docks"],
    "South Wharf": ["dfo south wharf", "south wharf dfo"],
    "Flagstaff Station": ["flagstaff"],
}

# Flat lookup: every alias AND every canonical name, lowercased, ->
# canonical name. This is the vocabulary fuzzy matching searches against.
_ALIAS_TO_CANONICAL: dict[str, str] = {}
for canonical, aliases in KNOWN_PLACES.items():
    _ALIAS_TO_CANONICAL[canonical.lower()] = canonical
    for alias in aliases:
        _ALIAS_TO_CANONICAL[alias.lower()] = canonical

_VOCABULARY = list(_ALIAS_TO_CANONICAL.keys())


def resolve_place_name(query: str, cutoff: float = 0.6, max_suggestions: int = 3):
    """
    Resolves a typed query against the known-places dictionary, in three
    layers:

      1. EXACT match (case-insensitive, alias or canonical) -- confident,
         resolves directly.

      2. SUBSTRING match (query is at least MIN_SUBSTRING_MATCH_LEN
         characters and appears as a chunk inside a known name) -- the
         "autocomplete" case, e.g. "flin" while someone is still typing
         "Flinders Street Station". If the substring is UNAMBIGUOUS
         (matches only one distinct place), that's confident enough to
         resolve directly -- typing a distinctive fragment of a unique
         name is a strong signal, not a guess. If it's AMBIGUOUS (matches
         several different places -- e.g. "station" matching Flinders
         Street, Southern Cross, AND Parliament stations), returns all of
         them as suggestions rather than arbitrarily picking one.

      3. TYPO match (edit-distance based fuzzy matching, via difflib) --
         only tried if nothing matched as a substring at all. Always
         returned as suggestions, never auto-resolved -- a typo could
         plausibly be a different intended place, so the user confirms.

    Returns (canonical_name, suggestions):
      - Confident match (layer 1, or unambiguous layer 2): (name, [])
      - Ambiguous or typo match: (None, [suggestion1, ...])
      - Nothing found at all: (None, []) -- caller should fall back to
        geocoding the raw text directly (handles real places not in this
        curated dictionary; most official names work fine on their own).
    """
    normalized = query.strip().lower()
    if not normalized:
        return None, []

    # Layer 1: exact match
    if normalized in _ALIAS_TO_CANONICAL:
        return _ALIAS_TO_CANONICAL[normalized], []

    # Layer 2: substring match (autocomplete-style partial typing)
    if len(normalized) >= MIN_SUBSTRING_MATCH_LEN:
        substring_matches = []
        for vocab_entry, canonical in _ALIAS_TO_CANONICAL.items():
            if normalized in vocab_entry or vocab_entry in normalized:
                if canonical not in substring_matches:
                    substring_matches.append(canonical)

        if len(substring_matches) == 1:
            return substring_matches[0], []  # unambiguous -- confident enough to resolve
        if len(substring_matches) > 1:
            return None, substring_matches[:max_suggestions]  # ambiguous -- ask the user

    # Layer 3: typo-tolerant fuzzy match, only reached if no substring matched at all
    close = difflib.get_close_matches(normalized, _VOCABULARY, n=max_suggestions, cutoff=cutoff)
    if close:
        # de-duplicate canonical names (multiple aliases of the same place
        # could all fuzzy-match) while preserving match-quality order
        seen = []
        for match in close:
            canonical = _ALIAS_TO_CANONICAL[match]
            if canonical not in seen:
                seen.append(canonical)
        return None, seen

    return None, []