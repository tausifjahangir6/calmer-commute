"use client";

/*
 * DISPLAY OWNER: preserve the deployed v81 interaction in this file.
 * It consumes Vince's real /api/crowd contract. Route-to-sensor matching is
 * still performed client-side for v81 parity until the follow-up backend PR.
 * Do not replace backend live-feed logic or claim prototype forecast fields
 * are a completed or validated AI model.
 */

import { useEffect, useState } from "react";
import GeographicMap, { loadGoogleMaps, requestRoutesApi, type DynamicRoute, type RouteId, type TravelTiming } from "./GeographicMap";
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

const HOME = "903/8 Pearl River Road, Docklands VIC 3008";
const WORK = "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000";

// FIX (flicker): a stable, shared empty-array reference. Using `crowdData?.mapSensors ?? []`
// inline creates a brand-new array on every render when crowdData is null, which made the
// GeographicMap useEffect (which depends on sensorReadings) re-run forever -> constant
// map rebuild/flicker. Reusing this constant keeps the reference stable across renders.
const EMPTY_SENSORS: CrowdData["mapSensors"] = [];

export default function Home() {
  const [screen, setScreen] = useState<Screen>("plan");
  const [selectedRoute, setSelectedRoute] = useState<RouteId>("route-0");
  const [homeAddress, setHomeAddress] = useState(HOME);
  const [workAddress, setWorkAddress] = useState(WORK);
  const [crowdLimit, setCrowdLimit] = useState(25);
  const [dataState, setDataState] = useState<DataState>("loading");
  const [crowdData, setCrowdData] = useState<CrowdData | null>(null);
  const [alertVisible, setAlertVisible] = useState(true);
  const [routeUpdated, setRouteUpdated] = useState(false);
  const [refreshToken, setRefreshToken] = useState(0);
  const [dynamicRoutes, setDynamicRoutes] = useState<DynamicRoute[]>([]);
  const [testScenario, setTestScenario] = useState(false);
  const travelTiming: TravelTiming = { mode: "now", dateTime: "" };

  useEffect(() => { setDynamicRoutes([]); setSelectedRoute("route-0"); }, [homeAddress, workAddress]);

  useEffect(() => {
    let cancelled = false;
    async function loadCrowdData() {
      try {
        const response = await fetch(testScenario ? "/api/crowd?scenario=2026-08-04T07:00" : "/api/crowd", { cache: "no-store" });
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
  }, [refreshToken, testScenario]);

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
            onHomeAddress={setHomeAddress}
            onWorkAddress={setWorkAddress}
            onContinue={() => navigate("routes")}
            testScenario={testScenario}
            onTestScenario={(value) => { setTestScenario(value); setCrowdLimit(value ? 12 : 25); }}
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
            onRoutesResolved={setDynamicRoutes}
            travelTiming={travelTiming}
          />
        )}

        {screen === "quiet" && <QuietSpotScreen onBack={() => navigate("journey")} arrivalAddress={workAddress} />}
      </div>
    </main>
  );
}

function SiteHeader({ onHome }: { onHome: () => void }) {
  return (
    <header className="site-header">
      <button className="brand-lockup" onClick={onHome} aria-label="Calmer Commute home">
        <span className="brand-mark" aria-hidden="true">C</span>
        <span className="brand-copy">
          <strong>Calmer Commute</strong>
          <em>A sensory-aware way to move through Melbourne</em>
        </span>
      </button>
      <nav className="site-nav" aria-label="Prototype navigation">
        <span className="web-label">Sensory-aware journey planner</span>
      </nav>
    </header>
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
  testScenario: boolean;
  onTestScenario: (value: boolean) => void;
}) {
  return (
    <section className="app-screen plan-view" aria-label="Plan your journey">
      <ScreenHeader
        title="Calmer Commute"
        subtitle="Choose the calmer journey that suits you."
      />

      <div className="planner-panel">
        <div className="location-card">
          <label>
            <span>From</span>
            <PlaceSearch ariaLabel="Departure address" value={props.homeAddress} onChange={props.onHomeAddress} />
          </label>
          <div className="location-connector" aria-hidden="true"><i /><span /></div>
          <label>
            <span>To</span>
            <PlaceSearch ariaLabel="Destination address" value={props.workAddress} onChange={props.onWorkAddress} />
          </label>
        </div>

        <button className="primary-action" onClick={props.onContinue}>Compare routes</button>
        <label className="test-scenario-toggle">
          <input type="checkbox" checked={props.testScenario} onChange={(event) => props.onTestScenario(event.target.checked)} />
          <span><strong>DoD check</strong><small>4 Aug 2026 · 7:00 am historical hourly conditions</small></span>
        </label>
        <p className="planner-note">Crowd preferences can be adjusted on the next screen.</p>
      </div>
    </section>
  );
}

