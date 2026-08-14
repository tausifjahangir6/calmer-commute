"use client";
/*
 * DISPLAY OWNER: this is the v81 map/overlay implementation.
 * Keep selected-route rendering, sensor markers, 75 m direct / 150 m proxy
 * matching and hotspot display together for first integration parity.
 * The currently merged Flask /api/routes/compare is not the v81 scoring source.
 * Coordinate with the backend owner before moving any of this contract.
 */

import { useEffect, useRef, useState } from "react";

/* eslint-disable @typescript-eslint/no-explicit-any */

type Risk = "High" | "Low" | "Unknown";
export type RouteId = string;
export type TravelTiming = { mode: "now" | "depart" | "arrive"; dateTime: string };
export type DynamicLeg = { mode: "Walk" | "Transit"; label: string; duration: string };
export type DynamicRoute = {
  id: RouteId;
  service: string;
  transportMode: string;
  duration: string;
  durationMinutes: number;
  walkingMinutes: number;
  transfers: number;
  legs: DynamicLeg[];
  nearbySensorIds: number[];
  directSensorIds: number[];
  proxySensors: { id: number; distanceMetres: number }[];
  routePath: { lat: number; lng: number }[];
  nearbySensors: { id: number; name: string; distanceMetres: number }[];
};
type MapSensorReading = { id: number; peoplePerMinute: number | null; latestObservation: string | null; sampleMinutes: number; freshness: "fresh" | "delayed" | "stale" | "unavailable"; evidence: "observed" | "inferred-zero" | "unavailable"; operationalStatus: "active" | "inactive" | "unknown" };
type Props = { trainCount: number | null; tramCount: number | null; trainRisk: Risk; tramRisk: Risk; selected: RouteId; refuge: boolean; quietSpot?: boolean; quietOrigin?: string; quietDestination?: string; crowdLimit?: number; sensorReadings?: MapSensorReading[]; onSelect: (route: RouteId) => void; onRoutesResolved?: (routes: DynamicRoute[]) => void; origin?: string; destination?: string; journeyDirection?: "to-work" | "home"; travelTiming?: TravelTiming; };
type RouteState = "loading" | "ready" | "not-found" | "unconfigured" | "error";

declare global {
  interface Window {
    google?: any;
    __calmerCommuteMapsPromise?: Promise<void>;
    __calmerCommuteMapsApiKey?: string;
    __calmerCommuteMapsApiKeyPromise?: Promise<string>;
  }
}

const HOME = "903/8 Pearl River Road, Docklands VIC 3008, Australia";
const WORK = "Growth Factory, 3/292 Flinders Street, Melbourne VIC 3000, Australia";
const CITY_LIBRARY = "City Library, 253 Flinders Lane, Melbourne VIC 3000, Australia";

export type SensorLocation = { id: number; name: string; lat: number; lng: number };

async function getMapsApiKey() {
  if (window.__calmerCommuteMapsApiKey) return window.__calmerCommuteMapsApiKey;
  if (!window.__calmerCommuteMapsApiKeyPromise) {
    window.__calmerCommuteMapsApiKeyPromise = (async () => {
      const response = await fetch("/api/maps-config", { cache: "no-store" });
      if (!response.ok) throw new Error("MAPS_NOT_CONFIGURED");
      const { apiKey } = await response.json() as { apiKey?: string };
      if (!apiKey) throw new Error("MAPS_NOT_CONFIGURED");
      window.__calmerCommuteMapsApiKey = apiKey;
      return apiKey;
    })().catch((error) => {
      window.__calmerCommuteMapsApiKeyPromise = undefined;
      throw error;
    });
  }
  return window.__calmerCommuteMapsApiKeyPromise;
}

