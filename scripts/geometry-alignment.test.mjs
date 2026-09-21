import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { importTypescript } from './import-typescript.mjs';
import { World } from 'cannon-es';
import { Box3, InstancedMesh, Vector3 } from 'three';
import { Element } from './test-dom.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const { geometrySupports } = await importTypescript(new URL('GeometryAlignment.ts', root));
const { partPose } = await importTypescript(new URL('BuildingProgression.ts', root));
const parts = JSON.parse(await readFile(new URL('../public/tycoon/dealership.json', import.meta.url))).parts;

test('owner ceiling fixtures wait for the matching workshop roof section', () => {
  const fixtures = parts.filter(p => /Personal_Fleet_Setting_\d+\.(FixtureSuspension|ShieldedPersonalLight)$/.test(p.path));
  assert.ok(fixtures.length > 3);
  for (const part of fixtures) {
    const z = part.attributes.FJ_CF[2], roof = z <= 66 ? 62 : z <= 94 ? 120 : 183;
    assert.equal(partPose(part, roof - 1).visible, false, part.path);
    if (part.attributes.FJ_First <= roof) assert.equal(partPose(part, roof).visible, true, part.path);
  }
});

test('native furniture stays at its authored pose while small floor gaps receive connected foundations', () => {
  const source = JSON.stringify(parts);
  for (const step of [3, 24, 64, 140, 196, 240]) {
    const entries = parts.map(part => ({ part, pose: partPose(part, step) })).filter(e => e.pose.visible && e.pose.transparency < 1);
    const poses = JSON.stringify(entries), aligned = geometrySupports(entries);
    assert.ok(aligned.entries.length > 0);
    assert.equal(JSON.stringify(entries), poses, 'Support construction cannot move or resize native geometry');
    aligned.entries.forEach(({ part, pose }, i) => {
      const proof = aligned.audit[i];
      assert.ok(Math.abs(pose.cf[1] - pose.size[1] / 2 - proof.bottom) < .003);
      assert.ok(Math.abs(pose.cf[1] + pose.size[1] / 2 - proof.top) < .003);
      assert.ok(proof.top > proof.bottom && proof.top - proof.bottom <= (proof.role === 'footing' ? 1 : 12));
      assert.equal(part.labels, undefined); assert.equal(part.mesh, undefined);
    });
    if (step === 24) {
      for (const name of ['Low_Scrap_Boundary', 'FoundingTimberSign', 'TenderServiceBackplate', 'DistributionBoard'])
        assert.ok(aligned.audit.some(a => a.role === 'mount' && a.source.endsWith(name)), name);
      assert.equal(aligned.audit.filter(a => a.source.endsWith('Transferable_Phone_Kit.Tripod_Leg')).length, 3);
    }
  }
  assert.equal(JSON.stringify(parts), source, 'Export remains a faithful source reference');
});

test('runtime supports render in collision alignment and the parts desk rests on the active floor', async () => {
  globalThis.document = { createElement: () => new Element() };
  const { TycoonEnvironment } = await importTypescript(new URL('TycoonEnvironment.ts', root));
  const { TycoonActors } = await importTypescript(new URL('TycoonActors.ts', root));
  const physics = new World(), environment = new TycoonEnvironment(parts, physics), actors = new TycoonActors([]);
  try {
    for (const step of [1, 24, 64, 240]) {
      environment.sync({ pads: [] }, step);
      actors.alignFixtures(point => environment.groundHeight(point));
      actors.root.updateMatrixWorld(true);
      const desk = actors.root.getObjectByName('Parts sales computer');
      for (const leg of desk.children.filter(p => p.name === 'Desk leg')) {
        const bounds = new Box3().setFromObject(leg), center = bounds.getCenter(new Vector3());
        assert.ok(Math.abs(bounds.min.y - environment.groundHeight(center)) < .005, `Desk leg at stage ${step}`);
      }
      const supports = environment.cameraObstacles.filter(p => p.name.includes('/Alignment '));
      assert.ok(environment.alignmentSupports.length > 0, 'Support geometry exists at every checked stage');
      if (step === 240) assert.ok(supports.length > 0, 'Solid supports use the real collision pipeline');
      assert.ok(environment.root.children.some(p => p instanceof InstancedMesh), 'Source and supports stay instanced');
      assert.equal(physics.bodies.length, environment.cameraObstacles.length);
    }
  } finally { environment.dispose(); actors.dispose(); }
  assert.equal(physics.bodies.length, 0);
});
