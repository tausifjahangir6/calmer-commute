"""HTTP endpoints for the onboarding vertical slice."""

from flask import Blueprint, current_app, jsonify, request

from .errors import ApiError
from .services.prediction_service import get_prediction
from .services.prototype_crowd_service import get_crowd_payload
from .services.google_maps_service import autocomplete_places
from .services.refuge_service import find_candidate_refuges
from .services.route_service import compare_routes
from .services.sensor_service import load_sensor_locations
from .validation import (
    optional_coordinate_pair,
    require_json_object,
    require_non_empty_string,
    validate_coordinates,
    validate_limit,
    validate_search_query,
    validate_threshold,
)


api = Blueprint("api", __name__)


MOCK_PLACE_SUGGESTIONS = (
    {
        "place_id": "mock-freddy-home",
        "description": "903/8 Pearl River Rd, Docklands VIC 3008, Australia",
    },
    {
        "place_id": "mock-freddy-work",
        "description": "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000, Australia",
    },
    {"place_id": "mock-flinders", "description": "Flinders Street Station, Melbourne VIC, Australia"},
    {"place_id": "mock-city-library", "description": "City Library, Flinders Lane, Melbourne VIC, Australia"},
    {"place_id": "mock-docklands", "description": "Docklands VIC, Australia"},
)


@api.get("/health")
def health():
    return jsonify({"status": "healthy", "service": "calmer-commute-backend"})


@api.get("/crowd")
def crowd():
    """Return the deployed prototype's live or DoD replay crowd contract."""
    try:
        return jsonify(get_crowd_payload(request.args.get("scenario")))
    except Exception:
        return jsonify({"ok": False, "dataStatus": "unavailable", "latestObservation": None,
                        "limitation": "The City feed could not be reached. High/Low classifications are withheld.",
                        "routes": {}, "mapSensors": []}), 503


@api.get("/prototype/defaults")
def prototype_defaults():
    """Give the frontend one authoritative source for Freddy's demo journey."""

    return jsonify(
        {
            "origin": current_app.config["DEFAULT_ORIGIN"],
            "destination": current_app.config["DEFAULT_DESTINATION"],
            "commute_window": {
                "days": list(current_app.config["DEFAULT_COMMUTE_DAYS"]),
                "start": current_app.config["DEFAULT_COMMUTE_START"],
                "end": current_app.config["DEFAULT_COMMUTE_END"],
                "timezone": current_app.config["DEFAULT_TIMEZONE"],
            },
            "crowd_threshold": current_app.config["DEFAULT_CROWD_THRESHOLD"],
        }
    )


@api.post("/routes/compare")
def routes_compare():
    """Orchestrate the current prototype route-comparison use case.

    Keep this HTTP layer thin. Each team replaces logic inside the imported
    Python modules; route handlers should not contain data, AI, or scoring
    algorithms. This preserves one Flask process and the agreed import-based
    integration approach.
    """
    payload = require_json_object(request.get_json(silent=True))
    normalised_request = {
        "origin": require_non_empty_string(payload, "origin"),
        "destination": require_non_empty_string(payload, "destination"),
        "origin_coordinates": optional_coordinate_pair(payload, "origin_coordinates"),
        "destination_coordinates": optional_coordinate_pair(payload, "destination_coordinates"),
        "departure_time": payload.get("departure_time"),
        "crowd_threshold": validate_threshold(
            payload.get("crowd_threshold", current_app.config["DEFAULT_CROWD_THRESHOLD"])
        ),
    }
    sensors = load_sensor_locations(str(current_app.config["SENSOR_LOCATIONS_PATH"]))
    observations = None
    if current_app.config.get("GOOGLE_INTEGRATION_MODE") == "live":
        observations = get_crowd_payload().get("mapSensors", [])
    result = compare_routes(
        normalised_request,
        sensors,
        current_app.config["DATA_MODE"],
        provider_config=current_app.config,
        observations=observations,
    )
    return jsonify(result)


@api.get("/refuges")
def refuges():
    """Find candidate refuges from the journey's arrival coordinates."""
    coordinates = validate_coordinates(request.args.get("latitude"), request.args.get("longitude"))
    limit = validate_limit(request.args.get("limit", current_app.config["DEFAULT_REFUGE_LIMIT"]))
    return jsonify(
        find_candidate_refuges(
            coordinates["latitude"],
            coordinates["longitude"],
            limit,
            provider_config=current_app.config,
        )
    )


@api.post("/places/autocomplete")
def places_autocomplete():
    """Supply search-box suggestions while keeping provider keys off the browser."""

    payload = require_json_object(request.get_json(silent=True))
    query = validate_search_query(payload)
    session_token = payload.get("session_token")
    if session_token is not None and not isinstance(session_token, str):
        raise ApiError("'session_token' must be a string.", code="validation_error", details={"field": "session_token"})
    if current_app.config.get("GOOGLE_INTEGRATION_MODE", "mock") == "live":
        suggestions = autocomplete_places(query, current_app.config, session_token)
        data_mode = "live"
    else:
        suggestions = [item for item in MOCK_PLACE_SUGGESTIONS if query.lower() in item["description"].lower()]
        data_mode = "mock"
    return jsonify({"query": query, "suggestions": suggestions, "metadata": {"data_mode": data_mode}})


@api.get("/predictions")
def predictions():
    """Expose the AI team's 60-minute sensor forecast through a stable shape."""
    sensor_id = request.args.get("sensor_id", "").strip()
    if not sensor_id:
        raise ApiError("'sensor_id' is required.", code="validation_error", details={"field": "sensor_id"})
    threshold = validate_threshold(request.args.get("crowd_threshold", current_app.config["DEFAULT_CROWD_THRESHOLD"]))
    return jsonify(get_prediction(sensor_id, threshold, current_app.config["FORECAST_HORIZON_MINUTES"]))
