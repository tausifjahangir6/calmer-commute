from flask import Flask, jsonify, request
import pandas as pd

from load_artifacts import load_forecast_artifacts, load_latest_features, load_base_thresholds_optional
from rf_explain import next_hour_forecast


def create_app() -> Flask:
    """Create and configure the Calmer Commute Flask application."""
    app = Flask(__name__)

    # Loaded ONCE at startup, not per-request. This is the entire point of
    # save_model.py / load_artifacts.py existing: the alternative is
    # retraining a Random Forest on 1.4M rows (or re-reading multi-MB
    # files) on every single forecast request.
    #
    # FAIL FAST if the core model artifacts are missing: load_forecast_artifacts()
    # raises FileNotFoundError with a clear "run save_model.py first" message.
    # We deliberately do NOT catch it here -- an app that can't forecast
    # shouldn't start up looking healthy and then fail confusingly on the
    # first real request. Missing artifacts should be loud and obvious at
    # startup, not silent until someone hits the endpoint.
    model, sensor_map, volatility_lookup = load_forecast_artifacts()

    # These two are OPTIONAL enhancements on top of the core forecast --
    # loaders return {} rather than raising if not yet generated, so the
    # app still starts and /api/forecast still works (just without live
    # feature data, or without alert thresholds, respectively) until
    # export_latest_features.py / export_base_thresholds.py have been run.
    latest_features = load_latest_features()
    base_thresholds = load_base_thresholds_optional()

    @app.get("/")
    def index():
        return jsonify(
            {
                "application": "Calmer Commute",
                "message": "Backend API is running.",
            }
        )

    @app.get("/api/health")
    def health():
        return jsonify(
            {
                "status": "healthy",
                "service": "calmer-commute-backend",
            }
        ), 200

    @app.get("/api/forecast/<int:sensor_id>")
    def forecast(sensor_id: int):
        """
        Next-hour pedestrian crowd forecast for one sensor.
        See ai/docs/AI-US2.2-01_writeup.md for methodology, model
        selection, and known limitations (pedestrian density is a proxy,
        not a safety guarantee -- see project Responsible Scope).

        Query params:
          sensitivity: "cautious" | "default" | "relaxed" (default: "default").
                       Only affects the alert threshold, not the forecast
                       number itself -- see ai/models/alert_thresholds.py.

        IMPORTANT LIMITATION: features come from latest_features.json, an
        INTERIM snapshot (see ai/models/export_latest_features.py) standing
        in for a live feature-ingestion pipeline that doesn't exist yet.
        The "latest" row is the most recent historical observation, not a
        genuinely unobserved future hour -- see that script's docstring.
        """
        latest = latest_features.get(sensor_id)
        if latest is None:
            return jsonify({
                "error": (
                    f"No feature data available for sensor_id {sensor_id}. "
                    "Either this isn't a valid sensor, or export_latest_features.py "
                    "hasn't been run yet."
                ),
            }), 404

        row = pd.Series(latest)
        row["sensor_id"] = sensor_id
        row["timestamp"] = pd.to_datetime(latest["timestamp"])

        sensitivity = request.args.get("sensitivity", "default")

        result = next_hour_forecast(
            sensor_id=sensor_id,
            model=model,
            sensor_map=sensor_map,
            latest_row=row,
            volatility_lookup=volatility_lookup,
            user_context={"sensitivity": sensitivity},
            base_thresholds=base_thresholds,
        )

        # pd.Timestamp isn't JSON-serializable by default -- convert before jsonify
        if result.get("timestamp") is not None:
            result["timestamp"] = result["timestamp"].isoformat()

        return jsonify(result), 200

    return app