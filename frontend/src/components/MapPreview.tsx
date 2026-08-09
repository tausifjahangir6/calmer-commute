export default function MapPreview({ className = "" }: { className?: string }) {
  return (
    <div
      className={`relative overflow-hidden rounded-xl border border-[#DDD8CC] bg-[#EFECE3] ${className}`}
      role="img"
      aria-label="Map preview showing the route from origin to destination"
    >
      <svg viewBox="0 0 300 260" className="h-full w-full" preserveAspectRatio="none">
        <g stroke="#DDD8CC" strokeWidth="2">
          <line x1="0" y1="60" x2="300" y2="60" />
          <line x1="0" y1="140" x2="300" y2="140" />
          <line x1="0" y1="210" x2="300" y2="210" />
          <line x1="70" y1="0" x2="70" y2="260" />
          <line x1="150" y1="0" x2="150" y2="260" />
          <line x1="230" y1="0" x2="230" y2="260" />
        </g>

        <path
          d="M20 150 Q90 120 170 150 T290 145 L290 190 Q170 200 90 190 T20 190 Z"
          fill="#CFE0C6"
          opacity="0.85"
        />

        <path
          d="M30 160 C90 150, 180 150, 260 40"
          fill="none"
          stroke="#6E8B67"
          strokeWidth="4"
          strokeLinecap="round"
          strokeDasharray="1 10"
        />
        <circle cx="30" cy="160" r="6" fill="#2E2B26" />
        <circle cx="260" cy="40" r="6" fill="#6E8B67" />
      </svg>
    </div>
  );
}