function RoutesScreen({ selected, crowdLimit, onCrowdLimit, dataState, crowdData, onSelect, onBack, onContinue, origin, destination, journeyDirection, dynamicRoutes, onRoutesResolved, travelTiming }: { selected: RouteId; crowdLimit: number; onCrowdLimit: (value: number) => void; dataState: DataState; crowdData: CrowdData | null; onRefresh: () => void; onSelect: (value: RouteId) => void; onBack: () => void; onContinue: () => void; origin: string; destination: string; journeyDirection: JourneyDirection; dynamicRoutes: DynamicRoute[]; onRoutesResolved: (routes: DynamicRoute[]) => void; travelTiming: TravelTiming }) {
  const usableSensors = getUsableSensors(crowdData);
  const dataAvailable = usableSensors.length > 0;
  const trainCount = crowdData?.routes.train.peoplePerMinute ?? null;
  const tramCount = crowdData?.routes.tram.peoplePerMinute ?? null;
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
    const forecast = route.transportMode.toLowerCase().includes("train")
      ? crowdData?.routes.train.forecast
      : crowdData?.routes.tram.forecast;
    const forecastCount = dataAvailable ? forecast?.peoplePerMinute ?? null : null;
    const forecastRisk = riskFrom(forecastCount, crowdLimit);
    const evidenceQuality = directMatched.length ? "direct" : proxyMatched.length ? "proxy" : "none";
    const inferredSensorIds = matched.filter((sensor) => sensor.evidence === "inferred-zero").map((sensor) => sensor.id);
    return { ...route, count, crowdRisk, forecastCount, forecastRisk, forecastHorizonMinutes: forecast?.horizonMinutes ?? 60, evidenceQuality, matchedSensorIds: matched.map((sensor) => sensor.id), inferredSensorIds, nearbyStaleSensorIds: nearbyStale.map((sensor) => sensor.id) };
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
  const verifiedAvoidance = Boolean(avoidedRoute && recommended && displayedHotspotRoute?.hotspotId === avoidedRoute.hotspotId);
  const noLowRoute = assessed.length > 0 && assessed.every((route) => route.crowdRisk === "High");
  useEffect(() => {
    if (!assessed.some((route) => route.id === selected)) onSelect(recommended?.id ?? fastest?.id ?? "route-0");
  }, [assessed.length, recommended?.id, fastest?.id, selected, onSelect]);
  return (
    <section className={`app-screen routes-view ${noLowRoute ? "has-no-low-route" : ""}`} aria-label="Select your path">
      <ScreenHeader title="Sensory-aware journey options" subtitle="Calmer Commute recommends sensory aware routes using supported pedestrian evidence and your crowd limit." back={onBack} />

      <div className="route-threshold" aria-label="Live crowd threshold control">
        <div><strong>Your crowd limit</strong><span>{crowdLimit} people/min</span></div>
        <input aria-label="Crowd threshold in people per minute" type="range" min={crowdData?.scenario ? "5" : "25"} max="200" step={crowdData?.scenario ? "1" : "25"} value={crowdLimit} onChange={(event) => onCrowdLimit(Number(event.target.value))} />
        <small>Adjust your limit to update the route cards and map.</small>
      </div>

      <div className="route-decision-stack">
        {displayedHotspotRoute && hotspotSensor && hotspotMeta && (
          <article className="hotspot-avoidance" aria-live="polite">
            <div className="hotspot-heading"><span aria-hidden="true">!</span><div><small>Supported crowd hotspot</small><strong>{hotspotMeta.name}</strong></div></div>
            <p><b>{hotspotSensor.peoplePerMinute} people/min · High</b> on the {displayedHotspotRoute.route.service} corridor · Sensor {hotspotSensor.id} · {formatObservation(hotspotSensor.latestObservation)}</p>
            {verifiedAvoidance && recommended ? <>
              <div className="avoidance-result"><span aria-hidden="true">✓</span><p><strong>{recommended.service} recommended</strong><small>Avoids this supported High-crowd corridor.</small></p></div>
              <p className="explicit-tradeoff"><strong>Trade-off:</strong> {recommended.durationMinutes === displayedHotspotRoute.route.durationMinutes ? "same journey time" : `${Math.abs(recommended.durationMinutes - displayedHotspotRoute.route.durationMinutes)} min ${recommended.durationMinutes > displayedHotspotRoute.route.durationMinutes ? "longer" : "shorter"}`} · {recommended.walkingMinutes === displayedHotspotRoute.route.walkingMinutes ? "same walking time" : `${Math.abs(recommended.walkingMinutes - displayedHotspotRoute.route.walkingMinutes)} min ${recommended.walkingMinutes > displayedHotspotRoute.route.walkingMinutes ? "more" : "less"} walking`}</p>
            </> : <p className="explicit-tradeoff"><strong>No verified lower-crowd alternative avoids this hotspot right now.</strong></p>}
          </article>
        )}
        <button className="primary-action" onClick={onContinue} disabled={!selectedDynamic}>{selectedDynamic ? `Start ${selectedDynamic.service} journey` : "Waiting for Google routes"}</button>
      </div>

      <div className="route-cards" role="radiogroup" aria-label="Route options">
        {orderedRoutes.map((route, index) => <RouteCard key={route.id}
          rank={index + 1}
          title={route.service}
          transportMode={route.transportMode}
          duration={route.duration}
          load={`Current crowd · ${route.crowdRisk}`}
          detail={route.count === null ? "Current crowd unavailable" : `${route.count} people/min · ${crowdData?.scenario ? "historical hourly average" : "latest available"} · ${route.count > crowdLimit ? "above" : "within"} your ${crowdLimit}/min limit`}
          forecast={route.forecastCount === null ? "Forecast unavailable" : `${route.forecastHorizonMinutes} min forecast · ${route.forecastRisk} expected · ${route.forecastCount} people/min predicted`}
          evidence={`${route.walkingMinutes} min walking · ${route.transfers} transfer${route.transfers === 1 ? "" : "s"} · ${route.evidenceQuality === "direct" ? `${route.matchedSensorIds.length} direct sensor${route.matchedSensorIds.length === 1 ? "" : "s"} (≤75 m)` : route.evidenceQuality === "proxy" ? `${route.matchedSensorIds.length} proxy sensor${route.matchedSensorIds.length === 1 ? "" : "s"} (75–150 m)` : route.nearbyStaleSensorIds.length ? `nearby sensor${route.nearbyStaleSensorIds.length === 1 ? "" : "s"} ID ${route.nearbyStaleSensorIds.join(", ")} found · latest reading stale` : "no sensor reading available within 150 m"}`}
          tradeoff={route.crowdRisk === "Unknown" ? "No sensory recommendation · evidence unavailable" : route.inferredSensorIds.length ? `${route.crowdRisk} (inferred) · Active sensor · no detections in latest complete 15-minute window` : route.evidenceQuality === "proxy" ? `${route.crowdRisk} · lower-confidence nearby-area proxy · partial coverage` : `${route.crowdRisk}: ${route.count} ${route.count !== null && route.count > crowdLimit ? ">" : "≤"} ${crowdLimit} people/min`}
          tone={route.crowdRisk === "Unknown" ? "neutral" : route.crowdRisk === "High" ? "warm" : "calm"}
          selected={selectedDynamic?.id === route.id}
          recommended={recommended?.id === route.id}
          onClick={() => onSelect(route.id)}
        />)}
        {!assessed.length && <p className="recommendation-withheld"><strong>Requesting Google alternatives…</strong><span>The cards will appear when genuine public-transport routes are returned.</span></p>}
      </div>

      {crowdData?.scenario && <p className="scenario-banner" role="status"><strong>DoD check</strong><span>{crowdData.scenario.label} · {crowdData.scenario.observationWindow}</span></p>}

      <div className="selection-copy" aria-live="polite">
        <span>{selectedDynamic ? `${selectedDynamic.service} selected` : "Waiting for Google routes"}</span>
        <strong>{selectedDynamic ? `${selectedDynamic.duration} · ${selectedDynamic.crowdRisk} crowd classification` : "No route assessment yet"}</strong>
      </div>

      <section className="route-preview" aria-label={`${selectedDynamic?.service ?? "Google public transport"} route preview`}>
        <div className="route-preview-heading">
          <div>
            <span>Selected route preview</span>
            <h2>{selectedDynamic?.service ?? "Google public transport"}</h2>
          </div>
          <strong>{selectedDynamic?.duration ?? "Checking…"}</strong>
        </div>
        <RealMap selected={selected} crowdLimit={crowdLimit} trainCount={trainCount} tramCount={tramCount} sensorReadings={crowdData?.mapSensors ?? EMPTY_SENSORS} refuge origin={origin} destination={destination} journeyDirection={journeyDirection} onRoutesResolved={onRoutesResolved} travelTiming={travelTiming} />
        <JourneyLegs selected={selected} journeyDirection={journeyDirection} route={selectedDynamic} />
      </section>

      {!dataAvailable && <p className="recommendation-withheld" role="status"><strong>No crowd recommendation available.</strong><span>{dataStateCopy.safeResponse}</span></p>}

      {noLowRoute && <p className="no-low-route" role="status"><strong>No route is within your crowd limit right now.</strong><span>You can wait and check again, or continue with either route. Calmer Commute will not block your choice.</span></p>}

      {highRoutes.length > 0 && !noLowRoute && !avoidedRoute && <p className="no-low-route" role="status"><strong>No verified route avoids the supported High-crowd corridor.</strong><span>A lower-scoring route may exist, but Calmer Commute will not claim corridor avoidance without supported evidence.</span></p>}

    </section>
  );
}

