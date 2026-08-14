"use client";
/* eslint-disable @typescript-eslint/no-explicit-any */

/*
 DISPLAY OWNER: preserve the deployed v81 interaction in this file.
It consumes Vince's real /api/crowd contract. Route-to-sensor matching is
still performed client-side for v81 parity until the follow-up backend PR.
UPDATE (2026-08-10): the forecast field now sources from AI-US2.2-01's
validated Random Forest model (see ai/docs/AI-US2.2-01_writeup.md) rather
than the original v81 linear-trend placeholder -- decision made by the
AI/ML card owner. The "method"/"confidence" fields now genuinely reflect
a validated model where available.
 */

import { useEffect, useState } from "react";
import GeographicMap, { loadGoogleMaps, requestRoutesApi, SENSOR_LOCATIONS, type DynamicRoute, type RouteId, type TravelTiming } from "./GeographicMap";
import PlaceSearch from "./PlaceSearch";

type Screen = "plan" | "routes" | "journey" | "quiet";
type JourneyDirection = "to-work" | "home";
type Risk = "High" | "Low" | "Unknown";
type DataState = "loading" | "fresh" | "stale" | "unavailable";
type SensorFreshness = "fresh" | "delayed" | "stale" | "unavailable";

type RouteReading = {
  peoplePerMinute: number | null;
  forecast: { peoplePerMinute: number | null; horizonMinutes: number; method: string; validationMae: number | null; confidence: string };
  coverage: { usableSensors: number; supportedSensors: number; scope: string };
  sensors: { id: number; name: string; peoplePerMinute: number | null; latestObservation: string | null; sampleMinutes: number }[];
};

