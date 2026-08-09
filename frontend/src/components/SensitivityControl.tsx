"use client";

import type { Sensitivity } from "@/lib/mock-data";

const options: { value: Sensitivity; label: string; hint: string }[] = [
  { value: "cautious", label: "Cautious", hint: "Warn me earlier" },
  { value: "default", label: "Default", hint: "Balanced" },
  { value: "relaxed", label: "Relaxed", hint: "Only when very crowded" },
];

export default function SensitivityControl({
  value,
  onChange,
}: {
  value: Sensitivity;
  onChange: (value: Sensitivity) => void;
}) {
  return (
    <fieldset>
      <legend className="mb-2 text-sm font-medium">Crowd alert sensitivity</legend>
      <div role="radiogroup" aria-label="Crowd alert sensitivity" className="flex gap-2">
        {options.map((option) => {
          const selected = option.value === value;
          return (
            <button
              key={option.value}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => onChange(option.value)}
              className={`flex-1 rounded-lg border px-3 py-2 text-left text-sm transition-colors ${
                selected
                  ? "border-[#6E8B67] bg-[#E8EFE4]"
                  : "border-[#DDD8CC] bg-white hover:border-[#6E8B67]/60"
              }`}
            >
              <span className="block font-medium">{option.label}</span>
              <span className="block text-xs text-[#8A8578]">{option.hint}</span>
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}