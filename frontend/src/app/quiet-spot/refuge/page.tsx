"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import MapPreview from "@/components/MapPreview";
import { fetchRefugeSpots, type RefugeSpot } from "@/lib/mock-data";

export default function RefugeSpotPage() {
  const router = useRouter();
  const [spots, setSpots] = useState<RefugeSpot[] | null>(null);

  useEffect(() => {
    fetchRefugeSpots().then(setSpots);
  }, []);

  return (
    <div className="grid gap-10 md:grid-cols-[1fr_320px]">
      <div className="space-y-4">
        <h1 className="font-display text-2xl font-semibold">Nearby candidate refuges</h1>
        <p className="text-sm text-[#8A8578]">
          Public facilities and open spaces ranked from your current location.
        </p>

        {!spots && (
          <div className="space-y-4">
            <div className="h-20 animate-pulse rounded-xl bg-[#EFECE3]" />
            <div className="h-20 animate-pulse rounded-xl bg-[#EFECE3]" />
          </div>
        )}

        {spots?.length === 0 && (
          <div className="rounded-xl border border-[#DDD8CC] bg-white px-5 py-4">
            <p className="text-sm font-medium">Candidate refuge search unavailable</p>
            <p className="mt-1 text-xs text-[#8A8578]">
              No supported park, library, museum, or community facility was found nearby. No
              fixed refuge is being substituted.
            </p>
          </div>
        )}

        {spots?.map((spot) => (
          <div
            key={spot.id}
            className="space-y-2 rounded-xl border border-[#DDD8CC] bg-white px-5 py-4"
          >
            <div className="flex items-center justify-between">
              <span className="font-display font-medium">{spot.name}</span>
              <span className="text-sm font-medium text-[#6E8B67]">
                {spot.decibels} DB · {spot.quietnessLabel}
              </span>
            </div>
            <p className="text-xs text-[#8A8578]">
              Type: {spot.type} · Accessibility: {spot.accessibility}
            </p>
            <button
              onClick={() => router.push(`/quiet-spot/navigate?spot=${spot.id}`)}
              className="rounded-lg bg-[#6E8B67] px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58]"
            >
              Navigate
            </button>
          </div>
        ))}
      </div>

      <MapPreview className="h-72 md:sticky md:top-24" />
    </div>
  );
}