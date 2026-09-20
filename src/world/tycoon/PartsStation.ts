// Sell Cars TycoonConfig.STATIONS[junk] and StationService's repeatable recovery job.
import { feature } from './FullJourney.js';
import { sourcePoint } from './FullJourneyCatalog.js';
import type { TycoonState } from './types.js';
export const PARTS_POSITION = sourcePoint(3020, 118);
export const PARTS_SECONDS = 5;
export const PARTS_MAX_LEVEL = 20;
export const partsPayout = (level: number) => 28 + 16 * (level - 1);
export const partsUpgradeCost = (level: number) => Math.floor(220 * Math.pow(1.35, level - 1));
export const partsUnlocked = (s: TycoonState) => !!s.parts && feature(s, 'lot');
export const partsAutomated = (s: TycoonState) => partsUnlocked(s) && feature(s, 'mechanic') && s.journey?.automation !== false;
export function startParts(s: TycoonState): boolean {
  if (!partsUnlocked(s) || s.parts!.remaining !== undefined || partsAutomated(s)) return false;
  s.parts!.remaining = PARTS_SECONDS; s.parts!.manual = true; return true;
}
export function tickParts(s: TycoonState, dt: number, typing = false) {
  const p = s.parts; if (!p || !partsUnlocked(s)) return;
  if (partsAutomated(s)) p.manual = false;
  if (p.remaining === undefined && partsAutomated(s) && s.car?.status !== 'repair') { p.remaining = PARTS_SECONDS; p.manual = false; }
  if (p.remaining === undefined) return;
  if ((p.manual ?? !partsAutomated(s)) && !typing) return;
  p.remaining = Math.max(0, p.remaining - dt);
  if (p.remaining > 1e-8) return;
  p.remaining = undefined; p.manual = undefined; p.completed++;
  const amount = partsPayout(p.level); s.cash += amount;
  s.ledger.push({ amount, kind: 'parts', subject: 'Salvaged parts batch' });
  (s.revenue ??= []).push({ at: s.clock, amount });
}
