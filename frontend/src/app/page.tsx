import Link from "next/link";

export default function HomePage() {
  return (
    <div className="flex flex-col items-center gap-10 py-12 text-center">
      <div className="space-y-2">
        <h1 className="font-display text-2xl font-semibold">Welcome back</h1>
        <p className="text-sm text-[#8A8578]">
          Jump back into your quiet spot, or update your sensory profile.
        </p>
      </div>

      <div className="grid w-full max-w-xl grid-cols-1 gap-6 sm:grid-cols-2">
        <Link
          href="/quiet-spot"
          className="flex aspect-square flex-col items-center justify-center gap-3 rounded-xl border border-[#DDD8CC] bg-white px-4 text-center transition-colors hover:border-[#6E8B67]"
        >
          <span className="font-display text-lg font-medium">Find a quiet route</span>
          <span className="text-xs text-[#8A8578]">Compare routes and avoid crowds</span>
        </Link>

        <Link
          href="/profile"
          className="flex aspect-square flex-col items-center justify-center gap-3 rounded-xl border border-[#DDD8CC] bg-white px-4 text-center transition-colors hover:border-[#6E8B67]"
        >
          <span className="font-display text-lg font-medium">Update profile</span>
          <span className="text-xs text-[#8A8578]">Adjust your sensors and triggers</span>
        </Link>
      </div>
    </div>
  );
}