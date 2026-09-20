import { catalog } from './catalog.js';
import { copy, fresh, freshJourney } from './TycoonModel.js';
import { migrateOpening } from './FullJourney.js';
import { offlineReward, applyOfflineReward } from './OfflineEarnings.js';
import { personalCarOption, personalModel } from './PersonalCars.js';
import { STARTER_PARTS } from './PartsEconomy.js';
import { entries } from './FullJourneyCatalog.js';
import type { OfflineReceipt, TycoonState } from './types.js';
export interface SaveStorage {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}
export const SAVE_KEY = 'sell-cars.tycoon.v2';
export const LEGACY_SAVE_KEY = 'sell-cars-integration.tycoon.v1';
const LEASE_SECONDS = 180;
const finite = (n: unknown): n is number => typeof n === 'number' && Number.isFinite(n) && n >= 0;
const point = (p: unknown) => Array.isArray(p) && p.length === 2 && p.every(n => typeof n === 'number' && Number.isFinite(n));
export function validState(value: unknown): value is TycoonState {
  if (!value || typeof value !== 'object') return false;
  const s = value as TycoonState;
  if (!finite(s.cash) || s.cash > 1e12 || !finite(s.clock) || !Number.isInteger(s.sales) || s.sales < 0 || !Array.isArray(s.pads)
    || new Set(s.pads).size !== s.pads.length || !s.pads.every(id => catalog.pads.some(p => p.id === id))
    || !Array.isArray(s.history) || !Array.isArray(s.ledger) || !s.worker || !point(s.worker.pos)
    || ![1, 2].includes(s.worker.level) || !finite(s.worker.jobs) || typeof s.worker.activity !== 'string'
    || typeof s.worker.hired !== 'boolean' || typeof s.seen !== 'boolean' || typeof s.lowballPassed !== 'boolean' || typeof s.completed !== 'boolean') return false;
  if (!s.ledger.every(e => e && typeof e.amount === 'number' && Number.isFinite(e.amount) && typeof e.kind === 'string' && typeof e.subject === 'string')) return false;
  for (const c of [...s.history, ...(s.car ? [s.car] : [])]) {
    if (!c || !Number.isInteger(c.index) || !catalog.cars[c.index - 1] || typeof c.id !== 'string' || !point(c.pos)
      || !['arriving', 'discovery', 'seller', 'owned', 'choose', 'moving', 'repair', 'ready', 'photo', 'buyer', 'waitingBuyer', 'sold'].includes(c.status)
      || !finite(c.purchase) || !finite(c.workSpent) || !['Quick', 'Good'].includes(c.depth) || !c.condition
      || !['Body', 'RunningGear', 'Mechanical', 'Exterior'].every(id => ['Good', 'Worn', 'Damaged', 'Ruined'].includes(c.condition[id as keyof typeof c.condition]))
      || !Array.isArray(c.history) || !c.history.every(e => typeof e === 'string')) return false;
    if (c.quote && (!finite(c.quote.accepted) || !Number.isInteger(c.quote.revision) || c.quote.revision < 0 || !['buy', 'sell'].includes(c.quote.mode) || typeof c.quote.line !== 'string')) return false;
    if (c.plan && (!Array.isArray(c.plan.jobs) || !finite(c.plan.cost) || !finite(c.plan.seconds) || !c.plan.jobs.every(j => j && ['Body', 'RunningGear', 'Mechanical', 'Exterior', 'Tune', 'Wash', 'Body_Restoration', 'Tune_Performance', 'Paint_Exterior', 'Detail_QC', 'Photo_Listing'].includes(j.id) && finite(j.cost) && finite(j.seconds) && j.seconds > 0 && finite(j.progress) && j.progress <= 1 && typeof j.started === 'boolean' && typeof j.done === 'boolean' && (!j.position || point(j.position)) && (j.staffAt === undefined || finite(j.staffAt)) && (j.speed === undefined || finite(j.speed) && j.speed > 0)))) return false;
    if (c.status === 'repair' && !c.plan) return false;
    for (const j of c.plan?.jobs ?? []) {
      if (j.manual !== undefined && typeof j.manual !== 'boolean') return false;
      const r = j.repair;
      if (!r) continue;
      const flags = (a: unknown, length: number) => Array.isArray(a) && a.length === length && a.every(n => typeof n === 'boolean');
      if (!['wheels', 'engine', 'tuning', 'body', 'wash', 'paint', 'detail', 'photo'].includes(r.kind) || !finite(r.openedAt)
        || !flags(r.wheels, 4) || !(r.kind === 'engine' ? flags(r.bolts, 2) || flags(r.bolts, 5) : flags(r.bolts, r.kind === 'wheels' ? 28 : 5)) || !flags(r.targets, r.kind === 'tuning' ? 5 : 6)
        || !finite(r.oil) || r.oil > 1 || typeof r.complete !== 'boolean') return false;
      if (r.drainStarted !== undefined && (!Number.isFinite(r.drainStarted) || r.drainStarted < -2.4 || r.drainStarted > s.clock)) return false;
      if (r.kind === 'tuning' && r.targets.some((installed, i) => installed && !r.bolts[i])) return false;
      if (r.filterInstalled !== undefined && (typeof r.filterInstalled !== 'boolean' || r.filterInstalled && (r.kind !== 'engine' || !r.bolts.every(Boolean)))) return false;
    }
    if (c.custom && (!['original', 'cream', 'blue', 'red', 'green'].includes(c.custom.paint) || !['original', 'sport'].includes(c.custom.wheels) || typeof c.custom.stripe !== 'boolean')) return false;
    if (c.business && (!s.journey || typeof c.business.tutorial !== 'boolean' || typeof c.business.consignment !== 'boolean' || !['Rusty', 'HondoCivixEK', 'Bavora', 'Gblock'].includes(c.business.templateId) || !c.definition)) return false;
    if (c.business?.offer !== undefined && !finite(c.business.offer)) return false;
    if (c.definition && (!finite(c.definition.ask) || !finite(c.definition.floor) || typeof c.definition.name !== 'string' || typeof c.definition.color !== 'string'
      || !Array.isArray(c.definition.offers) || c.definition.offers.length < 2 || !c.definition.offers.every(finite) || !finite(c.definition.buyerMax)
      || !c.definition.condition || !['Body', 'RunningGear', 'Mechanical', 'Exterior'].every(id => ['Good', 'Worn', 'Damaged', 'Ruined'].includes(c.definition!.condition[id as keyof typeof c.condition])))) return false;
    if (c.sale !== undefined && !finite(c.sale)) return false;
    if (c.status === 'sold' && c.sale === undefined) return false;
  }
  if (s.lead && (!['ordinary', 'rare'].includes(s.lead.kind) || !Number.isInteger(s.lead.index) || !catalog.cars[s.lead.index - 1])) return false;
  if (s.lead?.remindAt !== undefined && !finite(s.lead.remindAt)) return false;
  if (s.personal && (!point(s.personal.pos) || !point(s.personal.home) || !['parked', 'driving', 'atLead'].includes(s.personal.status))) return false;
  if (s.personal) {
    const p = s.personal;
    if (p.modelId !== undefined && !personalCarOption(p.modelId)) return false;
    if (p.ownedModels !== undefined && (!Array.isArray(p.ownedModels) || !p.ownedModels.length
      || new Set(p.ownedModels).size !== p.ownedModels.length || !p.ownedModels.every(id => !!personalCarOption(id))
      || !p.ownedModels.includes(personalModel(p)!))) return false;
    if ([p.yaw, p.height].some(n => n !== undefined && (typeof n !== 'number' || !Number.isFinite(n)))) return false;
  }
  for (const moving of [s.car, s.personal, s.worker]) if (moving?.route) {
    const r = moving.route;
    if (r.curved !== undefined && typeof r.curved !== 'boolean' || r.speed !== undefined && (!finite(r.speed) || r.speed > 100)) return false;
    if (r.reverse !== undefined && typeof r.reverse !== 'boolean') return false;
    if (!Array.isArray(r.points) || !r.points.every(point) || !Number.isInteger(r.step) || r.step < 0 || r.step >= r.points.length || !['intake', 'repair', 'sales', 'exit', 'home', 'lead', 'work'].includes(r.target)) return false;
  }
  if (s.journey) {
    const j = s.journey;
    if (j.cosmetics !== undefined && (!Array.isArray(j.cosmetics) || new Set(j.cosmetics).size !== j.cosmetics.length
      || !j.cosmetics.every(id => entries.some(e => e.id === id && e.category === 'Cosmetic')))) return false;
    if (!Number.isInteger(j.step) || j.step < 0 || j.step > 240 || !Number.isInteger(j.cycle) || j.cycle < 0 || !finite(j.nextSellerAt)
      || typeof j.tutorialComplete !== 'boolean' || typeof j.intakePaused !== 'boolean' || typeof j.automation !== 'boolean'
      || !Array.isArray(j.seenCars) || !j.seenCars.every(id => typeof id === 'string')) return false;
  }
  if (s.revenue && (!Array.isArray(s.revenue) || !s.revenue.every(e => e && finite(e.at) && finite(e.amount)))) return false;
  if (s.parts && (!Number.isInteger(s.parts.level) || s.parts.level < 1 || s.parts.level > 20 || !Number.isInteger(s.parts.completed) || s.parts.completed < 0 || (s.parts.remaining !== undefined && (!finite(s.parts.remaining) || s.parts.remaining > 5)))) return false;
  if (s.parts?.manual !== undefined && typeof s.parts.manual !== 'boolean') return false;
  if (s.partsStock !== undefined && (!Number.isInteger(s.partsStock) || s.partsStock < 0 || s.partsStock > 1e12)) return false;
  if (s.couriers && (!Array.isArray(s.couriers) || s.couriers.length > 3 || new Set(s.couriers.map(d => d.id)).size !== s.couriers.length || !s.couriers.every(d =>
    Number.isInteger(d.id) && d.id > 0 && d.id <= 3 && point(d.pos) && ['idle', 'outbound', 'loading', 'returning', 'unloading'].includes(d.phase)
    && finite(d.wait) && Number.isInteger(d.cargo) && d.cargo >= 0 && d.cargo <= 50 && Number.isInteger(d.trips) && d.trips >= 0
    && (d.angle === undefined || Number.isFinite(d.angle))
    && (!d.route || (d.route.curved === undefined || typeof d.route.curved === 'boolean') && (d.route.speed === undefined || finite(d.route.speed) && d.route.speed <= 100))
    && (!d.route || d.route.reverse === undefined || typeof d.route.reverse === 'boolean')
    && (!d.route || ['shop', 'depot'].includes(d.route.target) && Array.isArray(d.route.points) && d.route.points.length > 1 && d.route.points.every(point)
      && Number.isInteger(d.route.step) && d.route.step >= 0 && d.route.step < d.route.points.length)))) return false;
  for (const c of [...s.history, ...(s.car ? [s.car] : [])]) if (c.plan &&
    (c.plan.cashCost !== undefined && (!finite(c.plan.cashCost) || c.plan.cashCost > c.plan.cost)
    || c.plan.deferredCash !== undefined && (!finite(c.plan.deferredCash) || c.plan.deferredCash > c.plan.cost)
    || c.plan.partsCost !== undefined && (!Number.isInteger(c.plan.partsCost) || c.plan.partsCost < 0)
    || c.plan.pricedServices !== undefined && (!Number.isInteger(c.plan.pricedServices) || c.plan.pricedServices < 0 || c.plan.pricedServices > 100)
    || c.plan.cashCost !== undefined && c.plan.partsCost !== undefined && Math.abs(c.plan.cashCost + c.plan.partsCost * 10 - c.plan.cost) > 1e-6)) return false;
  return true;
}
interface SaveEnvelope { version: 2; state: TycoonState; savedAt: number; writer: string; leaseUntil: number; revision: number }
interface SaveOptions { now?: () => number; legacy?: boolean; sessionId?: string }
/** Browser persistence adapter. One atomic storage value includes cash, active work,
 * offline anchor and a renewable session lease. A network host must replace this
 * adapter with authoritative storage; local storage is not a server datastore. */