type CrowdData = {
  ok: boolean;
  dataStatus: Exclude<DataState, "loading">;
  latestObservation: string | null;
  limitation: string;
  source: { name: string; dataset: string; aggregation: string };
  routes: { train: RouteReading; tram: RouteReading };
  mapSensors: { id: number; peoplePerMinute: number | null; latestObservation: string | null; sampleMinutes: number; freshness: SensorFreshness; evidence: "observed" | "inferred-zero" | "unavailable"; operationalStatus: "active" | "inactive" | "unknown" }[];
  scenario?: { id: string; label: string; observationWindow: string };
};
type PredictionResponse = {
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

const HOME = "903/8 Pearl River Road, Docklands VIC 3008";
const WORK = "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000";

// Keep one shared empty-array reference. An inline `?? []` creates a new array
// on every render while crowd data is loading, which retriggers GeographicMap's
// effect and removes/recreates the route sensor overlays.
const EMPTY_SENSORS: CrowdData["mapSensors"] = [];

// Stable timing object — a new `{ mode: "now" }` each render retriggered the
// map effect, which called setDynamicRoutes and looped "Comparing public-transport…".
const DEFAULT_TRAVEL_TIMING: TravelTiming = { mode: "now", dateTime: "" };

function routeForecastFor(route: DynamicRoute | undefined, predictions: Record<number, PredictionResponse>) {
  if (!route) return null;
  const sensorIds = route.directSensorIds.length
    ? route.directSensorIds
    : route.proxySensors.map((sensor) => sensor.id);
  return sensorIds
    .map((sensorId) => predictions[sensorId])
    .filter((prediction) => prediction?.predicted_count_per_minute !== null && prediction?.predicted_count_per_minute !== undefined)
    .sort((a, b) => (b.predicted_count_per_minute ?? -1) - (a.predicted_count_per_minute ?? -1))[0] ?? null;
}

function useRoutePredictions(dynamicRoutes: DynamicRoute[], crowdLimit: number, crowdData: CrowdData | null) {
  const predictionSensorKey = [...new Set(dynamicRoutes.flatMap((route) =>
    route.directSensorIds.length ? route.directSensorIds : route.proxySensors.map((sensor) => sensor.id)
  ))].sort((a, b) => a - b).join(",");
  const rawScenarioId = crowdData?.scenario?.id;
  const predictionScenarioId = rawScenarioId === "dod-2026-08-04-0700" ? "2026-08-04T07:00" : rawScenarioId;
  const forecastRequestKey = predictionSensorKey
    ? `${predictionSensorKey}|${crowdLimit}|${predictionScenarioId ?? "live"}`
    : "";
  const [routePredictions, setRoutePredictions] = useState<Record<number, PredictionResponse>>({});
  const [loadedForecastKey, setLoadedForecastKey] = useState("");

  useEffect(() => {
    if (!predictionSensorKey) return;
    let cancelled = false;
    async function loadRouteForecasts() {
      const sensorIds = predictionSensorKey.split(",").map(Number).filter(Number.isFinite);
      const results = await Promise.all(sensorIds.map(async (sensorId) => {
        try {
          const params = new URLSearchParams({ sensor_id: String(sensorId), crowd_threshold: String(crowdLimit) });
          if (predictionScenarioId) params.set("scenario", predictionScenarioId);
          const response = await fetch(`/api/predictions?${params.toString()}`, { cache: "no-store" });
          if (!response.ok) return null;
          return { sensorId, prediction: await response.json() as PredictionResponse };
        } catch {
          return null;
        }
      }));
      if (cancelled) return;
      const next: Record<number, PredictionResponse> = {};
      results.forEach((result) => { if (result) next[result.sensorId] = result.prediction; });
      setRoutePredictions(next);
      setLoadedForecastKey(forecastRequestKey);
    }
    void loadRouteForecasts();
    return () => { cancelled = true; };
  }, [predictionSensorKey, forecastRequestKey, crowdLimit, predictionScenarioId]);

  return {
    routePredictions,
    routeForecastPending: Boolean(forecastRequestKey && loadedForecastKey !== forecastRequestKey),
  };
}

export default function Home() {
  const [screen, setScreen] = useState<Screen>("plan");
  const [selectedRoute, setSelectedRoute] = useState<RouteId>("route-0");
  const [homeAddress, setHomeAddress] = useState(HOME);
  const [workAddress, setWorkAddress] = useState(WORK);
  const [crowdLimit, setCrowdLimit] = useState(12);
  // The prototype opens in its deterministic DoD replay so the supported
  // route sensors are present on first load. Users can untick DoD check to
  // switch to the near-real-time feed.
  const [dataState, setDataState] = useState<DataState>("loading");
  const [crowdData, setCrowdData] = useState<CrowdData | null>(null);
  const [alertVisible, setAlertVisible] = useState(true);
  const [routeUpdated, setRouteUpdated] = useState(false);
  const [refreshToken, setRefreshToken] = useState(0);
  const [dynamicRoutes, setDynamicRoutes] = useState<DynamicRoute[]>([]);
  const travelTiming = DEFAULT_TRAVEL_TIMING;
  const { routePredictions, routeForecastPending } = useRoutePredictions(dynamicRoutes, crowdLimit, crowdData);

  function handleHomeAddress(value: string) {
    setHomeAddress(value);
    setDynamicRoutes([]);
    setSelectedRoute("route-0");
  }

  function handleWorkAddress(value: string) {
    setWorkAddress(value);
    setDynamicRoutes([]);
    setSelectedRoute("route-0");
  }

  useEffect(() => {
    let cancelled = false;
    async function loadCrowdData() {
      try {
        const response = await fetch("/api/crowd", { cache: "no-store" });
        const payload = await response.json() as CrowdData;
        if (cancelled) return;
        setCrowdData(payload);
        setDataState(payload.dataStatus);
      } catch {
        if (!cancelled) setDataState("unavailable");
      }
    }
    loadCrowdData();
    const timer = window.setInterval(loadCrowdData, 15 * 60_000);
    return () => { cancelled = true; window.clearInterval(timer); };
  }, [refreshToken]);

  function navigate(next: Screen) {
    setScreen(next);
    window.scrollTo({ top: 0, behavior: "auto" });
  }

  return (
    <main className="prototype-stage">
      <SiteHeader onHome={() => navigate("plan")} />
      <div className="web-shell">
        {screen === "plan" && (
          <PlanScreen
            homeAddress={homeAddress}
            workAddress={workAddress}
            onHomeAddress={handleHomeAddress}
            onWorkAddress={handleWorkAddress}
            onContinue={() => navigate("routes")}
          />
        )}

        {screen === "routes" && (
          <RoutesScreen
            selected={selectedRoute}
            crowdLimit={crowdLimit}
            onCrowdLimit={setCrowdLimit}
            dataState={dataState}
            crowdData={crowdData}
            onRefresh={() => { setDataState("loading"); setRefreshToken((value) => value + 1); }}
            onSelect={setSelectedRoute}
            onBack={() => navigate("plan")}
            onContinue={() => {
              setAlertVisible(true);
              setRouteUpdated(false);
              navigate("journey");
            }}
            origin={homeAddress}
            destination={workAddress}
            journeyDirection="to-work"
            dynamicRoutes={dynamicRoutes}
            routePredictions={routePredictions}
            routeForecastPending={routeForecastPending}
            onRoutesResolved={setDynamicRoutes}
            travelTiming={travelTiming}
          />
        )}

        {screen === "journey" && (
          <JourneyScreen
            selected={selectedRoute}
            crowdLimit={crowdLimit}
            dataState={dataState}
            crowdData={crowdData}
            alertVisible={alertVisible}
            routeUpdated={routeUpdated}
            onBack={() => navigate("routes")}
            onDismiss={() => setAlertVisible(false)}
            onReroute={() => {
              const alternate = dynamicRoutes.find((route) => route.id !== selectedRoute);
              if (alternate) setSelectedRoute(alternate.id);
              setRouteUpdated(true);
              setAlertVisible(false);
            }}
            onFindRefuge={() => navigate("quiet")}
            origin={homeAddress}
            destination={workAddress}
            journeyDirection="to-work"
            dynamicRoutes={dynamicRoutes}
            routePredictions={routePredictions}
            routeForecastPending={routeForecastPending}
            onRoutesResolved={setDynamicRoutes}
            travelTiming={travelTiming}
          />
        )}

        {screen === "quiet" && <QuietSpotScreen onBack={() => navigate("journey")} arrivalAddress={workAddress} crowdData={crowdData} crowdLimit={crowdLimit} />}
      </div>
      {screen === "plan" && <SiteFooter />}
    </main>
  );
}

function SiteHeader({ onHome }: { onHome: () => void }) {
  return (
    <header className="site-header">
      <button className="brand-lockup" onClick={onHome} aria-label="Calm-panion home">
        <span className="brand-mark" aria-hidden="true" />
        <span className="brand-copy"><strong>Calm-panion</strong></span>
      </button>
      <div className="header-location" aria-label="Location: Melbourne">
        <i aria-hidden="true" />
        <span>Melbourne</span>
      </div>
    </header>
  );
}

function SiteFooter() {
  return (
    <footer className="site-footer">
      <span>Made for sensory-sensitive journeys across Melbourne CBD.</span>
      <span>Conditions can change. Choose what feels right.</span>
    </footer>
  );
}

function ScreenHeader({ title, subtitle, back, action }: { title: string; subtitle?: string; back?: () => void; action?: { label: string; onClick: () => void } }) {
  return (
    <header className="screen-header">
      {(back || action) && (
        <div className="header-row">
          {back && <button className="back-control" onClick={back} aria-label="Go back"><span aria-hidden="true">‹</span> Back</button>}
          {action && <button className="header-action" onClick={action.onClick}>{action.label}</button>}
        </div>
      )}
      <h1>{title}</h1>
      {subtitle && <p>{subtitle}</p>}
    </header>
  );
}

function PlanScreen(props: {
  homeAddress: string;
  workAddress: string;
  onHomeAddress: (value: string) => void;
  onWorkAddress: (value: string) => void;
  onContinue: () => void;
}) {
  return (
    <section className="app-screen plan-view" aria-label="Plan your journey">
      <div className="plan-introduction">
        <p className="plan-kicker">A CALMER WAY THROUGH THE CITY</p>
        <h1>Arrive calm<br />and prepared.</h1>
        <p className="plan-description">Compare sensory-aware routes using latest pedestrian conditions and your personal crowd limit.</p>
      </div>

      <div className="planner-panel">
        <div className="planner-heading">
          <p>PLAN YOUR JOURNEY</p>
          <h2>Where are you going?</h2>
        </div>
        <div className="location-card">
          <label>
            <span>Start</span>
            <PlaceSearch ariaLabel="Departure address" placeholder="Origin" value={props.homeAddress} onChange={props.onHomeAddress} />
          </label>
          <div className="location-connector" aria-hidden="true"><i /><span /></div>
          <label>
            <span>Finish</span>
            <PlaceSearch ariaLabel="Destination address" placeholder="Destination" value={props.workAddress} onChange={props.onWorkAddress} />
          </label>
        </div>

        <button className="primary-action" onClick={props.onContinue}>Find my calmer route <span aria-hidden="true">→</span></button>
      </div>
    </section>
  );
}

function RoutesScreen({ selected, crowdLimit, onCrowdLimit, dataState, crowdData, onSelect, onBack, onContinue, origin, destination, journeyDirection, dynamicRoutes, routePredictions, routeForecastPending, onRoutesResolved, travelTiming }: { selected: RouteId; crowdLimit: number; onCrowdLimit: (value: number) => void; dataState: DataState; crowdData: CrowdData | null; onRefresh: () => void; onSelect: (value: RouteId) => void; onBack: () => void; onContinue: () => void; origin: string; destination: string; journeyDirection: JourneyDirection; dynamicRoutes: DynamicRoute[]; routePredictions: Record<number, PredictionResponse>; routeForecastPending: boolean; onRoutesResolved: (routes: DynamicRoute[]) => void; travelTiming: TravelTiming }) {
  const usableSensors = getUsableSensors(crowdData);
  const dataAvailable = usableSensors.length > 0;
  const trainCount = crowdData?.routes?.train?.peoplePerMinute ?? null;
  const tramCount = crowdData?.routes?.tram?.peoplePerMinute ?? null;
  const dataStateCopy = getDataStateCopy(dataState);
  const assessed = dynamicRoutes.map((route) => {
    const observedSensors = (crowdData?.mapSensors ?? EMPTY_SENSORS).filter((sensor) => sensor.latestObservation !== null);
    const directMatched = usableSensors.filter((sensor) => route.directSensorIds.includes(sensor.id));
    const proxyMatched = usableSensors.filter((sensor) => route.proxySensors.some((proxy) => proxy.id === sensor.id));
    const nearbyObserved = observedSensors.filter((sensor) => route.directSensorIds.includes(sensor.id) || route.proxySensors.some((proxy) => proxy.id === sensor.id));
    const nearbyStale = nearbyObserved.filter((sensor) => sensor.freshness === "stale");
    const matched = directMatched.length ? directMatched : proxyMatched;
    const count = matched.length ? Math.max(...matched.map((sensor) => sensor.peoplePerMinute as number)) : null;
    const crowdRisk = riskFrom(count, crowdLimit);
    const endpointForecast = routeForecastFor(route, routePredictions);
    const forecastCount = endpointForecast?.predicted_count_per_minute ?? null;
    const forecastRisk = riskFrom(forecastCount, crowdLimit);
    const evidenceQuality = directMatched.length ? "direct" : proxyMatched.length ? "proxy" : "none";
    const inferredSensorIds = matched.filter((sensor) => sensor.evidence === "inferred-zero").map((sensor) => sensor.id);
    return { ...route, count, crowdRisk, forecastCount, forecastRisk, forecastHorizonMinutes: endpointForecast?.forecast_horizon_minutes ?? 60, evidenceQuality, matchedSensorIds: matched.map((sensor) => sensor.id), inferredSensorIds, nearbyStaleSensorIds: nearbyStale.map((sensor) => sensor.id) };
  });
  const fastest = assessed.length ? [...assessed].sort((a, b) => a.durationMinutes - b.durationMinutes)[0] : null;
  const lowRoutes = assessed.filter((route) => route.crowdRisk === "Low");
  const recommended = lowRoutes.length ? [...lowRoutes].sort((a, b) => (a.count ?? Infinity) - (b.count ?? Infinity) || a.durationMinutes - b.durationMinutes)[0] : null;
  const highRoutes = assessed.filter((route) => route.crowdRisk === "High" && route.matchedSensorIds.length);
  const avoidedRoute = highRoutes
    .map((route) => ({ route, hotspotId: route.matchedSensorIds.sort((a, b) => {
      const readingA = usableSensors.find((sensor) => sensor.id === a)?.peoplePerMinute ?? -1;
      const readingB = usableSensors.find((sensor) => sensor.id === b)?.peoplePerMinute ?? -1;
      return readingB - readingA;
    })[0] }))
    .find(({ hotspotId }) => hotspotId !== undefined && recommended && !recommended.nearbySensorIds.includes(hotspotId));
  const orderedRoutes = [...assessed].sort((a, b) => {
    if (a.id === recommended?.id) return -1;
    if (b.id === recommended?.id) return 1;
    return a.durationMinutes - b.durationMinutes;
  });
  const selectedDynamic = assessed.find((route) => route.id === selected) ?? assessed[0];
  const selectedHighRoute = highRoutes.find((route) => route.id === selectedDynamic?.id);
  const selectedHotspotId = selectedHighRoute?.matchedSensorIds
    .slice()
    .sort((a, b) => (usableSensors.find((sensor) => sensor.id === b)?.peoplePerMinute ?? -1) - (usableSensors.find((sensor) => sensor.id === a)?.peoplePerMinute ?? -1))[0];
  const displayedHotspotRoute = selectedHighRoute
    ? { route: selectedHighRoute, hotspotId: selectedHotspotId }
    : avoidedRoute;
  const hotspotSensor = displayedHotspotRoute
    ? usableSensors.find((sensor) => sensor.id === displayedHotspotRoute.hotspotId)
    : null;
  const hotspotMeta = displayedHotspotRoute?.route.nearbySensors.find((sensor) => sensor.id === displayedHotspotRoute.hotspotId);
  const [hotspotForecast, setHotspotForecast] = useState<PredictionResponse | null>(null);
  useEffect(() => {
    let cancelled = false;
    const sensorId = hotspotSensor?.id;
    if (sensorId === undefined || sensorId === null) {
      return;
    }
    async function loadForecast() {
      try {
        const scenarioParam = crowdData?.scenario ? `&scenario=${crowdData.scenario.id}` : "";
        const response = await fetch(`/api/predictions?sensor_id=${sensorId}&crowd_threshold=${crowdLimit}${scenarioParam}`, { cache: "no-store" });
        const payload = await response.json() as PredictionResponse;
        if (!cancelled) setHotspotForecast(payload);
      } catch {
        if (!cancelled) setHotspotForecast(null);
      }
    }
    loadForecast();
    return () => { cancelled = true; };
  }, [hotspotSensor?.id, crowdLimit, crowdData?.scenario]);
  const verifiedAvoidance = Boolean(avoidedRoute && recommended && displayedHotspotRoute?.hotspotId === avoidedRoute.hotspotId);
  const noLowRoute = assessed.length > 0 && assessed.every((route) => route.crowdRisk === "High");
  const assessedRouteIds = assessed.map((route) => route.id).join(",");
  useEffect(() => {
    if (!assessedRouteIds) return;
    const ids = assessedRouteIds.split(",");
    if (!ids.includes(selected)) onSelect(recommended?.id ?? fastest?.id ?? ids[0] ?? "route-0");
  }, [assessedRouteIds, recommended?.id, fastest?.id, selected, onSelect]);
  // Follow the Low-crowd recommendation when the threshold changes, without
  // overriding a manual route pick while the limit stays the same.
  useEffect(() => {
    if (recommended?.id) onSelect(recommended.id);
  }, [crowdLimit, recommended?.id, onSelect]);
  return (
    <section className={`app-screen routes-view ${noLowRoute ? "has-no-low-route" : ""}`} aria-label="Select your path">
      <ScreenHeader title="Sensory-aware journey options" subtitle="Compare sensory-aware routes using latest pedestrian conditions and your personal crowd limit." back={onBack} />

      <div className="route-threshold" aria-label="Live crowd threshold control">
        <div><strong>Adjust crowd limit</strong><span>{crowdLimit} people/min</span></div>
        <input aria-label="Crowd threshold in people per minute" type="range" min="1" max="200" step="1" value={crowdLimit} onChange={(event) => onCrowdLimit(Number(event.target.value))} />
        <small>Route recommendations update when this limit changes.</small>
      </div>

      <div className="route-decision-stack">
        <button className="primary-action" onClick={onContinue} disabled={!selectedDynamic}>{selectedDynamic ? "Start journey" : "Checking your journey..."}</button>
        {noLowRoute && <p className="no-low-route" role="status"><strong>No route is within your crowd limit right now.</strong><span>You can wait and check again, or try different locations.</span></p>}
        {displayedHotspotRoute && hotspotSensor && hotspotMeta && (
          <div style={{ display: "flex", gap: "12px", flexWrap: "wrap" }}>
            <article className="hotspot-avoidance" aria-live="polite" style={{ flex: "1 1 260px" }}>
              <div className="hotspot-heading"><span aria-hidden="true">!</span><div><small>BUSY AREA AHEAD</small><strong>{hotspotMeta.name.replace(/\s*-\s*New footpath\s*$/i, "")}</strong></div></div>
              <p><b>High crowd · {formatObservation(hotspotSensor.latestObservation)}</b></p>
              {verifiedAvoidance && recommended ? <>
                <div className="avoidance-result"><span aria-hidden="true">✓</span><p><strong>{recommended.service} recommended</strong><small>Avoids this supported High-crowd corridor.</small></p></div>
                <p className="explicit-tradeoff"><strong>Trade-off:</strong> {recommended.durationMinutes === displayedHotspotRoute.route.durationMinutes ? "same journey time" : `${Math.abs(recommended.durationMinutes - displayedHotspotRoute.route.durationMinutes)} min ${recommended.durationMinutes > displayedHotspotRoute.route.durationMinutes ? "longer" : "shorter"}`} · {recommended.walkingMinutes === displayedHotspotRoute.route.walkingMinutes ? "same walking time" : `${Math.abs(recommended.walkingMinutes - displayedHotspotRoute.route.walkingMinutes)} min ${recommended.walkingMinutes > displayedHotspotRoute.route.walkingMinutes ? "more" : "less"} walking`}</p>
              </> : <p className="explicit-tradeoff"><strong>No verified lower-crowd alternative avoids this hotspot right now.</strong></p>}
            </article>
            <HotspotForecastCard forecast={hotspotForecast} sensorName={hotspotMeta.name} />
          </div>
        )}
      </div>

      <div className="route-cards" role="radiogroup" aria-label="Route options">
        {orderedRoutes.map((route, index) => <RouteCard key={route.id}
          rank={index + 1}
          title={route.service}
          transportMode={route.transportMode}
          duration={route.duration}
          load={dataState === "loading" ? "Checking your journey..." : route.crowdRisk === "Unknown" ? "Crowd unavailable" : `Crowd ${route.crowdRisk.toLowerCase()}`}
          current={dataState === "loading" ? "Checking your journey..." : route.count === null ? "Unavailable" : `${route.count} people/min · ${formatObservation(latestMatchedObservation(crowdData, route.matchedSensorIds))}`}
          forecast={routeForecastPending ? "Checking forecast..." : route.forecastCount === null ? "Unavailable" : `${route.forecastCount} people/min · within next ${route.forecastHorizonMinutes} min`}
          tone={route.crowdRisk === "Unknown" ? "neutral" : route.crowdRisk === "High" ? "warm" : "calm"}
          selected={selectedDynamic?.id === route.id}
          recommended={recommended?.id === route.id}
          onClick={() => onSelect(route.id)}
        />)}
        {!assessed.length && <p className="recommendation-withheld"><strong>Checking your journey...</strong></p>}
      </div>

      <section className="route-preview" aria-label={`${selectedDynamic?.service ?? "Google public transport"} route preview`}>
        <div className="route-preview-heading">
          <div>
            <span>Selected journey preview</span>
          </div>
        </div>
        <RealMap selected={selected} crowdLimit={crowdLimit} trainCount={trainCount} tramCount={tramCount} sensorReadings={crowdData?.mapSensors ?? EMPTY_SENSORS} refuge origin={origin} destination={destination} journeyDirection={journeyDirection} onRoutesResolved={onRoutesResolved} travelTiming={travelTiming} />
        <JourneyRouteLegend selected={selected} route={selectedDynamic} />
        <JourneyLegs selected={selected} journeyDirection={journeyDirection} route={selectedDynamic} condensed showLegend={false} />
      </section>

      {dataState === "loading" ? <p className="recommendation-withheld" role="status" aria-live="polite"><strong>Checking your journey...</strong></p> : !dataAvailable && <p className="recommendation-withheld" role="status"><strong>No crowd recommendation available.</strong><span>{dataStateCopy.safeResponse}</span></p>}

      {highRoutes.length > 0 && !noLowRoute && !avoidedRoute && <p className="no-low-route" role="status"><strong>No verified route avoids the supported High-crowd corridor.</strong><span>A lower-scoring route may exist, but Calm-panion will not claim corridor avoidance without supported evidence.</span></p>}

    </section>
  );
}

function RouteCard(props: { rank: number; title: string; transportMode: string; duration: string; load: string; current: string; forecast: string; tone: "warm" | "calm" | "neutral"; selected: boolean; recommended?: boolean; onClick: () => void }) {
  return (
    <article className={`route-card ${props.tone} ${props.selected ? "selected" : ""}`} role="radio" aria-checked={props.selected} tabIndex={0} onClick={props.onClick} onKeyDown={(event) => { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); props.onClick(); } }}>
      <span className="route-rank">Option {props.rank}</span>
      <div className="route-labels">
        {props.recommended && <span className="recommended">Recommended</span>}
      </div>
      <span className="route-radio" aria-hidden="true"><i /></span>
      <div className="load-badge"><span aria-hidden="true">{props.tone === "warm" ? "!" : props.tone === "neutral" ? "?" : "✓"}</span>{props.load}</div>
      <div className="route-core">
        <strong className="route-duration">{props.duration}</strong>
        <div className="route-service-row">
          <span className="route-mode-badge">{formatTransportMode(props.transportMode)}</span>
          <h2>{formatServiceNumber(props.transportMode, props.title)}</h2>
        </div>
      </div>
      <details onClick={(event) => event.stopPropagation()}>
        <summary>More details</summary>
        <div className="route-detail-content">
          <div><strong>Current</strong><p>{props.current}</p></div>
          <div><strong>Forecast</strong><p>{props.forecast}</p></div>
        </div>
      </details>
    </article>
  );
}
function HotspotForecastCard({ forecast, sensorName }: { forecast: PredictionResponse | null; sensorName: string }) {
  // Alert triggers off predicted_level, which compares the forecast
  // directly against the user's own crowd_limit slider -- crowd_level is a
  // fixed scale (density_band-derived) calibrated for bursty CURRENT
  // minute-counts (11-50+/min), not smoothed hourly-average forecasts
  // (typically under 1/min), so gating on it meant the alert could almost
  // never fire in practice.
  if (!forecast || forecast.predicted_level !== "High") {
    return null;
  }
  const count = forecast.predicted_count_per_minute;
  return (
    <article className="hotspot-avoidance" aria-live="polite" style={{ flex: "1 1 260px" }}>
      <div className="hotspot-heading"><span aria-hidden="true">⏱</span><div><small>Forecast alert</small><strong>{sensorName}</strong></div></div>
      <p><b>{count} people/min expected</b> in {forecast.forecast_horizon_minutes} min · {forecast.crowd_level}</p>
      <p className="explicit-tradeoff">
        {forecast.data_mode === "live"
          ? `Validated forecast · confidence: ${forecast.confidence ?? "unknown"}`
          : "Forecast not yet validated in this environment."}
      </p>
    </article>
  );
}

