import { exerciseManualRepair } from './repair-test-driver.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const M = await importTypescript(new URL('TycoonModel.ts', root));
const F = await importTypescript(new URL('FullJourneyCatalog.ts', root));
const J = await importTypescript(new URL('FullJourney.ts', root));
const O = await importTypescript(new URL('OfflineEarnings.ts', root));
const E = await importTypescript(new URL('PartsEconomy.ts', root));
const P = await importTypescript(new URL('PartsStation.ts', root));
const {workOrderRange}=await importTypescript(new URL('RepairWorkOrders.ts',root));
const { TycoonSession, actorPosition } = await importTypescript(new URL('TycoonSession.ts', root));
const { TycoonSave, SAVE_KEY, LEGACY_SAVE_KEY, validState } = await importTypescript(new URL('TycoonSave.ts', root));
const fixture = JSON.parse(await readFile(new URL('./fixtures/sell-cars-catalog.json', import.meta.url), 'utf8'));
function until(s, condition, act = () => {}) {
  for (let i = 0; i < 40000; i++) { if (condition()) return; act(); exerciseManualRepair(s); M.tick(s, .1, 0, s.parts?.manual === true); }
  assert.fail('Timed out: ' + JSON.stringify({ step:s.journey.step, car:s.car?.status, job:M.job(s), worker:s.worker, cash:s.cash }));
}
const pad = s => { const p = J.purchasePad(s); assert.ok(p); assert.ok(M.buyPad(s, p.id), p.name + ': ' + s.notice); };
function finishCar(s) {
  until(s, () => !s.car, () => {
    const c = s.car; if (!c) return;
    if (['seller', 'buyer'].includes(c.status)) { M.openDeal(s); assert.ok(c.status === 'seller' ? M.buy(s) : M.sell(s)); }
    if (c.status === 'choose') {
      while(!c.plan && E.partsStock(s)<E.repairCost(M.workQuote(s)).parts) {
        while(s.cash<100) {
          if(P.partsAutomated(s)) until(s,()=>s.cash>=100);
          else { if(s.parts.remaining===undefined) assert.ok(P.startParts(s),'Parts laptop provides recovery cash'); assert.ok(P.completeHillRun(s, 50)); }
        }
        if (c.plan) break;
        assert.ok(E.buyParts(s,'small'), 'Business earnings can replenish repair Parts');
      }
      if (!c.plan) assert.ok(M.plan(s, 'Quick'));
    }
    if (c.status === 'photo') assert.ok(M.list(s));
    if (c.status === 'repair' && M.job(s) && !M.job(s).started && !M.staffedJob(s)) assert.ok(M.startJob(s));
  });
}
function tutorial() {
  const s = M.freshJourney(); s.journey.intakePaused = true;
  pad(s); pad(s); until(s, () => s.car.status === 'seller');
  assert.equal(M.buyPad(s, F.entries[2].id), false);
  M.openDeal(s); assert.equal(s.car.quote.accepted, 25); assert.ok(M.buy(s));
  pad(s); assert.equal(M.buyPad(s, F.entries[3].id), false);
  until(s, () => s.car.status === 'ready', () => { if (s.car.status === 'repair' && !M.job(s)?.started) assert.ok(M.startJob(s)); });
  pad(s); pad(s); pad(s);
  until(s, () => s.car.status === 'buyer'); M.openDeal(s);
  assert.equal(s.car.quote.accepted, 1000); assert.ok(M.sell(s)); until(s, () => !s.car);
  return s;
}
test('all 240 costs, stable IDs, pad coordinates and 241 capability states match executable Sell Cars Luau', () => {
  assert.equal(F.entries.length, 240);
  for (let i = 0; i < 240; i++) {
    const e = F.entries[i], source = fixture.entries[i];
    const { padPosition, ...sourceFields } = source;
    const {title,benefit,...stable}=sourceFields;
    assert.deepEqual({id:e.id,step:e.step,cost:e.cost,unlocks:e.unlocks},stable);
    if([31,32,128,133,140,143].includes(e.step))assert.match(e.title,/Customer parking/);
    else if(e.step===6)assert.match(e.title,/Manny/);
    else {assert.equal(e.title,title);assert.equal(e.benefit,benefit);}
    e.padPosition.forEach((v,i) => assert.ok(Math.abs(v-padPosition[i]) < 1e-5, 'Vector3 float precision'));
  }
  for (let n = 0; n <= 240; n++) assert.deepEqual(F.capabilities(n), fixture.capabilities[n]);
});
test('source Rusty onboarding retains its gates, $25 acquisition, two free repairs and $1000 first sale', () => {
  const s = tutorial();
  assert.equal(s.cash, 1225); assert.equal(s.sales, 1); assert.equal(s.journey.step, 6); assert.equal(s.journey.tutorialComplete, true);
  assert.deepEqual(s.history[0].plan.jobs.map(j => j.id).sort(), ['Mechanical', 'RunningGear']);
  assert.equal(s.history[0].workSpent, 0); assert.ok(validState(s));
  assert.equal(s.cash, 400 + s.ledger.reduce((sum, e) => sum + e.amount, 0));
});
test('functional progression reaches step240 from business earnings without buying cosmetics', () => {
  const s = tutorial();
  while (s.journey.step < 240) {
    const cost = F.nextEntry(s.journey.step).cost;
    let loops = 0;
    while (s.cash < cost + M.reserve(s)) { assert.ok(++loops < 30); assert.ok(M.arriveBusiness(s)); finishCar(s); }
    pad(s);
  }
  assert.equal(s.journey.step, 240); assert.equal(J.purchasePad(s), undefined);assert.deepEqual(s.journey.cosmetics,[],'Every functional purchase remains reachable with no cosmetics');
  assert.ok(s.sales > 10); assert.ok(s.worker.hired); assert.ok(s.personal);
  assert.ok(M.arriveBusiness(s));const quote=M.workQuote(s),range=workOrderRange(quote,'Quick',s.car.condition);finishCar(s);
  const accepted=s.history.at(-1).plan;assert.ok(accepted.jobs.length>=range.min&&accepted.jobs.length<=range.max);
  assert.equal(accepted.pricedServices,quote.jobs.filter(job=>job.id!=='Tune').length);assert.equal(accepted.cost,quote.cost);
  assert.equal(s.cash, 400 + s.ledger.reduce((sum, e) => sum + e.amount, 0));
  assert.ok(validState(s));
});
test('consignment prevents bankruptcy; no-income refusal does not count as a sale', () => {
  const s = tutorial(); s.cash = 0; assert.ok(M.arriveBusiness(s)); until(s, () => s.car.status === 'seller');
  assert.equal(M.terms(s).ask, 0); assert.ok(s.car.business.consignment);
  const before = s.sales; assert.ok(M.decline(s)); until(s, () => !s.car); assert.equal(s.sales, before); assert.equal(s.cash, 0);
  assert.ok(M.arriveBusiness(s)); finishCar(s); assert.equal(s.sales, before + 1);
  assert.equal(s.history.at(-1).sale - s.history.at(-1).workSpent, F.operationProfit(6, 3, true));
  assert.equal(s.cash, s.ledger.filter(e=>['sale','work'].includes(e.kind)).slice(-3).reduce((sum,e)=>sum+e.amount,0), 'Consignment cash settlement includes repair reimbursement');
});
test('hired staff complete recurring source deals, while toggled manual mode waits for the player', () => {
  const s = tutorial(); s.journey.step = 40; s.worker.hired = true; s.journey.intakePaused = false;
  until(s, () => s.sales >= 3);
  assert.ok(s.cash > 1225);
  s.journey.automation = false; s.journey.intakePaused = true;
  if (s.car) finishCar(s);
  assert.ok(M.arriveBusiness(s)); until(s, () => s.car.status === 'seller');
  const cash = s.cash; for (let i = 0; i < 600; i++) M.tick(s, .1);
  assert.equal(s.cash, cash); assert.equal(s.car.status, 'seller');
});
test('journey purchases and negotiations reject stale, repeated, distant and seated requests', () => {
  const session = new TycoonSession(M.freshJourney()), s = session.state, first = J.purchasePad(s);
  assert.equal(session.dispatch({type:'Pad',id:first.id}, {position:first.pos,onFoot:false}).ok, false);
  assert.equal(session.dispatch({type:'Pad',id:first.id}, {position:[100,100],onFoot:true}).ok, false);
  assert.ok(session.dispatch({type:'Pad',id:first.id}, {position:first.pos,onFoot:true}).ok);
  assert.equal(session.dispatch({type:'Pad',id:first.id}, {position:first.pos,onFoot:true}).ok, false);
  pad(s); until(s, () => s.car.status === 'seller');
  const context = {position:actorPosition(s),onFoot:true};
  assert.ok(session.dispatch({type:'Deal'},context).ok);
  const accept = {type:'Accept',carId:s.car.id,revision:0,amount:25};
  assert.equal(session.dispatch({...accept,amount:0},context).ok,false);
  assert.ok(session.dispatch(accept,context).ok);
  assert.equal(session.dispatch(accept,context).ok,false);
});
const memoryStorage = () => {
  const data = new Map(); return { data, getItem:key=>data.get(key)??null, setItem:(key,value)=>data.set(key,value), removeItem:key=>data.delete(key) };
};