// All 65 coordinate rows from pivoted_cleaned_20260808.csv.
export const SENSOR_LOCATIONS: SensorLocation[] = `1|Bourke Street Mall (North)|-37.813494|144.965153
2|Bourke Street Mall (South)|-37.813807|144.965167
3|Melbourne Central|-37.811015|144.964295
4|Town Hall (West)|-37.81488|144.966088
5|Princes Bridge|-37.818742|144.967877
6|Flinders Underpass - Myki Barriers|-37.819074|144.965579
8|Webb Bridge|-37.822935|144.947175
9|Southern Cross Station|-37.81983|144.951026
10|Victoria Point|-37.818765|144.947105
11|Docklands Waterfront City Building Side|-37.815667|144.939744
12|New Quay|-37.81458|144.942924
14|Sandridge Bridge|-37.820112|144.962919
17|Collins Place (South)|-37.813625|144.973236
18|Collins Place (North)|-37.813449|144.973054
19|Chinatown-Swanston St (North)|-37.812372|144.965507
20|Chinatown-Lt Bourke St (South)|-37.811729|144.968247
21|155-161 Russell Street|-37.812673|144.967883
23|Spencer St-Collins St (South)|-37.819093|144.954527
24|Spencer St-Collins St (North)|-37.81888|144.954492
25|Melbourne Convention Exhibition Centre|-37.824018|144.956044
27|QV Market-Peel St|-37.806069|144.956447
29|St Kilda Rd-Alexandra Gardens|-37.819982|144.968729
30|Lonsdale St (South)|-37.811219|144.966568
31|Lygon St (West)|-37.801697|144.966589
35|Southbank Promenade|-37.820187|144.965085
36|Queen St (West)|-37.816525|144.961211
37|Lygon St (East)|-37.801071|144.967046
39|Alfred Place|-37.813797|144.969957
40|Lonsdale St-Spring St (West)|-37.809993|144.972276
41|Flinders La-Swanston St (West)|-37.816686|144.966897
42|Grattan St-Swanston St (West)|-37.800086|144.963864
43|Monash Rd-Swanston St (West)|-37.798445|144.964118
44|Tin Alley-Swanston St (West)|-37.796987|144.964413
45|Little Collins St-Swanston St (East)|-37.814141|144.966094
46|Pelham St (South)|-37.802407|144.961567
47|Melbourne Central-Elizabeth St (East)|-37.812585|144.962578
48|QVM-Queen St (East)|-37.806316|144.958667
49|QVM-Therry St (South)|-37.807301|144.959561
50|Faraday St-Lygon St (West)|-37.798082|144.96721
51|QVM-Franklin St (North)|-37.808418|144.959063
52|Elizabeth St-Lonsdale St (South)|-37.812522|144.96194
53|Collins Street (North)|-37.815642|144.965499
54|Lincoln-Swanston (West)|-37.804024|144.963084
56|Lonsdale St - Elizabeth St (North)|-37.812348|144.961533
58|Bourke St - Spencer St (North)|-37.816861|144.953581
59|Building 80 RMIT|-37.808256|144.963049
61|RMIT Building 14|-37.807675|144.963091
62|La Trobe St (North)|-37.809965|144.962165
63|231 Bourke St|-37.813331|144.966756
66|QV2 Apartments, 300 Swanston Street|-37.810578|144.964443
67|Flinders Ln -Degraves St (South)|-37.816888|144.965626
68|Flinders Ln -Degraves St (North)|-37.816848|144.965598
69|Flinders Ln -Degraves St (Crossing)|-37.816872|144.965591
70|Errol Street (East)|-37.80457|144.949462
71|Westwood Place|-37.812358|144.97137
72|Flinders St- ACMI|-37.817263|144.968728
75|Spring St- Flinders st (West)|-37.815153|144.974677
76|Macaulay Rd- Bellair St|-37.794538|144.930362
77|Harbour Esplanade (West) - Pedestrian path|-37.814414|144.94433
79|Flinders St (South)|-37.81794|144.966167
84|Elizabeth St - Flinders St (East) - New footpath|-37.81798|144.965034
85|Macaulay Rd (North)|-37.794324|144.929734
86|Queensberry St - Errol St (South)|-37.8031|144.949081
87|Errol St (West)|-37.804549|144.949219
107|Royal Mint 280 William St|-37.812463|144.956902`
  .split("\n")
  .map((row) => {
    const [id, name, lat, lng] = row.split("|");
    return { id: Number(id), name, lat: Number(lat), lng: Number(lng) };
  });

function googleDirections(origin: string, destination: string, mode: "transit" | "walking") {
  const params = new URLSearchParams({ api: "1", origin, destination, travelmode: mode });
  return `https://www.google.com/maps/dir/?${params.toString()}`;
}

