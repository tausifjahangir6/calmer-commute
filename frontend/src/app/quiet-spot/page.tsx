"use client";

import { useState } from "react";
import Link from "next/link";
import MapPreview from "@/components/MapPreview";

export default function QuietSpotPage() {
  const [from, setFrom] = useState("16 Orange Grove, Balaclava");
  const [to, setTo] = useState("Growth Factory, 3/292 Flinders St");
  const [avoidCongested, setAvoidCongested] = useState(false);
  const [showRefuge, setShowRefuge] = useState(true);

  const params = new URLSearchParams({
    from,
    to,
    avoidCongested: String(avoidCongested),
    showRefuge: String(showRefuge),
  });

  return (
    <div className="grid items-start gap-10 md:grid-cols-[1fr_320px]">
      <div className="space-y-6">
        <h1 className="font-display text-2xl font-semibold">Quiet Spot</h1>

        <div>
          <label htmlFor="from" className="mb-1 block text-sm text-[#8A8578]">
            From
          </label>
          <input
            id="from"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="w-full rounded-lg border border-[#DDD8CC] bg-white px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#6E8B67]/40"
          />
        </div>

        <div>
          <label htmlFor="to" className="mb-1 block text-sm text-[#8A8578]">
            To
          </label>
          <input
            id="to"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="w-full rounded-lg border border-[#DDD8CC] bg-white px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#6E8B67]/40"
          />
        </div>

        <div className="space-y-3 text-sm">
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={avoidCongested}
              onChange={(e) => setAvoidCongested(e.target.checked)}
              className="accent-[#6E8B67]"
            />
            Avoid highly congested areas
          </label>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={showRefuge}
              onChange={(e) => setShowRefuge(e.target.checked)}
              className="accent-[#6E8B67]"
            />
            Show nearby quiet refuge spots
          </label>
        </div>

        <Link
          href={`/quiet-spot/results?${params.toString()}`}
          className="inline-block rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58]"
        >
          Find routes
        </Link>
      </div>

      <MapPreview className="h-64 md:sticky md:top-24 md:h-72" />
    </div>
  );
}