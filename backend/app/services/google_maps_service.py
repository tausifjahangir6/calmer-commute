"""Google Routes and Places adapters used only when live mode is enabled."""

import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from ..errors import ApiError


def generate_candidate_routes(request_data: dict, config: dict) -> list[dict]:
    """Return normalised Google routes without applying sensory scoring."""

    origin = _waypoint(request_data["origin"], request_data.get("origin_coordinates"))
    destination = _waypoint(request_data["destination"], request_data.get("destination_coordinates"))
    body = {
        "origin": origin,
        "destination": destination,
        "travelMode": "TRANSIT",
        "computeAlternativeRoutes": bool(config["GOOGLE_ROUTE_ALTERNATIVES"]),
        "languageCode": "en-AU",
        "units": "METRIC",
    }
    if request_data.get("departure_time"):
        body["departureTime"] = request_data["departure_time"]

    response = _post_json(
        config["GOOGLE_ROUTES_URL"],
        body,
        config,
        field_mask="routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs",
    )
    return [_normalise_route(route, index + 1) for index, route in enumerate(response.get("routes", []))]


def search_nearby_refuges(latitude: float, longitude: float, limit: int, config: dict) -> list[dict]:
    """Return candidate places near the selected route arrival point."""

    body = {
        "includedTypes": list(config["GOOGLE_PLACE_TYPES"]),
        "maxResultCount": limit,
        "locationRestriction": {
            "circle": {
                "center": {"latitude": latitude, "longitude": longitude},
                "radius": float(config["GOOGLE_PLACES_RADIUS_METRES"]),
            }
        },
        "rankPreference": "DISTANCE",
        "languageCode": "en",
        "regionCode": "AU",
    }
    response = _post_json(
        config["GOOGLE_PLACES_URL"],
        body,
        config,
        field_mask="places.id,places.displayName,places.primaryType,places.location,places.formattedAddress",
    )
    return [_normalise_place(place) for place in response.get("places", [])]


def autocomplete_places(query: str, config: dict, session_token: str | None = None) -> list[dict]:
    """Return Melbourne-focused address/place suggestions for the frontend search box."""

    body = {
        "input": query,
        "includedRegionCodes": ["au"],
        "languageCode": "en-AU",
        "regionCode": "AU",
        "locationBias": {
            "circle": {
                "center": {"latitude": -37.8136, "longitude": 144.9631},
                "radius": 50000.0,
            }
        },
    }
    if session_token:
        body["sessionToken"] = session_token
    url = "https://places.googleapis.com/v1/places:autocomplete"
    response = _post_json(url, body, config)
    suggestions = []
    for item in response.get("suggestions", []):
        prediction = item.get("placePrediction", {})
        text = prediction.get("text", {}).get("text")
        place_id = prediction.get("placeId")
        if text and place_id:
            suggestions.append({"place_id": place_id, "description": text})
    return suggestions


def _waypoint(address: str, coordinates: dict | None) -> dict:
    if coordinates:
        return {"location": {"latLng": coordinates}}
    return {"address": address}


def _normalise_route(route: dict, route_number: int) -> dict:
    duration_seconds = int(str(route.get("duration", "0s")).removesuffix("s") or 0)
    return {
        "route_id": f"route-{route_number}",
        "duration_minutes": max(1, round(duration_seconds / 60)),
        "distance_metres": route.get("distanceMeters", 0),
        "legs": route.get("legs", []),
        "geometry": {"encoding": "google_encoded_polyline", "value": route.get("polyline", {}).get("encodedPolyline", "")},
    }


def _normalise_place(place: dict) -> dict:
    location = place.get("location", {})
    return {
        "refuge_id": place.get("id"),
        "name": place.get("displayName", {}).get("text", "Unnamed candidate"),
        "type": place.get("primaryType", "place"),
        "latitude": location.get("latitude"),
        "longitude": location.get("longitude"),
        "address": place.get("formattedAddress"),
    }


def _post_json(url: str, body: dict, config: dict, field_mask: str | None = None) -> dict:
    api_key = config.get("GOOGLE_MAPS_API_KEY", "")
    if not api_key:
        raise ApiError("Google Maps integration is not configured.", 503, "provider_unavailable")
    headers = {"Content-Type": "application/json", "X-Goog-Api-Key": api_key}
    if field_mask:
        headers["X-Goog-FieldMask"] = field_mask
    request = Request(url, data=json.dumps(body).encode("utf-8"), headers=headers, method="POST")
    try:
        with urlopen(request, timeout=config["GOOGLE_API_TIMEOUT_SECONDS"]) as response:
            return json.loads(response.read().decode("utf-8"))
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise ApiError(
            "The map provider is temporarily unavailable.",
            503,
            "provider_unavailable",
        ) from error
