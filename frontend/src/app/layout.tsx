import type { Metadata } from "next";
import "leaflet/dist/leaflet.css";
import "./globals.css";
import "./refinements.css";

export const metadata: Metadata = {
  title: "Calmer Commute",
  description: "A sensory-aware journey planner for Melbourne.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
