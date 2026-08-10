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
  const upstream = new URL("/api/crowd", backendBaseUrl());
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
        ok: false,
        dataStatus: "unavailable",
        latestObservation: null,
        limitation: "The crowd-data service could not be reached.",
        routes: {},
        mapSensors: [],
      },
      { status: 503, headers: { "Cache-Control": "no-store" } },
    );
  }
}
