import type { RouteOption } from "@/lib/mock-data";

const sensoryColor: Record<RouteOption["sensoryLevel"], string> = {
  Low: "text-[#6E8B67]",
  Moderate: "text-[#B98A3E]",
  High: "text-[#B5533C]",
};

export default function RouteCard({
  route,
  selected,
  onSelect,
}: {
  route: RouteOption;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={selected}
      className={`w-full rounded-xl border px-6 py-4 text-left transition-colors ${
        selected
          ? "border-[#6E8B67] bg-[#E8EFE4]"
          : "border-[#DDD8CC] bg-white hover:border-[#6E8B67]/60"
      }`}
    >
      <div className="flex items-center justify-between gap-4">
        <span className="font-display font-medium">
          {route.label}: {route.type === "fastest" ? "Fastest" : "Calmest"} (
          {route.durationMin} min)
        </span>
        <span className={`shrink-0 text-xs font-medium ${sensoryColor[route.sensoryLevel]}`}>
          {route.sensoryLevel} sensory
        </span>
      </div>
      <p className="mt-1 text-xs text-[#8A8578]">
        {route.distanceKm} km · {route.turnByTurnFirstStep}
      </p>
    </button>
  );
}