import { catalog } from './catalog.js';
import * as F from './FullJourneyCatalog.js';
import type { CarDefinition, JourneyState, Pad, Plan, Point, TycoonState } from './types.js';
export const initialJourney = (): JourneyState => ({
  step: 0, tutorialComplete: false, cycle: 0, nextSellerAt: 0,
  intakePaused: false, automation: true, seenCars: [], cosmetics: [],
});
/** Grant the completed prefix only where the old opening actually established it.
 * Later individually owned abilities remain in pads; no cash/car/job is replaced. */
export function migrateOpening(s: TycoonState): TycoonState {
  if (s.journey) return s;
  const n = s.pads.includes('display') ? 22 : s.pads.includes('salesdesk') ? 6
    : s.pads.includes('tools') ? 3 : s.pads.includes('intake') ? 2 : s.pads.includes('lot') ? 1 : 0;
  s.journey = { ...initialJourney(), step: n, tutorialComplete: s.sales > 0 || !!s.car || n > 2,
    cycle: s.sales, nextSellerAt: s.clock + F.sellerDelay(n) };
  s.parts ??= { level: 1, completed: 0 };
  if (n >= 3 && s.car?.owned && s.car.status === 'owned' && !s.car.plan) s.car.status = 'choose';
  return s;
}
export const feature = (s: TycoonState, id: string) => s.pads.includes(id)
  || (!!s.journey && F.featureSteps[id] !== undefined && s.journey.step >= F.featureSteps[id]);
/** Sales staff publish every restored car, including the player's special flips. */
export const staffedListing = (s: TycoonState) => feature(s, 'salesrep')
  && s.journey?.automation !== false && !s.car?.business?.tutorial;
export const staffedPhoto = (s: TycoonState) => staffedListing(s)
  && s.car?.plan?.jobs.find(j => !j.done)?.id === 'Photo_Listing';
/** Sales staff approach during repairs; only the photo/key handover remains afterward. */
export const salesHandoverSeconds = (_s: TycoonState): number => 2.4;
export function salesPreparationPoint(s: TycoonState): Point | undefined {
  const c = s.car;
  if (!c?.owned || c.remote || !c.plan) return undefined;
  if (c.status === 'repair' || c.status === 'ready') return c.pos;
  return c.route?.target === 'repair' ? c.route.points[c.route.points.length - 1] : undefined;
}
/** The mechanic's idle station moves with the authored repair shed. */
export const mechanicHome = (s: TycoonState): Point => feature(s, 'mechanic') && s.journey
  ? F.sourcePoint(3045, 177) : [...catalog.points.mechanic];