function JourneyScreen(props: {
  selected: RouteId;
  crowdLimit: number;
  dataState: DataState;
  crowdData: CrowdData | null;
  alertVisible: boolean;
  routeUpdated: boolean;
  onBack: () => void;
  onDismiss: () => void;
  onReroute: () => void;
  onFindRefuge: () => void;
  origin: string;
  destination: string;
  journeyDirection: JourneyDirection;
  dynamicRoutes: DynamicRoute[];
  routePredictions: Record<number, PredictionResponse>;
  routeForecastPending: boolean;
  onRoutesResolved: (routes: DynamicRoute[]) => void;
  travelTiming: TravelTiming;
}) {
  const usableSensors = getUsableSensors(props.crowdData);
  const dataAvailable = usableSensors.length > 0;
  const trainCount = props.crowdData?.routes?.train?.peoplePerMinute ?? null;
  const tramCount = props.crowdData?.routes?.tram?.peoplePerMinute ?? null;
  const selectedDynamic = props.dynamicRoutes.find((route) => route.id === props.selected) ?? props.dynamicRoutes[0];
  const selectedRouteForecast = routeForecastFor(selectedDynamic, props.routePredictions);
  const forecastCount = selectedRouteForecast?.predicted_count_per_minute ?? null;
  const forecastExceedsLimit = forecastCount !== null && forecastCount > props.crowdLimit;
  return (
    <section className="app-screen journey-view" aria-label="Your journey">
      <ScreenHeader title="Selected journey" subtitle={dataAvailable ? `CBD sensor ${formatObservation(props.crowdData?.latestObservation ?? null).replace(/^Updated/, "updated")}` : "Current CBD crowd classification unavailable"} back={props.onBack} />

      <div className="journey-map-column">
        <RealMap selected={props.selected} crowdLimit={props.crowdLimit} trainCount={trainCount} tramCount={tramCount} sensorReadings={props.crowdData?.mapSensors ?? EMPTY_SENSORS} refuge origin={props.origin} destination={props.destination} journeyDirection={props.journeyDirection} onRoutesResolved={props.onRoutesResolved} travelTiming={props.travelTiming} />
        <JourneyRouteLegend selected={props.selected} route={selectedDynamic} />
      </div>

      <div className="journey-details-column">
        <div className="next-step-card">
          <span>Next</span>
          <h2>{selectedDynamic?.legs[0]?.label ?? "Checking your journey..."}</h2>
          <div><strong>{selectedDynamic?.duration ?? "Checking…"}</strong><small>{props.journeyDirection === "to-work" ? "morning estimate" : "5:30 PM estimate"}</small></div>
        </div>

        <JourneyLegs selected={props.selected} journeyDirection={props.journeyDirection} route={selectedDynamic} showLegend={false} />

        <article className="forecast-evidence" aria-live="polite">
          <div><span>60-minute forecast</span></div>
          <strong>{props.routeForecastPending ? "Checking forecast..." : forecastCount === null ? "Forecast withheld" : `${forecastCount} people/min · ${forecastExceedsLimit ? "above" : "within"} your limit`}</strong>
        </article>

        <button className="support-entry" onClick={props.onFindRefuge}>
          <span><strong>Find a nearby quiet place</strong><small>Calmer public space near your destination</small></span>
          <b aria-hidden="true">›</b>
        </button>
      </div>
    </section>
  );
}

