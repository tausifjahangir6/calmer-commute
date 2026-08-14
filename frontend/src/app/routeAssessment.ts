import type { DynamicRoute } from "./GeographicMap";
import type {
  AssessedRoute,
  CrowdData,
  MapSensorReading,
  PredictionResponse,
  Risk,
} from "./journeyTypes";

export const EMPTY_SENSORS: MapSensorReading[] = [];

export function isVerifiedPrediction(
  prediction: PredictionResponse | null | undefined,
): prediction is PredictionResponse & { predicted_count_per_minute: number } {
  return Boolean(
    prediction
      && prediction.predicted_count_per_minute !== null
      && prediction.validation_status.startsWith("validated")
      && prediction.data_mode === "live"
      && prediction.model_version === "crowd-forecast-rf-v1",
  );
}

export function riskFrom(count: number | null, crowdLimit: number): Risk {
  if (count === null) return "Unknown";
  return count > crowdLimit ? "High" : "Low";
}

export function getUsableSensors(crowdData: CrowdData | null) {
  return (crowdData?.mapSensors ?? EMPTY_SENSORS).filter(isUsableSensor);
}

export function isUsableSensor(sensor: MapSensorReading) {
  return (sensor.freshness === "fresh" || sensor.freshness === "delayed")
    && sensor.peoplePerMinute !== null;
}

export function matchRouteSensors(route: DynamicRoute, sensors: MapSensorReading[]) {
  const usableSensors = sensors.filter(isUsableSensor);
  const direct = usableSensors.filter((sensor) => route.directSensorIds.includes(sensor.id));
  const proxy = usableSensors.filter((sensor) =>
    route.proxySensors.some((candidate) => candidate.id === sensor.id));
  const matched = direct.length ? direct : proxy;
  const count = matched.length
    ? Math.max(...matched.map((sensor) => sensor.peoplePerMinute as number))
    : null;
  return { matched, count, evidenceQuality: direct.length ? "direct" as const : proxy.length ? "proxy" as const : "none" as const };
}

export function sensorIdsForPrediction(route: DynamicRoute) {
  return route.directSensorIds.length
    ? route.directSensorIds
    : route.proxySensors.map((sensor) => sensor.id);
}

export function routeForecastFor(
  route: DynamicRoute | undefined,
  predictions: Record<number, PredictionResponse>,
) {
  if (!route) return null;
  return sensorIdsForPrediction(route)
    .map((sensorId) => predictions[sensorId])
    .filter(isVerifiedPrediction)
    .reduce<PredictionResponse | null>((highest, prediction) => {
      if (!highest) return prediction;
      return prediction.predicted_count_per_minute! > highest.predicted_count_per_minute!
        ? prediction
        : highest;
    }, null);
}

export function assessRoutes(
  routes: DynamicRoute[],
  crowdData: CrowdData | null,
  crowdLimit: number,
  predictions: Record<number, PredictionResponse>,
): AssessedRoute[] {
  const usableSensors = getUsableSensors(crowdData);
  return routes.map((route) => {
    const { matched, count } = matchRouteSensors(route, usableSensors);
    const forecast = routeForecastFor(route, predictions);
    return {
      ...route,
      count,
      crowdRisk: riskFrom(count, crowdLimit),
      forecast,
      // Intentionally retained for the prediction component's future route-risk UI.
      forecastRisk: riskFrom(forecast?.predicted_count_per_minute ?? null, crowdLimit),
      matchedSensorIds: matched.map((sensor) => sensor.id),
    };
  });
}

export function formatObservation(value: string | null) {
  if (!value) return "No usable current timestamp";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Timestamp unavailable";
  return `Updated ${new Intl.DateTimeFormat("en-AU", {
    timeZone: "Australia/Melbourne",
    hour: "numeric",
    minute: "2-digit",
    day: "numeric",
    month: "short",
  }).format(date)}`;
}

export function latestMatchedObservation(crowdData: CrowdData | null, sensorIds: number[]) {
  const observations = (crowdData?.mapSensors ?? EMPTY_SENSORS)
    .filter((sensor) => sensorIds.includes(sensor.id) && sensor.latestObservation)
    .map((sensor) => sensor.latestObservation as string)
    .sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
  return observations[0] ?? crowdData?.latestObservation ?? null;
}
