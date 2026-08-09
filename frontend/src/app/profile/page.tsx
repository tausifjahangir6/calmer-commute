"use client";

import { useState } from "react";
import SliderField from "@/components/SliderField";
import { defaultProfile, saveProfile, type UserProfile } from "@/lib/mock-data";

export default function ProfilePage() {
  const [profile, setProfile] = useState<UserProfile>(defaultProfile);
  const [saving, setSaving] = useState(false);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);

  function update<K extends keyof UserProfile>(key: K, value: UserProfile[K]) {
    setProfile((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSave() {
    setSaving(true);
    setSavedMessage(null);
    await saveProfile(profile);
    setSaving(false);
    setSavedMessage("Profile saved");
  }

  return (
    <div className="grid gap-10 md:grid-cols-[1fr_1px_1fr]">
      <section className="space-y-8">
        <h1 className="font-display text-2xl font-semibold">Sensors</h1>
        <SliderField
          label="Noise Tolerance"
          value={profile.noiseTolerance}
          onChange={(v) => update("noiseTolerance", v)}
          minLabel="quiet"
          maxLabel="moderate"
        />
        <SliderField
          label="Crowd Density"
          value={profile.crowdDensity}
          onChange={(v) => update("crowdDensity", v)}
          minLabel="alone"
          maxLabel="crowded"
        />
      </section>

      <div className="hidden bg-[#DDD8CC] md:block" />

      <section className="space-y-6">
        <h1 className="font-display text-2xl font-semibold">Trigger</h1>
        <div className="space-y-3 text-sm">
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={profile.avoidSun}
              onChange={(e) => update("avoidSun", e.target.checked)}
              className="accent-[#6E8B67]"
            />
            Avoid Sun
          </label>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={profile.avoidNeon}
              onChange={(e) => update("avoidNeon", e.target.checked)}
              className="accent-[#6E8B67]"
            />
            Avoid Neon
          </label>
        </div>
        <div>
          <label htmlFor="other-triggers" className="mb-1 block text-sm text-[#8A8578]">
            Other Triggers
          </label>
          <textarea
            id="other-triggers"
            value={profile.otherTriggers}
            onChange={(e) => update("otherTriggers", e.target.value)}
            rows={4}
            className="w-full rounded-lg border border-[#DDD8CC] bg-white px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#6E8B67]/40"
          />
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={handleSave}
            disabled={saving}
            className="rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58] disabled:opacity-60"
          >
            {saving ? "Saving…" : "Save Profile"}
          </button>
          {savedMessage && <span className="text-sm text-[#6E8B67]">{savedMessage}</span>}
        </div>
      </section>
    </div>
  );
}