function JourneyLegs({ selected, route, condensed = false, showLegend = true }: { selected: RouteId; journeyDirection?: JourneyDirection; route?: DynamicRoute; condensed?: boolean; showLegend?: boolean }) {
  const legs = route?.legs ?? [];
  const displayedLegs = condensed ? condenseJourneyLegs(route) : legs;
  return <div className="journey-itinerary">
    <ol className="journey-legs" aria-label="Journey legs">
      {displayedLegs.map((leg, index) => <li key={`${leg.mode}-${leg.label}-${index}`}>
        <span className="leg-number">{index + 1}</span><div><b>{leg.mode}</b><strong>{leg.label}</strong></div><time>{leg.duration}</time>
      </li>)}
      {!displayedLegs.length && <li><span className="leg-number">…</span><div><b>Journey</b><strong>Checking your journey...</strong></div><time>—</time></li>}
    </ol>
    {showLegend && <JourneyRouteLegend selected={selected} route={route} />}
  </div>;
}

function JourneyRouteLegend({ selected, route }: { selected: RouteId; route?: DynamicRoute }) {
  return <div className="journey-route-legend" aria-label="Route line legend">
    <span><i className="legend-walk" aria-hidden="true" />Walk <small>dotted line</small></span>
    <span><i className={selected === "route-0" ? "legend-train" : "legend-tram"} aria-hidden="true" />{route ? formatTransportService(route.transportMode, route.service) : "Public transport"} <small>solid line</small></span>
  </div>;
}

