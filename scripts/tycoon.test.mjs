import { exerciseManualRepair } from './repair-test-driver.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { importTypescript } from './import-typescript.mjs';
const M = await importTypescript(new URL('../src/world/tycoon/TycoonModel.ts', import.meta.url));
const E = await importTypescript(new URL('../src/world/tycoon/PartsEconomy.ts', import.meta.url));
const { RESIDENTIAL_PARKING, RESIDENTIAL_SELLER } = await importTypescript(new URL('../src/world/TownPlaces.ts', import.meta.url));
const visitArrival = s => { s.personal.pos = [...RESIDENTIAL_PARKING]; assert.ok(M.updatePersonalTravel(s, RESIDENTIAL_SELLER, true)); };
const homeArrival = s => { s.personal.pos = [...s.personal.home]; assert.ok(M.updatePersonalTravel(s, s.personal.home, true)); };
const { catalog } = await importTypescript(new URL('../src/world/tycoon/catalog.ts', import.meta.url));
const { TycoonSession } = await importTypescript(new URL('../src/world/tycoon/TycoonSession.ts', import.meta.url));
const { TycoonSave } = await importTypescript(new URL('../src/world/tycoon/TycoonSave.ts', import.meta.url));
const { partPose, openingStep } = await importTypescript(new URL('../src/world/tycoon/BuildingProgression.ts', import.meta.url));
const reference = JSON.parse(await readFile(new URL('./fixtures/tycoon-roblox.json', import.meta.url), 'utf8'));
const scene = JSON.parse(await readFile(new URL('../public/tycoon/dealership.json', import.meta.url), 'utf8'));
function untilState(s, fn) { for (let i = 0; i < 30000; i++) { if (fn()) return; M.tick(s, .1, 1); } assert.fail(`Timed out: ${s.car?.status}`); }
function normalize(value) {
  if (typeof value === 'number') return Math.round(value * 1e8) / 1e8;
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).filter(([,v]) => v !== undefined).map(([k,v]) => [k, normalize(v)]));
  return value;
}
test('four-car journey preserves source required repairs, prices and sale history with explicit Parts and randomized work substitutions', () => {
  const s = M.fresh(), snapshots = [], phoenixPurchase=M.phoenixDefinition().floor-300+150;
  const snap = name => { const c = s.car; snapshots.push(M.copy({ name, cash: s.cash, sales: s.sales, pads: s.pads, worker: { level: s.worker.level, jobs: s.worker.jobs }, completed: s.completed,
    car: c && { id: c.id, index: c.index, status: c.status, purchase: c.purchase, workSpent: c.workSpent, condition: c.condition }, history: s.history, ledger: s.ledger })); };
  const pad = id => assert.ok(M.buyPad(s, id), id);
  const buy = price => { untilState(s, () => s.car.status === 'seller'); assert.ok(M.openDeal(s)); assert.ok(M.counter(s, price)); assert.ok(M.buy(s)); };
  const manual = () => { untilState(s, () => s.car.status === 'repair'); while (s.car.status === 'repair') { const j = M.job(s); if (j && !j.started) assert.ok(M.startJob(s)); exerciseManualRepair(s); M.tick(s, .1, 1); } };
  const sell = price => { untilState(s, () => s.car.status === 'buyer'); assert.ok(M.openDeal(s)); assert.ok(M.counter(s, price)); assert.ok(M.sell(s)); untilState(s, () => !s.car); };
  pad('lot'); pad('intake'); buy(850); for (const id of ['repairbay', 'tools', 'power', 'air']) pad(id); manual(); pad('sales'); pad('salesdesk'); sell(2450); snap('first-sale');
  pad('finish'); assert.ok(M.arrive(s, 2)); buy(1200); assert.ok(M.plan(s, 'Good')); manual(); untilState(s, () => s.car.status === 'photo');
  assert.ok(M.customize(s, { paint: 'blue', wheels: 'sport', stripe: true })); assert.ok(M.list(s)); assert.ok(M.openDeal(s)); snap('lowball'); assert.ok(M.decline(s)); sell(3450); snap('second-sale');
  pad('mechanic'); assert.ok(M.arrive(s, 3)); buy(1000); assert.ok(M.plan(s, 'Quick')); untilState(s, () => s.car.status === 'photo'); assert.ok(M.upgrade(s)); assert.ok(M.list(s)); sell(2200); snap('automated-sale');
  pad('restoration'); pad('display'); untilState(s, () => !!s.lead); assert.ok(M.visit(s)); visitArrival(s); untilState(s, () => s.car?.status === 'discovery'); M.discover(s); buy(phoenixPurchase); homeArrival(s);
  untilState(s, () => s.personal.status === 'parked' && s.car.status === 'choose'); while(E.partsStock(s)<E.repairCost(M.workQuote(s)).parts) assert.ok(E.buyParts(s,'small')); assert.ok(M.plan(s, 'Quick')); untilState(s, () => s.car.status === 'photo'); assert.ok(M.list(s)); sell(7650); snap('rare-sale');
  for (const [i, snapshot] of snapshots.entries()) {
    const source = M.copy(reference[i]), actual = M.copy(snapshot);
    if(i===4){
      const phoenix=source.history.at(-1),oldPrice=phoenix.purchase;source.cash+=oldPrice-phoenixPurchase;
      source.ledger.filter(e=>e.kind==='car').at(-1).amount=-phoenixPurchase;
      phoenix.purchase=phoenixPurchase;phoenix.history=phoenix.history.map(line=>line===('Bought for $'+oldPrice)?'Bought for $'+phoenixPurchase:line);
    }
    const purchases = actual.ledger.filter(e=>e.kind==='parts-purchase').reduce((sum,e)=>sum-e.amount,0);
    const sourceWork = source.ledger.filter(e=>e.kind==='work');
    const actualWork = actual.ledger.filter(e=>e.kind==='work');
    assert.equal(actualWork.length,sourceWork.length);
    let substitution=0;
    for(const [index,entry] of sourceWork.entries()) {
      const parts=Math.floor(-entry.amount*.2/10); substitution+=parts*10;
      assert.equal(actualWork[index].amount,entry.amount+parts*10,'20% of work value consumes Parts');
      actualWork[index].amount=entry.amount;actualWork[index].subject=entry.subject;
    }
    assert.equal(actual.cash,source.cash+substitution-purchases,'Cash delta is fully explained by Parts');
    actual.cash=source.cash;actual.ledger=actual.ledger.filter(e=>e.kind!=='parts-purchase');
    for(const [index,car] of actual.history.entries()){
      const original=source.history[index],plan=car.plan,quoted=original.plan;
      assert.equal(plan.cost,quoted.cost);assert.equal(plan.seconds,quoted.seconds);
      assert.equal(plan.jobs.reduce((sum,j)=>sum+j.cost,0),quoted.cost);
      assert.ok(Math.abs(plan.jobs.reduce((sum,j)=>sum+j.seconds,0)-quoted.seconds)<1e-8);
      assert.equal(plan.pricedServices,quoted.jobs.filter(j=>j.id!=='Tune').length);
      for(const required of quoted.jobs){
        const performed=plan.jobs.find(j=>j.id===required.id);assert.ok(performed,'All original required repairs remain in the accepted order');
        assert.equal(performed.done,required.done);assert.equal(performed.progress,required.progress);assert.equal(performed.speed,required.speed);
      }
      for(const task of plan.jobs){assert.ok(task.done&&task.started&&task.progress===1);assert.equal(car.history.filter(event=>event===task.name+' completed').length,1);}
      plan.jobs=M.copy(quoted.jobs);delete plan.pricedServices;
      car.history=car.history.filter(event=>!event.endsWith(' completed'));original.history=original.history.filter(event=>!event.endsWith(' completed'));
    }
    const gameplay = value => {
      if(Array.isArray(value))return value.map(gameplay);
      if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).filter(([key])=>!['receiptUntil','angle','pos','repair','manual','cashCost','partsCost'].includes(key)).map(([key,v])=>[key,gameplay(v)]));
      return value;
    };
    assert.deepEqual(normalize(gameplay(actual)),normalize(gameplay(source)));
  }
  assert.ok(s.cash>=10220); assert.equal(s.completed, true); assert.equal(s.sales, 4);
  for (const id of ['shade','servicefloor','carbuyer','salesrep','wheeltools','fluidkit','finishtrolley','partsshelves']) pad(id);
  assert.equal(s.pads.length, 20, 'Every source purchase is reachable after the four-car journey');
  assert.equal(s.cash, 7000 + s.ledger.reduce((n, e) => n + e.amount, 0));
});
test('authority boundary rejects distant, seated, stale and duplicate transactions', () => {
  const session = new TycoonSession(), s = session.state;
  assert.equal(session.dispatch({ type: 'Pad', id: 'lot' }, { position: [50, 50], onFoot: true }).ok, false);
  assert.equal(session.dispatch({ type: 'Pad', id: 'lot' }, { position: [0, 0], onFoot: false }).ok, false);
  for (const id of ['lot', 'intake']) assert.ok(session.dispatch({ type: 'Pad', id }, { position: catalog.pads.find(p => p.id === id).pos, onFoot: true }).ok);
  untilState(s, () => s.car.status === 'seller'); const context = { position: [-6, -5.33333], onFoot: true };
  assert.ok(session.dispatch({ type: 'Deal' }, context).ok);
  const stale = { type: 'Accept', carId: s.car.id, revision: 0, amount: 900 };
  assert.ok(session.dispatch({ type: 'Counter', carId: s.car.id, revision: 0, amount: 850 }, context).ok);
  assert.equal(session.dispatch(stale, context).ok, false);
  const accept = { ...stale, revision: 1, amount: 850 };
  assert.ok(session.dispatch(accept, context).ok); const cash = s.cash;
  assert.equal(session.dispatch(accept, context).ok, false); assert.equal(s.cash, cash);
  assert.equal(M.counter(s, NaN), false); assert.equal(M.pay(s, Infinity, 'x', 'x'), false);
});
test('work reserves prevent optional spending and job plans are charged only once', () => {
  const s = M.fresh(); s.pads = ['lot','intake','repairbay','tools','power','air','sales','salesdesk','finish']; s.sales = 3;
  M.arrive(s, 3); untilState(s, () => s.car.status === 'seller'); M.openDeal(s); M.buy(s);
  s.cash = E.repairCost(M.workQuote(s)).cash;
  assert.equal(M.buyPad(s, 'shade'), false); assert.equal(s.cash, 280);
  assert.ok(M.plan(s, 'Quick')); assert.equal(s.cash, 0); assert.equal(M.reserve(s), 0);
  assert.equal(M.plan(s, 'Quick'), false); untilState(s, () => s.car.status === 'repair');
  assert.ok(M.startJob(s)); assert.equal(M.startJob(s), false); assert.equal(s.cash, 0);
});
test('rare invite and visited-lead budgets, decline/return, and recovery flips remain available', () => {
  const s = M.fresh(); s.pads = catalog.pads.filter(p => !p.optional).map(p => p.id); s.sales = 3;
  s.worker.hired = true; s.personal = { id: 'your-coupe', pos: [...catalog.points.garage], home: [...catalog.points.garage], status: 'parked' }; M.lead(s);
  const visitBudget=M.leadBudget(s,true)[0];s.cash = visitBudget-1; assert.equal(M.visit(s), false); assert.equal(M.arrive(s, 4), false);
  s.cash = visitBudget; assert.ok(M.visit(s)); visitArrival(s); untilState(s, () => s.car?.status === 'discovery'); M.discover(s);
  assert.equal(M.terms(s).ask, M.PHOENIX_PRICE-300); assert.ok(M.leave(s)); homeArrival(s); untilState(s, () => s.personal.status === 'parked'); assert.equal(s.lead.status, 'missed');
  const session = new TycoonSession(s); s.cash = M.leadBudget(s,false)[0]-1; assert.ok(session.dispatch({ type: 'Recovery' }, { position: [0,0], onFoot: true }).ok); assert.equal(s.car.index, 3);
});
test('saves resume paid work/routes without repeating charges and reject malformed snapshots', () => {
  let raw = null; const storage = { getItem: () => raw, setItem: (_, value) => { raw = value; } }, save = new TycoonSave(storage, { legacy: true });
  const s = M.fresh(); s.pads = ['lot','intake','air','sales','salesdesk']; M.arrive(s, 1); untilState(s, () => s.car.status === 'seller'); M.openDeal(s); M.buy(s); M.plan(s, 'Quick');
  M.tick(s, .1); assert.ok(save.write(s)); let restored = save.load(); assert.deepEqual(restored, M.copy(s));
  untilState(restored, () => restored.car.status === 'repair'); M.startJob(restored); M.tick(restored, .1); save.write(restored); restored = save.load();
  const cash = restored.cash; assert.equal(M.startJob(restored), false); M.tick(restored, .1); assert.equal(restored.cash, cash);
  for (const invalid of ['not json', JSON.stringify({version:99,state:s}), JSON.stringify({version:1,state:{...s,cash:-1}}), JSON.stringify({version:1,state:{...s,car:{...s.car,condition:null}}})]) { raw = invalid; assert.deepEqual(save.load(), M.fresh()); }
  assert.equal(new TycoonSave({getItem(){throw Error();},setItem(){throw Error();}}).write(s), false);
});
test('all 25,446 authored pieces and all 240 progression entries survive export', async () => {
  assert.equal(scene.parts.length, 25446); assert.equal(new Set(scene.parts.map(p => p.id)).size, 25446);
  const journey = JSON.parse(await readFile(new URL('../public/tycoon/journey.json', import.meta.url), 'utf8'));
  assert.equal(journey.Entries.length, 240); assert.equal(new Set(journey.Entries.map(e => e.id)).size, 240);
  for (const n of [0,1,24,64,140,196,229,230,233,235,240]) {
    let visible = 0;
    for (const part of scene.parts) { const p = partPose(part, n); assert.ok([...p.cf,...p.size,...p.color].every(Number.isFinite), part.path); assert.ok(p.size.every(n => n > 0)); if (p.visible && p.transparency < 1) visible++; }
    assert.ok(visible > 0, `Stage ${n} has visible geometry`);
  }
});
test('opening ownership keeps optional tools and shelter hidden and preserves source pad filtering', () => {
  const s = M.fresh(); s.pads = ['lot','intake','repairbay','tools','power','air'];
  assert.equal(openingStep(s), 16);
  for (const part of scene.parts) {
    if ([4,5,6,7,8,9,10,11,12,13,14].includes(part.attributes.FJ_First)) assert.equal(partPose(part, 16, s).visible, false, part.path);
  }
  const shelter = scene.parts.find(p => p.attributes.FJ_First === 13 && p.attributes.FJ_Transparency === 0);
  assert.ok(shelter); s.pads.push('shade'); assert.equal(partPose(shelter, 16, s).visible, true);
});