export function purchaseGate(s: TycoonState): string | undefined {
  const j = s.journey, c = s.car;
  if (!j || j.step >= F.COUNT) return 'Dealership complete';
  if (j.tutorialComplete || j.step < 2) return undefined;
  if (j.step === 2) return c?.owned ? undefined : 'Meet the seller and buy Rusty first';
  if (j.step < 6) return c?.business?.tutorial && c.condition.Mechanical === 'Good' && c.condition.RunningGear === 'Good'
    ? undefined : "Restore Rusty's engine and front-left wheel first";
  return "Close Rusty's first sale before expanding";
}
export function purchasePad(s: TycoonState): Pad | undefined {
  const j = s.journey, e = j && F.nextEntry(j.step); if (!e) return undefined;
  const p = j!.padPosition ?? e.padPosition;
  return { id: e.id, name: e.title, description: e.benefit, cost: e.cost, pos: F.sourcePoint(p[0], p[2]),
    after: [], at: 0, sourceId: e.id, sourcePosition: p, gameplayWired: true, category: e.category };
}
export function ownsCosmetic(s: TycoonState, step: number): boolean {
  const e = F.entries[step - 1];
  return !e || e.category !== 'Cosmetic' || !s.journey || (s.journey.cosmetics === undefined ? s.journey.step >= step : s.journey.cosmetics.includes(e.id));
}
export function cosmeticPads(s: TycoonState): Pad[] {
  const j = s.journey; if (!j || !j.tutorialComplete) return [];
  return F.entries.filter(e => e.category === 'Cosmetic' && !ownsCosmetic(s, e.step)
    && !F.entries.some(previous => previous.step < e.step && previous.step > j.step && previous.category !== 'Cosmetic')).map(e => {
    const index = F.entries.filter(row => row.category === 'Cosmetic').indexOf(e);
    const p = j.cosmeticPadPositions?.[e.id] ?? [3105, 1.9, 80 + index * 22] as [number, number, number];
    return { id: e.id, name: e.title, description: e.benefit, cost: e.cost, pos: F.sourcePoint(p[0], p[2]),
      after: [], at: 0, sourceId: e.id, sourcePosition: p, gameplayWired: false, category: 'Cosmetic', optional: true };
  });
}
export function allPurchasePads(s: TycoonState): Pad[] {
  const recommended = !purchaseGate(s) ? purchasePad(s) : undefined;
  return [...(recommended ? [recommended] : []), ...cosmeticPads(s)];
}
export function workPlan(s: TycoonState, good = false): Plan {
  const c = s.car!, j = s.journey!;
  const position = j.step >= 35 ? F.sourcePoint(3008, 187) : F.sourcePoint(3041, 132);
  const parts = c.business?.tutorial ? ['Mechanical', 'RunningGear'] as const : ['Body', 'RunningGear', 'Mechanical'] as const;
  const names = { Body: 'Repair body', RunningGear: 'Repair wheels', Mechanical: 'Repair engine' };
  const jobs: Plan['jobs'] = parts.filter(id => c.condition[id] !== 'Good').map(id => ({
    id, name: names[id], cost: c.business?.tutorial ? 0 : F.serviceInputCost(j.step), seconds: F.serviceSeconds(j.step), done: false, started: false, progress: 0,
    position: [...position], staffAt: c.business?.tutorial ? undefined : 40,
  }));
  if (!c.business?.tutorial) for (const d of F.departments) if (j.step >= d.first) jobs.push({
    id: d.id, name: d.name, cost: F.serviceInputCost(j.step, true), seconds: F.serviceSeconds(j.step), done: false, started: false, progress: 0,
    position: F.sourcePoint(d.x, d.z), staffAt: d.staff,
  });
  if (good && !c.business?.tutorial) jobs.push({ id: 'Tune', name: 'Tune & finish', cost: 220, seconds: 8, done: false, started: false, progress: 0, position: [...position], staffAt: 40 });
  return { jobs, cost: jobs.reduce((n, job) => n + job.cost, 0), seconds: jobs.reduce((n, job) => n + job.seconds, 0) };
}
export function staffedJob(s: TycoonState): boolean {
  const c = s.car, job = c?.plan?.jobs.find(j => !j.done);
  if (staffedPhoto(s)) return true;
  if (!c?.business) return s.worker.hired;
  if (c.business.tutorial || !s.journey?.automation || !job || job.staffAt === undefined) return false;
  return s.journey.step >= job.staffAt || (job.staffAt === 40 && s.worker.hired);
}
export function businessDefinition(s: TycoonState): { definition: CarDefinition; index: number; templateId: string; consignment: boolean } {
  const j = s.journey!, tutorial = !j.tutorialComplete;
  const choices = j.step >= 90 ? ['Bavora', 'HondoCivixEK', 'Rusty'] : ['Rusty', 'HondoCivixEK'];
  const gblock = F.entries.find(e => e.id === 'FJ_DEDICATED_WASH_ENCLOSURE')!;
  if (j.step >= gblock.step) choices.push('Gblock');
  const templateId = tutorial ? 'Rusty' : choices[j.cycle % choices.length];
  const index = templateId === 'Rusty' ? 1 : templateId === 'Bavora' ? 2 : 3;
  const base = catalog.cars[index - 1], ask = tutorial ? 25 : F.acquisitionCost(j.step);
  const serviceCost = 3 * F.serviceInputCost(j.step) + F.departments.filter(d => j.step >= d.first).length * F.serviceInputCost(j.step, true);
  const consignment = !tutorial && s.cash < ask + serviceCost;
  const names: Record<string, string> = { Rusty: 'Rusty', HondoCivixEK: 'Hondo Civix EK', Bavora: 'Bavora', Gblock: 'G-Block' };
  const condition = { Body: tutorial ? 'Good' : 'Damaged', Mechanical: 'Ruined', RunningGear: 'Damaged', Exterior: 'Good' } as const;
  return { index, templateId, consignment, definition: { ...base, id: templateId, name: names[templateId], condition,
    seller: 'Seller', sellerRole: consignment ? 'Consignment' : 'Local seller',
    sellerLine: tutorial ? "The engine is dead and the front-left wheel is missing. Rusty is yours for $25."
      : consignment ? 'Restore this car on consignment. No purchase deposit; you keep 75% of the service profit.' : 'A project car for your dealership.',
    ask: consignment ? 0 : ask, floor: tutorial ? 25 : consignment ? 0 : Math.floor(ask * .9),
    offers: [...base.offers], buyer: 'Buyer', buyerRole: 'Driver', buyerLine: 'That repair work made a difference.', buyerMax: 0,
  } };
}
// FullJourneyOperations CIRC02: the sampled curves and lane connections are kept in source studs.
const line = (out: Point[], x: number, z: number, X: number, Z: number) => {
  const n = Math.max(1, Math.ceil(Math.hypot(X - x, Z - z) / 3));
  for (let i = 0; i <= n; i++) out.push(F.sourcePoint(x + (X - x) * i / n, z + (Z - z) * i / n));
};
const arc = (out: Point[], x: number, z: number, radius: number, a: number, b: number) => {
  a *= Math.PI / 180; b *= Math.PI / 180;
  const n = Math.max(1, Math.ceil(Math.abs(b - a) * radius / 3));
  for (let i = 0; i <= n; i++) { const t = a + (b - a) * i / n; out.push(F.sourcePoint(x + radius * Math.cos(t), z + radius * Math.sin(t))); }
};
export const arrivalRoute: Point[] = [];
line(arrivalRoute, 3076, 8, 3076, 17); arc(arrivalRoute, 3063, 17, 13, 0, 90); line(arrivalRoute, 3063, 30, 3021, 30);
arc(arrivalRoute, 3021, 43, 13, -90, -180); line(arrivalRoute, 3008, 43, 3008, 88);
const workRoute: Point[] = [];
line(workRoute, 3008, 88, 3008, 90); arc(workRoute, 3021, 90, 13, 180, 90); line(workRoute, 3021, 103, 3060, 103);
arc(workRoute, 3060, 117.5, 14.5, -90, 0); arc(workRoute, 3060, 117.5, 14.5, 0, 90); line(workRoute, 3060, 132, 3041, 132);
const salesRoute: Point[] = [];
line(salesRoute, 3041, 132, 3060, 132); arc(salesRoute, 3060, 117.5, 14.5, 90, 0);
line(salesRoute, 3074.5, 117.5, 3074.5, 96); line(salesRoute, 3074.5, 96, 3073, 82);
export function laneRoute(from: Point, to: Point): Point[] {
  const x = 3035 + from[0] * 3, z = 112 + from[1] * 3, X = 3035 + to[0] * 3, Z = 112 + to[1] * 3;
  const oldLane = x < 3105 ? 3074.5 : 3135.5, newLane = X < 3105 ? 3074.5 : 3135.5;
  return [from, F.sourcePoint(oldLane, z), ...(oldLane !== newLane ? [F.sourcePoint(oldLane, 373), F.sourcePoint(newLane, 373)] : []), F.sourcePoint(newLane, Z), to];
}
export function travelRoute(s: TycoonState, target: string): Point[] {
  const c = s.car!, openingRepair = F.sourcePoint(3041, 132);
  if (target === 'repair') {
    const destination = c.plan?.jobs.find(j => !j.done)?.position ?? (s.journey!.step >= 35 ? F.sourcePoint(3008, 187) : openingRepair);
    if (s.journey!.step < 35 && Math.hypot(c.pos[0] + 9, c.pos[1] + 8) < 2) return [c.pos, ...workRoute];
    return laneRoute(c.pos, destination);
  }
  if (target === 'sales') return Math.hypot(c.pos[0] - openingRepair[0], c.pos[1] - openingRepair[1]) < 1
    ? [c.pos, ...salesRoute] : laneRoute(c.pos, F.sourcePoint(3073, 82));
  if (target === 'exit') return laneRoute(c.pos, F.sourcePoint(3073, 8));
  return laneRoute(c.pos, F.sourcePoint(3008, 88));
}
