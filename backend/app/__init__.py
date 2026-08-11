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

    # Force the (~1.4GB) forecast model to load exactly once, here, in a
    # single thread, at startup -- before any real request arrives.
    # Without this, /api/crowd's ThreadPoolExecutor(max_workers=8) can hit
    # predict_count() from multiple sensors CONCURRENTLY on a cold start,
    # racing to load the model in parallel -- each racing thread briefly
    # holding its own ~1.4GB copy, which is exactly what was OOM-killing
    # the process (dmesg: "Out of memory: Killed process ... anon-rss:1427136kB").
    # Loading it once, safely, up front removes the race entirely.
    from .ai.forecast import predict_count
    try:
        predict_count("5", horizon_minutes=60)
    except Exception:
        # If this fails (e.g. model artifacts genuinely missing in this
        # environment), don't crash the whole app over a warm-up attempt --
        # the existing lazy-loading fallback in forecast.py still applies
        # normally for every real request afterward.
        pass

    @app.get("/")
    def index():
        return jsonify({"service": "Calmer Commute API", "health": f"{app.config['API_PREFIX']}/health"})

    return app 

