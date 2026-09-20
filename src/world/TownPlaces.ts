import type { Point } from './tycoon/types.js';

const logical = (x: number, z: number): Point => [(x + 300) / 3, (z - 100) / 3];
export const PART_SHOPS = [
  { id: 'main', x: 250, z: 86, position: logical(250, 86) },
  { id: 'east', x: 690, z: 86, position: logical(690, 86) },
  { id: 'service', x: 862, z: 323, position: logical(862, 323) },
];
export const COURIER_DEPOT = { x: -215, z: -221, position: logical(-215, -221) };
export const RESIDENTIAL_HOME = logical(235, -450);
export const DEALERSHIP_GARAGE = logical(-157, 40);
export const RESIDENTIAL_SELLER = logical(328, -288);
export const RESIDENTIAL_CAR = logical(326, -299);
export const RESIDENTIAL_PARKING = logical(345, -285);
export const townPoint = logical;

/** Connect destinations using the open town streets and the dealership approach. */
export function townRoute(from: Point, to: Point): Point[] {
  const toWorld = (p: Point) => [p[0] * 3 - 300, p[1] * 3 + 100];
  const [x, z] = toWorld(from), [X, Z] = toWorld(to);
  const roadZ = (value: number) => [-480, -260, -40, 180, 400, 620].reduce((a, b) => Math.abs(b - value) < Math.abs(a - value) ? b : a);
  const a = roadZ(z), b = roadZ(Z);
  if (x < 140 || X < 140) {
    const outward: Point[] = [from, logical(-259, z), logical(-259, -260), logical(140, -260), logical(140, b), logical(X, b), to];
    if (x < 140) return outward;
    return townRoute(to, from).reverse();
  }
  return [from, logical(x, a), logical(360, a), logical(360, b), logical(X, b), to];
}
