import { feature } from './FullJourney.js';
import type { OfflineReceipt, TycoonState } from './types.js';
export const MIN_OFFLINE_SECONDS = 90;
export const MAX_OFFLINE_SECONDS = 8 * 60 * 60;
/** DataService.OFFLINE_RATE_BY_PAD, mapped to the equivalent FullJourney facility.
 * This bridge is explicit because the source FullJourney profile does not yet
 * consume the older DataService. Rates are dollars per second, never per car. */
export const offlineBindings = [
  { sourceId: 'CashRegister', step: 2, rate: .12, opening: 'intake' },
  { sourceId: 'FirstSalesman', step: 6, rate: .35, opening: 'salesdesk' },
  { sourceId: 'RB_CarLift', step: 79, rate: .85 },
  { sourceId: 'RB2_Foundation', step: 126, rate: .55 },
  { sourceId: 'CW_BrushMachine', step: 41, rate: 1.35 },
  { sourceId: 'CW2_BrushMachine', step: 124, rate: 1.35 },
  { sourceId: 'TA_DynoRollers', step: 91, rate: 2.25 },
  { sourceId: 'TA_BodyKitStation', step: 46, rate: 2.75 },
  { sourceId: 'TA_PaintControl', step: 97, rate: 3.15 },
];
export const offlineUnlocked = (s: TycoonState) => (s.journey?.tutorialComplete ?? s.sales > 0) && feature(s, 'mechanic');
export function offlineRate(s: TycoonState): number {
  return offlineBindings.reduce((sum, b) => sum + ((s.journey?.step ?? 0) >= b.step || (b.opening && s.pads.includes(b.opening)) ? b.rate : 0), 0);
}
export function offlineReward(s: TycoonState, savedAt: number | undefined, now: number): OfflineReceipt | undefined {
  if (!offlineUnlocked(s) || savedAt === undefined || !Number.isFinite(savedAt) || !Number.isFinite(now) || savedAt <= 0) return undefined;
  const elapsed = Math.max(0, Math.floor(now - savedAt)), seconds = Math.min(elapsed, MAX_OFFLINE_SECONDS);
  if (seconds < MIN_OFFLINE_SECONDS) return undefined;
  const rate = offlineRate(s), amount = Math.max(0, Math.min(1e12 - s.cash, Math.floor(seconds * rate)));
  return amount > 0 ? { seconds, rate, amount, capped: elapsed > MAX_OFFLINE_SECONDS } : undefined;
}
export function applyOfflineReward(s: TycoonState, receipt: OfflineReceipt) {
  s.cash += receipt.amount;
  s.ledger.push({ amount: receipt.amount, kind: 'offline', subject: 'Offline business earnings' });
}
export const revenuePerMinute = (s: TycoonState) => (s.revenue ?? []).filter(e => e.at > s.clock - 60 && e.at <= s.clock).reduce((sum, e) => sum + e.amount, 0);
