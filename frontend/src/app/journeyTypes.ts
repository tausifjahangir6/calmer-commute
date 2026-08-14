import type { DynamicRoute } from "./GeographicMap";

export type Screen = "plan" | "routes" | "journey" | "quiet";
export type JourneyDirection = "to-work" | "home";
export type Risk = "High" | "Low" | "Unknown";
export type DataState = "loading" | "fresh" | "stale" | "unavailable";
export type SensorFreshness = "fresh" | "delayed" | "stale" | "unavailable";

export type RouteReading = {
  peoplePerMinute: number | null;
  forecast: {
    peoplePerMinute: number | null;
    horizonMinutes: number;
    method: string;
    validationMae: number | null;
    confidence: string;
  };
  coverage: { usableSensors: number; supportedSensors: number; scope: string };
  sensors: {
    id: number;
    name: string;
    peoplePerMinute: number | null;
    latestObservation: string | null;
    sampleMinutes: number;
  }[];
};

export type MapSensorReading = {
  id: number;
  peoplePerMinute: number | null;
  latestObservation: string | null;
  sampleMinutes: number;
  freshness: SensorFreshness;
  evidence: "observed" | "inferred-zero" | "unavailable";
  operationalStatus: "active" | "inactive" | "unknown";
};

export type CrowdData = {
  ok: boolean;
  dataStatus: Exclude<DataState, "loading">;
  latestObservation: string | null;
  limitation: string;
  source: { name: string; dataset: string; aggregation: string };
  routes: { train: RouteReading; tram: RouteReading };
  mapSensors: MapSensorReading[];
  scenario?: { id: string; label: string; observationWindow: string };
};

export type PredictionResponse = {
  sensor_id: string;
  forecast_horizon_minutes: number;
  forecast_timestamp: string;
  predicted_count_per_minute: number | null;
  predicted_level: "High" | "Low" | "Unknown";
  crowd_level: "Low" | "Medium" | "High" | "Unknown";
  crowd_threshold: number;
  model_version: string;
  confidence: string | null;
  validation_status: string;
  generated_at: string;
  data_mode: string;
  limitation: string;
};

export type AssessedRoute = DynamicRoute & {
  count: number | null;
  crowdRisk: Risk;
  forecast: PredictionResponse | null;
  /** Retained for forecast-owner integration even though the current cards use predicted_level. */
  forecastRisk: Risk;
  matchedSensorIds: number[];
};
