import test from 'node:test';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const M = await importTypescript(new URL('TycoonModel.ts', root));
const { TycoonSession } = await importTypescript(new URL('TycoonSession.ts', root));
const { TycoonSave, validState } = await importTypescript(new URL('TycoonSave.ts', root));
const { garageVehicles } = await importTypescript(new URL('PersonalCars.ts', root));
function readyCar(s) {
  assert.ok(M.arriveBusiness(s));
  Object.assign(s.car, { owned: true, status: 'moving', pos: [0, 0], purchase: 200, route: { target: 'sales', points: [[0,0],[10,0]], step: 1 },
    plan: { cost: 100, seconds: 2, funded: true, jobs: [{ id: 'Mechanical', name: 'Engine', cost: 100, seconds: 2, started: true, done: true, progress: 1 }] } });
  s.car.business.templateId = 'Rusty'; s.car.business.consignment = false;
  return s.car;
}
function state() { const s = M.freshJourney(); s.journey.step = 40; s.journey.tutorialComplete = true; s.journey.intakePaused = true; s.journey.automation = false; s.cash = 100000; return s; }
const nearby = { position: [0, 0], onFoot: true };

test('keeping a car requires the current completed sales transfer, proximity and an on-foot player', () => {
  const s = state(), c = readyCar(s), session = new TycoonSession(s), action = { type: 'KeepCar', carId: c.id };
  for (const context of [{ ...nearby, onFoot: false }, { ...nearby, position: [100, 0] }]) assert.equal(session.dispatch(action, context).ok, false);
  assert.equal(session.dispatch({ ...action, carId: 'stale' }, nearby).ok, false);
  c.route.target = 'repair'; assert.equal(session.dispatch(action, nearby).ok, false); c.route.target = 'sales';
  c.plan.jobs[0].done = false; assert.equal(session.dispatch(action, nearby).ok, false); c.plan.jobs[0].done = true;
  const cash = s.cash; assert.ok(session.dispatch(action, nearby).ok);
  assert.equal(s.car, undefined); assert.equal(s.personal, undefined, 'Stored cars wait for an explicit spawn');
  assert.equal(s.cash, cash); assert.equal(s.sales, 0, 'Keeping never awards a fake sale');
  assert.equal(s.garage.length, 1); assert.equal(s.garage[0].modelId, 9); assert.equal(s.history[0].keptAs, s.garage[0].name);
  assert.equal(session.dispatch(action, nearby).ok, false, 'Repeated input cannot duplicate ownership');
  assert.ok(validState(s));
});

test('same-model cars retain distinct generated names, individual paint and identities through saves and respawns', () => {
  const s = state();
  for (let i = 0; i < 3; i++) { const c = readyCar(s); assert.ok(M.keepCar(s, c.id)); }
  assert.equal(new Set(s.garage.map(c => c.name)).size, 3); assert.equal(new Set(s.garage.map(c => c.id)).size, 3);
  assert.equal(new Set(s.garage.map(c => c.modelId)).size, 1);
  const [first, second] = s.garage;
  assert.ok(M.paintPersonal(s, first.id, '#357dc3')); assert.ok(M.paintPersonal(s, second.id, '#b54736'));
  assert.equal(M.paintPersonal(s, first.id, 'javascript:invalid'), false);
  assert.ok(M.spawnPersonal(s, first.id)); const old = s.personal;
  assert.ok(M.spawnPersonal(s, second.id)); assert.notEqual(s.personal, old); assert.equal(s.personal.id, second.id);
  assert.deepEqual(s.personal.ownedModels, [9]);
  const records = new Map(), save = new TycoonSave({ getItem: k => records.get(k) ?? null, setItem: (k,v) => records.set(k,v), removeItem: k => records.delete(k) }, { sessionId: 'collection' });
  assert.ok(save.write(s)); const loaded = save.load(); assert.deepEqual(loaded.garage, s.garage);
  assert.ok(M.spawnPersonal(loaded, first.id)); assert.equal(garageVehicles(loaded)[0].paint, '#357dc3');
  const names = loaded.garage.map(c => c.name); const c = readyCar(loaded); assert.ok(M.keepCar(loaded, c.id));
  assert.equal(loaded.garage.length, 4); assert.ok(!names.includes(loaded.garage[3].name));
  assert.equal(validState({ ...loaded, garage: [first, { ...second, id: first.id }] }), false);
});

test('legacy model ownership projects into the collection without losing the old selected car', () => {
  const s = state(); s.personal = { id: 'old-selected', modelId: 12, ownedModels: [9, 12], pos: [0,0], home: [0,0], status: 'parked' };
  const cars = garageVehicles(s); assert.deepEqual(cars.map(c => c.modelId), [9,12]);
  assert.ok(M.spawnPersonal(s, cars[0].id)); assert.equal(s.garage.length, 2);
  assert.ok(M.spawnPersonal(s, 'old-selected')); assert.equal(s.personal.modelId, 12);
});

test('consignment ownership and deferred repair bills settle exactly once before storage', () => {
  const s = state(), c = readyCar(s); c.business.consignment = true; c.plan.deferredCash = 75;
  const cost = M.keepCarCost(s); assert.ok(cost > 75); s.cash = cost - 1;
  assert.equal(M.keepCar(s, c.id), false); assert.equal(s.car, c); assert.equal(s.garage, undefined);
  s.cash = cost; assert.ok(M.keepCar(s, c.id)); assert.equal(s.cash, 0);
  assert.equal(s.history[0].plan.deferredCash, undefined); assert.equal(s.ledger.at(-1).amount, -cost);
});

test('a hired mechanic plans, orders missing Parts and completes every repair with no player actions', () => {
  const s = state(); assert.ok(M.arriveBusiness(s));
  Object.assign(s.car, { owned: true, status: 'choose', route: undefined }); s.car.business.consignment = false; s.partsStock = 0;
  for (let i = 0; i < 10000 && !M.canKeepCar(s); i++) M.tick(s, .1);
  assert.ok(M.canKeepCar(s), JSON.stringify({ status: s.car.status, job: M.job(s), worker: s.worker }));
  assert.ok(s.car.plan.jobs.every(j => j.done && j.manual === false));
  assert.equal(s.ledger.filter(e => e.subject === 'Mechanic ordered repair Parts').length, 1);
  assert.equal(s.ledger.filter(e => e.kind === 'work').length, 1);
  assert.equal(s.journey.automation, false, 'Deal automation remains independently controlled');
});
