import type { ImportedPart, PartPose } from './BuildingProgression.js';
import type { Vec } from './types.js';

export interface GeometryEntry { part: ImportedPart; pose: PartPose }
export interface GeometrySupport { source: string; bottom: number; top: number; role: 'footing' | 'mount' }

/** Source CFrames remain untouched. Fill verified support gaps beneath floor-standing
 * pieces, and give the source's freestanding signs/electrical panels actual posts. */
export function geometrySupports(entries: GeometryEntry[]): { entries: GeometryEntry[]; audit: GeometrySupport[] } {
  const floors = entries.filter(({ pose: p }) => p.visible && p.transparency < 1 && p.size[0] >= 2 && p.size[2] >= 2
    && p.size[1] <= 2 && Math.abs(p.cf[7]) > .999);
  const contains = (p: PartPose, x: number, z: number) => {
    const dx = x - p.cf[0], dz = z - p.cf[2];
    return Math.abs(dx * p.cf[3] + dz * p.cf[9]) <= p.size[0] / 2 + .01
      && Math.abs(dx * p.cf[5] + dz * p.cf[11]) <= p.size[2] / 2 + .01;
  };
  const supportAt = (x: number, z: number, below: number) => {
    let height = -Infinity;
    for (const { pose: p } of floors) {
      const top = p.cf[1] + p.size[1] / 2;
      if (top > below + .001 || top <= height) continue;
      if (contains(p, x, z)) height = top;
    }
    return height;
  };
  const supports: GeometryEntry[] = [], audit: GeometrySupport[] = [];
  const add = (source: GeometryEntry, center: Vec, size: Vec, bottom: number, top: number, role: GeometrySupport['role'], followYaw = true) => {
    const pose: PartPose = { ...source.pose, cf: [center[0], center[1], center[2], 1, 0, 0, 0, 1, 0, 0, 0, 1], size,
      color: role === 'mount' ? [.24, .29, .3] : source.pose.color, material: role === 'mount' ? 'Metal' : source.pose.material,
      transparency: 0, collide: source.pose.collide };
    if (role === 'footing' && followYaw) { pose.cf = [...source.pose.cf]; pose.cf[0] = center[0]; pose.cf[1] = center[1]; pose.cf[2] = center[2]; }
    supports.push({ part: { ...source.part, path: source.part.path + '/Alignment ' + role, shape: 'Block', mesh: undefined, labels: undefined }, pose });
    audit.push({ source: source.part.path, bottom, top, role });
  };
  for (const entry of entries) {
    const { part, pose: p } = entry;
    if (!p.visible || p.transparency >= 1) continue;
    const name = part.path.split('.').pop()!;
    const half = [0, 1, 2].map(axis => p.size.reduce((sum, size, i) => sum + Math.abs(p.cf[3 + axis * 3 + i]) * size / 2, 0));
    const bottom = p.cf[1] - half[1];
    const floorStanding = /(?:Foot|Caster|Leg|Base|Plinth|Slab|Floor|Deck|Mat|Pad|Stand|Tray|Upright|Post|Pedestal|Cabinet|Mast|Cradle|Rack$)/.test(name)
      && !/Roof|Ceiling|Upper|Raised|Suspended|Wall|Display|Socket|Anchor|Target/.test(name);
    // Only ground-level feet/base plates: never stretch ramps, wheels or upper-floor art.
    if (floorStanding && part.shape === 'Block' && !part.mesh && bottom < 3 && Math.abs(p.cf[7]) > .999) {
      const supported = floors.some(({ pose: floor }) => floor !== p && floor.cf[1] - floor.size[1] / 2 <= bottom
        && floor.cf[1] + floor.size[1] / 2 >= bottom - .08 && contains(floor, p.cf[0], p.cf[2]));
      const ground = supportAt(p.cf[0], p.cf[2], bottom - .01), gap = bottom - ground;
      if (!supported && Number.isFinite(ground) && gap > .08 && gap <= 1) {
        add(entry, [p.cf[0], ground + gap / 2, p.cf[2]], [p.size[0], gap + .004, p.size[2]], ground, bottom, 'footing');
      }
    }
    // Locate angled legs' lowest corner and cylinders' lowest rim point.
    if (part.shape === 'Cylinder' && /Caster|Foot/.test(name) || name === 'Tripod_Leg') {
      const radiusY = p.size[1] / 2, radiusZ = p.size[2] / 2;
      const radial = Math.hypot(p.cf[7] * radiusY, p.cf[8] * radiusZ);
      const local = part.shape === 'Block' ? p.size.map((size, i) => -Math.sign(p.cf[6 + i]) * size / 2) : [-Math.sign(p.cf[6]) * p.size[0] / 2,
        radial > 1e-8 ? -p.cf[7] * radiusY * radiusY / radial : 0,
        radial > 1e-8 ? -p.cf[8] * radiusZ * radiusZ / radial : 0];
      const contact = [0, 1, 2].map(axis => p.cf[axis] + local.reduce((sum, v, i) => sum + p.cf[3 + axis * 3 + i] * v, 0));
      const ground = supportAt(contact[0], contact[2], contact[1] - .01), gap = contact[1] - ground;
      if (contact[1] < 3 && gap > .08 && gap <= 1) {
        add(entry, [contact[0], ground + gap / 2, contact[2]], [.25, gap + .004, .25], ground, contact[1], 'footing', false);
      }
    }
    const rail = name === 'Low_Scrap_Boundary';
    const sign = name === 'FoundingTimberSign' || name === 'Identification' && part.path.includes('P019_Ready_Stock_Edge');
    const panel = name === 'DistributionBoard' && part.path.includes('P016_power') || name === 'TenderServiceBackplate';
    if (!rail && !sign && !panel) continue;
    const horizontal = half[0] > half[2] ? 0 : 2;
    for (const side of rail || sign ? [-1, 1] : [0]) {
      const center: Vec = [p.cf[0], 0, p.cf[2]];
      center[horizontal] += side * half[horizontal] * .8;
      const top = bottom + Math.min(.2, p.size[1] / 2), ground = supportAt(center[0], center[2], bottom - .01);
      if (!Number.isFinite(ground) || top - ground < .08 || top - ground > 12) continue;
      center[1] = (ground + top) / 2;
      add(entry, center, [.18, top - ground + .004, .18], ground, top, 'mount');
    }
  }
  return { entries: supports, audit };
}
