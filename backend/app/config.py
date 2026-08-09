"""Central configuration for the Calmer Commute onboarding backend."""

import os
from pathlib import Path


class Config:
    """Named settings keep tunable behaviour out of route and service logic."""

    API_PREFIX = "/api"
    DEFAULT_CROWD_THRESHOLD = 25.0
    DEFAULT_ORIGIN = "903/8 Pearl River Rd, Docklands VIC 3008"
    DEFAULT_DESTINATION = "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000"
    DEFAULT_COMMUTE_DAYS = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    DEFAULT_COMMUTE_START = "07:30"
    DEFAULT_COMMUTE_END = "08:00"
    DEFAULT_TIMEZONE = "Australia/Melbourne"
    MAX_CROWD_THRESHOLD = 500.0
    STALE_AFTER_MINUTES = 15
    FORECAST_HORIZON_MINUTES = 60
    DEFAULT_REFUGE_LIMIT = 5
    MAX_REFUGE_LIMIT = 20
    SENSOR_MATCH_RADIUS_METRES = 250
    DATA_DIR = Path(__file__).resolve().parent / "data"
    SENSOR_LOCATIONS_PATH = DATA_DIR / "sensor_locations.csv"
    DATA_MODE = "mock"
    GOOGLE_INTEGRATION_MODE = os.getenv("GOOGLE_INTEGRATION_MODE", "mock").lower()
    GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
    GOOGLE_ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"
    GOOGLE_PLACES_URL = "https://places.googleapis.com/v1/places:searchNearby"
    GOOGLE_API_TIMEOUT_SECONDS = 10
    GOOGLE_ROUTE_ALTERNATIVES = True
    GOOGLE_PLACES_RADIUS_METRES = 1200.0
    GOOGLE_PLACE_TYPES = ("library", "park", "museum", "community_center")
