from flask import Flask, jsonify


def create_app() -> Flask:
    """Create and configure the Calmer Commute Flask application."""
    app = Flask(__name__)

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

    return app