"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

export default function EmergencyPage() {
  const router = useRouter();
  const [muted, setMuted] = useState(false);
  const [calling, setCalling] = useState(false);

  const cards = [
    {
      title: "quiet refuge",
      description: "Find the nearest low-sensory space",
      onClick: () => router.push("/quiet-spot/refuge"),
    },
    {
      title: muted ? "Unmute Audio" : "Mute Audio",
      description: muted ? "Sound is currently off" : "Turn off app sounds instantly",
      onClick: () => setMuted((m) => !m),
    },
    {
      title: calling ? "Calling…" : "Call Help",
      description: "Contact your emergency contact",
      onClick: () => setCalling(true),
    },
  ];

  return (
    <div className="grid gap-6 sm:grid-cols-3">
      {cards.map((card) => (
        <button
          key={card.title}
          onClick={card.onClick}
          className="flex aspect-square flex-col items-center justify-center gap-3 rounded-xl border border-[#DDD8CC] bg-white px-4 text-center transition-colors hover:border-[#6E8B67]"
        >
          <span className="font-display text-lg font-medium">{card.title}</span>
          <span className="text-xs text-[#8A8578]">{card.description}</span>
        </button>
      ))}
    </div>
  );
}