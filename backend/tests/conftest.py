"""Shared Flask test client."""

from pathlib import Path

import pytest

from app import create_app
from app.config import Config


class TestConfig(Config):
    TESTING = True
    API_PREFIX = "/api"
    DEFAULT_CROWD_THRESHOLD = 25.0
    MAX_CROWD_THRESHOLD = 500.0
    FORECAST_HORIZON_MINUTES = 60
    DEFAULT_REFUGE_LIMIT = 5
    MAX_REFUGE_LIMIT = 20
    DATA_MODE = "mock"
    GOOGLE_INTEGRATION_MODE = "mock"
    SENSOR_LOCATIONS_PATH = (
        Path(__file__).resolve().parents[1] / "app" / "data" / "sensor_locations.csv"
    )


@pytest.fixture()
def client():
    app = create_app(TestConfig)
    return app.test_client()
