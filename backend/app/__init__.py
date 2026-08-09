"""Flask application factory for Calmer Commute."""

from flask import Flask, jsonify

from .config import Config
from .errors import register_error_handlers
from .routes import api


def create_app(config_object=Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config_object)
    app.register_blueprint(api, url_prefix=app.config["API_PREFIX"])
    register_error_handlers(app)

    @app.get("/")
    def index():
        return jsonify({"service": "Calmer Commute API", "health": f"{app.config['API_PREFIX']}/health"})

    return app

