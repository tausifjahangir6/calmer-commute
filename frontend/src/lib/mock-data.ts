export type SensoryLevel = "Low" | "Moderate" | "High";

export type RouteOption = {
  id: string;
  label: string;
  type: "fastest" | "calmest";
  durationMin: number;
  distanceKm: number;
  sensoryLevel: SensoryLevel;
  turnByTurnFirstStep: string;
  crowdForecast: number; // mirrors Ishrak's `forecast` field
  baseThreshold: number; // mirrors the 75th-percentile base threshold
};

export const mockRoutes: RouteOption[] = [
  {
    id: "route-a",
    label: "Route A",
    type: "fastest",
    durationMin: 16,
    distanceKm: 1.2,
    sensoryLevel: "Moderate",
    turnByTurnFirstStep: "Turn right onto XXX St",
    crowdForecast: 340,
    baseThreshold: 323,
  },
  {
    id: "route-b",
    label: "Option B",
    type: "calmest",
    durationMin: 23,
    distanceKm: 1.6,
    sensoryLevel: "Low",
    turnByTurnFirstStep: "Continue straight past the park",
    crowdForecast: 120,
    baseThreshold: 200,
  },
];

/**
 * Mocks POST /api/routes/compare.
 * Swap the body of this function for a real fetch() once
 * the backend contract is live — nothing that calls this needs to change.
 */
export async function fetchRoutes(from: string, to: string): Promise<RouteOption[]> {
  await new Promise((resolve) => setTimeout(resolve, 400));
  if (!from || !to) throw new Error("Missing origin or destination");
  return mockRoutes;
}

// --- US1.3: user crowd threshold + alert logic ---
// Mirrors Ishrak's SENSITIVITY_MULTIPLIERS in ai/models/alert_thresholds.py

export type Sensitivity = "cautious" | "default" | "relaxed";

export const sensitivityMultipliers: Record<Sensitivity, number> = {
  cautious: 0.7,
  default: 1.0,
  relaxed: 1.3,
};

export function getAlertThreshold(route: RouteOption, sensitivity: Sensitivity): number {
  return route.baseThreshold * sensitivityMultipliers[sensitivity];
}

export function isRouteAlerting(route: RouteOption, sensitivity: Sensitivity): boolean {
  return route.crowdForecast >= getAlertThreshold(route, sensitivity);
}

export type RefugeSpot = {
  id: string;
  name: string;
  type: string;
  decibels: number;
  quietnessLabel: string;
  accessibility: string;
};

export const mockRefugeSpots: RefugeSpot[] = [
  {
    id: "refuge-1",
    name: "State Library Reading Room",
    type: "Library",
    decibels: 32,
    quietnessLabel: "Very quiet",
    accessibility: "Wheelchair",
  },
];

// Mocks GET /api/refuges
export async function fetchRefugeSpots(): Promise<RefugeSpot[]> {
  await new Promise((resolve) => setTimeout(resolve, 300));
  return mockRefugeSpots;
}

export type UserProfile = {
  noiseTolerance: number;
  crowdDensity: number;
  avoidSun: boolean;
  avoidNeon: boolean;
  otherTriggers: string;
};

export const defaultProfile: UserProfile = {
  noiseTolerance: 30,
  crowdDensity: 50,
  avoidSun: false,
  avoidNeon: false,
  otherTriggers: "",
};

// Mocks POST /api/profile
export async function saveProfile(profile: UserProfile): Promise<{ success: boolean }> {
  await new Promise((resolve) => setTimeout(resolve, 300));
  return { success: true };
}