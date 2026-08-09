import Link from "next/link";

export default function OnboardPage() {
  return (
    <div className="flex flex-col items-center gap-6 py-24 text-center">
      <div className="space-y-2">
        <h1 className="font-display text-2xl font-semibold">Welcome</h1>
        <p className="text-sm text-[#8A8578]">
          Looking for a quiet trip?
        </p>
      </div>

      <Link
        href="/"
        className="rounded-lg bg-[#6E8B67] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#5E7A58]"
      >
        Continue to Home
      </Link>
    </div>
  );
}