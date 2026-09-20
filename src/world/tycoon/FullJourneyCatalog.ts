// FullJourneyCatalog from Sell Cars. Positions remain in source studs.
import { explicitPads, sourceEntries, thresholds, milestones } from './journeyData.js';
import type { Point, Vec } from './types.js';
import { purchaseCategory, PARKING_STEPS } from './PurchaseCategories.js';
import type { PurchaseCategory } from './PurchaseCategories.js';
export interface JourneySourceEntry {
  id: string; step: number; sourceOrder: number; title: string; delta: string; benefit: string;
  chapter: string; milestone: string; geometryFocus: Vec; sourceGeometryCount: number;
}
export interface JourneyMilestone {
  id: string; first: number; last: number; title: string; summary: string;
  limitation: string; preparation: string; payoff: string; anchor: number;
}
export interface JourneyEntry extends JourneySourceEntry { cost: number; padPosition: Vec; unlocks: string[]; category: PurchaseCategory }
export const COUNT = 240;
export const STARTING_CASH = 400;
export { thresholds, milestones };
const rounded = (n: number) => Math.floor(n / 25 + .5) * 25;
export function costForStep(step: number): number {
  if (!Number.isInteger(step) || step < 1 || step > COUNT) return Infinity;
  if (step <= 6) return [0, 25, 50, 25, 25, 25][step - 1];
  if (step <= 24) return rounded(75 + (step - 7) * (125 / 17));
  if (step <= 64) return rounded(225 + (step - 25) * (375 / 39));
  if (step <= 140) return rounded(650 + (step - 65) * 20);
  if (step <= 196) return rounded(2250 + (step - 141) * 50);
  return rounded(5100 + (step - 197) * 100);
}
export const entries: JourneyEntry[] = sourceEntries.map(e => ({
  ...e, cost: costForStep(e.step),
  category: PARKING_STEPS.has(e.step) ? 'Architectural' : purchaseCategory(e.step, e.title),
  ...(PARKING_STEPS.has(e.step) ? { title: e.step === 143 ? 'Customer parking forecourt' : 'Customer parking bay ' + ({ 31: 2, 32: 3, 128: 4, 133: 5, 140: 6 } as Record<number, number>)[e.step], benefit: 'Reuse the former sales-display footprint for customer parking and clear vehicle access', delta: 'Marked customer parking replaces static vehicle displays.' } : {}),
  ...(e.step === 6 ? { title: 'Sales desk and Manny', benefit: 'Build the handover desk and hire Manny to park your restored cars' } : {}),
  padPosition: explicitPads[e.step] ?? [3105, 1.9, Math.max(35, Math.min(450, Math.floor(e.geometryFocus[2] / 5 + .5) * 5))],
  unlocks: Object.keys(thresholds).filter(key => thresholds[key] === e.step).sort(),
}));
export const nextEntry = (step: number) => entries.find(e => e.step > step && e.category !== 'Cosmetic');
export const hasCapability = (step: number, capability: string) => thresholds[capability] !== undefined && step >= thresholds[capability];
export function capabilities(n: number): Record<string, boolean | number> {
  const step = Math.max(0, Math.min(COUNT, Math.floor(n)));
  const result: Record<string, boolean | number> = Object.fromEntries(Object.entries(thresholds).map(([key, threshold]) => [key, step >= threshold]));
  Object.assign(result, {
    IntakeCapacity: step >= 29 ? 2 : step >= 2 ? 1 : 0,
    SalesCapacity: step >= 140 ? 6 : step >= 133 ? 5 : step >= 128 ? 4 : step >= 32 ? 3 : step >= 31 ? 2 : step >= 6 ? 1 : 0,
    MechanicalCapacity: step >= 126 ? 2 : step >= 3 ? 1 : 0,
    WashCapacity: step >= 124 ? 2 : step >= 4 ? 1 : 0,
    BodyCapacity: step >= 129 ? 2 : step >= 7 ? 1 : 0,
    TuneCapacity: step >= 131 ? 2 : step >= 9 ? 1 : 0,
    PaintCapacity: step >= 134 ? 2 : step >= 8 ? 1 : 0,
    DetailCapacity: step >= 136 ? 2 : step >= 11 ? 1 : 0,
    PhotoCapacity: step >= 138 ? 2 : step >= 5 ? 1 : 0,
    PersonalCapacity: step >= 226 ? 6 : step >= 183 ? 5 : step >= 120 ? 3 : step >= 62 ? 2 : step >= 22 ? 1 : 0,
    SaleValueMultiplier: 1 + step * .025,
  });
  return result;
}
export const sourcePoint = (x: number, z: number): Point => [(x - 3035) / 3, (z - 112) / 3];
// Compatibility bindings preserve Integration abilities and individually owned upgrades.
export const featureSteps: Record<string, number> = {
  lot: 1, intake: 2, repairbay: 3, tools: 3, air: 3, sales: 5, salesdesk: 6,
  servicefloor: 4, restoration: 7, finish: 8, wheeltools: 9, fluidkit: 10,
  finishtrolley: 11, partsshelves: 12, shade: 13, power: 16,
  display: 22, carbuyer: 29, salesrep: 33, mechanic: 40,
};
export const departments = [
  { id: 'Wash', name: 'Wash', first: 41, staff: 42, x: 3023, z: 132 },
  { id: 'Body_Restoration', name: 'Body restoration', first: 46, staff: 89, x: 3023, z: 251 },
  { id: 'Tune_Performance', name: 'Performance tune', first: 51, staff: 95, x: 3023, z: 319 },
  { id: 'Paint_Exterior', name: 'Paint finish', first: 49, staff: 101, x: 3187, z: 319 },
  { id: 'Detail_QC', name: 'Detail and quality check', first: 43, staff: 105, x: 3187, z: 251 },
  { id: 'Photo_Listing', name: 'Listing photos', first: 60, staff: 108, x: 3187, z: 187 },
] as const;
export const serviceSeconds = (step: number) => Math.max(1, 3 - step / 120);
export const serviceInputCost = (step: number, department = false) => (department ? 30 : 50) + Math.floor(step / 10) * 10;
export const sellerDelay = (step: number) => Math.max(3, 10 - step / 30);
export const acquisitionCost = (step: number) => 200 + Math.floor(step / 10) * 50;
export const operationProfit = (step: number, services: number, consignment: boolean) => {
  const profit = Math.floor(150 + step * 14 + services * 35 + Math.pow(step, 1.35) * 3);
  return consignment ? Math.floor(profit * .75) : profit;
};
