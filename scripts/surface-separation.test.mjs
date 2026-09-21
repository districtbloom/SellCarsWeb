import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const { separateSurfaces } = await importTypescript(new URL('SurfaceSeparation.ts', root));
const { partPose } = await importTypescript(new URL('BuildingProgression.ts', root));
const entry = (id, size, center, yaw = 0, shape = 'Block') => ({ part: { id, path: 'part-' + id, shape }, pose: {
  visible: true, transparency: 0, collide: true, size, color: [1,1,1], material: 'Metal',
  cf: [...center, Math.cos(yaw),0,Math.sin(yaw),0,1,0,-Math.sin(yaw),0,Math.cos(yaw)],
} });

test('coplanar overlays receive small translations while touching joints and separated faces remain fixed', () => {
  const floor = entry(1, [20,1,20], [0,0,0]);
  const paint = entry(2, [5,.1,5], [0,.45,0], Math.PI / 4);
  const joint = entry(3, [20,1,20], [20,0,0]);
  const distinct = entry(4, [2,.1,2], [0,.6,0]);
  const source = [floor, paint, joint, distinct], before = JSON.stringify(source), fixed = separateSurfaces(source);
  assert.equal(fixed.unresolved, 0); assert.equal(fixed.adjustments.length, 1); assert.equal(fixed.adjustments[0].source, 'part-2');
  assert.ok(fixed.entries[1].pose.cf[1] > paint.pose.cf[1], 'Overlay moves outward instead of sinking into the floor');
  assert.equal(JSON.stringify(source), before);
  assert.equal(separateSurfaces(fixed.entries).adjustments.length, 0);
});

test('overlapping rotated wedges, cylinders and duplicate curved meshes separate without changing dimensions', () => {
  for (const shape of ['WedgePart', 'Cylinder', 'Ball']) {
    const source = [entry(1, [3,4,5], [0,0,0], .4, shape), entry(2, [3,4,5], [0,0,0], .4, shape)];
    const fixed = separateSurfaces(source);
    assert.equal(fixed.unresolved, 0); assert.equal(fixed.adjustments.length, 1);
    assert.deepEqual(fixed.entries[1].pose.size, source[1].pose.size);
    assert.equal(separateSurfaces(fixed.entries).adjustments.length, 0, shape);
  }
});

test('the real source is unchanged and a second independent scan finds no remaining planar overlaps', async () => {
  const { parts } = JSON.parse(await readFile(new URL('../public/tycoon/dealership.json', import.meta.url)));
  for (const stage of [24, 140, 240]) {
    const source = parts.map(part => ({ part, pose: partPose(part, stage) })).filter(e => e.pose.visible && e.pose.transparency < 1);
    const before = JSON.stringify(source), fixed = separateSurfaces(source), verification = separateSurfaces(fixed.entries);
    assert.equal(JSON.stringify(source), before); assert.equal(fixed.unresolved, 0);
    assert.ok(fixed.adjustments.length > 0); assert.equal(verification.adjustments.length, 0, `Stage ${stage}`);
    assert.ok(fixed.adjustments.every(a => Math.hypot(...a.offset) <= .061));
  }
});
