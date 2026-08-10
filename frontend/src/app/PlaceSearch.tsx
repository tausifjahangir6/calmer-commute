"use client";

/* DISPLAY OWNER: address-entry UI only; do not move crowd or forecast logic here. */

import { useEffect, useRef, useState } from "react";
import { loadGoogleMaps } from "./GeographicMap";

type Props = {
  ariaLabel: string;
  value: string;
  onChange: (value: string) => void;
};

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "gmp-place-autocomplete": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement>;
    }
  }
}

export default function PlaceSearch({ ariaLabel, value, onChange }: Props) {
  const host = useRef<HTMLDivElement>(null);
  const onChangeRef = useRef(onChange);
  const [status, setStatus] = useState<"loading" | "ready" | "fallback">("loading");

  useEffect(() => { onChangeRef.current = onChange; }, [onChange]);

  useEffect(() => {
    let cancelled = false;
    let autocomplete: any;
    let listener: ((event: Event) => void) | undefined;

    async function mountAutocomplete() {
      try {
        await loadGoogleMaps();
        const places = await window.google.maps.importLibrary("places");
        if (cancelled || !host.current) return;

        const PlaceAutocompleteElement = places.PlaceAutocompleteElement;
        autocomplete = new PlaceAutocompleteElement({
          includedRegionCodes: ["au"],
          locationBias: {
            center: { lat: -37.8136, lng: 144.9631 },
            radius: 50000,
          },
        });
        autocomplete.setAttribute("aria-label", ariaLabel);
        autocomplete.setAttribute("placeholder", "Search a Melbourne address");
        autocomplete.value = value;

        listener = async (event: Event) => {
          const prediction = (event as any).placePrediction;
          if (!prediction) return;
          const place = prediction.toPlace();
          await place.fetchFields({ fields: ["formattedAddress", "displayName", "location"] });
          const selected = place.formattedAddress || place.displayName;
          if (selected) onChangeRef.current(selected);
        };
        autocomplete.addEventListener("gmp-select", listener);
        host.current.replaceChildren(autocomplete);
        setStatus("ready");
      } catch {
        if (!cancelled) setStatus("fallback");
      }
    }

    void mountAutocomplete();
    return () => {
      cancelled = true;
      if (autocomplete && listener) autocomplete.removeEventListener("gmp-select", listener);
      if (host.current) host.current.replaceChildren();
    };
  }, [ariaLabel]);

  useEffect(() => {
    const element = host.current?.firstElementChild as any;
    if (status === "ready" && element && element.value !== value) element.value = value;
  }, [status, value]);

  if (status === "fallback") {
    return <textarea aria-label={ariaLabel} value={value} onChange={(event) => onChange(event.target.value)} rows={2} />;
  }

  return (
    <div className="place-search-shell">
      <div ref={host} className="place-search-host" />
      {status === "loading" && <div className="place-search-loading" aria-live="polite">Connecting Google address search…</div>}
    </div>
  );
}
