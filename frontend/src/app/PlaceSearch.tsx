"use client";

/* DISPLAY OWNER: address-entry UI only; do not move crowd or forecast logic here. */

import { useEffect, useRef, useState } from "react";
import { loadGoogleMaps } from "./GeographicMap";

type Props = {
  ariaLabel: string;
  value: string;
  onChange: (value: string) => void;
};

type PlaceAutocompleteElement = HTMLElement & {
  value: string;
  addEventListener(type: "gmp-select", listener: (event: Event) => void): void;
  removeEventListener(type: "gmp-select", listener: (event: Event) => void): void;
};

/* eslint-disable @typescript-eslint/no-namespace */
declare global {
  namespace JSX {
    interface IntrinsicElements {
      "gmp-place-autocomplete": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement>;
    }
  }
}
/* eslint-enable @typescript-eslint/no-namespace */

export default function PlaceSearch({ ariaLabel, value, onChange }: Props) {
  const host = useRef<HTMLDivElement>(null);
  const onChangeRef = useRef(onChange);
  const [status, setStatus] = useState<"loading" | "ready" | "fallback">("loading");

  useEffect(() => { onChangeRef.current = onChange; }, [onChange]);

  useEffect(() => {
    const hostNode = host.current;
    let cancelled = false;
    let autocomplete: PlaceAutocompleteElement | null = null;
    let listener: ((event: Event) => void) | undefined;

    async function mountAutocomplete() {
      try {
        await loadGoogleMaps();
        const places = await window.google.maps.importLibrary("places");
        if (cancelled || !host.current) return;

        const PlaceAutocompleteElement = places.PlaceAutocompleteElement;
        const autocompleteInstance = new PlaceAutocompleteElement({
          includedRegionCodes: ["au"],
          locationBias: {
            center: { lat: -37.8136, lng: 144.9631 },
            radius: 50000,
          },
        });
        autocomplete = autocompleteInstance;
        autocompleteInstance.setAttribute("aria-label", ariaLabel);
        autocompleteInstance.setAttribute("placeholder", "Search a Melbourne address");

        listener = async (event: Event) => {
          const prediction = (event as unknown as { placePrediction?: { toPlace: () => unknown } }).placePrediction;
          if (!prediction) return;
          const place = prediction.toPlace() as {
            fetchFields: (options: { fields: string[] }) => Promise<void>;
            formattedAddress?: string;
            displayName?: string;
          };
          await place.fetchFields({ fields: ["formattedAddress", "displayName", "location"] });
          const selected = place.formattedAddress || place.displayName;
          if (selected) onChangeRef.current(selected);
        };
        autocompleteInstance.addEventListener("gmp-select", listener);
        host.current.replaceChildren(autocompleteInstance);
        setStatus("ready");
      } catch {
        if (!cancelled) setStatus("fallback");
      }
    }

    void mountAutocomplete();
    return () => {
      cancelled = true;
      if (autocomplete && listener) autocomplete.removeEventListener("gmp-select", listener);
      if (hostNode) hostNode.replaceChildren();
    };
  }, [ariaLabel]);

  useEffect(() => {
    const hostNode = host.current;
    const element = hostNode?.firstElementChild as PlaceAutocompleteElement | null;
    if (status === "ready" && element && element.value !== value) {
      element.setAttribute("value", value);
    }
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
