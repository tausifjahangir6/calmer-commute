"use client";

import { useEffect, useState } from "react";
import GeographicMap, {
  loadGoogleMaps,
  requestRoutesApi,
  SENSOR_LOCATIONS,
} from "./GeographicMap";
import type { CrowdData, Risk } from "./journeyTypes";
import { getUsableSensors, riskFrom } from "./routeAssessment";

type RefugeCandidate = {
  name: string;
  address: string;
  type: string;
  walk: string;
  walkMinutes: number | null;
  crowdCount: number | null;
  crowdRisk: Risk;
};

type PlaceLike = {
  displayName?: string | { text?: string };
  formattedAddress?: string;
  location?: { lat: () => number; lng: () => number };
  primaryType?: string;
  primaryTypeDisplayName?: string;
  types?: string[];
};

type Props = {
  onBack: () => void;
  arrivalAddress: string;
  crowdData: CrowdData | null;
  crowdLimit: number;
};

const APPROVED_REFUGE_TYPES = new Set([
  "library",
  "park",
  "community_center",
  "cultural_center",
  "museum",
]);
const RELIGIOUS_PLACE_TYPES = new Set([
  "church",
  "hindu_temple",
  "mosque",
  "synagogue",
  "place_of_worship",
]);
const RELIGIOUS_PLACE_WORDS = /\b(church|chapel|cathedral|mosque|masjid|temple|synagogue|shul|parish|diocese|ministry|ministries|christian|catholic|anglican|baptist|presbyterian|lutheran|uniting church|salvation army|islamic|hindu|buddhist|sikh|religious|worship)\b/i;

function placeName(place: PlaceLike) {
  return typeof place.displayName === "string" ? place.displayName : place.displayName?.text;
}

function isEligibleRefuge(place: PlaceLike, name: string) {
  const types = [place.primaryType, ...(place.types ?? [])]
    .filter((type): type is string => Boolean(type))
    .map((type) => type.toLowerCase());
  const description = `${name} ${place.formattedAddress ?? ""}`;
  return types.some((type) => APPROVED_REFUGE_TYPES.has(type))
    && !types.some((type) => RELIGIOUS_PLACE_TYPES.has(type))
    && !RELIGIOUS_PLACE_WORDS.test(description);
}

function pointDistanceMetres(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
) {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const dLat = radians(b.lat - a.lat);
  const dLng = radians(b.lng - a.lng);
  const lat1 = radians(a.lat);
  const lat2 = radians(b.lat);
  const value = Math.sin(dLat / 2) ** 2
    + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}

function rankRefuges(a: RefugeCandidate, b: RefugeCandidate) {
  const riskRank = (candidate: RefugeCandidate) =>
    candidate.crowdRisk === "Low" ? 0 : candidate.crowdRisk === "High" ? 1 : 2;
  return riskRank(a) - riskRank(b)
    || (a.crowdCount ?? Number.POSITIVE_INFINITY)
      - (b.crowdCount ?? Number.POSITIVE_INFINITY)
    || (a.walkMinutes ?? Number.POSITIVE_INFINITY)
      - (b.walkMinutes ?? Number.POSITIVE_INFINITY);
}

