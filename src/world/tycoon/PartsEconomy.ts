import { moveVehicle } from './VehicleRoute.js';
import { COURIER_DEPOT, PART_SHOPS, townRoute } from '../TownPlaces.js';
import type { Plan, TycoonState } from './types.js';

export const STARTER_PARTS = 40;
export const PART_VALUE = 10;
export const PARTS_PACKAGES = [
  { id: 'small', key: 'Digit1', parts: 10, cost: 100 },
  { id: 'crate', key: 'Digit2', parts: 50, cost: 450 },
  { id: 'pallet', key: 'Digit3', parts: 200, cost: 1600 },
] as const;
export const partsStock = (s: TycoonState) => s.partsStock ?? STARTER_PARTS;
/** Small bundles are always available, including when only one or two Parts are missing. */
export const restockBudget = (required: number, stock: number) => Math.ceil(Math.max(0, required - stock) / 10) * 100;
export const courierCost = (s: TycoonState) => 600 + (s.couriers?.length ?? 0) * 600;
const courierParking = (id: number): [number, number] => [COURIER_DEPOT.position[0] + (id - 2) * 4, COURIER_DEPOT.position[1]];
export function repairCost(plan: Plan) {
  const parts = plan.partsCost ?? Math.floor(plan.cost * .2 / PART_VALUE);
  return { cash: plan.cashCost ?? plan.cost - parts * PART_VALUE, parts, total: plan.cost };
}
export function pricePlan(plan: Plan): Plan {
  const cost = repairCost(plan); return { ...plan, cashCost: cost.cash, partsCost: cost.parts };
}
export function fundRepair(s: TycoonState, plan: Plan, deferCash = false): boolean {
  const cost = repairCost(plan);
  if ((!deferCash && s.cash < cost.cash) || partsStock(s) < cost.parts) {
    s.notice = partsStock(s) < cost.parts ? `Need ${cost.parts - partsStock(s)} more Parts. Visit a Car Part Shop or hire a delivery driver.` : `Need $${Math.ceil(cost.cash - s.cash)} more for this work.`;
    s.noticeUntil = s.clock + 5; return false;
  }
  s.cash -= deferCash ? 0 : cost.cash; s.partsStock = partsStock(s) - cost.parts;
  if (deferCash) plan.deferredCash = cost.cash;
  s.ledger.push({ amount: deferCash ? 0 : -cost.cash, kind: 'work', subject: `Repair plan · ${cost.parts} Parts${deferCash ? ' · cash settled at sale' : ''}` });
  return true;
}
export function buyParts(s: TycoonState, packageId: string): boolean {
  const pack = PARTS_PACKAGES.find(p => p.id === packageId);
  if (!pack || s.cash < pack.cost) return false;
  s.cash -= pack.cost; s.partsStock = partsStock(s) + pack.parts;
  s.ledger.push({ amount: -pack.cost, kind: 'parts-purchase', subject: `${pack.parts} Parts` });
  s.notice = `Bought ${pack.parts} Parts`; s.noticeUntil = s.clock + 3; return true;
}
export function hireCourier(s: TycoonState): boolean {
  const cost = courierCost(s), couriers = s.couriers ??= [];
  if (couriers.length >= 3 || s.cash < cost) return false;
  s.cash -= cost; s.ledger.push({ amount: -cost, kind: 'staff', subject: 'Parts delivery driver' });
  const id = couriers.length + 1;
  couriers.push({ id, pos: courierParking(id), phase: 'idle', wait: 2 + (id - 1) * 4, cargo: 0, trips: 0 });
  s.notice = 'Driver hired. Each run buys 50 Parts for $400 and delivers them to your stock.'; s.noticeUntil = s.clock + 6; return true;
}
export function tickCouriers(s: TycoonState, dt: number, protectedCash = 500) {
  for (const driver of s.couriers ?? []) {
    if (driver.route) {
      if (moveVehicle(driver, dt, 16)) {
        driver.wait = driver.phase === 'outbound' ? 5 : 4;
        driver.phase = driver.phase === 'outbound' ? 'loading' : 'unloading';
      }
      continue;
    }
    driver.wait = Math.max(0, driver.wait - dt); if (driver.wait > 0) continue;
    if (driver.phase === 'idle') {
      // Stop stocking at a useful buffer and preserve cash for active work and ordinary acquisitions.
      if (partsStock(s) + (s.couriers ?? []).reduce((n, d) => n + d.cargo, 0) >= 150 || s.cash < 400 + Math.max(500, protectedCash)) { driver.wait = 5; continue; }
      s.cash -= 400; driver.cargo = 50;
      s.ledger.push({ amount: -400, kind: 'parts-delivery', subject: `Driver ${driver.id} · 50 Parts` });
      driver.phase = 'outbound'; driver.route = { target: 'shop', points: townRoute(driver.pos, PART_SHOPS[(driver.id - 1) % PART_SHOPS.length].position), step: 1 };
    } else if (driver.phase === 'loading') {
      driver.phase = 'returning'; driver.route = { target: 'depot', points: townRoute(driver.pos, courierParking(driver.id)), step: 1 };
    } else if (driver.phase === 'unloading') {
      s.partsStock = partsStock(s) + driver.cargo; driver.cargo = 0; driver.trips++;
      driver.phase = 'idle'; driver.wait = 12;
      s.notice = `Driver ${driver.id} delivered 50 Parts`; s.noticeUntil = s.clock + 4;
    }
  }
}
