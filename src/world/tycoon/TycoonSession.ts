import { performRepair } from './RepairGame.js';
import type { RepairInput } from './RepairGame.js';
import { catalog } from './catalog.js';
import { RESIDENTIAL_SELLER } from '../TownPlaces.js';
import * as M from './TycoonModel.js';
import { allPurchasePads } from './FullJourney.js';
import { sourcePoint } from './FullJourneyCatalog.js';
import { PARTS_POSITION, PARTS_MAX_LEVEL, partsUnlocked, partsUpgradeCost, startParts } from './PartsStation.js';
import { PART_SHOPS, COURIER_DEPOT } from '../TownPlaces.js';
import { buyParts, hireCourier } from './PartsEconomy.js';
import type { Depth, Look, Point, Receipt, TycoonState } from './types.js';

export type Action = { type: 'RepairInput'; input: RepairInput } | { type: 'Pad'; id: string } | { type: 'Counter' | 'Accept'; carId: string; revision: number; amount: number }
  | { type: 'BuyParts'; shopId: string; packageId: string } | { type: 'HireCourier' }
  | { type: 'Plan'; depth: Depth } | { type: 'Custom'; choice: Look }
  | { type: 'SpecialDeal'; index: 2 | 3 }
  | { type: 'BuyPersonal' | 'SelectPersonal'; modelId: number }
  | { type: 'KeepCar'; carId: string } | { type: 'SpawnPersonal'; vehicleId: string } | { type: 'PaintPersonal'; vehicleId: string; paint: string }
  | { type: 'ToggleIntake' | 'ToggleAutomation' | 'NextSeller' | 'SellParts' | 'UpgradeParts' | 'AnswerCall' | 'RemindCall' }
  | { type: 'Deal' | 'Decline' | 'Repair' | 'Photo' | 'Train' | 'Invite' | 'Recovery' | 'Visit' | 'Leave' | 'Discover' };