export class TycoonSave {
  status = 'Local save';
  offline?: OfflineReceipt;
  readOnly = false;
  private disabled = false;
  private resetCompleted = false;
  private owner: string;
  private clock: () => number;
  private expectedRevision?: number;
  get requiresCommit() { return !!this.storage && !this.disabled; }
  constructor(private storage?: SaveStorage, private options: SaveOptions = {}) {
    this.clock = options.now ?? Date.now;
    this.owner = options.sessionId ?? Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
  }
  private fresh() { return this.options.legacy ? fresh() : freshJourney(); }
  private now() { return Math.floor(this.clock() / 1000); }
  load(): TycoonState {
    if (this.resetCompleted) return this.fresh();
    this.offline = undefined; this.readOnly = false; this.disabled = false; this.expectedRevision = undefined;
    if (!this.storage) { this.status = 'Session only'; return this.fresh(); }
    try {
      const current = this.storage.getItem(SAVE_KEY);
      const raw = current ?? this.storage.getItem(LEGACY_SAVE_KEY);
      if (!raw) {
        const state = this.fresh();
        if (!this.write(state)) { this.disabled = true; this.status = 'Session only — save unavailable'; }
        return state;
      }
      const snapshot = JSON.parse(raw) as Omit<Partial<SaveEnvelope>, 'version'> & { version?: number };
      if (![1, 2].includes(snapshot.version!) || !validState(snapshot.state)) throw new Error('Incompatible save');
      if (snapshot.version === 2 && (!finite(snapshot.savedAt) || !finite(snapshot.leaseUntil) || !Number.isInteger(snapshot.revision) || typeof snapshot.writer !== 'string')) throw new Error('Malformed save envelope');
      const state = copy(snapshot.state);
      state.partsStock ??= STARTER_PARTS;
      if (state.journey) {
        state.journey.cosmetics ??= entries.filter(e => e.category === 'Cosmetic' && e.step <= state.journey!.step).map(e => e.id);
        state.journey.cosmeticPadPositions = undefined;
      }
      if (state.journey) state.journey.padPosition = undefined;
      if (snapshot.version === 1 && !this.options.legacy) migrateOpening(state);
      if (snapshot.version === 2 && snapshot.writer !== this.owner && snapshot.leaseUntil! > this.now()) {
        this.readOnly = true; this.status = 'Dealership open in another tab. Close it, then reload here.'; return state;
      }
      const receipt = offlineReward(state, snapshot.version === 2 ? snapshot.savedAt : undefined, this.now());
      const settled = copy(state);
      if (receipt) applyOfflineReward(settled, receipt);
      // Credit and advance the timestamp together before showing an already-paid receipt.
      if (this.write(settled)) { this.offline = receipt; return settled; }
      return state;
    } catch {
      // Preserve an unreadable/unsupported save; never overwrite it with a blank profile.
      this.disabled = true; this.status = 'Could not load local save — this session will not overwrite it'; return this.fresh();
    }
  }
  write(state: TycoonState, release = false): boolean {
    if (!this.storage || this.disabled || this.readOnly) return false;
    try {
      const raw = this.storage.getItem(SAVE_KEY);
      const previous = raw ? JSON.parse(raw) as SaveEnvelope : undefined;
      // Another tab may have reset this profile. Never resurrect its old state.
      if (!previous && this.expectedRevision !== undefined) {
        this.readOnly = true; this.status = 'Save was reset in another tab. Reload to start again.'; return false;
      }
      if (previous && (previous.version !== 2 || !validState(previous.state))) { this.disabled = true; this.status = 'Save changed or unreadable — reload to recover'; return false; }
      if (previous && previous.writer !== this.owner && (previous.leaseUntil > this.now() || this.expectedRevision !== undefined)) {
        this.readOnly = true; this.status = 'Dealership open in another tab. Close it, then reload here.'; return false;
      }
      if (!validState(state)) { this.status = 'Save rejected — invalid game state'; return false; }
      const envelope: SaveEnvelope = { version: 2, state, savedAt: this.now(), writer: this.owner,
        leaseUntil: release ? 0 : this.now() + LEASE_SECONDS, revision: (previous?.revision ?? 0) + 1 };
      this.storage.setItem(SAVE_KEY, JSON.stringify(envelope)); this.expectedRevision = envelope.revision; this.status = 'Saved locally'; return true;
    }
    catch { this.status = 'Could not save — changes paused until storage is available'; return false; }
  }
  release(state: TycoonState) { return this.write(state, true); }
  resume(state: TycoonState) { return this.storage ? this.load() : state; }
  reset(): boolean {
    try {
      // Delete migration input first, so it cannot restore progress on next launch.
      this.storage?.removeItem(LEGACY_SAVE_KEY);
      this.storage?.removeItem(SAVE_KEY);
    } catch {
      this.status = 'Could not reset local save'; return false;
    }
    // Permanent for this instance, including unload, dispose and resume callbacks.
    this.resetCompleted = true; this.disabled = true; this.readOnly = true;
    this.offline = undefined; this.status = 'Save reset'; return true;
  }
}