function RouteCard(props: { rank: number; title: string; transportMode: string; duration: string; load: string; detail: string; forecast: string; evidence: string; tradeoff: string; tone: "warm" | "calm" | "neutral"; selected: boolean; recommended?: boolean; onClick: () => void }) {
  return (
    <button className={`route-card ${props.tone} ${props.selected ? "selected" : ""}`} role="radio" aria-checked={props.selected} onClick={props.onClick}>
      <span className="route-rank">Suggestion {props.rank}</span>
      <div className="route-labels">
        {props.recommended && <span className="recommended">Recommended · Low crowd</span>}
      </div>
      <span className="route-radio" aria-hidden="true"><i /></span>
      <span className="transport-mode" aria-label={`Transport mode: ${props.transportMode || "Public transport"}`}>
        {props.transportMode || "Public transport"}
      </span>
      <h2>{props.title}</h2>
      <strong>{props.duration}</strong>
      <div className="load-badge"><span aria-hidden="true">{props.tone === "warm" ? "!" : props.tone === "neutral" ? "?" : "✓"}</span>{props.load}</div>
      <p>{props.detail}</p>
      <p className="route-forecast">{props.forecast}</p>
      <small className="route-evidence">{props.evidence}</small>
      <small className="route-tradeoff">{props.tradeoff}</small>
    </button>
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
  onRoutesResolved: (routes: DynamicRoute[]) => void;
  travelTiming: TravelTiming;
}) {
  const trainSelected = props.selected === props.dynamicRoutes[0]?.id;
  const usableSensors = getUsableSensors(props.crowdData);
  const dataAvailable = usableSensors.length > 0;
  const trainCount = props.crowdData?.routes.train.peoplePerMinute ?? null;
  const tramCount = props.crowdData?.routes.tram.peoplePerMinute ?? null;
  const selectedDynamic = props.dynamicRoutes.find((route) => route.id === props.selected) ?? props.dynamicRoutes[0];
  const alternateDynamic = props.dynamicRoutes.find((route) => route.id !== selectedDynamic?.id);
  const countFor = (route?: DynamicRoute) => {
    if (!route) return null;
    const directMatched = usableSensors.filter((sensor) => route.directSensorIds.includes(sensor.id));
    const matched = directMatched.length ? directMatched : usableSensors.filter((sensor) => route.proxySensors.some((proxy) => proxy.id === sensor.id));
    return matched.length ? Math.max(...matched.map((sensor) => sensor.peoplePerMinute as number)) : null;
  };
  const selectedCount = countFor(selectedDynamic);
  const alternateCount = countFor(alternateDynamic);
  const selectedExceedsLimit = selectedCount !== null && selectedCount > props.crowdLimit;
  const alternateWithinLimit = alternateCount !== null && alternateCount <= props.crowdLimit;
  const selectedCorridor = `${selectedDynamic?.service ?? "Selected route"} supported CBD approach`;
  const alternateMode = alternateDynamic?.service ?? "other Google alternative";
  const liveForecast = trainSelected ? props.crowdData?.routes.train.forecast : props.crowdData?.routes.tram.forecast;
  const forecastCount = dataAvailable ? liveForecast?.peoplePerMinute ?? null : null;
  const forecastExceedsLimit = forecastCount !== null && forecastCount > props.crowdLimit;
  return (
    <section className="app-screen journey-view" aria-label="Your journey">
      <ScreenHeader title={props.journeyDirection === "to-work" ? "Freddy’s journey to work" : "Freddy’s journey home"} subtitle={dataAvailable ? `City sensor update · ${formatObservation(props.crowdData?.latestObservation ?? null)} · CBD approach only` : "Current CBD crowd classification unavailable"} back={props.onBack} />

      <RealMap selected={props.selected} crowdLimit={props.crowdLimit} trainCount={trainCount} tramCount={tramCount} sensorReadings={props.crowdData?.mapSensors ?? EMPTY_SENSORS} refuge origin={props.origin} destination={props.destination} journeyDirection={props.journeyDirection} onRoutesResolved={props.onRoutesResolved} travelTiming={props.travelTiming} />

      <div className="next-step-card">
        <span>Next</span>
        <h2>{selectedDynamic?.legs[0]?.label ?? "Follow the selected Google journey"}</h2>
        <div><strong>{selectedDynamic?.duration ?? "Checking…"}</strong><small>{props.journeyDirection === "to-work" ? "morning estimate" : "5:30 PM estimate"}</small></div>
      </div>

      <JourneyLegs selected={props.selected} journeyDirection={props.journeyDirection} route={selectedDynamic} />

      <article className="forecast-evidence" aria-live="polite">
        <div><span>60-minute forecast</span><b>{liveForecast?.confidence ?? "Unavailable"}</b></div>
        <strong>{forecastCount === null ? "Forecast withheld" : `${forecastCount} people/min · ${forecastExceedsLimit ? "above" : "within"} your limit`}</strong>
        <small>{liveForecast?.validationMae === null || liveForecast?.validationMae === undefined ? "Insufficient holdout data for a runtime error estimate." : `${liveForecast.method}; runtime holdout MAE ${liveForecast.validationMae} people/min.`}</small>
      </article>

      {props.alertVisible && (selectedExceedsLimit || forecastExceedsLimit) && (
        <article className="journey-alert urgent" aria-live="polite">
          <button className="dismiss-alert" onClick={props.onDismiss} aria-label="Dismiss crowd alert">×</button>
          <div><span aria-hidden="true">!</span><p><b className="alert-kicker">{forecastExceedsLimit ? "Next-hour forecast" : "City sensor update"}</b><strong>{forecastExceedsLimit ? "Crowding may exceed your limit before arrival" : "Pedestrian crowd is above your limit"}</strong><small>{selectedCorridor} is {forecastExceedsLimit ? `forecast at ${forecastCount}` : `currently ${selectedCount}`} people/min. This applies only to the supported CBD approach and does not describe crowding onboard.</small></p></div>
          {alternateWithinLimit
            ? <div className="alert-actions"><button className="alert-action" onClick={props.onReroute}>Switch to the {alternateMode} route</button><button className="alert-refuge-action" onClick={props.onFindRefuge}>Find a nearby quiet place</button></div>
            : <><p className="safe-response"><strong>No lower-crowd route is available now.</strong> You can wait, leave later or continue. Calmer Commute will not block the journey.</p><button className="alert-refuge-action" onClick={props.onFindRefuge}>Find a nearby quiet place</button></>}
        </article>
      )}

      {!dataAvailable && <article className="journey-data-unavailable" role="status"><strong>Crowd recommendation unavailable</strong><p>{getDataStateCopy(props.dataState).safeResponse}</p><button className="alert-refuge-action" onClick={props.onFindRefuge}>Find a nearby quiet place</button></article>}

      {props.routeUpdated && <p className="route-confirmation" role="status"><span aria-hidden="true">✓</span> Route updated. Check the current CBD approach reading above. Onboard crowding remains unknown.</p>}

      {dataAvailable && !(props.alertVisible && selectedExceedsLimit) && <button className="support-entry" onClick={props.onFindRefuge}>
        <span><strong>Find a nearby quiet place</strong><small>Candidate public refuges ranked from your entered arrival address</small></span>
        <b aria-hidden="true">›</b>
      </button>}
    </section>
  );
}

