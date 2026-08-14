"use client";

import { useEffect, useState } from "react";
import GeographicMap, { type DynamicRoute, type RouteId, type TravelTiming } from "./GeographicMap";
import type { CrowdData, DataState, JourneyDirection, PredictionResponse, Screen } from "./journeyTypes";
import PlaceSearch from "./PlaceSearch";
import QuietSpotScreen from "./QuietSpotScreen";
import {
  assessRoutes,
  EMPTY_SENSORS,
  formatObservation,
  getUsableSensors,
  isVerifiedPrediction,
  latestMatchedObservation,
  riskFrom,
  routeForecastFor,
} from "./routeAssessment";
import { useCrowdData, useRoutePredictions } from "./useJourneyData";

const HOME = "903/8 Pearl River Road, Docklands VIC 3008";
const WORK = "Growth Factory, 3/292 Flinders St, Melbourne VIC 3000";

// Stable timing object — a new `{ mode: "now" }` each render retriggered the
// map effect, which called setDynamicRoutes and looped "Comparing public-transport…".
const DEFAULT_TRAVEL_TIMING: TravelTiming = { mode: "now", dateTime: "" };

export default function Home() {
  const [screen, setScreen] = useState<Screen>("plan");
  const [selectedRoute, setSelectedRoute] = useState<RouteId>("route-0");
  const [homeAddress, setHomeAddress] = useState(HOME);
  const [workAddress, setWorkAddress] = useState(WORK);
  const [crowdLimit, setCrowdLimit] = useState(12);
  const [dynamicRoutes, setDynamicRoutes] = useState<DynamicRoute[]>([]);
  const { crowdData, dataState } = useCrowdData();
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
            onSelect={setSelectedRoute}
            onBack={() => navigate("plan")}
            onContinue={() => {
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
            onBack={() => navigate("routes")}
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

function RoutesScreen({ selected, crowdLimit, onCrowdLimit, dataState, crowdData, onSelect, onBack, onContinue, origin, destination, journeyDirection, dynamicRoutes, routePredictions, routeForecastPending, onRoutesResolved, travelTiming }: { selected: RouteId; crowdLimit: number; onCrowdLimit: (value: number) => void; dataState: DataState; crowdData: CrowdData | null; onSelect: (value: RouteId) => void; onBack: () => void; onContinue: () => void; origin: string; destination: string; journeyDirection: JourneyDirection; dynamicRoutes: DynamicRoute[]; routePredictions: Record<number, PredictionResponse>; routeForecastPending: boolean; onRoutesResolved: (routes: DynamicRoute[]) => void; travelTiming: TravelTiming }) {
  const usableSensors = getUsableSensors(crowdData);
  const dataAvailable = usableSensors.length > 0;
  const trainCount = crowdData?.routes?.train?.peoplePerMinute ?? null;
  const tramCount = crowdData?.routes?.tram?.peoplePerMinute ?? null;
  const safeResponse = getSafeResponse(dataState);
  const assessed = assessRoutes(dynamicRoutes, crowdData, crowdLimit, routePredictions);
  const fastest = assessed.length ? [...assessed].sort((a, b) => a.durationMinutes - b.durationMinutes)[0] : null;
  const lowRoutes = assessed.filter((route) => route.crowdRisk === "Low");
  const recommended = lowRoutes.length ? [...lowRoutes].sort((a, b) => (a.count ?? Infinity) - (b.count ?? Infinity) || a.durationMinutes - b.durationMinutes)[0] : null;
  const highRoutes = assessed.filter((route) => route.crowdRisk === "High" && route.matchedSensorIds.length);
  const avoidedRoute = highRoutes
    .map((route) => ({ route, hotspotId: route.matchedSensorIds.slice().sort((a, b) => {
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
  const selectedForecast = selectedDynamic?.forecast ?? null;
  const forecastSensorName = selectedDynamic?.nearbySensors.find(
    (sensor) => sensor.id === Number(selectedForecast?.sensor_id),
  )?.name ?? (selectedForecast ? `Sensor ${selectedForecast.sensor_id}` : "Selected route");
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
          </div>
        )}
        {!routeForecastPending && (
          <HotspotForecastCard forecast={selectedForecast} sensorName={forecastSensorName} />
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
          forecast={routeForecastPending ? "Checking forecast..." : !route.forecast ? "Unverified" : `${route.forecast.predicted_count_per_minute} people/min · within next ${route.forecast.forecast_horizon_minutes} min`}
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

      {dataState === "loading" ? <p className="recommendation-withheld" role="status" aria-live="polite"><strong>Checking your journey...</strong></p> : !dataAvailable && <p className="recommendation-withheld" role="status"><strong>No crowd recommendation available.</strong><span>{safeResponse}</span></p>}

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
  if (!isVerifiedPrediction(forecast) || forecast.predicted_level !== "High") {
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
  onBack: () => void;
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
          <div><span>{forecastCount === null ? "Forecast" : forecastExceedsLimit ? "60-minute forecast alert" : "60-minute forecast"}</span></div>
          <strong>{props.routeForecastPending ? "Checking forecast..." : forecastCount === null ? "Unverified" : `${forecastCount} people/min · ${forecastExceedsLimit ? "above" : "within"} your limit`}</strong>
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

function getSafeResponse(state: DataState) {
  if (state === "fresh") return "Compare the current supported CBD observations with your limit.";
  if (state === "loading") return "Wait for the check to finish or continue without crowd guidance.";
  if (state === "stale") return "The latest observation is too old. Check again later or continue without crowd guidance.";
  return "Continue without crowd guidance or choose a candidate refuge if needed.";
}
