import { NextRequest } from "next/server";

export const dynamic = "force-dynamic";

function backendBaseUrl() {
  // Browser-facing NEXT_PUBLIC_API_BASE_URL is commonly localhost:5000.
  // From the frontend container, the Compose service name is the reliable host.
  return process.env.BACKEND_INTERNAL_URL
    ?? process.env.API_BASE_URL
    ?? "http://backend:5000";
}

export async function GET(request: NextRequest) {
  const sensorId = request.nextUrl.searchParams.get("sensor_id");
  if (!sensorId) {
    return Response.json(
      { error: { code: "validation_error", message: "'sensor_id' is required.", details: { field: "sensor_id" } } },
      { status: 400, headers: { "Cache-Control": "no-store" } },
    );
  }

  const upstream = new URL("/api/predictions", backendBaseUrl());
  upstream.searchParams.set("sensor_id", sensorId);
  const crowdThreshold = request.nextUrl.searchParams.get("crowd_threshold");
  if (crowdThreshold) upstream.searchParams.set("crowd_threshold", crowdThreshold);
  const scenario = request.nextUrl.searchParams.get("scenario");
  if (scenario) upstream.searchParams.set("scenario", scenario);

  try {
    const response = await fetch(upstream, {
      cache: "no-store",
      headers: { Accept: "application/json" },
    });
    const body = await response.text();
    return new Response(body, {
      status: response.status,
      headers: {
        "Content-Type": response.headers.get("content-type") ?? "application/json",
        "Cache-Control": "no-store",
      },
    });
  } catch {
    return Response.json(
      {
        sensor_id: sensorId,
        predicted_count_per_minute: null,
        predicted_level: "Unknown",
        crowd_level: "Unknown",
        confidence: null,
        validation_status: "not_validated",
        data_mode: "unavailable",
        limitation: "The forecast service could not be reached.",
      },
      { status: 503, headers: { "Cache-Control": "no-store" } },
    );
  }
}
