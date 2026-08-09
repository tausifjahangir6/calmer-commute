"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const primaryLink = { href: "/onboard", label: "Onboard" };

const centerLinks = [
  { href: "/", label: "Home" },
  { href: "/profile", label: "Profile" },
  { href: "/quiet-spot", label: "Quiet Spot" },
  { href: "/emergency", label: "Emergency" },
];

export default function NavBar() {
  const pathname = usePathname();

  function isActive(href: string) {
    return href === "/" ? pathname === "/" : pathname?.startsWith(href);
  }

  return (
    <header className="sticky top-0 z-10 border-b border-[#DDD8CC] bg-white/80 backdrop-blur">
      <nav className="mx-auto grid h-14 max-w-6xl grid-cols-[auto_1fr] items-center px-6 text-sm">
        <Link
          href={primaryLink.href}
          className={
            isActive(primaryLink.href)
              ? "font-medium text-[#6E8B67]"
              : "text-[#8A8578] transition-colors hover:text-[#2E2B26]"
          }
        >
          {primaryLink.label}
        </Link>

        <div className="flex justify-center gap-6">
          {centerLinks.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className={
                isActive(link.href)
                  ? "font-medium text-[#6E8B67]"
                  : "text-[#8A8578] transition-colors hover:text-[#2E2B26]"
              }
            >
              {link.label}
            </Link>
          ))}
        </div>
      </nav>
    </header>
  );
}