function formatTransportService(mode: string, service: string) {
  const cleanMode = mode.replace(/^Mixed\s*·\s*/i, "").trim();
  const cleanService = service.trim();
  if (!cleanMode || cleanMode === "Public transport") return cleanService || "Public transport";
  if (cleanService.toLowerCase().startsWith(cleanMode.toLowerCase())) return cleanService;
  return `${cleanMode} ${cleanService}`;
}

function formatTransportMode(mode: string) {
  return mode.replace(/^Mixed\s*·\s*/i, "").trim() || "Public transport";
}

function formatServiceNumber(mode: string, service: string) {
  const cleanMode = formatTransportMode(mode);
  const cleanService = service.trim();
  return cleanService.toLowerCase().startsWith(cleanMode.toLowerCase())
    ? cleanService.slice(cleanMode.length).trim() || cleanService
    : cleanService;
}

function condenseJourneyLegs(route?: DynamicRoute): DynamicRoute["legs"] {
  const legs = route?.legs ?? [];
  const firstTransit = legs.findIndex((leg) => leg.mode === "Transit");
  if (firstTransit < 0) return legs;

  let lastTransit = firstTransit;
  for (let index = legs.length - 1; index >= firstTransit; index -= 1) {
    if (legs[index].mode === "Transit") {
      lastTransit = index;
      break;
    }
  }

  const firstWalk = legs.slice(0, firstTransit).filter((leg) => leg.mode === "Walk");
  const transitSection = legs.slice(firstTransit, lastTransit + 1);
  const transitLegs = transitSection.filter((leg) => leg.mode === "Transit");
  const lastWalk = legs.slice(lastTransit + 1).filter((leg) => leg.mode === "Walk");
  const service = route ? formatTransportService(route.transportMode, route.service) : "Public transport";
  const transitDirections = transitLegs.map((leg) => leg.label).filter(Boolean).join(" → ");
  const modeLabel = route?.transportMode.replace(/^Mixed\s*·\s*/i, "").trim() ?? "";
  const transitLabel = transitDirections.toLowerCase().includes(route?.service.toLowerCase() ?? "")
    ? transitDirections
    : modeLabel && transitDirections.toLowerCase().startsWith(modeLabel.toLowerCase())
      ? `${service}${transitDirections.slice(modeLabel.length)}`
      : `${service} · ${transitDirections || "Continue towards destination"}`;

  const condensed: DynamicRoute["legs"] = [];
  if (firstWalk.length) condensed.push({ mode: "Walk", label: "Walk towards public transport", duration: totalLegDuration(firstWalk) });
  condensed.push({
    mode: "Transit",
    label: transitLabel,
    duration: totalLegDuration(transitSection),
  });
  if (lastWalk.length) condensed.push({ mode: "Walk", label: "Walk towards destination", duration: totalLegDuration(lastWalk) });
  return condensed;
}

