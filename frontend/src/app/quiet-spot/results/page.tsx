"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import MapPreview from "@/components/MapPreview";
import RouteCard from "@/components/RouteCard";
import SensitivityControl from "@/components/SensitivityControl";
import {
  fetchRoutes,
  getAlertThreshold,
  isRouteAlerting,
  type RouteOption,
  type Sensitivity,
} from "@/lib/mock-data";

export default function QuietSpotResultsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const from = searchParams.get("from") ?? "";
  const to = searchParams.get("to") ?? "";

  const [routes, setRoutes] = useState<RouteOption[] | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [sensitivity, setSensitivity] = useState<Sensitivity>("default");
  const [dismissedAlertFor, setDismissedAlertFor] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setRoutes(null);
    setError(null);

    fetchRoutes(from, to)
      .then((data) => {
        if (cancelled) return;
        setRoutes(data);
        setSelectedId(data[0]?.id ?? null);
      })
      .catch(() => {
        if (!cancelled) setError("Couldn't find routes for that trip. Try again.");
      });

    return () => {
      cancelled = true;
    };
  }, [from, to]);

  const selected = routes?.find((r) => r.id === selectedId);
  const alternative = routes?.find((r) => r.id !== selectedId);
  const selectedIsAlerting =
    selected != null &&
    isRouteAlerting(selected, sensitivity) &&
    dismissedAlertFor !== selected.id;

  function handleSelect(id: string) {
    setSelectedId(id);
    setDismissedAlertFor(null);
  }

  function handleAcceptAlternative() {
    if (alternative) {
      setSelectedId(alternative.id);
      setDismissedAlertFor(null);
    }
  }

  function handleDeclineAlternative() {
    if (selected) setDismissedAlertFor(selected.id);
  }

  return (
    <div className="grid gap-10 md:grid-cols-[1fr_320px]">
      <div className="space-y-4">
        <button
          onClick={() => router.push("/quiet-spot")}
          className="text-sm text-[#8A8578] hover:text-[#2E2B26]"
        >
          ← Change route
        </button>

        {error && (
          <p className="rounded-lg border border-[#E3B7AC] bg-[#FBF1EE] px-4 py-3 text-sm text-[#B5533C]">
            {error}
          </p>
        )}

        {!routes && !error && (
          <div className="space-y-4">
            <div className="h-20 animate-pulse rounded-xl bg-[#EFECE3]" />
            <div className="h-20 animate-pulse rounded-xl bg-[#EFECE3]" />
          </div>
        )}

        {routes && <SensitivityControl value={sensitivity} onChange={setSensitivity} />}

        {routes?.map((route) => {
          const alerting = isRouteAlerting(route, sensitivity);
          return (
            <div key={route.id} className="relative">
              <RouteCard
                route={route}
                selected={route.id === selectedId}
                onSelect={() => handleSelect(route.id)}
              />
              {alerting && (
                <span className="absolute right-4 top-4 rounded-full bg-[#FBF1EE] px-2 py-0.5 text-[10px] font-medium text-[#B5533C]">
                  Busier than your threshold
                </span>
              )}
            </div>
          );
        })}

        {selectedIsAlerting && alternative && selected && (
          <div className="space-y-3 rounded-xl border border-[#E3B7AC] bg-[#FBF1EE] px-5 py-4">
            <p className="text-sm text-[#8A4B3C]">
              {selected.label} is busier than your {sensitivity} threshold (
              {selected.crowdForecast} vs. {getAlertThreshold(selected, sensitivity).toFixed(0)}{" "}
              people/hr). Switch to {alternative.label} instead?
            </p>
            <div className="flex gap-3">
              <button
                onClick={handleAcceptAlternative}
                className="rounded-lg bg-[#6E8B67] px-4 py-2 text-sm font-medium text-white hover:bg-[#5E7A58]"
              >
                Switch to {alternative.label}
              </button>
              <button
                onClick={handleDeclineAlternative}
                className="rounded-lg border border-[#DDD8CC] px-4 py-2 text-sm font-medium hover:border-[#6E8B67]"
              >
                Keep {selected.label}
              </button>
            </div>
          </div>
        )}

        <button
          type="button"
          disabled={!selected}
          onClick={() => router.push(`/quiet-spot/navigate?route=${selectedId}`)}
          className="mt-2 rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58] disabled:opacity-40"
        >
          Start
        </button>
      </div>

      <MapPreview className="h-72 md:sticky md:top-24" />
    </div>
  );
}