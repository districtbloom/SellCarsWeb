import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Box3, Group, PerspectiveCamera, Scene, Vector3 } from 'three';
import { World } from 'cannon-es';
import { Element } from './test-dom.mjs';
import { importTypescript } from './import-typescript.mjs';
const root=new URL('../src/world/tycoon/',import.meta.url);
const M=await importTypescript(new URL('TycoonModel.ts',root));
const F=await importTypescript(new URL('FullJourneyCatalog.ts',root));
const J=await importTypescript(new URL('FullJourney.ts',root));
const {TycoonSession}=await importTypescript(new URL('TycoonSession.ts',root));
const {TycoonSave}=await importTypescript(new URL('TycoonSave.ts',root));
const {guidance}=await importTypescript(new URL('TycoonGuidance.ts',root));
const {PARTS_POSITION}=await importTypescript(new URL('PartsStation.ts',root));
const storage=()=>{const data=new Map();return{getItem:key=>data.get(key)??null,setItem:(key,value)=>data.set(key,value),removeItem:key=>data.delete(key)};};
function dom(){globalThis.HTMLElement=Element;globalThis.window=Object.assign(new EventTarget(),{innerWidth:1280,innerHeight:720});globalThis.document={body:new Element(),activeElement:new Element(),createElement(tag){const e=new Element();e.tagName=tag.toUpperCase();return e;},pointerLockElement:null};}

test('cosmetics are optional, never tutorial targets, and cannot gate functional construction',()=>{
  const s=M.freshJourney();s.cash=1e9;s.journey.step=6;s.journey.tutorialComplete=true;
  assert.equal(J.cosmeticPads(M.freshJourney()).length,0);
  const purchased=[];
  while(J.purchasePad(s)){
    const p=J.purchasePad(s),guide=guidance(s);assert.notEqual(p.category,'Cosmetic');
    if(guide.kind==='pad')assert.equal(guide.id,p.id);
    assert.ok(M.buyPad(s,p.id));purchased.push(p.id);
  }
  assert.equal(s.journey.step,240);assert.deepEqual(s.journey.cosmetics,[]);
  assert.equal(purchased.length,F.entries.filter(e=>e.step>6&&e.category!=='Cosmetic').length);
  const optional=J.cosmeticPads(s);assert.equal(optional.length,F.entries.filter(e=>e.category==='Cosmetic').length);
  const before=s.cash,p=optional[0],session=new TycoonSession(s);
  assert.equal(session.dispatch({type:'Pad',id:p.id},{position:[-999,-999],onFoot:true}).ok,false);
  assert.ok(session.dispatch({type:'Pad',id:p.id},{position:p.pos,onFoot:true}).ok);
  assert.equal(s.cash,before-p.cost);assert.equal(s.journey.step,240);assert.ok(J.ownsCosmetic(s,F.entries.find(e=>e.id===p.id).step));
  assert.equal(session.dispatch({type:'Pad',id:p.id},{position:p.pos,onFoot:true}).ok,false);
  const save=new TycoonSave(storage(),{sessionId:'cosmetics'});assert.ok(save.write(s));assert.deepEqual(save.load().journey.cosmetics,[p.id]);
  const legacy=M.copy(s);delete legacy.journey.cosmetics;legacy.journey.step=64;
  const oldSave=new TycoonSave(storage(),{sessionId:'old-cosmetics'});assert.ok(oldSave.write(legacy));
  assert.deepEqual(oldSave.load().journey.cosmetics,F.entries.filter(e=>e.category==='Cosmetic'&&e.step<=64).map(e=>e.id));
});

test('purchase pads have a smaller raised button and clear green/blue category colors; display cars are removed',async()=>{
  const {createPurchasePad}=await importTypescript(new URL('TycoonActors.ts',root));
  const {removedDisplayPart,PARKING_STEPS}=await importTypescript(new URL('PurchaseCategories.ts',root));
  const {partPose}=await importTypescript(new URL('BuildingProgression.ts',root));
  const group=new Group(),colors=[];
  for(const category of ['Money-making','Architectural','Cosmetic']){
    const pad=createPurchasePad(group,category,category),base=pad.getObjectByName('Base'),button=pad.getObjectByName('Button');
    assert.ok(base&&button);const baseSize=new Box3().setFromObject(base).getSize(new Vector3()),buttonSize=new Box3().setFromObject(button).getSize(new Vector3());
    assert.ok(baseSize.x>buttonSize.x&&baseSize.z>buttonSize.z);assert.ok(button.position.y>base.position.y);
    assert.equal(pad.userData.category,category);colors.push(button.material.color.getHex());
  }
  assert.equal(colors[0],colors[1]);assert.notEqual(colors[0],colors[2]);
  for(const step of PARKING_STEPS){assert.match(F.entries[step-1].title,/parking/i);assert.equal(F.entries[step-1].category,'Architectural');}
  const source=JSON.parse(await readFile(new URL('../public/tycoon/dealership.json',import.meta.url),'utf8'));
  const removed=source.parts.filter(p=>removedDisplayPart(p.path));assert.ok(removed.length>0);
  for(const part of removed)for(const step of [22,64,140,240])assert.equal(partPose(part,step).visible,false,part.path);
  group.traverse(node=>{node.geometry?.dispose();node.material?.dispose();});
});

