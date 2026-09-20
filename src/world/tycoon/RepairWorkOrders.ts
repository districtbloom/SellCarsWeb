import { repairKind } from './RepairGame.js';
import type { Condition, Depth, Job, Plan } from './types.js';

const core = new Set(['Body', 'RunningGear', 'Mechanical', 'Exterior']);
const severity = { Good: 0, Worn: 1, Damaged: 2, Ruined: 3 };
function choices(plan: Plan, depth: Depth, condition: Condition, tutorial: boolean) {
  const required = plan.jobs.filter(job => tutorial ? ['Mechanical', 'RunningGear'].includes(job.id)
    : core.has(job.id) && condition[job.id as keyof Condition] !== 'Good');
  if (tutorial || plan.seconds <= 0) return { required, optional: [] as Job[], min: 0, max: 0, weight: 1 };
  const base = required[0] ?? plan.jobs[0];
  const fallback = (id: Job['id'], name: string): Job => ({ id, name, cost: 0, seconds: 1, done: false, started: false, progress: 0,
    position: base?.position && [...base.position], staffAt: base?.staffAt });
  if (depth === 'Good') required.push(plan.jobs.find(job => job.id === 'Tune') ?? fallback('Tune', 'Tune & finish'));
  const used = new Set(required.map(repairKind)), optional: Job[] = [];
  const candidates = [...plan.jobs.filter(job => !core.has(job.id) && job.id !== 'Tune'),
    fallback('Wash', 'Wash and clean'), fallback('Detail_QC', 'Detail and inspect'),
    ...(depth === 'Good' ? [fallback('Paint_Exterior', 'Refresh the finish')] : [])];
  for (const job of candidates) {
    const kind = repairKind(job); if (used.has(kind)) continue;
    used.add(kind); optional.push(job);
  }
  const wear = Object.values(condition).reduce((n, grade) => n + severity[grade], 0);
  // Good always adds tuning and at least two extras; Quick has at most two extras.
  const min = Math.min(optional.length, depth === 'Good' ? 2 : 1);
  const max = Math.min(optional.length, depth === 'Good' ? wear >= 6 ? 4 : 3 : 2);
  return { required, optional, min, max, weight: wear >= 6 ? .5 : 1.5 };
}
export function workOrderRange(plan: Plan, depth: Depth, condition: Condition, tutorial = false): { min: number; max: number } {
  const c = choices(plan, depth, condition, tutorial);
  return { min: c.required.length + c.min, max: c.required.length + c.max };
}
/** Roll only a funded quote. Its fixed price and duration do not change with the task mix. */
export function randomWorkOrder(plan: Plan, depth: Depth, condition: Condition, tutorial = false, random = Math.random): Plan {
  const roll = () => { const n = random(); return Number.isFinite(n) ? Math.max(0, Math.min(.999999999, n)) : .5; };
  const shuffle = <T>(items: T[]): T[] => {
    for (let i = items.length - 1; i > 0; i--) { const j = Math.floor(roll() * (i + 1)); [items[i], items[j]] = [items[j], items[i]]; }
    return items;
  };
  const c = choices(plan, depth, condition, tutorial);
  plan.pricedServices ??= plan.jobs.filter(job => job.id !== 'Tune').length;
  const count = c.min + Math.floor(roll() ** c.weight * (c.max - c.min + 1));
  const tasks = [...c.required, ...shuffle(c.optional).slice(0, count)];
  // Listing photos document the finished vehicle, after every selected repair and finish task.
  const selected = [...shuffle(tasks.filter(job => job.id !== 'Photo_Listing')), ...tasks.filter(job => job.id === 'Photo_Listing')];
  let cost = 0, seconds = 0;
  plan.jobs = selected.map((job, index) => {
    const last = index === selected.length - 1;
    const nextCost = last ? plan.cost : Math.floor(plan.cost * (index + 1) / selected.length);
    const nextSeconds = last ? plan.seconds : plan.seconds * (index + 1) / selected.length;
    const result: Job = { ...job, position: job.position && [...job.position], cost: nextCost - cost, seconds: nextSeconds - seconds,
      done: false, started: false, progress: 0, speed: undefined, manual: undefined, repair: undefined };
    cost = nextCost; seconds = nextSeconds; return result;
  });
  return plan;
}