export interface InteractionContext { position: Point; onFoot: boolean }
export interface ActionResult { ok: boolean; openDeal?: boolean; receipt?: Receipt }
export function actorPosition(s: TycoonState): Point {
  if (s.car?.business) return s.car.status === 'seller' ? sourcePoint(3017, 96) : sourcePoint(3066, 86);
  return s.car?.remote ? RESIDENTIAL_SELLER : s.car?.status === 'seller' ? [-6, -5.33333] : [10.33333, -6.7];
}
/** Local authority boundary replacing HubServer's RemoteEvent. A network host can own this unchanged. */
export class TycoonSession {
  constructor(readonly state: TycoonState = M.fresh()) {}
  dispatch(action: Action, context: InteractionContext): ActionResult {
    const s = this.state, c = s.car;
    const near = (p: Point, studs: number) => context.onFoot && Math.hypot(context.position[0] - p[0], context.position[1] - p[1]) * 3 < studs;
    if (action.type === 'Counter' || action.type === 'Accept') {
      if (!c?.quote || action.carId !== c.id || action.revision !== c.quote.revision || (action.type === 'Accept' && action.amount !== c.quote.accepted)) {
        M.note(s, 'The offer changed. Check the current price.'); return { ok: false };
      }
    }
    switch (action.type) {
      case 'AnswerCall': return { ok: M.answerCall(s) };
      case 'RemindCall': return { ok: M.remindCall(s) };
      case 'BuyParts': { const shop = PART_SHOPS.find(p => p.id === action.shopId); return { ok: !!shop && near(shop.position, 22) && buyParts(s, action.packageId) }; }
      case 'HireCourier': return { ok: near(COURIER_DEPOT.position, 22) && hireCourier(s) };
      case 'Pad': { const p = s.journey ? allPurchasePads(s).find(pad => pad.id === action.id) : catalog.pads.find(p => p.id === action.id); return { ok: !!p && near(p.pos, 12) && M.buyPad(s, p.id) }; }
      case 'Deal': { const ok = near(actorPosition(s), 24) && M.openDeal(s); return { ok, openDeal: ok }; }
      case 'Counter': return { ok: near(actorPosition(s), 26) && M.counter(s, action.amount) };
      case 'Accept': {
        if (!c?.quote || !near(actorPosition(s), 26)) return { ok: false };
        const buying = c.quote.mode === 'buy', amount = c.quote.accepted, d = M.def(s), b = buying ? undefined : M.buyer(s);
        const ok = buying ? M.buy(s) : M.sell(s);
        return { ok, receipt: ok ? { buying, car: d.name, person: b?.name ?? d.seller, amount, purchase: c.purchase, work: c.workSpent,
          profit: buying ? undefined : amount - c.purchase - c.workSpent,
          line: buying ? (c.business ? c.business.tutorial ? 'Install the repair kit. Restore the engine, then the front-left wheel.' : 'Choose a work plan at the car.' : c.remote ? 'Elias brings it back. Drive home.' : c.index === 1 ? 'Build your workshop. Repairs cost $500.' : 'Next: choose how to prepare it.') : 'Thanks. I’ll take good care of it.' } : undefined };
      }
      case 'Decline': return { ok: near(actorPosition(s), 26) && M.decline(s) };
      case 'Plan': return { ok: !!c && near(c.pos, 25) && M.plan(s, action.depth) };
      case 'RepairInput': return { ok: !!c && near(c.pos, 22) && performRepair(s, action.input) };
      case 'Repair': return { ok: !!c && near(c.pos, 22) && M.startJob(s) };
      case 'Photo': return { ok: M.list(s) };
      case 'Custom': return { ok: !!c && near(c.pos, 30) && M.customize(s, action.choice) };
      case 'Train': { const ok = M.upgrade(s); if (!ok) M.note(s, 'Finish a job and keep $350 spare to train Jo.'); return { ok }; }
      case 'Invite': return { ok: M.invite(s) };
      case 'Recovery': return { ok: !c && s.sales >= 3 && M.arrive(s, 3) };
      case 'BuyPersonal': case 'SelectPersonal': return { ok: context.onFoot && M.selectPersonal(s, action.modelId, action.type === 'BuyPersonal') };
      case 'KeepCar': return { ok: !!c && near(c.pos, 22) && M.keepCar(s, action.carId) };
      case 'SpawnPersonal': return { ok: context.onFoot && M.spawnPersonal(s, action.vehicleId) };
      case 'PaintPersonal': return { ok: context.onFoot && M.paintPersonal(s, action.vehicleId, action.paint) };
      case 'Visit': return { ok: context.onFoot && M.visit(s) };
      case 'Leave': return { ok: M.leave(s) };
      case 'Discover': return { ok: M.discover(s) };
      case 'ToggleIntake': { if (!s.journey) return { ok: false }; s.journey.intakePaused = !s.journey.intakePaused; return { ok: true }; }
      case 'ToggleAutomation': { if (!s.journey?.tutorialComplete) return { ok: false }; s.journey.automation = !s.journey.automation; return { ok: true }; }
      case 'NextSeller': return { ok: !!s.journey?.tutorialComplete && M.arriveBusiness(s) };
      case 'SpecialDeal': return { ok: !!s.journey?.tutorialComplete && [2, 3].includes(action.index) && M.has(s, 'finish') && M.arrive(s, action.index) };
      case 'SellParts': return { ok: near(PARTS_POSITION, 18) && startParts(s) };
      case 'UpgradeParts': {
        const station = s.parts;
        if (!near(PARTS_POSITION, 18) || !partsUnlocked(s) || !station || station.level >= PARTS_MAX_LEVEL || s.cash - M.reserve(s) < partsUpgradeCost(station.level)) return { ok: false };
        const ok = M.pay(s, partsUpgradeCost(station.level), 'station', 'Parts laptop level ' + (station.level + 1));
        if (ok) station.level++; return { ok };
      }
    }
  }
  tick(dt: number, throttle = 0, typingParts = false) {
    // HubServer pauses its simulation for the rare-car reveal.
    if (this.state.car?.status !== 'discovery') M.tick(this.state, Math.min(.1, Math.max(0, dt)), throttle, typingParts);
  }
}
