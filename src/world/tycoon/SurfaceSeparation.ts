import type { GeometryEntry } from './GeometryAlignment.js';
import type { Vec } from './types.js';

type V2 = [number, number];
interface Face { normal: Vec; plane: number; polygon: V2[]; bounds: number[]; owner: number; key: string }
export interface SurfaceAdjustment { source: string; offset: Vec; against: string[] }
const dot = (a: number[], b: number[]) => a.reduce((sum, n, i) => sum + n * b[i], 0);
const sub = (a: number[], b: number[]): Vec => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const cross = (a: number[], b: number[]): Vec => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const PLANE_EPSILON = .0015, SEPARATION = .012, CELL = 24;

/** Actual planar faces, including sloped wedges and the rendered 12-sided cylinders.
 * Curved spheres have no planar surface pairs; exact coincident meshes are handled below. */
function faces(entry: GeometryEntry, owner: number): Face[] {
  const { part, pose } = entry;
  if (part.mesh?.type === 'Sphere' || part.mesh?.type === 'Head' || part.shape === 'Ball') return [];
  let vertices: number[][], polygons: number[][];
  if (part.shape === 'WedgePart') {
    vertices = [[-.5,-.5,-.5],[.5,-.5,-.5],[-.5,-.5,.5],[.5,-.5,.5],[-.5,.5,.5],[.5,.5,.5]];
    polygons = [[0,1,3,2],[2,3,5,4],[0,2,4],[1,5,3],[0,4,5,1]];
  } else if (part.shape === 'Cylinder') {
    vertices = [-.5, .5].flatMap(x => Array.from({ length: 12 }, (_, i) => [x, Math.sin(i * Math.PI / 6) * .5, Math.cos(i * Math.PI / 6) * .5]));
    polygons = [Array.from({ length: 12 }, (_, i) => i), Array.from({ length: 12 }, (_, i) => i + 12),
      ...Array.from({ length: 12 }, (_, i) => [i, (i + 1) % 12, (i + 1) % 12 + 12, i + 12])];
  } else {
    vertices = [[-.5,-.5,-.5],[.5,-.5,-.5],[-.5,-.5,.5],[.5,-.5,.5],[-.5,.5,-.5],[.5,.5,-.5],[-.5,.5,.5],[.5,.5,.5]];
    polygons = [[4,5,7,6],[0,2,3,1],[1,3,7,5],[0,4,6,2],[2,6,7,3],[0,1,5,4]];
  }
  const cf = pose.cf, center = [cf[0] - 3000, cf[1], cf[2]];
  const points = vertices.map(vertex => {
    const local = vertex.map((v, i) => v * pose.size[i] + (part.mesh?.offset[i] ?? 0));
    return center.map((v, axis) => v + local.reduce((sum, n, i) => sum + n * cf[3 + axis * 3 + i], 0));
  });
  return polygons.map(indices => {
    const p = indices.map(i => points[i]), normal = cross(sub(p[1], p[0]), sub(p[2], p[0]));
    const length = Math.hypot(...normal);
    for (let i = 0; i < 3; i++) normal[i] /= length;
    const centroid = [0,1,2].map(axis => p.reduce((sum, v) => sum + v[axis], 0) / p.length);
    if (dot(normal, sub(centroid, center)) < 0) for (let i = 0; i < 3; i++) normal[i] *= -1;
    const drop = normal.map(Math.abs).indexOf(Math.max(...normal.map(Math.abs)));
    const polygon = p.map(v => v.filter((_, i) => i !== drop) as V2);
    const bounds = [Math.min(...polygon.map(v => v[0])), Math.min(...polygon.map(v => v[1])), Math.max(...polygon.map(v => v[0])), Math.max(...polygon.map(v => v[1]))];
    return { normal, plane: dot(normal, p[0]), polygon, bounds, owner, key: normal.map(v => Math.round(v * 10000)).join(',') };
  });
}
function overlaps(a: Face, b: Face) {
  if (a.bounds[0] >= b.bounds[2] - .01 || a.bounds[2] <= b.bounds[0] + .01 || a.bounds[1] >= b.bounds[3] - .01 || a.bounds[3] <= b.bounds[1] + .01) return false;
  // Separating-axis test distinguishes actual face overlap from overlapping AABBs.
  for (const polygon of [a.polygon, b.polygon]) for (let i = 0; i < polygon.length; i++) {
    const p = polygon[i], q = polygon[(i + 1) % polygon.length], axis = [p[1] - q[1], q[0] - p[0]];
    const length = Math.hypot(...axis); if (length < 1e-8) continue;
    const A = a.polygon.map(v => dot(v, axis) / length), B = b.polygon.map(v => dot(v, axis) / length);
    if (Math.min(Math.max(...A), Math.max(...B)) - Math.max(Math.min(...A), Math.min(...B)) <= .01) return false;
  }
  return true;
}
function keys(face: Face, neighbors: boolean) {
  const result: string[] = [], plane = Math.round(face.plane / (PLANE_EPSILON * 2));
  for (let x = Math.floor(face.bounds[0] / CELL); x <= Math.floor(face.bounds[2] / CELL); x++)
    for (let y = Math.floor(face.bounds[1] / CELL); y <= Math.floor(face.bounds[3] / CELL); y++)
      for (const offset of neighbors ? [-1, 0, 1] : [0]) result.push(`${face.key}:${plane + offset}:${x}:${y}`);
  return result;
}

