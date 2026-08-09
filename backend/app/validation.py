"""Request validation at the API boundary."""

from typing import Any

from flask import current_app

from .errors import ApiError


def require_json_object(payload: Any) -> dict:
    """Reject absent, array, or scalar JSON before service code reads fields."""

    if not isinstance(payload, dict):
        raise ApiError("Request body must be a JSON object.", code="invalid_json")
    return payload


def require_non_empty_string(payload: dict, field: str) -> str:
    value = payload.get(field)
    if not isinstance(value, str) or not value.strip():
        raise ApiError(
            f"'{field}' is required and must be a non-empty string.",
            code="validation_error",
            details={"field": field},
        )
    return value.strip()


def validate_search_query(payload: dict) -> str:
    query = require_non_empty_string(payload, "query")
    if len(query) < 2 or len(query) > 200:
        raise ApiError(
            "'query' must contain between 2 and 200 characters.",
            code="validation_error",
            details={"field": "query"},
        )
    return query


def optional_coordinate_pair(payload: dict, field: str) -> dict | None:
    """Validate latitude/longitude together so partial coordinates cannot leak downstream."""

    value = payload.get(field)
    if value is None:
        return None
    if not isinstance(value, dict):
        raise ApiError(f"'{field}' must be an object.", code="validation_error", details={"field": field})
    return validate_coordinates(value.get("latitude"), value.get("longitude"), field)


def validate_coordinates(latitude: Any, longitude: Any, field: str = "coordinates") -> dict:
    if isinstance(latitude, bool) or isinstance(longitude, bool):
        raise _coordinate_error(field)
    try:
        latitude_value = float(latitude)
        longitude_value = float(longitude)
    except (TypeError, ValueError):
        raise _coordinate_error(field) from None
    if not -90 <= latitude_value <= 90 or not -180 <= longitude_value <= 180:
        raise _coordinate_error(field)
    return {"latitude": latitude_value, "longitude": longitude_value}


def validate_threshold(value: Any) -> float:
    if isinstance(value, bool):
        raise _threshold_error()
    try:
        threshold = float(value)
    except (TypeError, ValueError):
        raise _threshold_error() from None
    maximum = current_app.config["MAX_CROWD_THRESHOLD"]
    if threshold <= 0 or threshold > maximum:
        raise _threshold_error()
    return threshold


def validate_limit(value: Any) -> int:
    if isinstance(value, bool):
        raise ApiError("'limit' must be a positive integer.", code="validation_error", details={"field": "limit"})
    try:
        limit = int(value)
    except (TypeError, ValueError):
        raise ApiError("'limit' must be a positive integer.", code="validation_error", details={"field": "limit"}) from None
    if limit < 1 or limit > current_app.config["MAX_REFUGE_LIMIT"]:
        raise ApiError(
            f"'limit' must be between 1 and {current_app.config['MAX_REFUGE_LIMIT']}.",
            code="validation_error",
            details={"field": "limit"},
        )
    return limit


def _coordinate_error(field: str) -> ApiError:
    return ApiError(
        f"'{field}' must contain valid latitude and longitude values.",
        code="validation_error",
        details={"field": field},
    )


def _threshold_error() -> ApiError:
    return ApiError(
        "'crowd_threshold' must be greater than 0 and within the configured maximum.",
        code="validation_error",
        details={"field": "crowd_threshold"},
    )