test('reset removes current and legacy progress, preserves other storage and cannot be undone by shutdown or another tab', () => {
  const storage = memoryStorage(), owner = new TycoonSave(storage,{sessionId:'owner'});
  const old = owner.load(); old.cash = 9999; assert.ok(owner.write(old));
  storage.setItem(LEGACY_SAVE_KEY,JSON.stringify({version:1,state:M.fresh()}));
  storage.setItem('unrelated-setting','keep');
  const other = new TycoonSave(storage,{sessionId:'other'}); other.load();
  assert.ok(other.readOnly); assert.ok(other.reset());
  assert.deepEqual([...storage.data], [['unrelated-setting','keep']]);
  assert.equal(other.release(old),false); other.load(); other.resume(old);
  assert.equal(other.write(old),false);
  assert.equal(owner.release(old),false,'An old tab cannot restore a deleted profile');
  assert.deepEqual([...storage.data], [['unrelated-setting','keep']]);
  const fresh = new TycoonSave(storage,{sessionId:'new'}).load();
  assert.equal(fresh.cash,400); assert.equal(fresh.journey.step,0); assert.equal(fresh.sales,0);
  assert.equal(owner.write(old),false,'An old tab cannot overwrite the new profile either');
});

test('reset failures retain current progress and allow retry; temporary sessions never access browser storage', () => {
  const storage = memoryStorage(); let blocked = true;
  const save = new TycoonSave({...storage,removeItem(key){if(blocked)throw Error('denied');storage.removeItem(key);}});
  const state = save.load(), raw = storage.getItem(SAVE_KEY);
  assert.equal(save.reset(),false); assert.equal(storage.getItem(SAVE_KEY),raw);
  assert.ok(save.write(state)); blocked=false; assert.ok(save.reset());
  const session = new TycoonSave(); assert.ok(session.reset());
  session.load(); assert.equal(session.write(state),false);
});
test('offline rewards honor source thresholds, capped elapsed time, functional-pad rates and already-paid receipts', () => {
  const s = tutorial(); const anchor = 100000;
  assert.equal(O.offlineReward(s,anchor,anchor+9999),undefined);
  s.journey.step = 40; s.worker.hired = true;
  assert.equal(O.offlineReward(s,undefined,anchor+9999),undefined);
  assert.equal(O.offlineReward(s,anchor,anchor-1),undefined);
  assert.equal(O.offlineReward(s,anchor,anchor+89),undefined);
  assert.equal(O.offlineReward(s,anchor,anchor+90).amount,42);
  s.journey.step = 240;
  const r = O.offlineReward(s,anchor,anchor+999999);
  assert.equal(r.seconds,28800); assert.equal(r.capped,true); assert.equal(r.amount,366336);
  const storage = memoryStorage(); let now = anchor*1000;
  const save = new TycoonSave(storage,{now:()=>now,sessionId:'a'}); assert.ok(save.write(s)); assert.ok(save.release(s));
  now += 3600*1000;
  const back = new TycoonSave(storage,{now:()=>now,sessionId:'b'}), restored = back.load();
  assert.equal(restored.cash,s.cash+Math.floor(3600*O.offlineRate(s))); assert.equal(back.offline.amount,45792);
  assert.equal(back.load().cash,restored.cash); assert.equal(back.offline,undefined,'Reload cannot claim the interval twice');
});
test('version-one saves migrate without losing paid work, routes, cash, special leads or individually owned features', () => {
  const s = M.fresh(); s.pads = ['lot','intake','tools','air','sales','salesdesk','finish','mechanic'];
  s.sales = 3; s.worker.hired = true; M.arrive(s,3);
  untilLegacy(s,()=>s.car.status==='seller'); M.openDeal(s); M.buy(s); M.plan(s,'Good'); M.tick(s,.1);
  const storage = memoryStorage(), old = JSON.stringify({version:1,state:s}); storage.data.set(LEGACY_SAVE_KEY,old);
  const save = new TycoonSave(storage,{now:()=>100000000,sessionId:'a'}), next = save.load();
  assert.equal(next.cash,s.cash); assert.deepEqual(next.car,M.copy(s.car)); assert.deepEqual(next.pads,s.pads);
  assert.equal(next.journey.step,6); assert.ok(M.has(next,'mechanic')); assert.equal(save.offline,undefined);
  assert.equal(storage.data.get(LEGACY_SAVE_KEY),old); assert.ok(storage.data.has(SAVE_KEY));
});
function untilLegacy(s, condition) { for(let i=0;i<30000;i++){if(condition())return;M.tick(s,.1);} assert.fail('legacy timeout'); }
test('save leases prevent tab overwrites; corrupt saves and write failures never award offline cash or erase saved profiles', () => {
  const storage = memoryStorage(); let now = 100000000;
  const a = new TycoonSave(storage,{now:()=>now,sessionId:'a'}), first = a.load(); first.cash=500; a.write(first);
  const b = new TycoonSave(storage,{now:()=>now,sessionId:'b'}); assert.equal(b.load().cash,500); assert.ok(b.readOnly);
  assert.equal(b.write({...first,cash:1}),false);
  now += 181000; const restored = b.load(); restored.cash = 700; assert.ok(b.write(restored));
  assert.equal(a.write(first),false); assert.equal(JSON.parse(storage.data.get(SAVE_KEY)).state.cash,700);
  storage.data.set(SAVE_KEY,'{broken');
  const corrupt = new TycoonSave(storage); corrupt.load(); assert.equal(corrupt.write(M.freshJourney()),false); assert.equal(storage.data.get(SAVE_KEY),'{broken');
  const s = tutorial(); s.journey.step=40; s.worker.hired=true;
  const good = memoryStorage(), writer=new TycoonSave(good,{now:()=>100000000}); writer.write(s); writer.release(s);
  const raw=good.data.get(SAVE_KEY);
  const failed = new TycoonSave({getItem:key=>good.getItem(key),setItem(){throw Error('quota');}},{now:()=>103600000});
  assert.equal(failed.load().cash,s.cash); assert.equal(failed.offline,undefined); assert.equal(good.data.get(SAVE_KEY),raw);
});
test('rolling business revenue excludes offline credits and expires after sixty seconds', () => {
  const s = tutorial(); assert.equal(O.revenuePerMinute(s),1000);
  s.ledger.push({amount:100000,kind:'offline',subject:'Offline'}); assert.equal(O.revenuePerMinute(s),1000);
  s.clock += 61; assert.equal(O.revenuePerMinute(s),0);
});
test('hill laptop replaces manual timers, discards interrupted rounds, and preserves mechanic automation', () => {
  const s=M.freshJourney();s.journey.intakePaused=true;pad(s);s.cash=0;
  const session=new TycoonSession(s),context={position:P.PARTS_POSITION,onFoot:true};
  assert.equal(session.dispatch({type:'SellParts'},{position:[99,99],onFoot:true}).ok,false);
  assert.equal(session.dispatch({type:'SellParts'},{...context,onFoot:false}).ok,false);
  assert.ok(session.dispatch({type:'SellParts'},context).ok);
  assert.equal(session.dispatch({type:'SellParts'},context).ok,false);
  for(let i=0;i<100;i++)M.tick(s,.1,0,true);assert.equal(s.cash,0);assert.equal(s.parts.remaining,30,'Old typing ticks cannot pay manual runs');
  const storage=memoryStorage(),save=new TycoonSave(storage,{sessionId:'parts'});assert.ok(save.write(s));
  const restored=save.load();assert.equal(restored.parts.remaining,undefined);assert.equal(restored.cash,0);
  assert.equal(P.completeHillRun(restored,14),false,'Reloaded rounds cannot settle');
  assert.ok(P.startParts(restored));assert.ok(P.completeHillRun(restored,14));assert.equal(restored.cash,28);
  assert.equal(P.completeHillRun(restored,14),false);assert.equal(restored.parts.completed,1);
  restored.cash=220;const resumed=new TycoonSession(restored);
  assert.ok(resumed.dispatch({type:'UpgradeParts'},context).ok);assert.equal(restored.cash,0);assert.equal(restored.parts.level,2);
  assert.equal(P.partsUpgradeCost(2),297);assert.equal(P.partsPayout(2),44);
  restored.journey.step=40;restored.journey.tutorialComplete=true;restored.worker.hired=true;
  for(let i=0;i<50;i++)M.tick(restored,.1);assert.equal(restored.cash,44);assert.equal(restored.parts.completed,2);
});
test('listed quotes stay fixed across construction and unfinished legacy purchases keep a route into work planning', () => {
  const s=tutorial();assert.ok(M.arriveBusiness(s));
  until(s,()=>s.car.status==='photo',()=>{
    if(s.car.status==='seller'){M.openDeal(s);M.buy(s);}
    if(s.car.status==='choose')M.plan(s,'Quick');
    if(s.car.status==='repair'&&!M.job(s)?.started)M.startJob(s);
  });
  assert.ok(M.list(s));const offer=M.buyer(s).ask;s.journey.step=140;
  assert.equal(M.buyer(s).ask,offer);M.openDeal(s);assert.equal(s.car.quote.accepted,offer);
  const old=M.fresh();old.pads=['lot','intake'];M.arrive(old,1);untilLegacy(old,()=>old.car.status==='seller');
  M.openDeal(old);M.buy(old);assert.equal(old.car.status,'owned');J.migrateOpening(old);pad(old);
  assert.equal(old.car.status,'choose');assert.ok(M.plan(old,'Quick'));
});