export async function loadGoogleMaps() {
  if (window.google?.maps?.importLibrary) return;
  if (window.__calmerCommuteMapsPromise) return window.__calmerCommuteMapsPromise;
  window.__calmerCommuteMapsPromise = (async () => {
    const apiKey = await getMapsApiKey();
    await new Promise<void>((resolve, reject) => {
      const callback = `__calmerCommuteMapsReady_${Date.now()}`;
      (window as any)[callback] = () => { delete (window as any)[callback]; resolve(); };
      const script = document.createElement("script");
      script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}&v=weekly&loading=async&language=en&region=AU&callback=${callback}`;
      script.async = true;
      script.onerror = () => {
        window.__calmerCommuteMapsPromise = undefined;
        reject(new Error("MAPS_LOAD_FAILED"));
      };
      document.head.appendChild(script);
    });
  })().catch((error) => {
    window.__calmerCommuteMapsPromise = undefined;
    throw error;
  });
  return window.__calmerCommuteMapsPromise;
}

function routeTime(timing?: TravelTiming) {
  if (!timing || timing.mode === "now") return new Date(Date.now() + 60_000);
  const chosen = new Date(timing.dateTime);
  return Number.isFinite(chosen.getTime()) ? chosen : new Date(Date.now() + 60_000);
}

function coordinate(point: any) { return { lat: typeof point.lat === "function" ? point.lat() : point.lat, lng: typeof point.lng === "function" ? point.lng() : point.lng }; }
function minutes(value: unknown) {
  if (typeof value === "number") return Math.round(value / 60);
  const match = String(value ?? "").match(/([\d.]+)s/);
  return match ? Math.round(Number(match[1]) / 60) : 0;
}
function stepMode(step: any) { return String(step?.travelMode ?? step?.travel_mode ?? "").toUpperCase() === "WALK" || String(step?.travelMode ?? step?.travel_mode ?? "").toUpperCase() === "WALKING" ? "Walk" : "Transit"; }
function serviceNames(route: any) {
  const names: string[] = [];
  for (const leg of route?.legs ?? []) for (const step of leg?.steps ?? []) {
    const detail = step?.transitDetails ?? step?.transit;
    const line = detail?.transitLine ?? detail?.line ?? {};
    const name = line.nameShort ?? line.shortName ?? line.short_name ?? line.name;
    if (name && !names.includes(String(name))) names.push(String(name));
  }
  return names.length ? names.join(" + ") : "Public transport";
}
function transportMode(route: any) {
  const modes: string[] = [];
  const labels: Record<string, string> = {
    BUS: "Bus",
    COACH: "Bus",
    INTERCITY_BUS: "Bus",
    TROLLEYBUS: "Bus",
    TRAM: "Tram",
    LIGHT_RAIL: "Tram",
    RAIL: "Train",
    HEAVY_RAIL: "Train",
    COMMUTER_TRAIN: "Train",
    HIGH_SPEED_TRAIN: "Train",
    INTERCITY_TRAIN: "Train",
    LONG_DISTANCE_TRAIN: "Train",
    METRO_RAIL: "Train",
    MONORAIL: "Train",
    SUBWAY: "Train",
  };
  for (const leg of route?.legs ?? []) for (const step of leg?.steps ?? []) {
    const detail = step?.transitDetails ?? step?.transit;
    if (!detail) continue;
    const line = detail?.transitLine ?? detail?.line ?? {};
    const rawType = line?.vehicle?.type ?? detail?.vehicle?.type;
    const vehicleName = line?.vehicle?.name?.text ?? line?.vehicle?.name ?? detail?.vehicle?.name?.text ?? detail?.vehicle?.name;
    const searchable = [
      rawType,
      vehicleName,
      line?.name,
      line?.nameLong,
      line?.longName,
      step?.navigationInstruction?.instructions,
      step?.instructions,
    ].filter(Boolean).join(" ").toUpperCase();
    const label = labels[String(rawType ?? "").toUpperCase()]
      ?? (/TRAM|LIGHT[ _-]?RAIL/.test(searchable) ? "Tram"
        : /TRAIN|RAIL|SUBWAY|METRO/.test(searchable) ? "Train"
          : /BUS|COACH/.test(searchable) ? "Bus"
            : "Public transport");
    if (!modes.includes(label)) modes.push(label);
  }
  return modes.length > 1 ? `Mixed · ${modes.join(" + ")}` : modes[0] ?? "Public transport";
}
function metresBetween(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const rad = Math.PI / 180;
  const dLat = (b.lat - a.lat) * rad;
  const dLng = (b.lng - a.lng) * rad;
  const x = dLng * Math.cos(((a.lat + b.lat) / 2) * rad);
  return 6371000 * Math.sqrt(dLat * dLat + x * x);
}
function pointToSegmentMetres(point: { lat: number; lng: number }, start: { lat: number; lng: number }, end: { lat: number; lng: number }) {
  const metresPerLat = 111_320;
  const metresPerLng = metresPerLat * Math.cos(point.lat * Math.PI / 180);
  const ax = (start.lng - point.lng) * metresPerLng;
  const ay = (start.lat - point.lat) * metresPerLat;
  const bx = (end.lng - point.lng) * metresPerLng;
  const by = (end.lat - point.lat) * metresPerLat;
  const dx = bx - ax;
  const dy = by - ay;
  const lengthSquared = dx * dx + dy * dy;
  const t = lengthSquared === 0 ? 0 : Math.max(0, Math.min(1, -(ax * dx + ay * dy) / lengthSquared));
  return Math.hypot(ax + t * dx, ay + t * dy);
}
function distanceToRoute(point: { lat: number; lng: number }, path: { lat: number; lng: number }[]) {
  if (!path.length) return Infinity;
  if (path.length === 1) return metresBetween(point, path[0]);
  let closest = Infinity;
  for (let index = 1; index < path.length; index += 1) {
    closest = Math.min(closest, pointToSegmentMetres(point, path[index - 1], path[index]));
  }
  return closest;
}
function routeMeta(route: any, index: number): DynamicRoute {
  const legs: DynamicLeg[] = [];
  // Sensor coverage follows the complete suggested journey, not only its walk steps.
  // Prefer Google's overview polyline because it includes departure, transit and
  // arrival geometry; retain step geometry as a fallback for response variants.
  const routePath: { lat: number; lng: number }[] = route?.polyline?.encodedPolyline
    ? decodePolyline(route.polyline.encodedPolyline)
    : [];
  const hasOverviewPath = routePath.length > 0;
  let walkingMinutes = 0;
  let transitSteps = 0;
  for (const leg of route?.legs ?? []) for (const step of leg?.steps ?? []) {
    const mode = stepMode(step);
    const durationMinutes = typeof step?.duration?.value === "number" ? Math.round(step.duration.value / 60) : minutes(step?.staticDurationMillis ? step.staticDurationMillis / 1000 : step?.staticDuration ?? step?.duration);
    if (mode === "Walk") walkingMinutes += durationMinutes; else transitSteps += 1;
    if (!hasOverviewPath && step?.polyline?.encodedPolyline) routePath.push(...decodePolyline(step.polyline.encodedPolyline));
    const detail = step?.transitDetails ?? step?.transit;
    const line = detail?.transitLine ?? detail?.line ?? {};
    const service = line.nameShort ?? line.shortName ?? line.short_name ?? line.name;
    const instruction = step?.instructions ?? step?.html_instructions ?? step?.navigationInstruction?.instructions;
    if (instruction || mode !== "Walk") {
      const label = instruction ?? (service ? `Take ${service}` : "Public transport segment");
      legs.push({ mode, label: String(label).replace(/<[^>]+>/g, ""), duration: durationMinutes ? `${durationMinutes} min` : "—" });
    }
  }
  const legacySeconds = (route?.legs ?? []).reduce((sum: number, leg: any) => sum + (leg?.duration?.value ?? 0), 0);
  const durationMinutes = legacySeconds ? Math.round(legacySeconds / 60) : minutes(route?.durationMillis ? route.durationMillis / 1000 : route?.duration ?? route?.staticDuration);
  const durationLabel = (route?.legs ?? []).length === 1 ? route.legs[0]?.duration?.text : null;
  const sensorDistances = SENSOR_LOCATIONS.map((sensor) => ({ id: sensor.id, distanceMetres: Math.round(distanceToRoute(sensor, routePath)) }));
  const directSensorIds = sensorDistances.filter((sensor) => sensor.distanceMetres <= 75).map((sensor) => sensor.id);
  const proxySensors = sensorDistances.filter((sensor) => sensor.distanceMetres > 75 && sensor.distanceMetres <= 150);
  const nearbySensorIds = [...directSensorIds, ...proxySensors.map((sensor) => sensor.id)];
  const nearbySensors = sensorDistances
    .filter((sensor) => sensor.distanceMetres <= 150)
    .map((sensor) => ({ ...sensor, name: SENSOR_LOCATIONS.find((location) => location.id === sensor.id)?.name ?? `Sensor ${sensor.id}` }));
  return { id: `route-${index}`, service: serviceNames(route), transportMode: transportMode(route), duration: durationLabel ?? route?.localizedValues?.duration ?? (durationMinutes ? `${durationMinutes} min` : "Current estimate"), durationMinutes, walkingMinutes, transfers: Math.max(0, transitSteps - 1), legs, nearbySensorIds, directSensorIds, proxySensors, routePath, nearbySensors };
}

function routeDurationMinutes(route: any) {
  const legacySeconds = (route?.legs ?? []).reduce((sum: number, leg: any) => sum + (leg?.duration?.value ?? 0), 0);
  return legacySeconds ? Math.round(legacySeconds / 60) : minutes(route?.durationMillis ? route.durationMillis / 1000 : route?.duration ?? route?.staticDuration);
}

function decodePolyline(encoded: string) {
  const points: { lat: number; lng: number }[] = [];
  let index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    let shift = 0, result = 0, byte = 0;
    do { byte = encoded.charCodeAt(index++) - 63; result |= (byte & 0x1f) << shift; shift += 5; } while (byte >= 0x20);
    lat += (result & 1) ? ~(result >> 1) : result >> 1;
    shift = 0; result = 0;
    do { byte = encoded.charCodeAt(index++) - 63; result |= (byte & 0x1f) << shift; shift += 5; } while (byte >= 0x20);
    lng += (result & 1) ? ~(result >> 1) : result >> 1;
    points.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }
  return points;
}

export async function requestRoutesApi(origin: string, destination: string, timing: TravelTiming | undefined, mode: "TRANSIT" | "WALK" = "TRANSIT") {
  const apiKey = await getMapsApiKey();
  const fieldMask = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.duration,routes.legs.polyline.encodedPolyline,routes.legs.steps.staticDuration,routes.legs.steps.travelMode,routes.legs.steps.navigationInstruction,routes.legs.steps.polyline.encodedPolyline,routes.legs.steps.transitDetails";
  const fetchVariant = async (routingPreference?: "LESS_WALKING" | "FEWER_TRANSFERS") => {
    const response = await fetch("https://routes.googleapis.com/directions/v2:computeRoutes", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Goog-Api-Key": apiKey, "X-Goog-FieldMask": fieldMask },
      body: JSON.stringify({
        origin: { address: origin }, destination: { address: destination }, travelMode: mode,
        ...(mode === "TRANSIT" ? { computeAlternativeRoutes: true } : {}),
        ...(mode === "TRANSIT" ? (timing?.mode === "arrive" ? { arrivalTime: routeTime(timing).toISOString() } : { departureTime: routeTime(timing).toISOString() }) : {}),
        languageCode: "en-AU", regionCode: "AU", units: "METRIC",
        ...(mode === "TRANSIT" && routingPreference ? { transitPreferences: { routingPreference } } : {}),
      }),
    });
    if (!response.ok) throw new Error(`ROUTES_${response.status}_${(await response.text()).slice(0, 180)}`);
    return response.json() as Promise<{ routes?: any[] }>;
  };
  const results = mode === "WALK"
    ? await Promise.allSettled([fetchVariant()])
    : await Promise.allSettled([fetchVariant(), fetchVariant("LESS_WALKING"), fetchVariant("FEWER_TRANSFERS")]);
  const routes = results.flatMap((result) => result.status === "fulfilled" ? result.value.routes ?? [] : []);
  const unique = [...new Map(routes.map((route) => [route?.polyline?.encodedPolyline ?? JSON.stringify(route), route])).values()];
  if (!unique.length) {
    const rejected = results.find((result): result is PromiseRejectedResult => result.status === "rejected");
    throw rejected?.reason ?? new Error("ROUTES_EMPTY");
  }
  return { routes: unique };
}

export default function GeographicMap(props: Props) {
  const mapNode = useRef<HTMLDivElement>(null);
  const callbackRef = useRef(props.onRoutesResolved);
  const sensorReadingsRef = useRef(props.sensorReadings);
  const crowdLimitRef = useRef(props.crowdLimit);
  const selectedRef = useRef(props.selected);
  const resolvedRoutesKeyRef = useRef("");
  useEffect(() => { callbackRef.current = props.onRoutesResolved; }, [props.onRoutesResolved]);
  useEffect(() => { sensorReadingsRef.current = props.sensorReadings; }, [props.sensorReadings]);
  useEffect(() => { crowdLimitRef.current = props.crowdLimit; }, [props.crowdLimit]);
  useEffect(() => { selectedRef.current = props.selected; }, [props.selected]);
  const [state, setState] = useState<RouteState>("loading");
  const [message, setMessage] = useState("Requesting current Google routes…");
  const isQuietSpot = Boolean(props.quietSpot);
  const direction = props.journeyDirection ?? "to-work";
  const origin = isQuietSpot ? props.quietOrigin ?? props.origin ?? (direction === "to-work" ? HOME : WORK) : props.origin ?? (direction === "to-work" ? HOME : WORK);
  const destination = isQuietSpot ? props.quietDestination ?? CITY_LIBRARY : props.destination ?? (direction === "to-work" ? WORK : HOME);
  const googleUrl = googleDirections(origin, destination, isQuietSpot ? "walking" : "transit");
  // Value deps only — object/array identity from parents must not retrigger Google Routes.
  const timingMode = props.travelTiming?.mode ?? "now";
  const timingDateTime = props.travelTiming?.dateTime ?? "";
  const sensorSignature = (props.sensorReadings ?? [])
    .map((reading) => `${reading.id}:${reading.peoplePerMinute ?? "x"}:${reading.freshness}`)
    .join("|");

  useEffect(() => {
    let cancelled = false;
    const polylines: any[] = [];
    const markers: any[] = [];
    async function renderRoute() {
      setState("loading");
      setMessage(isQuietSpot ? "Requesting the current walking route…" : `Comparing public-transport alternatives for ${direction === "to-work" ? "weekday 7:15 AM" : "weekday 5:30 PM"}…`);
      try {
        await loadGoogleMaps();
        if (cancelled || !mapNode.current) return;
        const [{ Map }, { LatLngBounds }] = await Promise.all([window.google.maps.importLibrary("maps"), window.google.maps.importLibrary("core")]);
        const map = new Map(mapNode.current, { center: { lat: -37.8155, lng: 144.946 }, zoom: 13, mapTypeControl: false, streetViewControl: false, fullscreenControl: false, clickableIcons: false, gestureHandling: "cooperative" });
        const result = await requestRoutesApi(origin, destination, { mode: timingMode, dateTime: timingDateTime }, isQuietSpot ? "WALK" : "TRANSIT");
        const rawRoutes = [...(result?.routes ?? [])]
          .sort((a, b) => routeDurationMinutes(a) - routeDurationMinutes(b))
          .slice(0, isQuietSpot ? 1 : 4);
        if (!rawRoutes.length) { setState("not-found"); setMessage(isQuietSpot ? "Google did not return a walking route to this refuge." : "Google did not return a public-transport route for these places and travel time."); callbackRef.current?.([]); return; }
        const routes = rawRoutes.map(routeMeta);
        const routesKey = routes.map((route) => route.id).join(",");
        if (resolvedRoutesKeyRef.current !== routesKey) {
          resolvedRoutesKeyRef.current = routesKey;
          callbackRef.current?.(routes);
        }
        const selected = selectedRef.current;
        const crowdLimit = crowdLimitRef.current ?? 25;
        const sensorReadings = sensorReadingsRef.current ?? [];
        const selectedIndex = Math.max(0, routes.findIndex((route) => route.id === selected));
        const chosen = rawRoutes[selectedIndex];
        const meta = routes[selectedIndex];
        const segments: { mode: "Walk" | "Transit"; path: any[] }[] = [];
        for (const leg of chosen?.legs ?? []) for (const step of leg?.steps ?? []) {
          const encoded = step?.polyline?.encodedPolyline;
          const path = encoded ? decodePolyline(encoded) : (step?.path ?? []).map(coordinate);
          if (path.length) segments.push({ mode: stepMode(step), path });
        }
        const overviewEncoded = chosen?.polyline?.encodedPolyline;
        const overviewPath = overviewEncoded ? decodePolyline(overviewEncoded) : chosen?.overview_path ?? chosen?.path ?? [];
        if (!segments.length && overviewPath.length) segments.push({ mode: isQuietSpot ? "Walk" : "Transit", path: overviewEncoded ? overviewPath : overviewPath.map(coordinate) });
        const allPoints = segments.flatMap((segment) => segment.path);
        if (!allPoints.length) throw new Error("EMPTY_ROUTE");
        const Marker = window.google.maps.Marker;
        const transitColor = selectedIndex === 0 ? "#2563a6" : "#c65f35";
        for (const segment of segments) {
          const walking = segment.mode === "Walk";
          polylines.push(new window.google.maps.Polyline({ map, path: segment.path, strokeColor: walking ? "#3f7567" : transitColor, strokeOpacity: walking ? 0 : .96, strokeWeight: walking ? 4 : 6, icons: walking ? [{ icon: { path: window.google.maps.SymbolPath.CIRCLE, fillColor: "#3f7567", fillOpacity: 1, strokeOpacity: 0, scale: 2.25 }, offset: "0", repeat: "12px" }] : undefined }));
        }
        if (!isQuietSpot) {
          const usableReadings = sensorReadings.filter((reading) =>
            (reading.freshness === "fresh" || reading.freshness === "delayed") && reading.peoplePerMinute !== null,
          );
          const routeAssessment = routes.map((route) => {
            const direct = usableReadings.filter((reading) => route.directSensorIds.includes(reading.id));
            const matched = direct.length ? direct : usableReadings.filter((reading) => route.proxySensors.some((proxy) => proxy.id === reading.id));
            const hotspot = matched.sort((a, b) => (b.peoplePerMinute ?? -1) - (a.peoplePerMinute ?? -1))[0];
            return { route, hotspot, risk: hotspot && (hotspot.peoplePerMinute ?? 0) > crowdLimit ? "High" : hotspot ? "Low" : "Unknown" };
          });
          const selectedAssessment = routeAssessment.find((item) => item.route.id === selected);
          const selectedHigh = selectedAssessment?.risk === "High" ? selectedAssessment : null;
          const avoidedHigh = routeAssessment
            .filter((item) => item.risk === "High" && item.hotspot && !selectedAssessment?.route.nearbySensorIds.includes(item.hotspot.id))
            .sort((a, b) => (b.hotspot?.peoplePerMinute ?? 0) - (a.hotspot?.peoplePerMinute ?? 0))[0];
          const displayedHotspot = selectedHigh ?? (selectedAssessment?.risk === "Low" ? avoidedHigh : null);
          if (displayedHotspot?.hotspot) {
            const location = SENSOR_LOCATIONS.find((sensor) => sensor.id === displayedHotspot.hotspot?.id);
            const path = displayedHotspot.route.routePath;
            if (location && path.length > 1) {
              let closestIndex = 0;
              let closestDistance = Infinity;
              path.forEach((point, index) => {
                const distance = metresBetween(location, point);
                if (distance < closestDistance) { closestDistance = distance; closestIndex = index; }
              });
              const start = Math.max(0, closestIndex - 2);
              const end = Math.min(path.length, closestIndex + 3);
              polylines.push(new window.google.maps.Polyline({ map, path: path.slice(start, end), strokeColor: "#c5533d", strokeOpacity: 1, strokeWeight: 10, zIndex: 30 }));
              markers.push(new Marker({ map, position: location, label: { text: "!", color: "#ffffff", fontWeight: "800" }, title: `${selectedHigh ? "Selected route" : "Avoided"} High-crowd hotspot · ${location.name}`, zIndex: 80, icon: { path: window.google.maps.SymbolPath.CIRCLE, fillColor: "#c5533d", fillOpacity: 1, strokeColor: "#ffffff", strokeWeight: 3, scale: 14 } }));
            }
          }
        }
        const bounds = new LatLngBounds(); allPoints.forEach((point: any) => bounds.extend(point)); map.fitBounds(bounds, 46);
        const sensorInfo = new window.google.maps.InfoWindow();
        const returnedSensorIds = new Set(sensorReadings.map((reading) => reading.id));
        const directEvidenceIds = meta.directSensorIds.filter((id) => returnedSensorIds.has(id));
        // Show the complete supported corridor around the selected route. Direct
        // sensors remain the primary scoring evidence, while nearby proxy sensors
        // stay visible for consistent geographic coverage along the whole journey.
        const relevantSensorIds = new Set([
          ...directEvidenceIds,
          ...meta.proxySensors.filter((sensor) => returnedSensorIds.has(sensor.id)).map((sensor) => sensor.id),
        ]);
        // Render every sensor returned by /api/crowd. Freshness controls whether
        // it can be classified, not whether its known location is visible.
        const sensorMarkers = SENSOR_LOCATIONS.filter((sensor) => returnedSensorIds.has(sensor.id)).map((sensor) => {
          const reading = sensorReadings.find((item) => item.id === sensor.id);
          const relevant = relevantSensorIds.has(sensor.id);
          const count = reading?.peoplePerMinute ?? null;
          const classifiable = reading?.freshness === "fresh" || reading?.freshness === "delayed";
          const risk: Risk = classifiable && count !== null ? (count <= crowdLimit ? "Low" : "High") : "Unknown";
          const fillColor = risk === "Low" ? "#2f7d61" : risk === "High" ? "#c5533d" : "#6e7781";
          const marker = new Marker({
            map,
            position: { lat: sensor.lat, lng: sensor.lng },
            title: `Sensor ${sensor.id} · ${sensor.name}`,
            zIndex: relevant ? 40 : 10,
            clickable: true,
            opacity: relevant ? 1 : .55,
            icon: {
              path: window.google.maps.SymbolPath.CIRCLE,
              fillColor,
              fillOpacity: 1,
              strokeColor: "#ffffff",
              strokeOpacity: relevant ? 1 : .7,
              strokeWeight: relevant ? 2.5 : 1,
              scale: relevant ? (sensor.id >= 100 ? 11 : 10) : 6,
            },
          });
          const IdOverlay = class extends window.google.maps.OverlayView {
            div?: HTMLButtonElement;
            onAdd() {
              const div = document.createElement("button");
              div.type = "button";
              div.className = `sensor-id-overlay${relevant ? " is-route-relevant" : " is-background"}`;
              div.textContent = String(sensor.id);
              div.title = `Sensor ${sensor.id} · ${sensor.name}`;
              div.setAttribute("aria-label", div.title);
              div.addEventListener("click", () => window.google.maps.event.trigger(marker, "click"));
              this.div = div;
              this.getPanes()?.overlayMouseTarget.appendChild(div);
            }
            draw() {
              const point = this.getProjection().fromLatLngToDivPixel(new window.google.maps.LatLng(sensor.lat, sensor.lng));
              if (this.div && point) this.div.style.transform = `translate(${Math.round(point.x - 11)}px, ${Math.round(point.y - 11)}px)`;
            }
            onRemove() { this.div?.remove(); this.div = undefined; }
          };
          const idOverlay = new IdOverlay();
          idOverlay.setMap(map);
          marker.addListener("click", () => {
            const observed = reading?.latestObservation ? new Date(reading.latestObservation).toLocaleString("en-AU", { timeZone: "Australia/Melbourne", dateStyle: "medium", timeStyle: "short" }) : "No observation returned";
            const basis = reading?.evidence === "inferred-zero" ? " · inferred from no detections in 15 min" : reading?.evidence === "observed" ? ` · ${reading.sampleMinutes} detected minute${reading.sampleMinutes === 1 ? "" : "s"}` : "";
            const timing = reading?.freshness === "delayed" ? " · latest available feed is delayed" : reading?.freshness === "stale" ? " · stale; unavailable for classification" : reading?.freshness === "unavailable" ? " · data unavailable" : "";
            sensorInfo.setContent(`<div style="font:600 13px/1.45 system-ui;color:#17344a">Sensor ID ${sensor.id}<br><span style="font-weight:400">${sensor.name}</span><br><span style="font-weight:700;color:${fillColor}">${risk === "Unknown" ? "Unknown · no current classification" : `${count} people/min · ${risk}`}</span><br><span style="font-weight:400">${observed}${basis}${timing}</span></div>`);
            sensorInfo.open({ map, anchor: marker });
          });
          return [marker, idOverlay];
        });
        markers.push(
          ...sensorMarkers.flat(),
          new Marker({ map, position: allPoints[0], label: "S", title: origin, zIndex: 10 }),
          new Marker({ map, position: allPoints[allPoints.length - 1], label: "F", title: destination, zIndex: 10 }),
        );
        setState("ready"); setMessage(isQuietSpot ? `Google walking route · ${meta.duration}` : `${meta.service} · ${meta.duration} · ${routes.length} Google alternative${routes.length === 1 ? "" : "s"}`);
      } catch (error) {
        if (cancelled) return;
        const reason = error instanceof Error ? error.message : "";
        setState(reason === "MAPS_NOT_CONFIGURED" ? "unconfigured" : "error");
        setMessage(reason === "MAPS_NOT_CONFIGURED" ? "Google Maps has not been connected." : isQuietSpot ? "Google could not return a walking route to this refuge." : "Google could not return a public-transport journey for these places and travel time.");
        callbackRef.current?.([]);
      }
    }
    void renderRoute();
    return () => { cancelled = true; polylines.forEach((line) => line.setMap(null)); markers.forEach((marker) => marker.setMap(null)); };
    // crowdLimit is included so High/Low overlays and recommended corridor update with
    // the slider. timingMode/timingDateTime are primitives so this does not loop.
  }, [destination, direction, isQuietSpot, origin, props.selected, props.crowdLimit, sensorSignature, timingMode, timingDateTime]);

  return <div className="geo-map-wrap google-map-panel" role="region" aria-label="Google Maps selected route">
    <div ref={mapNode} className="google-live-map" aria-hidden={state !== "ready"} />
    {state === "loading" && <div className={`route-map-state ${state}`} role="status"><span className="route-map-spinner" aria-hidden="true" /><strong>{message}</strong></div>}
    {(state === "not-found" || state === "unconfigured" || state === "error") && <div className={`route-map-state ${state}`} role="status"><strong>{message}</strong></div>}
    {state === "ready" && !isQuietSpot && <>
      <div className="sensor-map-legend" aria-label="Pedestrian sensor legend"><span><i className="sensor-low" />Low</span><span><i className="sensor-high" />High</span></div>
    </>}
    <a className="google-route-action map-open-action" href={googleUrl} target="_blank" rel="noreferrer">Open in Google Maps</a>
  </div>;
}
