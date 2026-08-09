"""Candidate-refuge contract pending a live places and walking-route provider."""

from math import asin, cos, radians, sin, sqrt

from .google_maps_service import search_nearby_refuges


CANDIDATE_REFUGES = (
    {"refuge_id": "city-library", "name": "City Library", "type": "library", "latitude": -37.8175, "longitude": 144.9652},
    {"refuge_id": "state-library", "name": "State Library Victoria", "type": "library", "latitude": -37.8098, "longitude": 144.9652},
    {"refuge_id": "flagstaff-gardens", "name": "Flagstaff Gardens", "type": "park", "latitude": -37.8105, "longitude": 144.9547},
    {"refuge_id": "carlton-gardens", "name": "Carlton Gardens", "type": "park", "latitude": -37.8062, "longitude": 144.9712},
)
AVERAGE_WALKING_METRES_PER_MINUTE = 80.0


def find_candidate_refuges(
    latitude: float,
    longitude: float,
    limit: int,
    provider_config: dict | None = None,
) -> dict:
    """Rank known candidates from the actual arrival coordinates, never a fixed origin."""

    # PLACES/ROUTING REPLACEMENT POINT:
    # 1. Search libraries, parks, museums and community centres around the
    #    supplied arrival coordinates.
    # 2. If typed nearby search returns nothing, run the agreed text-search
    #    fallback around the same point.
    # 3. Deduplicate by provider place ID.
    # 4. Ask the walking-route provider for actual walking distance/time.
    # 5. Return the same public keys used below and retain
    #    verification_status="candidate_not_verified" unless a separate
    #    verification process is established.

    if provider_config and provider_config.get("GOOGLE_INTEGRATION_MODE") == "live":
        candidates = search_nearby_refuges(latitude, longitude, limit, provider_config)
        ranked = []
        for candidate in candidates:
            if candidate["latitude"] is None or candidate["longitude"] is None:
                continue
            distance = _haversine_metres(latitude, longitude, candidate["latitude"], candidate["longitude"])
            ranked.append(
                {
                    **candidate,
                    "distance_metres": round(distance),
                    "walking_minutes": max(1, round(distance / AVERAGE_WALKING_METRES_PER_MINUTE)),
                    "verification_status": "candidate_not_verified",
                }
            )
        ranked.sort(key=lambda item: item["distance_metres"])
        return {
            "arrival": {"latitude": latitude, "longitude": longitude},
            "refuges": ranked[:limit],
            "metadata": {
                "data_mode": "live_places_estimated_walk",
                "walking_time_method": "straight-line estimate",
                "limitation": "Google place candidates are not verified as quiet, sensory-safe, accessible or open.",
            },
        }

    ranked = []
    for candidate in CANDIDATE_REFUGES:
        distance = _haversine_metres(latitude, longitude, candidate["latitude"], candidate["longitude"])
        ranked.append(
            {
                **candidate,
                "distance_metres": round(distance),
                "walking_minutes": max(1, round(distance / AVERAGE_WALKING_METRES_PER_MINUTE)),
                "verification_status": "candidate_not_verified",
            }
        )
    ranked.sort(key=lambda item: item["distance_metres"])
    return {
        "arrival": {"latitude": latitude, "longitude": longitude},
        "refuges": ranked[:limit],
        "metadata": {
            "data_mode": "placeholder",
            "walking_time_method": "straight-line estimate",
            "limitation": "Candidates are not verified as quiet, sensory-safe, accessible or open.",
        },
    }


def _haversine_metres(latitude_a: float, longitude_a: float, latitude_b: float, longitude_b: float) -> float:
    """Estimate straight-line distance for the placeholder only.

    This must not be relabelled as a walking-route distance. The future places
    adapter should replace this estimate with provider walking-route results.
    """
    earth_radius_metres = 6_371_000
    latitude_delta = radians(latitude_b - latitude_a)
    longitude_delta = radians(longitude_b - longitude_a)
    value = sin(latitude_delta / 2) ** 2 + cos(radians(latitude_a)) * cos(radians(latitude_b)) * sin(longitude_delta / 2) ** 2
    return 2 * earth_radius_metres * asin(sqrt(value))
