import { Matrix4, Vector3 } from 'three';
import type { Frame } from './BuildingProgression.js';
import type { Point, Vec } from './types.js';
// One Roblox stud remains one scene unit. Locate the lot beside the existing car course.
export const SOURCE_ORIGIN = new Vector3(3035, 1.43, 112);
export const LOT_ORIGIN = new Vector3(-300, 0, 100);
export function worldPoint(p: Point, sourceY = 3.4): Vector3 {
  return new Vector3(3035 + p[0] * 3, sourceY, 112 + p[1] * 3).sub(SOURCE_ORIGIN).add(LOT_ORIGIN);
}
export function logicalPoint(p: Vector3): Point { return [(p.x - LOT_ORIGIN.x) / 3, (p.z - LOT_ORIGIN.z) / 3]; }
export function frameMatrix(cf: Frame, size?: Vec): Matrix4 {
  const m = new Matrix4().set(cf[3], cf[4], cf[5], cf[0] - SOURCE_ORIGIN.x + LOT_ORIGIN.x,
    cf[6], cf[7], cf[8], cf[1] - SOURCE_ORIGIN.y, cf[9], cf[10], cf[11], cf[2] - SOURCE_ORIGIN.z + LOT_ORIGIN.z, 0, 0, 0, 1);
  if (size) m.scale(new Vector3(...size)); return m;
}
