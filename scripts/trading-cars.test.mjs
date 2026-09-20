import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Box3, Mesh, ObjectLoader, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';
import { Element } from './test-dom.mjs';

const root = new URL('../src/world/', import.meta.url);
const { TradingCarVisual } = await importTypescript(new URL('tycoon/TradingCarVisual.ts', root));
const { CarInstance } = await importTypescript(new URL('driving/CarInstance.ts', root));
const M = await importTypescript(new URL('tycoon/TycoonModel.ts', root));
const { businessDefinition } = await importTypescript(new URL('tycoon/FullJourney.ts', root));
const json = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
for (const image of json.images ?? []) image.url = { data: [255, 255, 255, 255], width: 1, height: 1, type: 'Uint8Array' };
const scene = await new ObjectLoader().parseAsync(json);
const cars = [9, 10, 12, 6, 14, 11].map(id => new CarInstance(scene, id));

test('built sales advisor photographs the actual car and Manny sits in it during transfer to the sale point', async () => {
  const oldDocument=globalThis.document;globalThis.document={createElement:()=>new Element()};
  const {TycoonActors}=await importTypescript(new URL('tycoon/TycoonActors.ts',root));
  const {sourcePoint}=await importTypescript(new URL('tycoon/FullJourneyCatalog.ts',root));
  const {worldPoint}=await importTypescript(new URL('tycoon/TycoonCoordinates.ts',root));
  const source=JSON.parse(await readFile(new URL('../public/tycoon/dealership.json',import.meta.url),'utf8'));
  const actors=new TycoonActors(cars,source.parts),s=M.freshJourney(),player=new Vector3();
  try {
    s.cash=100000;s.journey.step=6;s.journey.tutorialComplete=true;s.journey.intakePaused=true;actors.sync(s,player);
    const manny=actors.root.getObjectByName('Manny'),advisor=actors.root.getObjectByName('Sales advisor');
    assert.ok(manny.visible);assert.equal(advisor.visible,false);
    s.journey.step=33;assert.ok(M.arrive(s,4));s.car.status='repair';s.car.route=undefined;s.car.owned=true;s.car.pos=sourcePoint(3055,107);
    s.car.plan={cost:0,seconds:5,funded:true,jobs:[{id:'Mechanical',name:'Engine repair',cost:0,seconds:5,started:true,done:false,progress:.5,manual:true}]};
    actors.sync(s,player);const start=advisor.position.clone();
    for(let i=0;i<60;i++){s.clock+=.1;actors.sync(s,player);}
    assert.ok(advisor.visible);assert.ok(advisor.position.distanceTo(start)>3);assert.equal(advisor.userData.activity,'Preparing listing beside repair');
    assert.equal(manny.userData.activity,'Waiting beside repair for handover');assert.ok(advisor.position.distanceTo(worldPoint(s.car.pos,5.5))<8);
    assert.equal(advisor.getObjectByName('Listing camera').visible,false,'The advisor waits beside unfinished repairs');
    const prepared=advisor.position.clone();s.car.status='ready';s.car.plan.jobs[0].done=true;actors.sync(s,player);
    assert.ok(advisor.position.distanceTo(prepared)<.01,'Photography starts from the prepared position without another walk');assert.equal(advisor.userData.activity,'Photographing and listing');
    assert.ok(advisor.getObjectByName('Listing camera').visible);assert.ok(advisor.getObjectByName('Left arm pivot').rotation.x>1.8);
    assert.equal(actors.root.children.filter(person=>/^sales.?advisor$/i.test(person.name)).length,1,'Imported advisor does not duplicate the active staff member');
    assert.equal(manny.userData.activity,'Collecting car for sale point');
    for(let i=0;i<200&&s.car.status==='ready';i++){M.tick(s,.1);actors.sync(s,player);}
    assert.equal(s.car.route?.target,'sales');assert.ok(s.car.listing);assert.equal(manny.userData.activity,'Driving car to sale point');
    assert.ok(manny.position.distanceTo(worldPoint(s.car.pos,5))<2);assert.equal(manny.getObjectByName('Left leg pivot').rotation.x,Math.PI/2);
    const drivingPosition=manny.position.clone();for(let i=0;i<10;i++){M.tick(s,.1);actors.sync(s,player);}
    assert.ok(manny.position.distanceTo(drivingPosition)>.1);assert.ok(manny.position.distanceTo(worldPoint(s.car.pos,5))<2);
    assert.equal(advisor.getObjectByName('Listing camera').visible,false);
    s.journey.step=60;s.car.status='repair';s.car.route=undefined;
    s.car.plan={cost:0,seconds:5,funded:true,jobs:[{id:'Photo_Listing',name:'Listing photos',cost:0,seconds:5,started:true,done:false,progress:.2,manual:false,staffAt:108}]};
    s.worker.activity='Working';
    for(let i=0;i<100;i++){s.clock+=.1;actors.sync(s,player);}
    assert.equal(advisor.userData.activity,'Photographing and listing');assert.ok(advisor.getObjectByName('Listing camera').visible);
    assert.ok(advisor.getObjectByName('Left arm pivot').rotation.x>1.8,'The advisor photographs the department job too');
    assert.ok(actors.worker.getObjectByName('Left arm pivot').rotation.x<.9,'The mechanic does not perform a repair pose for advisor photography');
  }finally{actors.dispose();globalThis.document=oldDocument;}
});