test('hill controller locks movement, cancels without payment, and releases input on exit',async()=>{
  dom();const {HillDriveGame}=await importTypescript(new URL('../activities/HillDriveGame.ts',root));
  let locked=false,paid=0,cancelled=0;
  const game=new HillDriveGame(v=>locked=v,()=>{paid++;return true;},()=>cancelled++);
  try {
    game.begin();assert.ok(locked);assert.ok(game.active);assert.equal(paid,0);
    game.start();game.canvas.onpointerdown({button:0,pointerId:1,preventDefault(){}});assert.ok(game.left);
    game.tick(.1);window.dispatchEvent(new Event('blur'));assert.equal(game.left,false);
    const key=Object.assign(new Event('keydown',{cancelable:true}),{code:'Escape'});window.dispatchEvent(key);
    assert.equal(game.active,false);assert.equal(locked,false);assert.equal(cancelled,1);assert.equal(paid,0);
    game.begin();game.start();game.model.distance=17;game.model.ended='time';game.tick(.1);game.tick(.1);
    assert.equal(paid,1,'A finished run only settles once');game.close();assert.equal(cancelled,1);
  }finally{game.dispose();}
});

test('Phoenix call waits for full delivered affordability, protects its reserve, and keeps ordinary sellers arriving',()=>{
  const s=M.freshJourney();s.journey.step=22;s.journey.tutorialComplete=true;s.journey.intakePaused=false;
  const full=M.leadBudget(s,false)[0];s.cash=full-1;M.lead(s);assert.equal(s.lead,undefined);
  s.cash=full;for(let i=0;i<60&&!s.lead;i++)M.tick(s,.1);assert.equal(s.lead?.kind,'rare');
  assert.ok(s.car?.business,'A pending Phoenix call does not pause normal seller intake');
  assert.equal(M.reserve(s),full);const next=J.purchasePad(s);assert.equal(M.buyPad(s,next.id),false,'Construction cannot spend the promised car budget');
  assert.ok(M.PHOENIX_PRICE>F.acquisitionCost(22));assert.ok(full<5700);
  assert.equal(M.leadBudget(s,true)[0],full-300,'Driving saving is optional, not required for affordability');
  const delivery=M.freshJourney();delivery.journey.step=22;delivery.journey.tutorialComplete=true;delivery.journey.intakePaused=true;delivery.cash=M.leadBudget(delivery,false)[0];
  assert.ok(M.arrive(delivery,4));for(let i=0;i<2000&&delivery.car.status==='arriving';i++)M.tick(delivery,.1);
  if(delivery.car.status==='discovery')M.discover(delivery);assert.ok(M.openDeal(delivery));assert.equal(delivery.car.quote.accepted,M.PHOENIX_PRICE);
  assert.ok(M.buy(delivery),'The exact advertised delivered budget can buy the car and reserve repairs');assert.ok(M.plan(delivery,'Quick'));
});

test('five-minute phone reminder persists and ordinary sellers do not erase it',()=>{
  const s=M.freshJourney();s.cash=10000;s.journey.step=22;s.journey.tutorialComplete=true;s.journey.intakePaused=false;M.lead(s);
  const session=new TycoonSession(s),context={position:[0,0],onFoot:true};
  assert.ok(session.dispatch({type:'AnswerCall'},context).ok);assert.equal(s.lead.status,'answered');
  assert.ok(session.dispatch({type:'RemindCall'},context).ok);assert.equal(s.lead.status,'snoozed');assert.equal(s.lead.remindAt,s.clock+300);
  M.tick(s,.1);assert.ok(s.car?.business);assert.equal(s.lead.status,'snoozed');
  const save=new TycoonSave(storage(),{sessionId:'reminder'});assert.ok(save.write(s));const resumed=save.load();
  resumed.clock=resumed.lead.remindAt-.1;M.tick(resumed,.05);assert.equal(resumed.lead.status,'snoozed');M.tick(resumed,.051);
  assert.equal(resumed.lead.status,'ringing');assert.equal(resumed.lead.remindAt,undefined);
});

