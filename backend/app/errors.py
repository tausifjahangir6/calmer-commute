"""Consistent API errors shared by every endpoint."""

from dataclasses import dataclass

from flask import Flask, jsonify


@dataclass
class ApiError(Exception):
    """A safe client-facing error with an HTTP status and stable code."""

    message: str
    status_code: int = 400
    code: str = "bad_request"
    details: dict | None = None


def register_error_handlers(app: Flask) -> None:
    """Register one JSON error shape so the frontend can handle failures reliably."""

    @app.errorhandler(ApiError)
    def handle_api_error(error: ApiError):
        payload = {
            "error": {
                "code": error.code,
                "message": error.message,
                "details": error.details or {},
            }
        }
        return jsonify(payload), error.status_code

    @app.errorhandler(404)
    def handle_not_found(_error):
        return jsonify({"error": {"code": "not_found", "message": "Endpoint not found.", "details": {}}}), 404

    @app.errorhandler(405)
    def handle_method_not_allowed(_error):
        return jsonify({"error": {"code": "method_not_allowed", "message": "HTTP method not allowed.", "details": {}}}), 405