export default function QuietSpotScreen({
  onBack,
  arrivalAddress,
  crowdData,
  crowdLimit,
}: Props) {
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
        const geocoded = await new Geocoder().geocode({ address: arrivalAddress, region: "AU" });
        const location = geocoded.results?.[0]?.geometry?.location;
        if (!location) throw new Error("ARRIVAL_NOT_FOUND");
        const centre = { lat: location.lat(), lng: location.lng() };
        const fields = [
          "displayName",
          "formattedAddress",
          "location",
          "primaryType",
          "primaryTypeDisplayName",
          "types",
        ];
        const nearbySearch = places.Place.searchNearby({
          fields,
          locationRestriction: { center: centre, radius: 2500 },
          includedPrimaryTypes: ["library", "park", "museum", "community_center", "cultural_center"],
          maxResultCount: 20,
          rankPreference: "DISTANCE",
          language: "en",
          region: "au",
        });
        const textSearches = [
          "public library",
          "public park",
          "public garden",
          "public museum",
          "civic community centre",
        ].map((kind) => places.Place.searchByText({
          textQuery: `${kind} near ${arrivalAddress}`,
          fields,
          locationBias: { center: centre, radius: 2500 },
          maxResultCount: 8,
          language: "en",
          region: "au",
        }));
        const searches = await Promise.allSettled([nearbySearch, ...textSearches]);
        const nearbyPlaces = searches.flatMap((search) =>
          search.status === "fulfilled" ? search.value.places ?? [] : []) as PlaceLike[];
        const unique = [...new Map(nearbyPlaces
          .filter((place) => {
            const name = placeName(place);
            return Boolean(place.location && name && isEligibleRefuge(place, name));
          })
          .map((place) => [`${placeName(place)}|${place.formattedAddress ?? ""}`, place]))
          .values()].slice(0, 3);
        const usableSensors = getUsableSensors(crowdData);
        const initial = unique.map((place) => {
          const name = placeName(place)!;
          const address = place.formattedAddress || `${name}, Melbourne VIC, Australia`;
          const lat = place.location!.lat();
          const lng = place.location!.lng();
          const nearest = usableSensors
            .map((reading) => {
              const sensor = SENSOR_LOCATIONS.find((item) => item.id === reading.id);
              return sensor
                ? { reading, distance: Math.round(pointDistanceMetres({ lat, lng }, sensor)) }
                : null;
            })
            .filter((match): match is NonNullable<typeof match> => Boolean(match))
            .filter((match) => match.distance <= 150)
            .sort((a, b) => a.distance - b.distance)[0];
          const crowdCount = nearest?.reading.peoplePerMinute ?? null;
          return {
            name,
            address,
            type: place.primaryTypeDisplayName
              || String(place.primaryType ?? "Public place").replaceAll("_", " "),
            walk: "Calculating route…",
            walkMinutes: null,
            crowdCount,
            crowdRisk: riskFrom(crowdCount, crowdLimit),
          } satisfies RefugeCandidate;
        }).sort(rankRefuges);
        if (cancelled) return;
        if (!initial.length) throw new Error("NO_CANDIDATES");
        setCandidates(initial);
        setSelectedSpot(initial[0].name);
        setSearchState("ready");
        await Promise.all(initial.map(async (candidate) => {
          let walkMinutes: number | null = null;
          try {
            const result = await requestRoutesApi(
              arrivalAddress,
              candidate.address,
              { mode: "now", dateTime: "" },
              "WALK",
            );
            const match = String(result.routes?.[0]?.duration ?? "").match(/([\d.]+)s/);
            walkMinutes = match ? Math.max(1, Math.round(Number(match[1]) / 60)) : null;
          } catch {
            // Keep the candidate and disclose that its walking time is unavailable.
          }
          if (!cancelled) {
            setCandidates((current) => current
              .map((item) => item.name === candidate.name
                ? {
                    ...item,
                    walkMinutes,
                    walk: walkMinutes ? `${walkMinutes} min` : "Walking time unavailable",
                  }
                : item)
              .sort(rankRefuges));
          }
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
      <header className="screen-header">
        <div className="header-row">
          <button className="back-control" onClick={onBack} aria-label="Go back">
            <span aria-hidden="true">‹</span> Back
          </button>
        </div>
        <h1>Nearby candidate refuges</h1>
        <p>Calmer and closer public space recommended for you</p>
      </header>

      <div className="quiet-map-panel">
        <div className="real-map-card quiet-map-card">
          {selected ? (
            <GeographicMap
              trainCount={null}
              tramCount={null}
              trainRisk="Unknown"
              tramRisk="Unknown"
              selected="route-0"
              refuge
              quietSpot
              quietOrigin={arrivalAddress}
              quietDestination={selected.address}
              onSelect={() => {}}
            />
          ) : (
            <div className="route-map-state loading" role="status" aria-live="polite">
              <strong>
                {searchState === "loading"
                  ? "Finding refuge options…"
                  : "No supported nearby candidate could be returned for this arrival address."}
              </strong>
              {searchState === "loading" && <small>Checking nearby crowd and eligible public places…</small>}
            </div>
          )}
        </div>
      </div>

      <div className="quiet-detail-stack">
        <div className="refuge-options" role="radiogroup" aria-label="Candidate refuges">
          {candidates.map((candidate) => (
            <button
              key={candidate.name}
              role="radio"
              aria-checked={selectedSpot === candidate.name}
              className={selectedSpot === candidate.name ? "selected" : ""}
              onClick={() => setSelectedSpot(candidate.name)}
            >
              <span>
                <strong>{candidate.name}</strong>
                <small className="refuge-type">{candidate.type}</small>
                <small className="refuge-address">{candidate.address}</small>
              </span>
              <b>
                {candidate.walkMinutes === null && candidate.walk === "Calculating route…"
                  ? "Calculating walking route…"
                  : candidate.walk}
              </b>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}