test('accepting Phoenix during an ordinary flip queues delivery without replacing the current car or starving the lead',()=>{
  let s=M.freshJourney();s.cash=10000;s.journey.step=40;s.journey.tutorialComplete=true;s.worker.hired=true;
  assert.ok(M.arriveBusiness(s));const ordinary=s.car.id;M.lead(s);assert.ok(M.invite(s));
  assert.equal(s.car.id,ordinary);assert.equal(s.lead.status,'queued');
  const save=new TycoonSave(storage(),{sessionId:'queued-call'});assert.ok(save.write(s));s=save.load();
  for(let i=0;i<10000&&s.car?.index!==4;i++)M.tick(s,.1);
  assert.equal(s.sales,1);assert.equal(s.history[0].id,ordinary);assert.equal(s.car?.index,4);assert.equal(s.lead,undefined);
  assert.equal(s.car.business,undefined,'Queued Phoenix takes the next slot before another routine arrival');
});

test('sales staff list restored special cars before transport; construction gates and manual mode preserve manual listing',()=>{
  for(const [step,automation,listed] of [[32,true,false],[33,false,false],[33,true,true]]){
    let s=M.freshJourney();s.cash=100000;s.journey.step=step;s.journey.tutorialComplete=true;s.journey.intakePaused=true;s.journey.automation=automation;
    assert.ok(M.arrive(s,4));s.car.status='ready';s.car.route=undefined;s.car.owned=true;s.car.pos=[0,0];s.car.plan={jobs:[],cost:0,seconds:0,funded:true};
    assert.equal(J.staffedListing(s),listed);
    const duration=J.salesHandoverSeconds(s);assert.equal(duration,2.4,'Prepositioned staff need only a short handover');
    if(listed)s.car.wait=90;
    M.tick(s,.1);assert.equal(s.car.status,'ready');assert.ok(s.car.wait>0&&s.car.wait<=2.4,'Old saved walk delays are clamped to the short handover');
    const save=new TycoonSave(storage(),{sessionId:`handover-${step}-${automation}`});assert.ok(save.write(s));const remaining=s.car.wait;s=save.load();assert.equal(s.car.wait,remaining);
    for(let i=0;i<Math.ceil(duration*10)+2&&s.car.status==='ready';i++)M.tick(s,.1);
    assert.equal(s.car.route?.target,'sales');assert.equal(!!s.car.listing,listed);assert.equal(!!s.car.photo,listed);
    for(let i=0;i<3000&&s.car.route;i++)M.tick(s,.1);
    assert.equal(s.car.status,listed?'buyer':'photo');assert.equal(s.sales,0,'Special-car final negotiation remains manual');
    if(!listed)assert.ok(M.list(s),'Unstaffed/manual-mode listings retain a usable fallback');
    assert.equal(s.car.history.filter(event=>event==='Photographed and listed').length,1);
  }
});

test('sales advisor resumes an old photo-stage save with a visible delay and no duplicate listing',()=>{
  let s=M.freshJourney();s.cash=100000;s.journey.step=33;s.journey.tutorialComplete=true;s.journey.intakePaused=true;
  assert.ok(M.arrive(s,4));s.car.route=undefined;s.car.status='photo';s.car.owned=true;
  const save=new TycoonSave(storage(),{sessionId:'old-photo-stage'});assert.ok(save.write(s));s=save.load();
  for(let i=0;i<17;i++)M.tick(s,.1);assert.equal(s.car.status,'photo');assert.equal(!!s.car.listing,false);
  M.tick(s,.101);assert.equal(s.car.status,'buyer');assert.ok(s.car.photo&&s.car.listing);
  for(let i=0;i<30;i++)M.tick(s,.1);
  assert.equal(s.car.status,'buyer');assert.equal(s.car.history.filter(event=>event==='Photographed and listed').length,1);assert.equal(s.sales,0);
});

