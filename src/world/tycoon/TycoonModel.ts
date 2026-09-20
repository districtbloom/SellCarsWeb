import { repairProgress } from './RepairGame.js';
import { randomWorkOrder } from './RepairWorkOrders.js';
import { moveVehicle } from './VehicleRoute.js';
import { DEALERSHIP_GARAGE, RESIDENTIAL_CAR, RESIDENTIAL_PARKING, RESIDENTIAL_SELLER, townRoute } from '../TownPlaces.js';
// Port of ReplicatedStorage.HubSlice.HubModel. Mutations are owned by TycoonSession.
// Source car indices remain 1-based; JavaScript route waypoint indices are 0-based.
import { catalog as D } from './catalog.js';
import * as F from './FullJourneyCatalog.js';
import * as J from './FullJourney.js';
import { tickParts } from './PartsStation.js';
import { STARTER_PARTS, pricePlan, repairCost, partsStock, restockBudget, fundRepair, tickCouriers } from './PartsEconomy.js';
import { garageUnlocked, ownedPersonalModels, personalCarOption } from './PersonalCars.js';
import type { Buyer, CarDefinition, Condition, Depth, Grade, Look, Moving, Pad, PartId, Plan, Point, TycoonState } from './types.js';

export const copy = <T>(value: T): T => JSON.parse(JSON.stringify(value)) as T;
export const originalLook = (): Look => ({ paint: 'original', wheels: 'original', stripe: false });
export const PHOENIX_PRICE = 2200;
export const phoenixDefinition = (): CarDefinition => ({ ...D.cars[3], ask: PHOENIX_PRICE, floor: 2000 });
export function fresh(): TycoonState {
  return { cash: 7000, partsStock: STARTER_PARTS, couriers: [], pads: [], sales: 0, clock: 0, history: [], ledger: [],
    worker: { hired: false, level: 1, jobs: 0, pos: copy(D.points.mechanic), activity: 'Ready' },
    seen: false, lowballPassed: false, completed: false };
}
export const freshJourney = (): TycoonState => ({ ...fresh(), cash: F.STARTING_CASH, journey: J.initialJourney(), revenue: [], parts: { level: 1, completed: 0 } });
export const has = J.feature;
export const staffedJob = J.staffedJob;
export const def = (s: TycoonState): CarDefinition => {
  if (!s.car) throw new Error('No active trading car');
  return s.car.definition ?? (s.car.index === 4 ? phoenixDefinition() : D.cars[s.car.index - 1]);
};
export function grade(condition: Condition): Grade {
  return (Object.values(condition) as Grade[]).reduce((worst, g) => D.grades[g] > D.grades[worst] ? g : worst, 'Good');
}
export function quote(car: Pick<CarDefinition, 'condition'>, depth?: Depth): Plan {
  const q: Plan = { jobs: [], cost: 0, seconds: 0 };
  for (const id of ['Body', 'RunningGear', 'Mechanical', 'Exterior'] as PartId[]) {
    const base = D.base[id], multiplier = D.grades[car.condition[id]];
    if (multiplier > 0) q.jobs.push({ id, name: base.name, cost: base.cost * multiplier,
      seconds: base.seconds * multiplier, done: false, started: false, progress: 0 });
  }
  if (depth === 'Good') q.jobs.push({ id: 'Tune', name: 'Tune & finish', cost: 220, seconds: 8, done: false, started: false, progress: 0 });
  for (const j of q.jobs) { q.cost += j.cost; q.seconds += j.seconds; }
  return q;
}
export const workQuote = (s: TycoonState, depth?: Depth) => pricePlan(s.car?.business ? J.workPlan(s, depth === 'Good') : quote(def(s), depth));
export function note(s: TycoonState, text: string) { s.notice = text; s.noticeUntil = s.clock + 3; }
export function pay(s: TycoonState, n: number, kind: string, subject: string) {
  if (!Number.isFinite(n) || n < 0 || s.cash < n) return false;
  s.cash -= n; s.ledger.push({ amount: -n, kind, subject }); return true;
}
function event(s: TycoonState, text: string) { s.car?.history.push(text); }
export function terms(s: TycoonState) {
  const d = def(s), discount = s.car?.remote ? 300 : 0;
  return { ask: d.ask - discount, floor: d.floor - discount };
}
export function reserve(s: TycoonState): number {
  if (s.personal?.route?.target === 'lead' || s.lead?.status === 'visiting') return leadBudget(s, true)[0];
  const c = s.car;
  if (!c || s.lead?.kind === 'rare' && !c.remote && c.index !== 4) return s.lead?.kind === 'rare' ? leadBudget(s, false)[0] : 0;
  if (c.index === 4 && !c.owned) {
    const input = repairCost(quote(def(s)));
    return (c.quote?.accepted ?? terms(s).ask) + input.cash + restockBudget(input.parts, partsStock(s));
  }
  if (c.owned && !c.plan) { const cost = repairCost(workQuote(s)); return cost.cash + restockBudget(cost.parts, partsStock(s)); }
  if (c.plan?.funded) return 0;
  return c.plan?.jobs.reduce((sum, j) => sum + (j.started ? 0 : j.cost), 0) ?? 0;
}
export function eligible(s: TycoonState, p: Pad): boolean {
  if (s.journey) return p.id === J.purchasePad(s)?.id && !J.purchaseGate(s);
  return !has(s, p.id) && s.sales >= p.at && (!p.ownedCar || !!s.car?.owned)
    && (!p.readyCar || s.car?.status === 'ready') && p.after.every(id => has(s, id));
}
export const nextPad = (s: TycoonState) => s.journey ? (J.purchaseGate(s) ? undefined : J.purchasePad(s)) : D.pads.find(p => !p.optional && eligible(s, p));
export function lead(s: TycoonState, status = 'ringing') {
  if (!s.lead && status === 'ringing' && leadBudget(s, false)[1] > 0) { s.rareCallAt = s.clock + 5; return; }
  s.lead = { kind: 'rare', index: 4, status, caller: 'Jo', text: `Elias has a rare Phoenix for $${PHOENIX_PRICE.toLocaleString()} delivered. Collect it in Maple Heights to save $300.` };
}
export function answerCall(s: TycoonState) {
  if (!s.lead || !['ringing', 'missed', 'answered'].includes(s.lead.status)) return false;
  s.lead.status = 'answered'; return true;
}
export function remindCall(s: TycoonState) {
  if (!s.lead || s.lead.status === 'visiting') return false;
  s.lead.status = 'snoozed'; s.lead.remindAt = s.clock + 300; note(s, 'Jo will remind you in five minutes. Ordinary sellers keep arriving.'); return true;
}
export function invite(s: TycoonState) {
  if (!s.lead) return false;
  if (s.lead.kind === 'rare' && s.car) {
    s.lead.status = 'queued'; s.lead.remindAt = undefined;
    note(s, 'Elias will deliver the Phoenix after your current flip.'); return true;
  }
  return arrive(s, s.lead.index);
}
export function buyPad(s: TycoonState, id: string): boolean {
  if (s.journey) {
    const j = s.journey, p = J.allPurchasePads(s).find(pad => pad.id === id);
    if (!p) return false;
    const protectedCash = s.lead?.kind === 'rare' || s.car?.owned && !s.car.business ? reserve(s) : 0;
    if (s.cash - protectedCash < p.cost) { note(s, 'Keep enough cash for this upgrade and your current repairs.'); return false; }
    if (!pay(s, p.cost, 'pad', p.name)) return false;
    if (p.category === 'Cosmetic') {
      j.cosmetics ??= F.entries.filter(e => e.category === 'Cosmetic' && e.step <= j.step).map(e => e.id);
      j.cosmetics.push(p.id); note(s, p.name + ' ready'); return true;
    }
    j.step = F.entries.find(e => e.id === p.id)!.step;
    if (!F.nextEntry(j.step)) j.step = F.COUNT;
    j.padPosition = undefined; j.cosmeticPadPositions = undefined; note(s, p.name + ' ready');
    if (j.step === 2 && !s.car) arriveBusiness(s);
    if (j.step === 3 && s.car?.owned && !s.car.plan) {
      if (s.car.business?.tutorial) plan(s, 'Quick'); else s.car.status = 'choose';
    }
    if (j.step === 6 && s.car?.status === 'ready') route(s, 'sales');
    if (j.step === 22) {
      s.personal ??= { id: 'your-coupe', pos: copy(DEALERSHIP_GARAGE), home: copy(DEALERSHIP_GARAGE), status: 'parked' };
      if (!s.completed) s.rareCallAt = s.clock + 3;
    }
    if (j.step === 40) s.worker.hired = true;
    return true;
  }
  const p = D.pads.find(row => row.id === id);
  if (!p || !eligible(s, p)) return false;
  if (s.cash - reserve(s) < p.cost) {
    note(s, `Need $${Math.ceil(p.cost - Math.max(0, s.cash - reserve(s)))} more. Work money stays safe.`); return false;
  }
  pay(s, p.cost, 'pad', p.name); s.pads.push(id); note(s, `${p.name} ready`);
  if (id === 'intake') arrive(s, 1);
  if (id === 'air' && s.car?.owned) { plan(s, 'Quick'); note(s, `Bay ready. $${s.car.plan?.cost ?? 0} work funded.`); }
  if (id === 'salesdesk' && s.car?.status === 'ready') route(s, 'sales');
  if (id === 'finish') s.lead = { kind: 'ordinary', index: 2, status: 'ringing', caller: 'Maya', text: 'I’ve got a coupe you might like. Can I bring it by?' };
  if (id === 'mechanic') {
    s.worker.hired = true;
    s.lead = { kind: 'ordinary', index: 3, status: 'ringing', caller: 'Nora', text: 'A small hatchback. Your mechanic could give it a new start.' };
  }
  if (id === 'display') {
    s.personal ??= { id: 'your-coupe', pos: copy(DEALERSHIP_GARAGE), home: copy(DEALERSHIP_GARAGE), status: 'parked' };
    s.rareCallAt = s.clock + 3; note(s, 'Your own car. You’ve earned this.');
  }
  return true;
}
export function arrive(s: TycoonState, index: number, remote = false): boolean {
  if (s.car || (!remote && s.personal && s.personal.status !== 'parked')) return false;
  const d = index === 4 ? phoenixDefinition() : D.cars[index - 1]; if (!d) return false;
  if (index === 4 && leadBudget(s, remote)[1] > 0) {
    note(s, 'Build cash with another ordinary flip first.'); return false;
  }
  const c: NonNullable<TycoonState['car']> = { id: `${d.id}-${s.sales + 1}`, index, owned: false,
    status: 'arriving', pos: copy(D.points.entry), condition: copy(d.condition), arrivalGrade: grade(d.condition),
    depth: 'Quick', workSpent: 0, purchase: 0, history: [], remote, buyerAttempt: 0, photo: false,
    route: { target: 'intake', points: [copy(D.points.entry), [-16, -12], [D.points.intake[0], -12], copy(D.points.intake)], step: 1 } };
  s.car = c;
  if (remote) { c.pos = copy(RESIDENTIAL_CAR); c.route = undefined; c.status = s.seen ? 'seller' : 'discovery'; }
  event(s, remote ? 'Found at Elias’s garage' : 'Arrived at the dealership'); if (index === 4 || s.lead?.kind !== 'rare') s.lead = undefined; return true;
}
export function arriveBusiness(s: TycoonState): boolean {
  if (!s.journey || s.journey.step < 2 || s.car || (s.personal && s.personal.status !== 'parked')) return false;
  const data = J.businessDefinition(s), leadBefore = s.lead;
  if (!arrive(s, data.index)) return false;
  const c = s.car!;
  c.definition = copy(data.definition); c.condition = copy(data.definition.condition); c.arrivalGrade = grade(c.condition);
  c.id = 'business-' + data.templateId + '-' + (s.journey.cycle + 1) + '-' + s.sales;
  c.business = { tutorial: !s.journey.tutorialComplete, templateId: data.templateId, consignment: data.consignment };
  c.pos = copy(J.arrivalRoute[0]); c.route = { target: 'intake', points: copy(J.arrivalRoute), step: 1 };
  s.lead = leadBefore;
  if (!s.journey.seenCars.includes(data.templateId)) s.journey.seenCars.push(data.templateId);
  return true;
}
export function buy(s: TycoonState): boolean {
  const c = s.car;
  if (!c || c.status !== 'seller' || c.owned || c.quote?.mode !== 'buy') return false;
  const amount = c.quote.accepted;
  const setup = c.business ? 0 : D.pads.filter(p => ['repairbay', 'tools', 'power', 'air', 'sales', 'salesdesk'].includes(p.id) && !has(s, p.id)).reduce((n, p) => n + p.cost, 0);
  const work = repairCost(workQuote(s)), needed = work.cash + restockBudget(work.parts, partsStock(s));
  if (s.cash < amount + (c.business?.consignment ? 0 : needed) + setup) { note(s, 'Keep enough for repairs and the sale corner.'); return false; }
  if (!pay(s, amount, 'car', def(s).name)) return false;
  c.purchase = amount; c.owned = true; c.quote = undefined; c.status = has(s, 'air') ? 'choose' : 'owned'; event(s, `Bought for $${amount}`);
  if (c.business?.tutorial && s.journey!.step >= 3) plan(s, 'Quick');
  if (c.remote) {
    c.status = 'moving'; c.route = { target: 'intake', points: townRoute(copy(c.pos), copy(D.points.intake)), step: 1 };
    returnHome(s); note(s, 'Elias brings the Phoenix. Drive your car home.');
  }
  return true;
}
export function route(s: TycoonState, target: string) {
  const c = s.car; if (!c) return;
  if (s.journey) { c.status = 'moving'; c.route = { target, points: J.travelRoute(s, target), step: 1 }; return; }
  c.status = 'moving'; c.route = { target, points: [copy(c.pos), [c.pos[0], -12], [D.points[target][0], -12], copy(D.points[target])], step: 1 };
}
export function plan(s: TycoonState, depth: Depth): boolean {
  const c = s.car;
  if (!c?.owned || c.plan || !['choose', 'owned'].includes(c.status) || !['Quick', 'Good'].includes(depth) || (depth === 'Good' && !has(s, 'finish'))) return false;
  if (c.business && s.journey!.step < 3) return false;
  const q = workQuote(s, depth);
  if (!fundRepair(s, q, !!c.business?.consignment)) return false;
  randomWorkOrder(q, depth, c.condition, !!c.business?.tutorial);
  q.funded = true; c.workSpent += q.cost;
  c.plan = q; c.depth = depth; event(s, `Chose ${depth}`); route(s, 'repair'); return true;
}
export const job = (s: TycoonState) => s.car?.plan?.jobs.find(j => !j.done);
export function startJob(s: TycoonState): boolean {
  const c = s.car, j = job(s);
  if (!c || c.status !== 'repair' || !j || j.started || (staffedJob(s) && !J.staffedPhoto(s) && s.worker.activity !== 'Working')) return false;
  if (!c.plan?.funded) { if (!fundRepair(s, { jobs: [j], cost: j.cost, seconds: j.seconds })) return false; c.workSpent += j.cost; }
  j.started = true; j.manual = !staffedJob(s); if (j.manual) repairProgress(j, s.clock); j.speed = staffedJob(s) && s.worker.level > 1 ? 1.25 : 1; return true;
}
export function list(s: TycoonState): boolean {
  const c = s.car; if (c?.status !== 'photo') return false;
  c.photo = true; c.listing = true; c.status = 'buyer'; c.wait = undefined;
  if (c.business) c.business.offer = buyer(s).ask;
  event(s, 'Photographed and listed'); note(s, 'Photo taken. Your listing is live.'); return true;
}
export function fit(c: { custom?: Look }, role: string): [number, string, string] {
  const custom = c.custom ?? originalLook();
  if (role === 'Collector') {
    const original = custom.paint === 'original' && custom.wheels === 'original' && !custom.stripe;
    return [original ? 300 : -150, original ? 'Original character' : 'Prefers original', original ? 'That original shape. That’s what I came for.' : 'I’d have kept the original look.'];
  }
  if (role === 'Enthusiast') return [(custom.paint !== 'original' ? 80 : 0) + (custom.wheels === 'sport' ? 180 : 0) + (custom.stripe ? 100 : 0), 'Style matters', custom.wheels === 'sport' ? 'Those sport wheels suit it. My kind of coupe.' : 'A clean coupe. I can make it my own.'];
  return [0, 'Repairs matter', 'The repair work is done. That’s what matters to me.'];
}
export function buyer(s: TycoonState): Buyer {
  const c = s.car!; const d = def(s), base = d.offers[c.depth === 'Good' ? 1 : 0];
  if (c.business) {
    const services = c.plan?.pricedServices ?? c.plan?.jobs.filter(j => j.done && j.id !== 'Tune').length ?? 0;
    const ask = c.business.offer ?? (c.business.tutorial ? 1000 : c.purchase + (c.plan?.cost ?? 0) + F.operationProfit(s.journey!.step, services, c.business.consignment)
      + (c.depth === 'Good' ? d.offers[1] - d.offers[0] : 0) + fit(c, d.buyerRole)[0]);
    return { name: 'Buyer', role: d.buyerRole, line: c.business.tutorial ? "One thousand. That's a fair price for Rusty." : 'Your work brought this car back to life.',
      cue: c.business.consignment ? 'Consignment · 75% service profit' : 'Repairs matter', ask, max: c.business.tutorial ? 1000 : Math.floor(ask * 1.05) };
  }
  if (c.index === 2 && !s.lowballPassed) {
    const cost = c.purchase + (c.plan?.cost ?? 0);
    return { name: 'Blake', role: 'Bargain hunter', line: 'I’m buying a deal. Extras don’t change my budget.', cue: 'Price first', ask: cost - 150, max: cost - 50, lowball: true };
  }
  const role = c.index === 2 ? 'Enthusiast' : d.buyerRole, [bonus, cue, line] = fit(c, role);
  return { name: c.index === 2 ? 'Riley' : d.buyer, role, line, cue, ask: base + bonus, max: base + bonus + (c.index === 1 ? 100 : (d.buyerMax || 100)) };
}
export function estimate(s: TycoonState, depth?: Depth, choice?: Look) {
  const c = s.car; if (!c) return undefined;
  const d = def(s), role = c.index === 2 ? 'Enthusiast' : d.buyerRole;
  const candidate = copy(c); if (choice) candidate.custom = choice;
  const q = c.plan && (depth ?? c.depth) === c.depth ? c.plan : workQuote(s, depth ?? c.depth), sale = c.business
    ? c.business.tutorial ? 1000 : c.purchase + q.cost + F.operationProfit(s.journey!.step, q.pricedServices ?? q.jobs.filter(j => j.id !== 'Tune').length, c.business.consignment) + ((depth ?? c.depth) === 'Good' ? d.offers[1] - d.offers[0] : 0) + fit(candidate, role)[0]
    : d.offers[(depth ?? c.depth) === 'Good' ? 1 : 0] + fit(candidate, role)[0];
  return { sale, profit: sale - c.purchase - q.cost, role, seconds: q.seconds, cost: q.cost };
}
export function leadBudget(s: TycoonState, visit: boolean): [number, number] {
  const work = repairCost(quote(phoenixDefinition()));
  const needed = PHOENIX_PRICE - (visit ? 300 : 0) + work.cash + restockBudget(work.parts, partsStock(s));
  return [needed, Math.max(0, needed - s.cash)];
}
export function openDeal(s: TycoonState): boolean {
  const c = s.car; if (!c || !['seller', 'buyer'].includes(c.status)) return false;
  if (!c.quote) {
    const mode = c.status === 'seller' ? 'buy' : 'sell', b = mode === 'sell' ? buyer(s) : undefined;
    if (c.business && b) c.business.offer = b.ask;
    c.quote = { mode, accepted: b?.ask ?? terms(s).ask, line: b?.line ?? def(s).sellerLine, reaction: 'neutral', revision: 0 };
  }
  return true;
}
export function counter(s: TycoonState, amount: number): boolean {
  const q = s.car?.quote;
  if (!q || !Number.isFinite(amount) || amount > 1000000000000 || (s.car?.business ? amount < 0 || !Number.isInteger(amount) || q.revision > 0 : amount < 50 || amount > 20000 || amount % 50 !== 0)) return false;
  if (q.mode === 'buy') {
    const t = terms(s); if (amount > t.ask) return false;
    q.accepted = Math.max(amount, t.floor); q.reaction = amount >= t.floor ? 'happy' : 'firm';
    q.line = amount >= t.floor ? 'You’ve got a deal.' : `I can do $${t.floor}. That’s my price.`;
  } else {
    const b = buyer(s); if (amount < q.accepted) return false;
    if (amount <= b.max) { q.accepted = amount; q.reaction = 'happy'; q.line = 'All right. Let’s do it.'; }
    else { q.reaction = 'firm'; q.line = 'It’s a nice car, but that’s too much for me.'; }
  }
  q.revision++; return true;
}
export function decline(s: TycoonState): boolean {
  if (s.car?.business && s.car.status === 'seller' && !s.car.business.tutorial) {
    event(s, 'Seller declined'); s.car.wait = 3; route(s, 'exit'); return true;
  }
  if (s.car?.status !== 'buyer') return false;
  if (s.car.business) s.car.business.offer = undefined;
  s.lowballPassed = true; s.car.quote = undefined; s.car.status = 'waitingBuyer'; s.car.wait = 4;
  note(s, 'Listing stays live. Another buyer is coming.'); return true;
}
export function sell(s: TycoonState): boolean {
  const c = s.car; if (c?.status !== 'buyer' || c.quote?.mode !== 'sell') return false;
  c.sale = c.quote.accepted; c.soldTo = buyer(s); s.cash += c.sale;
  s.ledger.push({ amount: c.sale, kind: 'sale', subject: def(s).name }); c.quote = undefined;
  if (c.plan?.deferredCash) { s.cash -= c.plan.deferredCash; s.ledger.push({ amount: -c.plan.deferredCash, kind: 'work', subject: 'Consignment service settlement' }); c.plan.deferredCash = undefined; }
  if (s.journey) {
    (s.revenue ??= []).push({ at: s.clock, amount: c.sale });
    if (c.business?.tutorial) s.journey.tutorialComplete = true;
  }
  c.status = 'sold'; c.receiptUntil = s.clock + 2; event(s, `Sold to ${c.soldTo.name}`); return true;
}
export function customizationCost(s: TycoonState, choice: Look): number {
  const old = s.car?.custom ?? originalLook();
  return (old.paint !== choice.paint ? 180 : 0) + (old.wheels !== choice.wheels ? 120 : 0) + (old.stripe !== choice.stripe ? 80 : 0);
}
export function customize(s: TycoonState, choice: Look): boolean {
  const c = s.car; if (c?.status !== 'photo' || !has(s, 'finish') || !choice) return false;
  if (!['original', 'cream', 'blue', 'red', 'green'].includes(choice.paint) || !['original', 'sport'].includes(choice.wheels) || typeof choice.stripe !== 'boolean') return false;
  const cost = customizationCost(s, choice); if (!cost) return true;
  if (!pay(s, cost, 'customization', def(s).name)) return false;
  c.workSpent += cost; c.custom = copy(choice); c.photo = false; return true;
}
export function upgrade(s: TycoonState): boolean {
  if (!s.worker.hired || s.worker.level !== 1 || s.worker.jobs < 1 || s.cash - reserve(s) < 350) return false;
  pay(s, 350, 'staff', 'Jo training'); s.worker.level = 2; note(s, 'Jo trained. Next repairs take 20% less time.'); return true;
}
export function selectPersonal(s: TycoonState, modelId: number, purchase: boolean): boolean {
  const option = personalCarOption(modelId), current = s.personal;
  if (!option || !garageUnlocked(s) || current?.route || (current && current.status !== 'parked')) return false;
  const owned = [...ownedPersonalModels(current)];
  if (purchase) {
    if (owned.includes(modelId)) return false;
    if (s.cash - reserve(s) < option.price) { note(s, 'Keep enough cash for this car and your current work.'); return false; }
    if (!pay(s, option.price, 'personal-car', 'Car ' + modelId + ' · ' + option.name)) return false;
    owned.push(modelId);
  } else if (!owned.includes(modelId)) return false;
  const home = copy(current?.home ?? DEALERSHIP_GARAGE);
  s.personal = { id: 'personal-' + modelId, modelId, ownedModels: owned, pos: copy(home), home, status: 'parked' };
  note(s, option.name + ' is ready at your garage.'); return true;
}
export function visit(s: TycoonState): boolean {
  if (s.personal?.status !== 'parked' || s.car || s.lead?.kind !== 'rare') return false;
  if (leadBudget(s, true)[1] > 0) { note(s, `Keep $${leadBudget(s, true)[0]} for the Phoenix and repairs.`); return false; }
  const p = s.personal; p.route = undefined;
  p.status = 'driving'; s.lead.status = 'visiting';
  note(s, 'Drive your car to Elias in Maple Heights. Park beside his driveway, then walk over.'); return true;
}
export function returnHome(s: TycoonState): boolean {
  const p = s.personal; if (p?.status !== 'atLead') return false;
  p.route = undefined; p.status = 'driving';
  note(s, 'Drive home to your dealership garage.'); return true;
}
/** Advance a visit only from the physical car/player positions, never a scripted ride. */
export function updatePersonalTravel(s: TycoonState, player: Point, onFoot: boolean): boolean {
  const p = s.personal;
  if (p?.status !== 'driving' || p.route) return false;
  if (s.lead?.status === 'visiting') {
    const nearCar = Math.hypot(p.pos[0] - RESIDENTIAL_PARKING[0], p.pos[1] - RESIDENTIAL_PARKING[1]) < 22;
    const nearSeller = Math.hypot(player[0] - RESIDENTIAL_SELLER[0], player[1] - RESIDENTIAL_SELLER[1]) < 16;
    if (!onFoot || !nearCar || !nearSeller || !arrive(s, 4, true)) return false;
    p.status = 'atLead'; return true;
  }
  if (!onFoot || Math.hypot(p.pos[0] - p.home[0], p.pos[1] - p.home[1]) >= 12) return false;
  p.status = 'parked'; note(s, 'Home. Your dealership is ready.'); return true;
}
export function leave(s: TycoonState): boolean {
  if (s.personal?.status !== 'atLead' || s.car?.owned) return false;
  s.car = undefined; lead(s, 'missed'); return returnHome(s);
}
export function discover(s: TycoonState): boolean {
  if (s.car?.status !== 'discovery') return false;
  s.seen = true; s.car.status = 'seller'; return true;
}
function move(o: Moving, dt: number, speed: number): string | undefined {
  const r = o.route; if (!r) return undefined;
  const p = r.points[r.step], dx = p[0] - o.pos[0], dz = p[1] - o.pos[1], dist = Math.hypot(dx, dz);
  if (dist > .001) o.angle = Math.atan2(-dx, dz);
  if (dist <= dt * speed) { o.pos = copy(p); r.step++; if (r.step >= r.points.length) { o.route = undefined; return r.target; } }
  else if (dt > 0) { o.pos[0] += dx / dist * dt * speed; o.pos[1] += dz / dist * dt * speed; }
  return undefined;
}
export function tick(s: TycoonState, dt: number, throttle = 0, typingParts = false) {
  if (!Number.isFinite(dt) || dt <= 0) return;
  s.clock += dt;
  if (s.revenue) s.revenue = s.revenue.filter(e => e.at > s.clock - 60);
  tickParts(s, dt, typingParts);
  tickCouriers(s, dt, reserve(s));
  if (s.rareCallAt !== undefined && s.clock >= s.rareCallAt) { s.rareCallAt = undefined; lead(s); }
  if (s.lead?.remindAt !== undefined && s.clock >= s.lead.remindAt) { s.lead.remindAt = undefined; s.lead.status = 'ringing'; }
  if (!s.car && s.lead?.status === 'queued' && leadBudget(s, false)[1] === 0) arrive(s, 4);
  if (s.personal?.route) {
    const goal = moveVehicle(s.personal, dt * Math.max(0, Math.min(1, throttle)), 9);
    if (goal) { s.personal.status = goal === 'lead' ? 'atLead' : 'parked'; if (goal === 'lead') arrive(s, 4, true); else note(s, 'Home. Your dealership is ready.'); }
  }
  if (s.journey && !s.car && s.journey.step >= 2 && !s.journey.intakePaused && s.lead?.status !== 'visiting' && s.clock >= s.journey.nextSellerAt) arriveBusiness(s);
  const c = s.car, w = s.worker;
  // Imported older progress can own the workstation without its redundant hired flag.
  if (has(s, 'mechanic')) w.hired = true;
  const staffed = staffedJob(s);
  if (w.hired || staffed) {
    const j = c?.status === 'repair' && !J.staffedPhoto(s) ? job(s) : undefined;
    const offsets: Record<string, Point> = { Body: [-2, 0], RunningGear: [-2, 1], Mechanical: [0, 3], Exterior: [2, 0], Tune: [0, 3] };
    const inspecting = !!c && !c.remote && ['seller', 'choose', 'photo', 'ready'].includes(c.status);
    const o = j && (offsets[j.id] ?? [2, 0]);
    const home = J.mechanicHome(s);
    const goal: Point = o && c ? [c.pos[0] + o[0], c.pos[1] + o[1]] : inspecting ? [c!.pos[0] - 3, c!.pos[1] + 2]
      : [home[0] + (Math.floor(s.clock / 10) % 2 ? 2 : 0), home[1]];
    if (!w.goal || w.goal[0] !== goal[0] || w.goal[1] !== goal[1]) {
      w.goal = copy(goal); const front = c && (j || inspecting) ? c.pos[1] + 3.6 : goal[1];
      w.route = { target: 'work', step: 1, points: [copy(w.pos), [w.pos[0], front], [goal[0], front], copy(goal)] };
    }
    if (w.route) { move(w, dt, 4); w.activity = j ? `Heading to ${j.name}` : inspecting ? 'Checking arriving vehicle' : 'Checking tools'; }
    else w.activity = j ? 'Working' : inspecting ? 'Inspecting vehicle' : 'Ready';
  }
  if (!c) return;
  if (c.route) {
    const dest = moveVehicle(c, dt, 7);
    if (dest === 'intake') { if (c.owned) { c.remote = false; c.status = 'choose'; } else c.status = c.index === 4 && !s.seen ? 'discovery' : 'seller'; }
    else if (dest === 'repair') c.status = 'repair';
    else if (dest === 'sales') {
      c.status = c.listing || c.business?.tutorial || !c.business && c.index === 1 ? 'buyer' : 'photo';
      c.listing = c.status === 'buyer';
    }
    else if (dest === 'exit') {
      if (!c.business || c.sale !== undefined) { s.history.push(copy(c)); s.sales++; }
      s.car = undefined;
      if (s.journey) {
        if (c.business && c.sale !== undefined) s.journey.cycle++;
        s.journey.nextSellerAt = s.clock + (c.sale === undefined ? 3 : F.sellerDelay(s.journey.step));
      }
      if (c.index === 4 && !c.business) s.completed = true;
      else if (!s.journey && s.sales >= 3 && s.personal) lead(s, 'missed');
    }
    return;
  }
  if (c.status === 'repair') {
    const j = job(s);
    if (j) {
      if (c.business && j.position && Math.hypot(c.pos[0] - j.position[0], c.pos[1] - j.position[1]) > .1) { route(s, 'repair'); return; }
      const staffReady = J.staffedPhoto(s) || w.activity === 'Working';
      if (staffed && !j.started && staffReady) startJob(s);
      if (staffed && j.manual && staffReady) j.manual = false;
      if (j.started) {
        if (!j.manual) j.progress = Math.min(1, j.progress + dt * (j.speed ?? 1) / j.seconds);
        if (j.progress >= 1) { j.done = true; c.wait = undefined; if (['Body', 'RunningGear', 'Mechanical', 'Exterior'].includes(j.id)) c.condition[j.id as PartId] = 'Good'; event(s, `${j.name} completed`); }
      }
    }
    if (!job(s)) { c.status = 'ready'; c.wait = undefined; if (w.hired) w.jobs++; }
  } else if (c.status === 'waitingBuyer') { c.wait = (c.wait ?? 4) - dt; if (c.wait <= 0) c.status = 'buyer'; }
  else if (c.status === 'sold' && s.clock >= (c.receiptUntil ?? s.clock)) route(s, 'exit');
  if (c.status === 'ready' && has(s, 'salesdesk')) {
    c.wait = Math.min(c.wait ?? J.salesHandoverSeconds(s), J.salesHandoverSeconds(s)) - dt;
    if (c.wait <= 0) {
      if (J.staffedListing(s)) { c.status = 'photo'; list(s); }
      c.wait = undefined; route(s, 'sales');
    }
  } else if (c.status === 'photo' && J.staffedListing(s)) {
    c.wait = (c.wait ?? 1.8) - dt;
    if (c.wait <= 0) list(s);
  }
  if (c.business && s.journey?.tutorialComplete && s.journey.automation) {
    if (c.status === 'seller' && has(s, 'carbuyer')) {
      openDeal(s);
      if (c.quote!.accepted > s.cash) { c.business.consignment = true; c.definition!.ask = 0; c.definition!.floor = 0; c.quote!.accepted = 0; }
      buy(s);
    }
    if (c.status === 'choose' && has(s, 'mechanic')) plan(s, 'Quick');
    if (c.status === 'buyer' && has(s, 'salesrep')) { openDeal(s); sell(s); }
  }
}