function totalLegDuration(legs: DynamicRoute["legs"]) {
  const minutes = legs.reduce((sum, leg) => {
    const match = leg.duration.match(/([\d.]+)\s*min/i);
    return sum + (match ? Number(match[1]) : 0);
  }, 0);
  return minutes > 0 ? `${Math.round(minutes)} min` : "—";
}

function RealMap({ selected, crowdLimit, trainCount, tramCount, sensorReadings = EMPTY_SENSORS, compact = false, refuge = false, onSelect = () => {}, onRoutesResolved, origin, destination, journeyDirection = "to-work", travelTiming }: { selected: RouteId; crowdLimit: number; trainCount: number | null; tramCount: number | null; sensorReadings?: CrowdData["mapSensors"]; compact?: boolean; refuge?: boolean; onSelect?: (route: RouteId) => void; onRoutesResolved?: (routes: DynamicRoute[]) => void; origin?: string; destination?: string; journeyDirection?: JourneyDirection; travelTiming?: TravelTiming }) {
  const trainRisk = riskFrom(trainCount, crowdLimit);
  const tramRisk = riskFrom(tramCount, crowdLimit);
  const selectedRisk = selected === "route-0" ? trainRisk : tramRisk;
  const otherRisk = selected === "route-0" ? tramRisk : trainRisk;
  const routeStatus = selectedRisk === "Unknown" ? "crowd recommendation unavailable" : selectedRisk === "Low" && otherRisk === "High" ? "avoids the High-crowd segment" : `CBD crowd ${selectedRisk}`;
  return (
    <div className={`real-map-card ${compact ? "compact" : ""}`}>
      <GeographicMap
        trainCount={trainCount}
        tramCount={tramCount}
        trainRisk={trainRisk}
        tramRisk={tramRisk}
        selected={selected}
        refuge={refuge}
        onSelect={onSelect}
        origin={origin}
        destination={destination}
        journeyDirection={journeyDirection}
        travelTiming={travelTiming}
        crowdLimit={crowdLimit}
        sensorReadings={sensorReadings}
        onRoutesResolved={onRoutesResolved}
      />
      {!refuge && <div className="selected-route-badge" aria-label="Selected route status">
        <span>Selected route</span>
        <strong>Google alternative {Number(selected.replace("route-", "")) + 1 || 1} · {routeStatus}</strong>
      </div>}
    </div>
  );
}