test('hired repair staff handle every department even with manual deals; the advisor can start photos immediately',()=>{
  for(const [id,automation,automatic] of [['Photo_Listing',true,true],['Photo_Listing',false,true],['Body_Restoration',true,true]]){
    const s=M.freshJourney();s.cash=100000;s.journey.step=60;s.journey.tutorialComplete=true;s.journey.intakePaused=true;s.journey.automation=automation;
    assert.ok(M.arriveBusiness(s));const plan=J.workPlan(s),task=plan.jobs.find(job=>job.id===id);assert.ok(task);
    s.car.status='repair';s.car.route=undefined;s.car.owned=true;s.car.pos=[...task.position];s.car.plan={...plan,jobs:[task],funded:true};
    assert.equal(M.staffedJob(s),automatic);
    M.tick(s,.1);
    if(id==='Photo_Listing'&&automation)assert.ok(task.progress>0,'The prepositioned advisor starts photos without another walk countdown');
    if(automatic){
      for(let i=0;i<2000&&!task.done;i++)M.tick(s,.1);
      assert.ok(task.done,'The advisor completes listing photos without player taps');assert.equal(task.manual,false);
    }else{
      assert.ok(M.startJob(s));for(let i=0;i<200;i++)M.tick(s,.1);
      assert.equal(task.progress,0);assert.equal(task.manual,true);assert.equal(task.done,false);
    }
  }
});

test('the mechanic unlocks at functional step 40 and manual deals do not disable repairs',()=>{
  assert.equal(F.featureSteps.mechanic,40);assert.match(F.entries[39].title,/mechanic/i);
  for(const [step,automation,staffed] of [[39,true,false],[40,true,true],[40,false,true]]){
    const s=M.freshJourney();s.cash=100000;s.journey.step=step;s.journey.tutorialComplete=true;s.journey.intakePaused=true;s.journey.automation=automation;
    assert.ok(M.arriveBusiness(s));const plan=J.workPlan(s),task=plan.jobs.find(job=>job.id==='Mechanical');assert.ok(task);
    s.car.status='repair';s.car.route=undefined;s.car.owned=true;s.car.pos=[...task.position];s.car.plan={...plan,jobs:[task],funded:true};
    assert.equal(M.has(s,'mechanic'),step>=40);assert.equal(M.staffedJob(s),staffed);
    if(staffed){for(let i=0;i<1000&&!task.started;i++)M.tick(s,.1);assert.ok(task.started,'The unlocked mechanic reaches the car and starts work');}
    else assert.ok(M.startJob(s));
    assert.equal(task.manual,!staffed);
  }
});

test('smartphone shows caller and message; Enter answers once into the follow-up dialog and reminder hides it',async()=>{
  dom();const {TycoonHUD}=await importTypescript(new URL('TycoonHUD.ts',root));
  const s=M.fresh();M.lead(s);const session=new TycoonSession(s),actions=[];let menu=false;
  const hud=new TycoonHUD({state:s,dispatch(action){actions.push(action);return session.dispatch(action,{position:[0,0],onFoot:true});},navigate(){},setMenu(value){menu=value;},saveStatus:()=>''});
  const press=(code,repeat=false)=>window.dispatchEvent(Object.assign(new Event('keydown',{cancelable:true}),{code,repeat}));
  try {
    const phone=hud.root.querySelector('.tycoon-smartphone');assert.ok(phone);assert.ok(phone.classList.contains('visible'));
    assert.equal(phone.querySelector('h3').textContent,s.lead.caller);assert.equal(phone.querySelector('.smartphone-message').textContent,s.lead.text);
    assert.equal(menu,false);press('Enter',true);assert.equal(actions.length,0);
    press('Enter');assert.equal(s.lead.status,'answered');assert.equal(hud.cameraMode,'call');assert.equal(menu,true);assert.equal(phone.classList.contains('visible'),false);
    press('Enter');assert.equal(actions.filter(a=>a.type==='AnswerCall').length,1,'Holding or pressing Enter in the follow-up does not answer twice');
    assert.ok(hud.content.querySelectorAll('button').some(button=>/Phoenix/.test(button.textContent)),'Follow-up exposes the actual offer');
    hud.content.querySelectorAll('button').find(button=>/Remind me/.test(button.textContent)).onclick();hud.update();
    assert.equal(s.lead.status,'snoozed');assert.equal(menu,false);assert.equal(phone.classList.contains('visible'),false);
    s.clock=s.lead.remindAt;M.tick(s,.01);hud.update();assert.ok(phone.classList.contains('visible'));
    phone.querySelector('.smartphone-answer').onclick();assert.equal(hud.cameraMode,'call');assert.equal(s.lead.status,'answered');
  }finally{hud.dispose();}
});
