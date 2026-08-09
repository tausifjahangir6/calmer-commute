"use client";

import { useRouter, useSearchParams } from "next/navigation";
import MapPreview from "@/components/MapPreview";
import { mockRoutes } from "@/lib/mock-data";

export default function NavigatePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const routeId = searchParams.get("route");
  const route = mockRoutes.find((r) => r.id === routeId) ?? mockRoutes[0];

  return (
    <div className="space-y-6">
      <div className="relative">
        <MapPreview className="h-80" />
        <div className="absolute bottom-4 left-1/2 flex -translate-x-1/2 gap-4 rounded-xl border border-[#DDD8CC] bg-white px-6 py-3 text-center shadow-sm">
          <div>
            <p className="font-display text-lg font-semibold">{route.durationMin} Mins</p>
          </div>
          <div className="w-px bg-[#DDD8CC]" />
          <div>
            <p className="font-display text-lg font-semibold">{route.distanceKm} Km</p>
          </div>
          <div className="w-px bg-[#DDD8CC]" />
          <div>
            <p className="text-sm">{route.turnByTurnFirstStep}</p>
          </div>
        </div>
      </div>

      <div className="flex justify-between gap-4">
        <button
          onClick={() => router.push("/emergency")}
          className="rounded-lg border border-[#DDD8CC] px-6 py-3 text-sm font-medium hover:border-[#6E8B67]"
        >
          Emergency
        </button>
        <button
          onClick={() => router.push("/quiet-spot")}
          className="rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white hover:bg-[#5E7A58]"
        >
          End Trip
        </button>
        <button
          onClick={() => router.back()}
          className="rounded-lg border border-[#DDD8CC] px-6 py-3 text-sm font-medium hover:border-[#6E8B67]"
        >
          Change Route
        </button>
      </div>
    </div>
  );
}