function riskFrom(count: number | null, crowdLimit: number): Risk {
  if (count === null) return "Unknown";
  return count > crowdLimit ? "High" : "Low";
}

function getUsableSensors(crowdData: CrowdData | null) {
  return (crowdData?.mapSensors ?? EMPTY_SENSORS).filter(
    (sensor) => (sensor.freshness === "fresh" || sensor.freshness === "delayed") && sensor.peoplePerMinute !== null,
  );
}

function getDataStateCopy(state: DataState) {
  if (state === "fresh") return {
    summary: "Live · CBD sensors only",
    shortReason: "A fresh City observation is available",
    explanation: "High or Low compares the supported CBD pedestrian count with your selected limit.",
    safeResponse: "Compare the current supported CBD observations with your limit.",
  };
  if (state === "loading") return {
    summary: "Checking City sensors",
    shortReason: "Checking for a current observation",
    explanation: "Calm-panion is checking the City of Melbourne pedestrian feed.",
    safeResponse: "Wait for the check to finish or continue without crowd guidance.",
  };
  if (state === "stale") return {
    summary: "Stale · recommendation withheld",
    shortReason: "The latest observation is too old",
    explanation: "The latest observation is older than 30 minutes, so neither route is classified High or Low.",
    safeResponse: "The latest observation is too old. Check again later or continue without crowd guidance.",
  };
  return {
    summary: "Unavailable · recommendation withheld",
    shortReason: "No usable current observation was returned",
    explanation: "No usable current pedestrian observation was returned, so the interface displays Unknown instead of guessing.",
    safeResponse: "Continue without crowd guidance or choose a candidate refuge if needed.",
  };
}