function JourneyLegs({ selected, route }: { selected: RouteId; journeyDirection?: JourneyDirection; route?: DynamicRoute }) {
  const legs = route?.legs ?? [];
  return <div className="journey-itinerary">
    <ol className="journey-legs" aria-label="Journey legs">
      {legs.map((leg, index) => <li key={`${leg.mode}-${leg.label}-${index}`}>
        <span className="leg-number">{index + 1}</span><div><b>{leg.mode}</b><strong>{leg.label}</strong><small>{leg.mode === "Transit" ? "Onboard crowding Unknown" : "Walking exposure included in sensory score"}</small></div><time>{leg.duration}</time>
      </li>)}
      {!legs.length && <li><span className="leg-number">…</span><div><b>Google route</b><strong>Requesting itinerary</strong><small>No fixed service is substituted.</small></div><time>—</time></li>}
    </ol>
    <div className="journey-route-legend" aria-label="Route line legend">
      <span><i className="legend-walk" aria-hidden="true" />Walk <small>dotted line</small></span>
      <span><i className={selected === "route-0" ? "legend-train" : "legend-tram"} aria-hidden="true" />{route?.service ?? "Public transport"} <small>solid line</small></span>
    </div>
  </div>;
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
    explanation: "Calmer Commute is checking the City of Melbourne pedestrian feed.",
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

function timingLabel(timing: TravelTiming) {
  if (timing.mode === "now") return "Leave now · current Google estimate";
  if (!timing.dateTime) return timing.mode === "depart" ? "Choose a departure time" : "Choose an arrival time";
  const value = new Date(timing.dateTime);
  if (!Number.isFinite(value.getTime())) return "Choose a valid date and time";
  const formatted = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" }).format(value);
  return `${timing.mode === "depart" ? "Depart" : "Arrive"} · ${formatted}`;
}

function coverageLabel(route: RouteReading | undefined) {
  if (!route) return "No supported reading";
  return `${route.coverage.usableSensors} of ${route.coverage.supportedSensors} supported sensors · ${route.coverage.scope}`;
}

type RefugeCandidate = { name: string; address: string; type: string; walk: string; walkMinutes: number; access: string };

function QuietSpotScreen({ onBack, arrivalAddress }: { onBack: () => void; arrivalAddress: string }) {
  const [navigationStarted, setNavigationStarted] = useState(false);
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
        const fields = ["displayName", "formattedAddress", "location", "primaryType", "primaryTypeDisplayName"];
        const nearbySearch = places.Place.searchNearby({
          fields,
          locationRestriction: { center: centre, radius: 2500 },
          includedPrimaryTypes: ["library", "park", "museum", "community_center"],
          maxResultCount: 20,
          rankPreference: "DISTANCE",
          language: "en",
          region: "au",
        });
        // Text Search is an independent fallback for Maps projects or API
        // versions that reject one of the typed Nearby Search categories.
        const textSearches = ["public library", "public park", "museum", "community centre"].map((kind) =>
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
          .filter((place: any) => place.location && placeName(place))
          .map((place: any) => [`${placeName(place)}|${place.formattedAddress ?? ""}`, place]))
          .values()].slice(0, 12) as any[];
        const resolved = await Promise.all(unique.map(async (place: any) => {
          const name = placeName(place);
          const address = place.formattedAddress || `${name}, Melbourne VIC, Australia`;
          let walkMinutes = 0;
          try {
            const routeResult = await requestRoutesApi(arrivalAddress, address, { mode: "now", dateTime: "" }, "WALK");
            const match = String(routeResult.routes?.[0]?.duration ?? "").match(/([\d.]+)s/);
            walkMinutes = match ? Math.max(1, Math.round(Number(match[1]) / 60)) : 0;
          } catch { /* Keep the place, but do not invent a duration. */ }
          const type = place.primaryTypeDisplayName || String(place.primaryType ?? "Public place").replaceAll("_", " ");
          const outdoor = String(place.primaryType ?? "").includes("park");
          return { name, address, type, walk: walkMinutes ? `${walkMinutes} min` : "Check route", walkMinutes: walkMinutes || 999, access: outdoor ? "Outdoor public space" : "Opening hours and access may apply" };
        }));
        if (cancelled) return;
        const ranked = resolved.sort((a, b) => a.walkMinutes - b.walkMinutes).slice(0, 3);
        if (!ranked.length) throw new Error("NO_CANDIDATES");
        setCandidates(ranked);
        setSelectedSpot(ranked[0].name);
        setSearchState("ready");
      } catch {
        if (!cancelled) setSearchState("unavailable");
      }
    }
    void findCandidates();
    return () => { cancelled = true; };
  }, [arrivalAddress]);
  return (
    <section className="app-screen quiet-spot-view" aria-label="Quiet Spot Finder">
      <ScreenHeader title="Nearby candidate refuges" subtitle={`Public facilities and open spaces ranked from your arrival at ${arrivalAddress}, with uncertainty shown clearly.`} back={onBack} />

      <div className="quiet-map-panel">
        <div className="real-map-card quiet-map-card">
          {selected ? <GeographicMap trainCount={null} tramCount={null} trainRisk="Unknown" tramRisk="Unknown" selected="tram" refuge quietSpot quietOrigin={arrivalAddress} quietDestination={selected.address} onSelect={() => {}} /> : <div className="route-map-state loading" role="status"><strong>{searchState === "loading" ? "Finding candidate refuges near your arrival…" : "No supported nearby candidate could be returned for this arrival address."}</strong></div>}
          <div className="real-map-caption"><span>Distance and time determined by Google Maps</span><strong>Walking route · live handoff</strong></div>
        </div>
      </div>

      <div className="quiet-detail-stack">
        <div className="refuge-options" role="radiogroup" aria-label="Candidate refuges">
          {candidates.map((candidate) => <button key={candidate.name} role="radio" aria-checked={selectedSpot === candidate.name} className={selectedSpot === candidate.name ? "selected" : ""} onClick={() => { setSelectedSpot(candidate.name); setNavigationStarted(false); }}><span><strong>{candidate.name}</strong><small>{candidate.type}</small></span><b>{candidate.walk}</b></button>)}
        </div>
        {selected ? <><article className="availability-card">
          <span>Candidate refuge</span>
          <h2>{selected.name}</h2>
          <p>{selected.address}. Ranked by current walking proximity and place type. Current quietness is not verified, so the app never labels it “quiet now.”</p>
        </article>

        <article className="spot-detail-card">
          <span>What is known</span>
          <dl>
            <div><dt>Type</dt><dd>{selected.type}</dd></div>
            <div><dt>Crowd</dt><dd>Current reading unavailable</dd></div>
            <div><dt>Noise</dt><dd>Live dB data unavailable</dd></div>
            <div><dt>Access</dt><dd>{selected.access} · verify before relying on it</dd></div>
          </dl>
        </article>

        <button className="primary-action" onClick={() => setNavigationStarted(true)}>{navigationStarted ? "Directions ready" : `Start ${selected.walk} walk`}</button>
        {navigationStarted && <p className="quiet-navigation-status" role="status"><span aria-hidden="true">✓</span> Directions are ready. You can return to the journey at any time.</p>}
        </> : <article className="journey-data-unavailable" role="status"><strong>{searchState === "loading" ? "Finding nearby candidates" : "Candidate refuge search unavailable"}</strong><p>{searchState === "loading" ? "Searching near the entered arrival address." : "No supported park, library, museum or community facility was returned near this arrival. No fixed refuge is being substituted."}</p></article>}
      </div>
    </section>
  );
}
