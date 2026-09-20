import test from 'node:test';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const M = await importTypescript(new URL('TycoonModel.ts', root));
const P = await importTypescript(new URL('PartsEconomy.ts', root));
const J = await importTypescript(new URL('FullJourney.ts', root));
const { PART_SHOPS, COURIER_DEPOT } = await importTypescript(new URL('../TownPlaces.ts', root));
const { TycoonSession } = await importTypescript(new URL('TycoonSession.ts', root));
const { validState } = await importTypescript(new URL('TycoonSave.ts', root));

test('Parts replace one fifth of a repair bill and insufficient stock never partially charges', () => {
  const s = M.fresh(), plan = P.pricePlan({ jobs: [], cost: 500, seconds: 20 });
  assert.deepEqual(P.repairCost(plan), { cash: 400, parts: 10, total: 500 });
  s.partsStock = 9; const cash = s.cash;
  assert.equal(P.fundRepair(s, plan), false); assert.equal(s.cash, cash); assert.equal(s.partsStock, 9);
  s.partsStock = 10; assert.ok(P.fundRepair(s, plan)); assert.equal(s.cash, cash - 400); assert.equal(s.partsStock, 0);
});

test('one missing Part reserves a purchasable $100 bundle for acquisition, repairs, and Phoenix', () => {
  for (const [required, stock, expected] of [[10, 10, 0], [10, 11, 0], [10, 9, 100], [10, 0, 100], [11, 0, 200]]) {
    assert.equal(P.restockBudget(required, stock), expected);
  }
  const s = M.freshJourney(); s.journey.step = 22; s.journey.tutorialComplete = true; s.cash = 100000;
  assert.ok(M.arriveBusiness(s)); s.car.status = 'seller'; assert.ok(M.openDeal(s));
  const work = P.repairCost(M.workQuote(s)), price = s.car.quote.accepted;
  s.partsStock = work.parts - 1; s.cash = price + work.cash + 99;
  assert.equal(M.buy(s), false, 'A hypothetical single-Part purchase cannot fund the repair');
  assert.equal(s.cash, price + work.cash + 99); assert.equal(s.partsStock, work.parts - 1);
  s.cash++; assert.ok(M.buy(s)); assert.equal(M.reserve(s), work.cash + 100);
  assert.ok(P.buyParts(s, 'small')); assert.equal(M.reserve(s), work.cash);
  assert.ok(M.plan(s, 'Quick')); assert.equal(s.cash, 0); assert.equal(s.partsStock, 9);

  const phoenix = M.freshJourney(); phoenix.journey.step = 22; phoenix.journey.tutorialComplete = true; phoenix.cash = 100000;
  assert.ok(M.arrive(phoenix, 4));
  const phoenixWork = P.repairCost(M.workQuote(phoenix)); phoenix.partsStock = phoenixWork.parts - 1;
  const required = M.PHOENIX_PRICE + phoenixWork.cash + 100;
  phoenix.cash = required - 1;
  assert.deepEqual(M.leadBudget(phoenix, false), [required, 1]);
  assert.deepEqual(M.leadBudget(phoenix, true), [required - 300, 0]);
  assert.equal(M.reserve(phoenix), required, 'An unowned Phoenix protects the actual shop-bundle repair budget');
  phoenix.car.status = 'seller'; assert.ok(M.openDeal(phoenix)); phoenix.car.quote.accepted -= 100;
  assert.equal(M.reserve(phoenix), required - 100, 'The reserve follows negotiated acquisition terms');
});

test('shop and courier hiring authority requires a valid package and nearby on-foot player', () => {
  const s = M.fresh(), session = new TycoonSession(s), shop = PART_SHOPS[0];
  const action = { type: 'BuyParts', shopId: shop.id, packageId: 'crate' };
  assert.equal(session.dispatch(action, { position: [0, 0], onFoot: true }).ok, false);
  assert.equal(session.dispatch(action, { position: shop.position, onFoot: false }).ok, false);
  assert.equal(session.dispatch({ ...action, packageId: 'forged' }, { position: shop.position, onFoot: true }).ok, false);
  assert.ok(session.dispatch(action, { position: shop.position, onFoot: true }).ok);
  assert.equal(s.partsStock, 90); assert.equal(s.cash, 6550);
  assert.ok(session.dispatch({ type: 'HireCourier' }, { position: COURIER_DEPOT.position, onFoot: true }).ok);
  assert.equal(s.cash, 5950); assert.ok(validState(s));
});

test('delivery driver pays once, visits a shop, returns, and credits persisted cargo once', () => {
  const s = M.fresh(); s.partsStock = 0; assert.ok(P.hireCourier(s));
  P.tickCouriers(s, 2); assert.equal(s.cash, 6000); assert.equal(s.couriers[0].cargo, 50);
  const resumed = M.copy(s); assert.ok(validState(resumed));
  const phases = new Set();
  for (let i = 0; i < 20000 && resumed.couriers[0].trips === 0; i++) { phases.add(resumed.couriers[0].phase); P.tickCouriers(resumed, .1); }
  assert.equal(resumed.couriers[0].trips, 1); assert.equal(resumed.partsStock, 50); assert.equal(resumed.cash, 6000);
  assert.ok(phases.has('outbound') && phases.has('loading') && phases.has('returning') && phases.has('unloading'));
  P.tickCouriers(resumed, 1); assert.equal(resumed.partsStock, 50); assert.ok(validState(resumed));
});

test('couriers preserve a cash buffer, stop at stock capacity, and reject forged saved cargo', () => {
  const s = M.fresh(); assert.ok(P.hireCourier(s)); s.cash = 899; P.tickCouriers(s, 10);
  assert.equal(s.couriers[0].phase, 'idle'); assert.equal(s.cash, 899);
  s.cash = 5000; s.partsStock = 150; P.tickCouriers(s, 10); assert.equal(s.cash, 5000);
  s.couriers[0].cargo = -50; assert.equal(validState(s), false);
});

test('business tiers consume Parts while consignment cash is paid from sale proceeds', () => {
  for (const step of [6, 40, 90, 140, 240]) {
    const s = M.freshJourney(); s.journey.step = step; s.journey.tutorialComplete = true; s.cash = 100000;
    assert.ok(M.arriveBusiness(s)); s.car.status = 'seller'; M.openDeal(s); assert.ok(M.buy(s));
    const q = M.workQuote(s); assert.ok(q.partsCost > 0); assert.equal(q.cost, q.cashCost + q.partsCost * 10);
    assert.ok(q.cost > 0 && J.workPlan(s).cost === q.cost);
  }
  const s = M.freshJourney(); s.journey.step = 6; s.journey.tutorialComplete = true; s.cash = 0;
  assert.ok(M.arriveBusiness(s)); s.car.status = 'seller'; M.openDeal(s); assert.ok(M.buy(s)); assert.ok(M.plan(s, 'Quick'));
  assert.equal(s.cash, 0); assert.ok(s.car.plan.deferredCash > 0); assert.ok(validState(s));
  s.car.plan.jobs.forEach(j => { j.started = j.done = true; j.progress = 1; });
  s.car.status = 'buyer'; M.openDeal(s); const sale = s.car.quote.accepted, debt = s.car.plan.deferredCash;
  assert.ok(M.sell(s)); assert.equal(s.cash, sale - debt); assert.equal(s.car.plan.deferredCash, undefined);
});
