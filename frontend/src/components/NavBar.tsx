"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const links = [
  { href: "/onboard", label: "Onboard" },
  { href: "/", label: "Home" },
  { href: "/profile", label: "Profile" },
  { href: "/quiet-spot", label: "Quiet Spot" },
  { href: "/emergency", label: "Emergency" },
];

export default function NavBar() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-10 border-b border-[#DDD8CC] bg-white/80 backdrop-blur">
      <nav className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6 text-sm">
        <div className="flex gap-6">
          {links.map((link) => {
            const active =
              link.href === "/" ? pathname === "/" : pathname?.startsWith(link.href);
            return (
              <Link
                key={link.href}
                href={link.href}
                className={
                  active
                    ? "font-medium text-[#6E8B67]"
                    : "text-[#8A8578] transition-colors hover:text-[#2E2B26]"
                }
              >
                {link.label}
              </Link>
            );
          })}
        </div>
        <button className="text-[#8A8578] transition-colors hover:text-[#2E2B26]">
          Sign out
        </button>
      </nav>
    </header>
  );
}