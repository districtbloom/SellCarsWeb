import type { Job, TycoonState } from './types.js';

export type RepairKind = 'wheels' | 'engine' | 'tuning' | 'body' | 'wash' | 'paint' | 'detail' | 'photo';
export type RepairInput = { kind: 'wheel'; index: number } | { kind: 'bolt'; index: number }
  | { kind: 'pour'; amount: number } | { kind: 'oil-filter' } | { kind: 'target'; index: number }
  | { kind: 'remove'; index: number } | { kind: 'install'; index: number; part: 'filter' | 'plug' };
export interface RepairProgress { kind: RepairKind; openedAt: number; wheels: boolean[]; bolts: boolean[]; targets: boolean[]; oil: number; complete: boolean; drainStarted?: number; filterInstalled?: boolean }
export const REPAIR_OPEN_SECONDS = 2;
export const OIL_DRAIN_SECONDS = 2.4;
export const drainProgress = (game: RepairProgress, clock: number) => game.drainStarted === undefined ? 0 : Math.min(1, Math.max(0, (clock - game.drainStarted) / OIL_DRAIN_SECONDS));
const kinds: Record<string, RepairKind> = { RunningGear: 'wheels', Mechanical: 'engine', Tune: 'tuning', Tune_Performance: 'tuning', Body: 'body', Body_Restoration: 'body', Wash: 'wash', Exterior: 'paint', Paint_Exterior: 'paint', Detail_QC: 'detail', Photo_Listing: 'photo' };
export const repairKind = (job: Job): RepairKind => kinds[job.id] ?? 'detail';
export function repairProgress(job: Job, clock: number): RepairProgress {
  let game = job.repair;
  if (!game) {
    const kind = repairKind(job);
    game = { kind, openedAt: clock, wheels: Array(4).fill(false), bolts: Array(kind === 'wheels' ? 28 : kind === 'engine' ? 2 : 5).fill(false), targets: Array(kind === 'tuning' ? 5 : 6).fill(false), oil: 0, complete: false, ...(kind === 'engine' ? { filterInstalled: false } : {}) };
    job.repair = game;
  }
  if (repairKind(job) === 'tuning' && game.kind === 'engine') {
    // Older tuning saves used oil service. Carry their earned work into the replacement sequence.
    const steps = game.complete ? 10 : Math.min(9, Math.floor(job.progress * 10));
    game.kind = 'tuning'; game.bolts = Array.from({ length: 5 }, (_, i) => i * 2 < steps);
    game.targets = Array.from({ length: 5 }, (_, i) => i * 2 + 1 < steps);
    game.oil = 0; game.drainStarted = undefined; game.filterInstalled = undefined; job.progress = steps / 10;
  }
  if (game.kind === 'engine' && game.bolts.length === 5) {
    game.bolts = [game.bolts.slice(0, 4).every(Boolean), game.bolts[4]];
    if (game.bolts[0]) game.drainStarted = clock - OIL_DRAIN_SECONDS;
  }
  // Previously, clicking the old filter also installed its replacement in the same action.
  if (game.kind === 'engine' && game.filterInstalled === undefined) game.filterInstalled = game.bolts[1];
  return game;
}
export function restartOpening(job: Job, clock: number) { repairProgress(job, clock).openedAt = clock; }
/** Validates ordered work at the session boundary. Tool travel is deliberately cosmetic. */
export function performRepair(s: TycoonState, input: RepairInput): boolean {
  const j = s.car?.plan?.jobs.find(job => !job.done);
  if (s.car?.status !== 'repair' || !j?.started || !j.manual) return false;
  const g = repairProgress(j, s.clock);
  if (s.clock - g.openedAt + 1e-8 < REPAIR_OPEN_SECONDS || g.complete) return false;
  const index = 'index' in input ? input.index : -1;
  if ('index' in input && (!Number.isInteger(index) || index < 0)) return false;
  if (input.kind === 'wheel') {
    if (g.kind !== 'wheels' || index > 3 || g.wheels[index]) return false;
    g.wheels[index] = true;
  } else if (input.kind === 'bolt') {
    if (!['wheels', 'engine'].includes(g.kind) || index >= g.bolts.length || g.bolts[index]) return false;
    if (g.kind === 'wheels' && !g.wheels[Math.floor(index / 7)]) return false;
    if (g.kind === 'engine' && index === 1 && drainProgress(g, s.clock) < 1) return false;
    g.bolts[index] = true;
    if (g.kind === 'engine' && index === 0) g.drainStarted = s.clock;
  } else if (input.kind === 'oil-filter') {
    if (g.kind !== 'engine' || !g.bolts.every(Boolean) || drainProgress(g, s.clock) < 1 || g.filterInstalled) return false;
    g.filterInstalled = true;
  } else if (input.kind === 'pour') {
    if (g.kind !== 'engine' || !g.filterInstalled || !g.bolts.every(Boolean) || drainProgress(g, s.clock) < 1 || !Number.isFinite(input.amount) || input.amount <= 0 || input.amount > .06) return false;
    g.oil = Math.min(1, g.oil + input.amount);
  } else if (input.kind === 'remove') {
    if (g.kind !== 'tuning' || index >= 5 || g.bolts[index]) return false;
    g.bolts[index] = true;
  } else if (input.kind === 'install') {
    if (g.kind !== 'tuning' || index >= 5 || !g.bolts[index] || g.targets[index] || input.part !== (index === 0 ? 'filter' : 'plug')) return false;
    g.targets[index] = true;
  } else if (input.kind === 'target') {
    if (['wheels', 'engine', 'tuning'].includes(g.kind) || index >= 6 || g.targets[index]) return false;
    g.targets[index] = true;
  } else return false;
  const fractions: Record<RepairKind, number> = {
    wheels: (g.wheels.filter(Boolean).length + g.bolts.filter(Boolean).length) / 32,
    engine: (g.bolts.filter(Boolean).length + drainProgress(g, s.clock) + Number(!!g.filterInstalled) + g.oil * 2) / 6,
    tuning: (g.bolts.filter(Boolean).length + g.targets.filter(Boolean).length) / 10,
    body: 0, wash: 0, paint: 0, detail: 0, photo: 0,
  };
  j.progress = ['wheels', 'engine', 'tuning'].includes(g.kind) ? fractions[g.kind] : g.targets.filter(Boolean).length / 6;
  g.complete = j.progress >= 1;
  return true;
}
