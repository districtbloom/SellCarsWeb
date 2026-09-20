import type { Moving, Point } from './types.js';

const mix = (a: Point, b: Point, t: number): Point => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
const distance = (a: Point, b: Point) => Math.hypot(b[0] - a[0], b[1] - a[1]);
/** Trim corners inside the road corridor and join them with tangent-continuous arcs. */
export function roundedRoute(points: Point[]): Point[] {
  const out: Point[] = [points[0]];
  const line = (end: Point) => {
    const start = out[out.length - 1], n = Math.max(1, Math.ceil(distance(start, end) / .18));
    for (let i = 1; i <= n; i++) out.push(mix(start, end, i / n));
  };
  for (let i = 1; i < points.length - 1; i++) {
    const a = points[i - 1], b = points[i], c = points[i + 1];
    const ab = distance(a, b), bc = distance(b, c);
    if (ab < .01 || bc < .01) continue;
    const radius = Math.min(3.2, ab * .42, bc * .42);
    const entry = mix(b, a, radius / ab), exit = mix(b, c, radius / bc);
    line(entry);
    const n = Math.max(12, Math.ceil(radius * 14));
    for (let j = 1; j <= n; j++) { const t = j / n; out.push(mix(mix(entry, b, t), mix(b, exit, t), t)); }
  }
  if (points.length > 1) line(points[points.length - 1]);
  return out;
}
/** Pure pursuit steers a moving axle along a saved path; position never slides toward a waypoint. */
export function moveVehicle(o: Moving, dt: number, cruise = 7): string | undefined {
  const route = o.route;
  if (!route || !Number.isFinite(dt) || dt <= 0) return;
  if (!route.curved) {
    route.points = roundedRoute([o.pos.slice() as Point, ...route.points.slice(route.step)]);
    route.step = 1; route.curved = true; route.speed = 0;
  }
  if (route.step >= route.points.length) { o.route = undefined; return route.target; }
  const end = route.points[route.points.length - 1];
  const initial = route.points[route.step];
  const desiredHeading = Math.atan2(-(initial[0] - o.pos[0]), initial[1] - o.pos[1]);
  o.angle ??= desiredHeading;
  route.reverse ??= Math.cos(desiredHeading - o.angle) < -.25;
  const direction = route.reverse ? Math.PI : 0;
  const steps = Math.max(1, Math.ceil(dt / .02)), h = dt / steps;
  for (let n = 0; n < steps; n++) {
    // A monotonic nearest-point cursor survives reloads and avoids skipping across hairpins.
    let nearest = route.step, best = distance(o.pos, route.points[nearest]);
    let scanned = 0;
    for (let i = route.step + 1; i < route.points.length; i++) {
      scanned += distance(route.points[i - 1], route.points[i]);
      if (scanned > 8) break;
      const d = distance(o.pos, route.points[i]);
      if (d < best) { best = d; nearest = i; }
    }
    route.step = nearest;
    let aim = nearest, remaining = 0;
    const lookahead = Math.max(1.3, Math.min(3.2, (route.speed ?? 0) * .3));
    while (aim < route.points.length - 1 && remaining < lookahead) {
      remaining += distance(route.points[aim], route.points[aim + 1]); aim++;
    }
    const target = route.points[aim], targetDistance = distance(o.pos, target), endDistance = distance(o.pos, end);
    const finishing = aim === route.points.length - 1;
    if (finishing && endDistance < .08) { o.pos = end.slice() as Point; o.route = undefined; return route.target; }
    const motion = o.angle + direction;
    const heading = Math.atan2(-(target[0] - o.pos[0]), target[1] - o.pos[1]);
    const error = Math.atan2(Math.sin(heading - motion), Math.cos(heading - motion));
    const curvature = Math.max(-.85, Math.min(.85, 2 * Math.sin(error) / Math.max(.1, targetDistance)));
    const cornerSpeed = Math.sqrt(3 / Math.max(.015, Math.abs(curvature)));
    const desired = Math.min(cruise, cornerSpeed, finishing ? Math.max(.15, endDistance * 2) : cruise);
    route.speed ??= 0;
    route.speed += Math.max(-10 * h, Math.min(4 * h, desired - route.speed));
    const travel = Math.min(route.speed * h, finishing ? Math.max(.025, endDistance * .6) : Infinity);
    const turn = curvature * travel, middle = motion + turn / 2;
    o.pos = [o.pos[0] - Math.sin(middle) * travel, o.pos[1] + Math.cos(middle) * travel];
    o.angle += turn;
  }
  return undefined;
}
