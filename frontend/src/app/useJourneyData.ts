"use client";

import { useEffect, useMemo, useState } from "react";
import type { DynamicRoute } from "./GeographicMap";
import type { CrowdData, DataState, PredictionResponse } from "./journeyTypes";
import { sensorIdsForPrediction } from "./routeAssessment";

const EMPTY_PREDICTIONS: Record<number, PredictionResponse> = {};

export function useCrowdData() {
  const [dataState, setDataState] = useState<DataState>("loading");
  const [crowdData, setCrowdData] = useState<CrowdData | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    async function loadCrowdData() {
      try {
        const response = await fetch("/api/crowd", {
          cache: "no-store",
          signal: controller.signal,
        });
        if (!response.ok) throw new Error(`CROWD_${response.status}`);
        const payload = await response.json() as CrowdData;
        setCrowdData(payload);
        setDataState(payload.dataStatus);
      } catch (error) {
        if (!(error instanceof DOMException && error.name === "AbortError")) {
          setDataState("unavailable");
        }
      }
    }
    void loadCrowdData();
    const timer = window.setInterval(loadCrowdData, 15 * 60_000);
    return () => {
      controller.abort();
      window.clearInterval(timer);
    };
  }, []);

  return { crowdData, dataState };
}

export function useRoutePredictions(
  dynamicRoutes: DynamicRoute[],
  crowdLimit: number,
  crowdData: CrowdData | null,
) {
  const sensorKey = useMemo(() => [...new Set(dynamicRoutes.flatMap(sensorIdsForPrediction))]
    .sort((a, b) => a - b)
    .join(","), [dynamicRoutes]);
  const rawScenarioId = crowdData?.scenario?.id;
  const scenarioId = rawScenarioId === "dod-2026-08-04-0700"
    ? "2026-08-04T07:00"
    : rawScenarioId;
  const requestKey = sensorKey
    ? `${sensorKey}|${crowdLimit}|${scenarioId ?? "live"}`
    : "";
  const [predictions, setPredictions] = useState<Record<number, PredictionResponse>>({});
  const [loadedKey, setLoadedKey] = useState("");

  useEffect(() => {
    if (!requestKey) return;
    const controller = new AbortController();
    async function loadPredictions() {
      const sensorIds = sensorKey.split(",").map(Number).filter(Number.isFinite);
      const results = await Promise.all(sensorIds.map(async (sensorId) => {
        try {
          const params = new URLSearchParams({
            sensor_id: String(sensorId),
            crowd_threshold: String(crowdLimit),
          });
          if (scenarioId) params.set("scenario", scenarioId);
          const response = await fetch(`/api/predictions?${params.toString()}`, {
            cache: "no-store",
            signal: controller.signal,
          });
          if (!response.ok) return null;
          return { sensorId, prediction: await response.json() as PredictionResponse };
        } catch (error) {
          if (error instanceof DOMException && error.name === "AbortError") throw error;
          return null;
        }
      }));
      if (controller.signal.aborted) return;
      const next: Record<number, PredictionResponse> = {};
      results.forEach((result) => {
        if (result) next[result.sensorId] = result.prediction;
      });
      setPredictions(next);
      setLoadedKey(requestKey);
    }
    void loadPredictions();
    return () => controller.abort();
  }, [crowdLimit, requestKey, scenarioId, sensorKey]);

  return {
    // Do not expose values from a previous route/threshold while a new request is pending.
    routePredictions: requestKey && loadedKey === requestKey ? predictions : EMPTY_PREDICTIONS,
    routeForecastPending: Boolean(requestKey && loadedKey !== requestKey),
  };
}
