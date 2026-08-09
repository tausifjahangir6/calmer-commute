"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import MapPreview from "@/components/MapPreview";
import { fetchRefugeSpots, type RefugeSpot } from "@/lib/mock-data";

export default function RefugeSpotPage() {
  const router = useRouter();
  const [spot, setSpot] = useState<RefugeSpot | null>(null);

  useEffect(() => {
    fetchRefugeSpots().then((spots) => setSpot(spots[0] ?? null));
  }, []);

  return (
    <div className="grid gap-10 md:grid-cols-[1fr_320px]">
      <MapPreview className="h-72" />
      <div className="space-y-4">
        {!spot && <div className="h-40 animate-pulse rounded-xl bg-[#EFECE3]" />}
        {spot && (
          <>
            <div>
              <p className="font-display text-4xl font-semibold text-[#6E8B67]">
                {spot.decibels} DB
              </p>
              <p className="text-sm text-[#6E8B67]">{spot.quietnessLabel}</p>
            </div>
            <div className="space-y-1 text-sm">
              <p className="text-[#8A8578]">Specifications</p>
              <p>Type: {spot.type}</p>
              <p>Accessibility: {spot.accessibility}</p>
            </div>
            <button
              onClick={() => router.push(`/quiet-spot/navigate?spot=${spot.id}`)}
              className="rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58]"
            >
              Navigate
            </button>
          </>
        )}
      </div>
    </div>
  );
}