/** Keep large structural pieces fixed, then separate smaller coplanar details.
 * Opposite-facing joints are intentionally excluded: touching blocks do not flicker.
 * Only render poses are copied; source data is never modified. */
export function separateSurfaces(source: GeometryEntry[]) {
  const entries = source.map(e => ({ part: e.part, pose: { ...e.pose, cf: [...e.pose.cf] as typeof e.pose.cf } }));
  const ordered = entries.map((entry, index) => ({ entry, index })).filter(e => e.entry.pose.visible && e.entry.pose.transparency < 1)
    .sort((a, b) => b.entry.pose.size.reduce((v, n) => v * n, 1) - a.entry.pose.size.reduce((v, n) => v * n, 1) || a.entry.part.id - b.entry.part.id);
  const grid = new Map<string, Face[]>(), exact = new Map<string, number>(), adjustments: SurfaceAdjustment[] = [];
  let conflicts = 0, unresolved = 0;
  for (const { entry, index } of ordered) {
    const original = entry.pose.cf.slice(0, 3), against = new Set<string>();
    const duplicateKey = JSON.stringify([entry.part.shape, entry.part.mesh, entry.pose.cf.map(v => Math.round(v * 10000)), entry.pose.size.map(v => Math.round(v * 10000))]);
    const duplicates = exact.get(duplicateKey) ?? 0; exact.set(duplicateKey, duplicates + 1);
    if (duplicates && (entry.part.shape === 'Ball' || entry.part.mesh)) {
      for (let i = 0; i < 3; i++) entry.pose.cf[i] += SEPARATION * duplicates;
      conflicts++; against.add('Coincident curved mesh');
    }
    let current = faces(entry, index);
    for (let attempt = 0; attempt <= 12; attempt++) {
      const hitNormals: Vec[] = [];
      for (const face of current) {
        const seen = new Set<Face>();
        for (const key of keys(face, true)) for (const other of grid.get(key) ?? []) {
          if (seen.has(other)) continue; seen.add(other);
          if (Math.abs(face.plane - other.plane) > PLANE_EPSILON || dot(face.normal, other.normal) < .999999 || !overlaps(face, other)) continue;
          hitNormals.push(face.normal); against.add(entries[other.owner].part.path); conflicts++;
        }
      }
      if (!hitNormals.length) break;
      if (attempt === 12) { unresolved += hitNormals.length; break; }
      const offset: Vec = [0, 0, 0];
      for (const normal of hitNormals) if (Math.abs(dot(offset, normal)) < SEPARATION / 2) {
        const previous = entry.pose.cf.slice(0, 3).map((v, i) => v - original[i]);
        const direction = dot(previous, normal) < -PLANE_EPSILON ? -1 : 1;
        for (let i = 0; i < 3; i++) offset[i] += normal[i] * SEPARATION * direction;
      }
      for (let i = 0; i < 3; i++) entry.pose.cf[i] += offset[i];
      current = faces(entry, index);
    }
    for (const face of current) for (const key of keys(face, false)) { const list = grid.get(key) ?? []; list.push(face); grid.set(key, list); }
    const offset = entry.pose.cf.slice(0, 3).map((v, i) => v - original[i]) as Vec;
    if (offset.some(v => Math.abs(v) > 1e-8)) adjustments.push({ source: entry.part.path, offset, against: [...against].slice(0, 4) });
  }
  return { entries, adjustments, conflicts, unresolved };
}