function formatObservation(value: string | null) {
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

function latestMatchedObservation(crowdData: CrowdData | null, sensorIds: number[]) {
  const observations = (crowdData?.mapSensors ?? EMPTY_SENSORS)
    .filter((sensor) => sensorIds.includes(sensor.id) && sensor.latestObservation)
    .map((sensor) => sensor.latestObservation as string)
    .sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
  return observations[0] ?? crowdData?.latestObservation ?? null;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function timingLabel(timing: TravelTiming) {
  if (timing.mode === "now") return "Leave now · current Google estimate";
  if (!timing.dateTime) return timing.mode === "depart" ? "Choose a departure time" : "Choose an arrival time";
  const value = new Date(timing.dateTime);
  if (!Number.isFinite(value.getTime())) return "Choose a valid date and time";
  const formatted = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" }).format(value);
  return `${timing.mode === "depart" ? "Depart" : "Arrive"} · ${formatted}`;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function coverageLabel(route: RouteReading | undefined) {
  if (!route) return "No supported reading";
  return `${route.coverage.usableSensors} of ${route.coverage.supportedSensors} supported sensors · ${route.coverage.scope}`;
}

type RefugeCandidate = {
  name: string;
  address: string;
  type: string;
  walk: string;
  walkMinutes: number | null;
  access: string;
  lat: number;
  lng: number;
  crowdCount: number | null;
  crowdRisk: Risk;
  sensorId: number | null;
  sensorDistance: number | null;
  sensorObservation: string | null;
};

const APPROVED_REFUGE_TYPES = new Set(["library", "park", "community_center", "cultural_center", "museum"]);
const RELIGIOUS_PLACE_TYPES = new Set(["church", "hindu_temple", "mosque", "synagogue", "place_of_worship"]);
const RELIGIOUS_PLACE_WORDS = /\b(church|chapel|cathedral|mosque|masjid|temple|synagogue|shul|parish|diocese|ministry|ministries|christian|catholic|anglican|baptist|presbyterian|lutheran|uniting church|salvation army|islamic|hindu|buddhist|sikh|religious|worship)\b/i;

function isEligibleRefuge(place: any, name: string) {
  const types = [place.primaryType, ...(Array.isArray(place.types) ? place.types : [])]
    .filter(Boolean)
    .map((type) => String(type).toLowerCase());
  const description = `${name} ${place.formattedAddress ?? ""}`;
  return types.some((type) => APPROVED_REFUGE_TYPES.has(type))
    && !types.some((type) => RELIGIOUS_PLACE_TYPES.has(type))
    && !RELIGIOUS_PLACE_WORDS.test(description);
}

function pointDistanceMetres(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const dLat = radians(b.lat - a.lat);
  const dLng = radians(b.lng - a.lng);
  const lat1 = radians(a.lat);
  const lat2 = radians(b.lat);
  const value = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}

function rankRefuges(a: RefugeCandidate, b: RefugeCandidate) {
  // Supported Low readings lead. Supported High readings remain transparent
  // but are deprioritised. Unknown is last and is never treated as Low.
  const riskRank = (candidate: RefugeCandidate) => candidate.crowdRisk === "Low" ? 0 : candidate.crowdRisk === "High" ? 1 : 2;
  return riskRank(a) - riskRank(b)
    || (a.crowdCount ?? Number.POSITIVE_INFINITY) - (b.crowdCount ?? Number.POSITIVE_INFINITY)
    || (a.walkMinutes ?? Number.POSITIVE_INFINITY) - (b.walkMinutes ?? Number.POSITIVE_INFINITY);
}

function QuietSpotScreen({ onBack, arrivalAddress, crowdData, crowdLimit }: { onBack: () => void; arrivalAddress: string; crowdData: CrowdData | null; crowdLimit: number }) {
  const [selectedSpot, setSelectedSpot] = useState("");
  const [candidates, setCandidates] = useState<RefugeCandidate[]>([]);
  const [searchState, setSearchState] = useState<"loading" | "ready" | "unavailable">("loading");
  const selected = candidates.find((candidate) => candidate.name === selectedSpot) ?? candidates[0];

  useEffect(() => {
    let cancelled = false;
    async function findCandidates() {
      setSearchState("loading");
      setCandidates([]);
      try {
        await loadGoogleMaps();
        const [{ Geocoder }, places] = await Promise.all([
          window.google.maps.importLibrary("geocoding"),
          window.google.maps.importLibrary("places"),
        ]);
        const geocoder = new Geocoder();
        const geocoded = await geocoder.geocode({ address: arrivalAddress, region: "AU" });
        const location = geocoded.results?.[0]?.geometry?.location;
        if (!location) throw new Error("ARRIVAL_NOT_FOUND");
        const centre = { lat: location.lat(), lng: location.lng() };
        const fields = ["displayName", "formattedAddress", "location", "primaryType", "primaryTypeDisplayName", "types"];
        const nearbySearch = places.Place.searchNearby({
          fields,
          locationRestriction: { center: centre, radius: 2500 },
          includedPrimaryTypes: ["library", "park", "museum", "community_center", "cultural_center"],
          maxResultCount: 20,
          rankPreference: "DISTANCE",
          language: "en",
          region: "au",
        });
        // Text Search is an independent fallback for Maps projects or API
        // versions that reject one of the typed Nearby Search categories.
        const textSearches = ["public library", "public park", "public garden", "public museum", "civic community centre"].map((kind) =>
          places.Place.searchByText({
            textQuery: `${kind} near ${arrivalAddress}`,
            fields,
            locationBias: { center: centre, radius: 2500 },
            maxResultCount: 8,
            language: "en",
            region: "au",
          })
        );
        const searches = await Promise.allSettled([nearbySearch, ...textSearches]);
        const nearbyPlaces = searches.flatMap((search) => search.status === "fulfilled" ? search.value.places ?? [] : []);
        const placeName = (place: any) => typeof place.displayName === "string" ? place.displayName : place.displayName?.text;
        const unique = [...new Map(nearbyPlaces
          .filter((place: any) => {
            const name = placeName(place);
            return place.location && name && isEligibleRefuge(place, name);
          })
          .map((place: any) => [`${placeName(place)}|${place.formattedAddress ?? ""}`, place]))
          .values()].slice(0, 3) as any[];
        const usableSensors = getUsableSensors(crowdData);
        const initial = unique.map((place: any) => {
          const name = placeName(place);
          const address = place.formattedAddress || `${name}, Melbourne VIC, Australia`;
          const lat = place.location.lat();
          const lng = place.location.lng();
          const nearest = usableSensors
            .map((reading) => {
              const sensor = SENSOR_LOCATIONS.find((item) => item.id === reading.id);
              return sensor ? { reading, distance: Math.round(pointDistanceMetres({ lat, lng }, sensor)) } : null;
            })
            .filter((match): match is NonNullable<typeof match> => Boolean(match))
            .filter((match) => match.distance <= 150)
            .sort((a, b) => a.distance - b.distance)[0];
          const crowdCount = nearest?.reading.peoplePerMinute ?? null;
          const type = place.primaryTypeDisplayName || String(place.primaryType ?? "Public place").replaceAll("_", " ");
          const outdoor = String(place.primaryType ?? "").includes("park");
          return { name, address, type, walk: "Calculating route…", walkMinutes: null, access: outdoor ? "Outdoor public space" : "Opening hours and access may apply", lat, lng, crowdCount, crowdRisk: riskFrom(crowdCount, crowdLimit), sensorId: nearest?.reading.id ?? null, sensorDistance: nearest?.distance ?? null, sensorObservation: nearest?.reading.latestObservation ?? null } satisfies RefugeCandidate;
        }).sort(rankRefuges);
        if (cancelled) return;
        if (!initial.length) throw new Error("NO_CANDIDATES");
        // Show useful candidates immediately; precise walking routes resolve in
        // parallel and update cards progressively.
        setCandidates(initial);
        setSelectedSpot(initial[0].name);
        setSearchState("ready");
        await Promise.all(initial.map(async (candidate) => {
          let walkMinutes: number | null = null;
          try {
            const routeResult = await requestRoutesApi(arrivalAddress, candidate.address, { mode: "now", dateTime: "" }, "WALK");
            const match = String(routeResult.routes?.[0]?.duration ?? "").match(/([\d.]+)s/);
            walkMinutes = match ? Math.max(1, Math.round(Number(match[1]) / 60)) : null;
          } catch { /* Keep the candidate and disclose unavailable route time. */ }
          if (!cancelled) setCandidates((current) => current
            .map((item) => item.name === candidate.name ? { ...item, walkMinutes, walk: walkMinutes ? `${walkMinutes} min` : "Walking time unavailable" } : item)
            .sort(rankRefuges));
        }));
      } catch {
        if (!cancelled) setSearchState("unavailable");
      }
    }
    void findCandidates();
    return () => { cancelled = true; };
  }, [arrivalAddress, crowdData, crowdLimit]);
  return (
    <section className="app-screen quiet-spot-view" aria-label="Quiet Spot Finder">
      <ScreenHeader title="Nearby candidate refuges" subtitle="Calmer and closer public space recommended for you" back={onBack} />

      <div className="quiet-map-panel">
        <div className="real-map-card quiet-map-card">
          {selected ? <GeographicMap trainCount={null} tramCount={null} trainRisk="Unknown" tramRisk="Unknown" selected="tram" refuge quietSpot quietOrigin={arrivalAddress} quietDestination={selected.address} onSelect={() => {}} /> : <div className="route-map-state loading" role="status" aria-live="polite"><strong>{searchState === "loading" ? "Finding refuge options…" : "No supported nearby candidate could be returned for this arrival address."}</strong>{searchState === "loading" && <small>Checking nearby crowd and eligible public places…</small>}</div>}
        </div>
      </div>

      <div className="quiet-detail-stack">
        <div className="refuge-options" role="radiogroup" aria-label="Candidate refuges">
          {candidates.map((candidate) => <button key={candidate.name} role="radio" aria-checked={selectedSpot === candidate.name} className={selectedSpot === candidate.name ? "selected" : ""} onClick={() => setSelectedSpot(candidate.name)}>
            <span>
              <strong>{candidate.name}</strong>
              <small className="refuge-type">{candidate.type}</small>
              <small className="refuge-address">{candidate.address}</small>
            </span>
            <b>{candidate.walkMinutes === null && candidate.walk === "Calculating route…" ? "Calculating walking route…" : candidate.walk}</b>
          </button>)}
        </div>
      </div>
    </section>
  );
}
