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
    STALE_AFTER_MINUTES = 30
    FORECAST_HORIZON_MINUTES = 60
    DEFAULT_REFUGE_LIMIT = 5
    MAX_REFUGE_LIMIT = 20
    DIRECT_SENSOR_RADIUS_METRES = 75
    PROXY_SENSOR_RADIUS_METRES = 150

    # --- Crowd-level classification (AI-US2.2-01 forecast card) ---
    # Converted from database/schema/01_schema.sql's density_band reference
    # table (Low 0-50 / Medium 51-150 / High 151+ pedestrians), which is
    # calibrated in HOURLY counts. The live /api/predictions contract
    # reports predicted_count_per_minute (INTEGRATION_GUIDE.md section
    # 4.4), a different unit -- both bounds below are density_band's
    # original values divided by 60 to convert.
    #
    # NOT required by AI-US2.2-01's own LeanKit acceptance criteria (which
    # specifies only a binary client-threshold alert -- see
    # predicted_level in prediction_service.py). Added specifically to
    # satisfy AI_Team_Route_Scoring_Expectations.docx's explicit request
    # for a LOW/MEDIUM/HIGH/UNKNOWN crowd_level field from the
    # route-scoring team. This is a separate field from predicted_level,
    # not a replacement for it -- see prediction_service.py's
    # classify_crowd_level() docstring for why both are needed.
    #
    # ASSUMPTION, not yet independently validated: the /60 conversion
    # assumes density_band's bounds were calibrated for a roughly uniform
    # per-minute rate across the hour. Real pedestrian traffic is not
    # uniform (e.g. a lunchtime spike within an otherwise quiet hour), so
    # this is an approximation, not a measured per-minute calibration --
    # worth revisiting against real per-sensor CBD forecast magnitudes if
    # it proves miscalibrated in practice.
    #
    # Effect of raising these values: fewer sensors classify as
    # Medium/High (more conservative, more "Low" results). Lowering: more
    # sensors classify as Medium/High.
    CROWD_LEVEL_LOW_MAX_PER_MINUTE = 50 / 60      # ~0.8333 people/minute
    CROWD_LEVEL_MEDIUM_MAX_PER_MINUTE = 150 / 60  # =2.5 people/minute

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