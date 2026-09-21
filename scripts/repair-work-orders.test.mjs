import test from 'node:test';
import assert from 'node:assert/strict';
import {importTypescript} from './import-typescript.mjs';
const root=new URL('../src/world/tycoon/',import.meta.url);
const M=await importTypescript(new URL('TycoonModel.ts',root));
const J=await importTypescript(new URL('FullJourney.ts',root));
const E=await importTypescript(new URL('PartsEconomy.ts',root));
const {randomWorkOrder,workOrderRange}=await importTypescript(new URL('RepairWorkOrders.ts',root));
const {repairKind}=await importTypescript(new URL('RepairGame.ts',root));
const {TycoonSave,validState}=await importTypescript(new URL('TycoonSave.ts',root));
function seeded(seed){return()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};}
function business(grade='Worn'){
  const s=M.freshJourney();s.cash=100000;s.journey.step=100;s.journey.tutorialComplete=true;s.journey.intakePaused=true;
  assert.ok(M.arriveBusiness(s));s.car.condition={Body:grade,RunningGear:grade,Mechanical:grade,Exterior:'Good'};return s;
}

test('random work orders retain required repairs, vary unlocked extras and order, and scale workload by condition and flip depth',()=>{
  for(const grade of ['Worn','Ruined']){
    const s=business(grade),quick=J.workPlan(s),good=J.workPlan(s,true);
    const qRange=workOrderRange(quick,'Quick',s.car.condition),gRange=workOrderRange(good,'Good',s.car.condition);
    assert.ok(gRange.min>qRange.max,'A Good flip always has more work than the same Quick flip');
    const mixes=new Set(),orders=new Set();
    for(let seed=1;seed<=40;seed++)for(const [plan,depth,range] of [[quick,'Quick',qRange],[good,'Good',gRange]]){
      const quoted=M.copy(plan),rolled=randomWorkOrder(quoted,depth,s.car.condition,false,seeded(seed));
      assert.ok(rolled.jobs.length>=range.min&&rolled.jobs.length<=range.max);
      for(const id of ['Body','RunningGear','Mechanical'])assert.equal(rolled.jobs.filter(job=>job.id===id).length,1,'Required damaged repair is retained');
      if(depth==='Good')assert.equal(rolled.jobs.filter(job=>job.id==='Tune').length,1);
      if(rolled.jobs.some(job=>job.id==='Photo_Listing'))assert.equal(rolled.jobs.at(-1).id,'Photo_Listing','Listing photos follow all physical repairs');
      assert.equal(new Set(rolled.jobs.map(repairKind)).size,rolled.jobs.length,'Optional work never duplicates a minigame kind');
      assert.equal(rolled.cost,plan.cost);assert.equal(rolled.seconds,plan.seconds);
      assert.equal(rolled.jobs.reduce((sum,job)=>sum+job.cost,0),plan.cost);
      assert.ok(Math.abs(rolled.jobs.reduce((sum,job)=>sum+job.seconds,0)-plan.seconds)<1e-8);
      assert.equal(rolled.pricedServices,plan.jobs.filter(job=>job.id!=='Tune').length);
      assert.ok(rolled.jobs.every(job=>!job.started&&!job.done&&job.progress===0&&job.seconds>0));
      mixes.add(rolled.jobs.map(job=>job.id).sort().join(','));orders.add(rolled.jobs.map(job=>job.id).join(','));
    }
    assert.ok(mixes.size>4,'Accepted work varies by service mix');assert.ok(orders.size>10,'Service order varies between flips');
  }
  const easy=business('Worn'),hard=business('Ruined');
  const taskCount=s=>Array.from({length:99},(_,i)=>randomWorkOrder(M.copy(J.workPlan(s)),'Quick',s.car.condition,false,()=>(i+1)/100).jobs.length).reduce((sum,n)=>sum+n,0);
  assert.ok(taskCount(hard)>taskCount(easy),'Worse condition increases the expected Quick workload without removing variation');
  assert.ok(workOrderRange(J.workPlan(hard,true),'Good',hard.car.condition).max>workOrderRange(J.workPlan(easy,true),'Good',easy.car.condition).max);
});

test('tutorial work only shuffles its two free required repairs without adding extra minigames',()=>{
  const s=M.freshJourney();s.journey.step=3;s.cash=1000;assert.ok(M.arriveBusiness(s));const plan=J.workPlan(s),orders=new Set();
  assert.deepEqual(workOrderRange(plan,'Quick',s.car.condition,true),{min:2,max:2});
  for(const value of [.01,.99]){
    const rolled=randomWorkOrder(M.copy(plan),'Quick',s.car.condition,true,()=>value);
    assert.deepEqual(rolled.jobs.map(job=>job.id).sort(),['Mechanical','RunningGear']);assert.equal(rolled.cost,0);assert.equal(rolled.seconds,plan.seconds);
    orders.add(rolled.jobs.map(job=>job.id).join(','));
  }
  assert.equal(orders.size,2);
});

test('work orders roll only after payment and remain fixed through quotes, repeat actions and saves without changing quoted profit',()=>{
  const s=business();s.journey.automation=false;s.car.route=undefined;s.car.status='choose';s.car.owned=true;s.car.purchase=1000;
  const quote=M.workQuote(s,'Good'),inputs=E.repairCost(quote),estimate=M.estimate(s,'Good'),beforePlan=M.copy(s.car);
  const originalRandom=Math.random;let rolls=0;Math.random=()=>{rolls++;return .37;};
  try{
    s.cash=0;assert.equal(M.plan(s,'Good'),false);assert.equal(rolls,0);assert.equal(s.car.plan,undefined);
    s.cash=inputs.cash;s.partsStock=0;assert.equal(M.plan(s,'Good'),false);assert.equal(rolls,0,'Mechanic must fund missing Parts before generating a work order');
    s.partsStock=inputs.parts;s.cash=inputs.cash;assert.ok(M.plan(s,'Good'));assert.ok(rolls>0);
    assert.equal(s.cash,0);assert.equal(s.partsStock,0);assert.equal(s.car.plan.cost,quote.cost);assert.equal(s.car.plan.seconds,quote.seconds);
    assert.equal(s.car.workSpent,quote.cost);assert.equal(s.car.plan.pricedServices,quote.jobs.filter(job=>job.id!=='Tune').length);
    const accepted=M.copy(s.car.plan),count=rolls;assert.equal(M.plan(s,'Good'),false);M.workQuote(s,'Good');assert.equal(rolls,count);
    const records=new Map(),save=new TycoonSave({getItem:key=>records.get(key)??null,setItem:(key,value)=>records.set(key,value),removeItem:key=>records.delete(key)},{sessionId:'work-order'});
    assert.ok(save.write(s));const restored=save.load();assert.deepEqual(restored.car.plan,accepted);assert.equal(rolls,count);
    restored.car.plan.jobs.forEach(job=>{job.started=true;job.done=true;job.progress=1;});restored.car.status='buyer';restored.car.route=undefined;
    assert.equal(M.buyer(restored).ask,estimate.sale,'Randomized workload cannot alter the previously quoted sale estimate');
    assert.equal(M.estimate(restored,'Good').profit,estimate.profit);assert.ok(validState(restored));
    restored.car.plan.pricedServices=-1;assert.equal(validState(restored),false);
    assert.equal(beforePlan.plan,undefined);
  }finally{Math.random=originalRandom;}
});
