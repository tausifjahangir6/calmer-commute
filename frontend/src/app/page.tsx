import Link from "next/link";

export default function HomePage() {
  return (
    <div className="space-y-4">
      <h1 className="font-display text-2xl font-semibold">Welcome back</h1>
      <p className="text-sm text-[#8A8578]">
        Jump back into your quiet spot, or update your sensory profile.
      </p>
      <div className="flex gap-4">
        <Link
          href="/quiet-spot"
          className="rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white hover:bg-[#5E7A58]"
        >
          Find a quiet route
        </Link>
        <Link
          href="/profile"
          className="rounded-lg border border-[#DDD8CC] px-6 py-3 text-sm font-medium hover:border-[#6E8B67]"
        >
          Update profile
        </Link>
      </div>
    </div>
  );
}