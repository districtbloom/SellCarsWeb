import { catalog } from './catalog.js';
import * as M from './TycoonModel.js';
import { actorPosition } from './TycoonSession.js';
import { allPurchasePads, staffedListing } from './FullJourney.js';
import type { Point, TycoonState } from './types.js';
import { RESIDENTIAL_PARKING } from '../TownPlaces.js';
export interface Guidance { text: string; label: string; kind?: 'pad' | 'deal' | 'build' | 'repair' | 'photo' | 'phone' | 'drive' | 'complete' | 'discover' | 'parts'; point?: Point; id?: string }
/** Walking targets leave space beside a vehicle; its billboard belongs above the vehicle itself. */
export function guidanceAnchor(s: TycoonState, g: Guidance): Point | undefined {
  return s.car && ['repair', 'build', 'photo'].includes(g.kind ?? '') ? s.car.pos : g.point ?? s.car?.pos;
}
export function guidance(s: TycoonState): Guidance {
  if (s.personal?.route) return { text: s.personal.route.target === 'lead' ? 'Drive to Elias’s garage.' : 'Drive your car home.', label: 'Hold W to drive', kind: 'drive' };
  if (s.personal?.status === 'driving') return {
    text: s.lead?.status === 'visiting' ? 'Drive to Maple Heights. Park and step out by Elias’s garage.' : 'Drive back to your dealership and step out.',
    label: 'Go to your car', kind: 'drive', point: s.lead?.status === 'visiting' ? RESIDENTIAL_PARKING : s.personal.home,
  };
  const c = s.car;
  const statusGuides: Record<string, () => Guidance> = {
    seller: () => ({ text: M.def(s).seller + ' has a car for you.', label: 'Meet seller', kind: 'deal', point: actorPosition(s) }),
    buyer: () => ({ text: M.buyer(s).name + ' is ready to make an offer.', label: 'View offer', kind: 'deal', point: actorPosition(s) }),
    choose: () => ({ text: 'Choose how much work to put into this flip.', label: 'Choose flip', kind: 'build', point: [c!.pos[0], c!.pos[1] + 3] }),
    repair: () => { const j = M.job(s), staffed = M.staffedJob(s); return { text: staffed ? 'Your staff has this service covered.' : j?.name ?? 'Finishing up.', label: staffed ? 'View team' : j?.started ? 'Continue repair' : j?.name ?? '', kind: 'repair', point: [c!.pos[0], c!.pos[1] + 3] }; },
    photo: () => staffedListing(s) ? { text: 'Your sales advisor is photographing and listing this car.', label: '' }
      : { text: 'Ready. Find this car a buyer.', label: 'Prepare for sale', kind: 'photo' },
    ready: () => ({ text: staffedListing(s) ? 'Your advisor is listing the car. Manny will drive it to the sale point.' : 'Manny is collecting the car for the sale point.', label: '' }),
    sold: () => ({ text: 'Off to its new owner.', label: '' }),
    discovery: () => ({ text: 'RARE FIND · 1972 Phoenix GT', label: 'Meet Elias', kind: 'discover' }),
    moving: () => ({ text: 'Your car is on its way.', label: '' }),
    arriving: () => ({ text: 'Your car is on its way.', label: '' }),
    waitingBuyer: () => ({ text: 'Another buyer is on the way.', label: '' }),
  };
  const carGuide = c && (c.status !== 'ready' || M.has(s, 'salesdesk')) && statusGuides[c.status];
  if (carGuide) return carGuide();
  const p = M.nextPad(s);
  if (p) return { text: p.id === 'lot' ? 'Step onto the first pad to open your lot.' : `Next, add ${p.name.toLowerCase()}.`, label: 'Show me →', kind: 'pad', point: p.pos, id: p.id };
  if (s.rareCallAt !== undefined) return { text: 'Your own car. You’ve earned this.', label: '' };
  if (s.lead) return { text: 'There’s a call for you.', label: 'Open phone', kind: 'phone' };
  if (s.completed) return { text: 'Your first rare flip. A real business.', label: 'Your journey', kind: 'complete' };
  return { text: 'Explore your dealership.', label: 'Phone', kind: 'phone' };
}
export const money = (n: number) => '$' + Math.floor(n).toLocaleString('en-US');
export function nearestPad(s: TycoonState, p: Point) {
  if (s.journey) return allPurchasePads(s).map(pad => ({ pad, distance: Math.hypot(p[0] - pad.pos[0], p[1] - pad.pos[1]) * 3 }))
    .filter(row => row.distance < 14).sort((a, b) => a.distance - b.distance)[0]?.pad;
  return catalog.pads.filter(pad => M.eligible(s, pad)).map(pad => ({ pad, distance: Math.hypot(p[0] - pad.pos[0], p[1] - pad.pos[1]) * 3 }))
    .filter(row => row.distance < 14).sort((a, b) => a.distance - b.distance)[0]?.pad;
}