test('story and recurring flip cars use complete, grounded asset models appropriate to their identity', () => {
  const visual = new TradingCarVisual(cars);
  try {
    for (const [index, modelId, rarity] of [[1, 9, 'COMMON'], [2, 12, 'UNCOMMON'], [3, 10, 'COMMON'], [4, 6, 'RARE']]) {
      const s = M.fresh(); assert.ok(M.arrive(s, index));
      s.car.angle = -Math.PI / 2; const before = JSON.stringify(s);
      visual.sync(s); assert.equal(JSON.stringify(s), before, 'Rendering never changes prices, condition, rarity, or saves');
      assert.equal(M.def(s).rarity, rarity); assert.equal(visual.root.userData.modelId, modelId);
      const model = visual.root.getObjectByName(`Car ${modelId}`);
      assert.ok(model); assert.notEqual(model, cars.find(c => c.id === modelId).car);
      for (const wheel of ['fl', 'fr', 'rl', 'rr']) assert.ok(model.getObjectByName(`Wheel${wheel}${modelId}`).visible);
      const bounds = new Box3().setFromObject(visual.root);
      assert.ok(Math.abs(bounds.min.y - .47) < 1e-5, 'Tires rest on the dealership surface');
      assert.ok(bounds.getSize(new Vector3()).x > 15, 'Actual full-size car geometry replaces the eight-unit box');
      assert.ok(new Vector3(0, 0, -1).applyQuaternion(visual.root.quaternion).distanceTo(new Vector3(1, 0, 0)) < 1e-6, 'Nose faces route travel');
    }
    const seen = new Set();
    for (let cycle = 0; cycle < 4; cycle++) {
      const s = M.freshJourney(); s.journey.step = 240; s.journey.tutorialComplete = true; s.journey.cycle = cycle;
      const expected = businessDefinition(s); assert.ok(M.arriveBusiness(s)); visual.sync(s);
      const ids = { Rusty: 9, HondoCivixEK: 10, Bavora: 14, Gblock: 11 };
      assert.equal(visual.root.userData.modelId, ids[expected.templateId]); seen.add(expected.templateId);
    }
    assert.equal(seen.size, 4);
    visual.sync(M.fresh()); assert.equal(visual.root.visible, false);
  } finally { visual.dispose(); }
});

test('tutorial wheel repair, custom previews and disposal preserve the garage source models', () => {
  const visual = new TradingCarVisual(cars), s = M.freshJourney(); s.journey.step = 2;
  assert.ok(M.arriveBusiness(s)); visual.sync(s);
  const model = visual.root.getObjectByName('Car 9'), wheel = model.getObjectByName('Wheelfl9');
  const source = cars.find(car => car.id === 9).cloneModel(), sourceShell = source.getObjectByName('Chassis3');
  const body = model.getObjectByName('Chassis3'), originalColor = sourceShell.material.color.clone();
  let sharedDisposals = 0, materialDisposals = 0;
  source.traverse(object => {
    if (!(object instanceof Mesh)) return;
    object.geometry.addEventListener('dispose', () => sharedDisposals++);
    object.material.addEventListener('dispose', () => sharedDisposals++);
    object.material.map?.addEventListener('dispose', () => sharedDisposals++);
  });
  body.material.addEventListener('dispose', () => materialDisposals++);
  assert.equal(wheel.visible, false); assert.ok(source.getObjectByName('Wheelfl9').visible);
  s.car.condition.RunningGear = 'Good'; visual.sync(s); assert.ok(wheel.visible);
  assert.equal(visual.root.getObjectByName('Car 9'), model, 'Repair reuses the same model');
  const before = body.material.color.clone();
  visual.sync(s, { paint: 'blue', wheels: 'sport', stripe: true });
  assert.ok(!body.material.color.equals(before)); assert.ok(sourceShell.material.color.equals(originalColor));
  assert.equal(body.geometry, sourceShell.geometry); assert.equal(body.material.map, sourceShell.material.map);
  assert.notEqual(body.material, sourceShell.material);
  const stripes = visual.root.children.filter(child => child.name === 'Trading stripe');
  assert.ok(stripes.length && stripes.every(stripe => stripe.visible && stripe.geometry.attributes.position.count > 0));
  visual.sync(s); assert.ok(body.material.color.equals(before)); assert.ok(stripes.every(stripe => !stripe.visible));
  s.car = undefined; s.cash = 10000; assert.ok(M.arrive(s, 4)); visual.sync(s);
  assert.equal(materialDisposals, 1, 'Replacing a deal disposes its private materials');
  visual.dispose(); assert.equal(sharedDisposals, 0, 'Shared asset geometry, materials and textures stay alive');
});
