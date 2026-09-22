import { exerciseManualRepair } from './repair-test-driver.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Box3, InstancedMesh, ObjectLoader, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';

// Minimal DOM services for constructing the real gameplay classes in Node. No browser/GPU is simulated.
import { Element } from './test-dom.mjs';

globalThis.innerWidth = 1280; globalThis.innerHeight = 720;
globalThis.HTMLElement = Element;
globalThis.window = Object.assign(new EventTarget(), { innerWidth:1280, innerHeight:720 });
globalThis.document = Object.assign(new EventTarget(), { body: new Element(), createElement(tag) { const e = new Element(); e.tagName = tag.toUpperCase(); return e; }, pointerLockElement: null, hidden: false, exitPointerLock() {} });
globalThis.location = { search:'?save=off&opening=integration', pathname:'/' };
const data = JSON.parse(await readFile(new URL('../public/tycoon/dealership.json', import.meta.url), 'utf8'));
globalThis.fetch = async url => { assert.ok(url.endsWith('tycoon/dealership.json')); return { ok:true, json:async()=>data }; };
const { DrivingSystem } = await importTypescript(new URL('../src/world/driving/DrivingSystem.ts', import.meta.url));
const { TycoonSystem } = await importTypescript(new URL('../src/world/tycoon/TycoonSystem.ts', import.meta.url));
const { guidance } = await importTypescript(new URL('../src/world/tycoon/TycoonGuidance.ts', import.meta.url));
const M = await importTypescript(new URL('../src/world/tycoon/TycoonModel.ts', import.meta.url));

test('Hill Drive world interaction opens the laptop, locks driving and commits distance rewards once',async()=>{
  location.search='?save=off';
  const json=JSON.parse(await readFile(new URL('../public/scenes/main.scene.json',import.meta.url),'utf8'));
  for(const image of json.images??[])image.url={data:[255,255,255,255],width:1,height:1,type:'Uint8Array'};
  const scene=await new ObjectLoader().parseAsync(json),camera=scene.getObjectByName('MainCamera');
  const driving=new DrivingSystem(scene,camera,new Element()),tycoon=await TycoonSystem.create(scene,driving,camera,'/'),s=tycoon.state;
  const {PARTS_POSITION}=await importTypescript(new URL('../src/world/tycoon/PartsStation.ts',import.meta.url));
  const {worldPoint}=await importTypescript(new URL('../src/world/tycoon/TycoonCoordinates.ts',import.meta.url));
  const step=n=>{for(let i=0;i<n;i++){driving.tick(1/60);tycoon.tick(1/60);}};
  try {
    s.journey.step=1;s.journey.intakePaused=true;tycoon.syncEnvironment();driving.placePlayer(worldPoint(PARTS_POSITION,6));step(90);
    const label=tycoon.actors.partsLabel.material.map.image.getContext('2d').commands;
    assert.ok(label.some(c=>c.text==='HILL DRIVE'));assert.ok(label.some(c=>c.text.includes('DISTANCE')));
    const cash=s.cash;assert.ok(driving.onInteract());assert.ok(tycoon.minigameActive);assert.equal(driving.controlsEnabled,false);assert.ok(tycoon.hud.root.hidden);
    step(360);assert.equal(s.cash,cash,'Waiting at the laptop cannot earn old timer money');
    const game=tycoon.hillGame;game.start();game.model.distance=123;game.model.ended='time';step(2);
    assert.equal(s.cash,cash+246);assert.equal(s.parts.completed,1);game.close();assert.equal(driving.controlsEnabled,true);assert.equal(tycoon.hud.root.hidden,false);
    const {TycoonSave}=await importTypescript(new URL('../src/world/tycoon/TycoonSave.ts',import.meta.url));const records=new Map();let fail=false;
    tycoon.save=new TycoonSave({getItem:key=>records.get(key)??null,setItem(key,value){if(fail)throw Error('quota');records.set(key,value);},removeItem:key=>records.delete(key)},{sessionId:'hill-feedback'});
    assert.ok(tycoon.save.write(s));const earned=s.cash;assert.ok(driving.onInteract());game.start();game.model.distance=90;game.model.ended='crashed';fail=true;step(2);
    assert.equal(s.cash,earned,'Failed persistence rolls back the reward');assert.equal(s.parts.completed,1);game.close();fail=false;
    assert.ok(driving.onInteract());assert.ok(tycoon.minigameActive,JSON.stringify({parts:s.parts,notice:s.notice,status:tycoon.save.status,menu:tycoon.menu}));game.close();assert.equal(s.cash,earned);assert.equal(s.parts.manual,undefined);
  }finally{tycoon.dispose();driving.dispose();location.search='?save=off&opening=integration';}
});

test('repair interaction preserves the exact real camera from keypress through opening, minigame, and control return',async()=>{
  location.search='?save=off&opening=integration';
  const json=JSON.parse(await readFile(new URL('../public/scenes/main.scene.json',import.meta.url),'utf8'));
  for(const image of json.images??[])image.url={data:[255,255,255,255],width:1,height:1,type:'Uint8Array'};
  const scene=await new ObjectLoader().parseAsync(json),camera=scene.getObjectByName('MainCamera');
  const driving=new DrivingSystem(scene,camera,new Element()),tycoon=await TycoonSystem.create(scene,driving,camera,'/'),s=tycoon.state;
  const {worldPoint}=await importTypescript(new URL('../src/world/tycoon/TycoonCoordinates.ts',import.meta.url));
  const pose=()=>({position:camera.position.toArray(),quaternion:camera.quaternion.toArray(),fov:camera.fov,zoom:camera.zoom});let expected;
  const tick=count=>{for(let i=0;i<count;i++){driving.tick(1/60);tycoon.tick(1/60);if(expected)assert.deepEqual(pose(),expected,'Repair never changes the selected camera');}};
  try {
    s.pads=['lot','intake','repairbay','tools','power','air','sales','salesdesk'];assert.ok(M.arrive(s,1));
    Object.assign(s.car,{status:'repair',route:undefined,owned:true,pos:[9,0],plan:{cost:0,seconds:5,funded:true,jobs:[{id:'RunningGear',name:'Wheel repair',cost:0,seconds:5,done:false,started:false,progress:0}]}});
    tycoon.syncEnvironment();driving.placePlayer(worldPoint([9,3],6));tick(90);expected=pose();
    window.dispatchEvent(Object.assign(new Event('keydown',{cancelable:true}),{code:'KeyE',repeat:false}));tick(1);assert.ok(tycoon.repair.active);
    tick(118);assert.ok(tycoon.repair.root.hidden);tick(2);assert.equal(tycoon.repair.root.hidden,false);
    for(const wheel of tycoon.repair.root.querySelectorAll('[data-wheel]'))wheel.onclick();
    for(const bolt of tycoon.repair.root.querySelectorAll('[data-bolt]'))bolt.onclick();
    tick(1);assert.equal(tycoon.repair.active,false);assert.equal(driving.controlsEnabled,true);tick(1);
    const released=pose();expected=undefined;window.dispatchEvent(Object.assign(new Event('keydown'),{code:'KeyW'}));tick(30);
    window.dispatchEvent(Object.assign(new Event('keyup'),{code:'KeyW'}));assert.notDeepEqual(pose().position,released.position,'Normal movement resumes camera following after the action');
  }finally{tycoon.dispose();driving.dispose();}
});

test('garage arrows preview every authored model; purchases spawn the real car, preserve stats and survive failed saves',async()=>{
  location.search='?save=off';
  const json=JSON.parse(await readFile(new URL('../public/scenes/main.scene.json',import.meta.url),'utf8'));
  for(const image of json.images??[])image.url={data:[255,255,255,255],width:1,height:1,type:'Uint8Array'};
  const scene=await new ObjectLoader().parseAsync(json),camera=scene.getObjectByName('MainCamera');
  const driving=new DrivingSystem(scene,camera,new Element());
  const tycoon=await TycoonSystem.create(scene,driving,camera,'/'),s=tycoon.state;
  const {personalCars}=await importTypescript(new URL('../src/world/tycoon/PersonalCars.ts',import.meta.url));
  const {TycoonSave,SAVE_KEY}=await importTypescript(new URL('../src/world/tycoon/TycoonSave.ts',import.meta.url));
  const nodes=node=>[node,...node.children.flatMap(nodes)];
  const press=code=>window.dispatchEvent(Object.assign(new Event('keydown',{cancelable:true}),{code,repeat:false}));
  const step=(n=60)=>{for(let i=0;i<n;i++){driving.tick(1/60);tycoon.tick(1/60);}};
  try {
    s.journey.tutorialComplete=true;s.journey.intakePaused=true;s.cash=200000;
    step();tycoon.hud.open('personal');
    const positions=driving.cars.map(car=>car.physics.body.position.clone());
    const rendered=[];
    let viewport=[1280,720];
    const renderer={getSize:v=>v.set(...viewport),setViewport(){},render(scene,camera){
      rendered.push([scene,camera]);scene.updateMatrixWorld(true);camera.updateMatrixWorld(true);
      const bounds=new Box3().setFromObject(tycoon.showroom.turntable);
      for(const x of [bounds.min.x,bounds.max.x])for(const y of [bounds.min.y,bounds.max.y])for(const z of [bounds.min.z,bounds.max.z]){
        const point=new Vector3(x,y,z).project(camera);
        assert.ok(Math.abs(point.x)<1&&Math.abs(point.y)<1&&Math.abs(point.z)<1,'Preview car fits the camera at '+viewport.join('x'));
      }
    }};
    for(const option of personalCars){
      assert.equal(tycoon.showroom.selected,option.id);
      const model=tycoon.showroom.turntable.children[0];
      assert.ok(model);assert.notEqual(model,driving.cars.find(car=>car.id===option.id).car);
      let wheels=0;model.traverse(object=>{if(/^Wheel(?:fl|fr|rl|rr)\d+$/.test(object.name))wheels++;});assert.equal(wheels,4);
      const size=new Box3().setFromObject(model).getSize(new Vector3());assert.ok(size.toArray().every(n=>n>0&&Number.isFinite(n)));
      for(viewport of [[1280,720],[375,667],[844,390]])assert.ok(tycoon.renderPreview(renderer));
      const live=driving.cars.find(car=>car.id===option.id);
      assert.ok(nodes(tycoon.hud.root).some(node=>node.textContent===live.physics.tuning.horsepower+' hp'));
      const arrows=nodes(tycoon.hud.root).filter(node=>node.className==='garage-arrow');assert.equal(arrows.length,2);arrows[1].onclick();
    }
    assert.equal(rendered.length,42);assert.equal(tycoon.showroom.selected,9,'Next arrow wraps around');
    press('ArrowLeft');assert.equal(tycoon.showroom.selected,1);press('ArrowRight');assert.equal(tycoon.showroom.selected,9);
    driving.cars.forEach((car,i)=>assert.ok(car.physics.body.position.almostEquals(positions[i]),'Browsing never moves real cars'));
    const records=new Map();let fail=false;
    tycoon.save=new TycoonSave({getItem:key=>records.get(key)??null,setItem(key,value){if(fail)throw Error('quota');records.set(key,value);},removeItem:key=>records.delete(key)},{sessionId:'garage-world'});
    assert.ok(tycoon.save.write(s));fail=true;
    assert.equal(tycoon.dispatch({type:'BuyPersonal',modelId:9}).ok,false);assert.equal(s.personal,undefined);assert.equal(s.cash,200000);
    fail=false;
    for(const option of personalCars){
      assert.ok(tycoon.dispatch({type:'BuyPersonal',modelId:option.id}).ok);
      const active=driving.cars.find(car=>car.id===option.id);assert.equal(tycoon.personalCar.car,active);
      assert.equal(active.physics.tuning.horsepower,option.tuning.horsepower);step(60);
      assert.ok(active.physics.body.position.y>-2,'Purchased car is supported at the garage');
      assert.ok(tycoon.personalCar.walkingTarget(),option.name+' has a clear supported exit');
    }
    assert.equal(driving.cars.length,14);assert.equal(s.cash,4500);assert.equal(s.personal.ownedModels.length,14);
    assert.equal(JSON.parse(records.get(SAVE_KEY)).state.personal.modelId,1);
    const before=s.cash;assert.ok(tycoon.dispatch({type:'SelectPersonal',modelId:14}).ok);assert.equal(s.cash,before);
    tycoon.hud.close();tycoon.hud.open('personal');
    nodes(tycoon.hud.root).find(node=>node.textContent==='Go to car').onclick();
    assert.equal(tycoon.showroom.active,false);assert.equal(driving.walkingToTarget,true);
    for(let i=0;i<3600&&driving.walkingToTarget;i++)step(1);
    assert.ok(driving.player.canEnter(tycoon.personalCar.car.physics.body),'Go to car reaches an entry point with the real walking controller');
    press('KeyE');step(1);assert.equal(driving.drivenCarId,14);
    assert.equal(tycoon.dispatch({type:'SelectPersonal',modelId:1}).ok,false,'Cannot swap a car while seated');
    const origin=driving.physics.body.position.clone();press('KeyW');step(60);
    assert.ok(driving.physics.body.position.distanceTo(origin)>1,'The purchased car uses real driving physics');
    press('KeyR');step(1);press('KeyE');step(1);assert.equal(driving.isDriving,false);step(90);
    s.cash=10000;M.lead(s);assert.ok(tycoon.dispatch({type:'Visit'}).ok);step(1);
    assert.ok(driving.physics.world.bodies.includes(tycoon.personalCar.car.physics.body),'The residential visit keeps the personal car in physical driving');
    assert.equal(s.personal.route,undefined);assert.equal(s.personal.status,'driving');
    const {RESIDENTIAL_PARKING,RESIDENTIAL_SELLER}=await importTypescript(new URL('../src/world/TownPlaces.ts',import.meta.url));
    const {worldPoint}=await importTypescript(new URL('../src/world/tycoon/TycoonCoordinates.ts',import.meta.url));
    const parking=worldPoint(RESIDENTIAL_PARKING);parking.y=0;
    tycoon.personalCar.car.place(parking,0,true);driving.placePlayer(worldPoint(RESIDENTIAL_SELLER,6));step(1);
    assert.equal(s.personal.status,'atLead');assert.ok(s.car?.remote);
    assert.ok(driving.physics.world.bodies.includes(tycoon.personalCar.car.physics.body),'Arrival preserves the real driving car');
    assert.equal(s.personal.modelId,14);
  } finally {tycoon.dispose();driving.dispose();location.search='?save=off&opening=integration';}
});

test('real car/player physics and imported construction support the complete on-foot opening', async () => {
  const json = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
  for (const image of json.images ?? []) image.url = { data:[255,255,255,255], width:1, height:1, type:'Uint8Array' };
  const scene = await new ObjectLoader().parseAsync(json), camera = scene.getObjectByName('MainCamera');
  const driving = new DrivingSystem(scene, camera, new Element());
  const tycoon = await TycoonSystem.create(scene, driving, camera, '/');
  const s = tycoon.state;
  const advance = (until, maxSeconds = 30) => { for (let i=0;i<maxSeconds*60;i++) { driving.tick(1/60); tycoon.tick(1/60); exerciseManualRepair(s, input => tycoon.dispatch({type:'RepairInput',input}).ok); if (until()) return; } assert.fail(`Timed out: ${JSON.stringify({car:s.car?.status,pads:s.pads,player:driving.player.mesh.position.toArray(),walking:driving.walkingToTarget,notice:s.notice,guide:guidance(s)})}`); };
  const next = () => tycoon.navigate(guidance(s));
  try {
    advance(()=>driving.player.grounded, 5);
    assert.ok(driving.player.mesh.position.distanceTo(new Vector3(-300,4,112)) < 5);
    assert.equal(driving.cars.length, 14);
    next(); advance(()=>M.has(s,'lot')); next(); advance(()=>M.has(s,'intake'));
    advance(()=>s.car?.status==='seller'); next(); advance(()=>!!s.car?.quote && tycoon.hud.isOpen);
    const dealCamera={position:camera.position.toArray(),quaternion:camera.quaternion.toArray()};tycoon.tick(1/60);
    assert.deepEqual({position:camera.position.toArray(),quaternion:camera.quaternion.toArray()},dealCamera,'Opening a deal preserves the current camera');
    const cash = s.cash, pos = driving.player.mesh.position.clone();
    advance(()=>s.clock>20, 30); assert.ok(driving.player.mesh.position.distanceTo(pos) < 1, 'Menus stop walking input');
    assert.ok(tycoon.dispatch({type:'Accept',carId:s.car.id,revision:s.car.quote.revision,amount:s.car.quote.accepted}).ok);
    assert.equal(s.cash, cash-900); tycoon.hud.close();
    for(const id of ['repairbay','tools','power','air']) { assert.equal(guidance(s).id,id); next(); advance(()=>M.has(s,id),60); }
    advance(()=>s.car.status==='repair');
    const {worldPoint}=await importTypescript(new URL('../src/world/tycoon/TycoonCoordinates.ts',import.meta.url));
    const {guidanceAnchor}=await importTypescript(new URL('../src/world/tycoon/TycoonGuidance.ts',import.meta.url));
    const carPosition=worldPoint(s.car.pos,10),repairGuide=guidance(s);
    assert.notDeepEqual(repairGuide.point,s.car.pos,'Walking target remains beside the car');
    assert.deepEqual(guidanceAnchor(s,repairGuide),s.car.pos,'Billboard anchor is the car, independent of its walk-up point');
    tycoon.hud.next.onclick(); // Dismiss the welcome before checking the world objective.
    let target;const pointAtWorld=tycoon.objectiveArrow.pointAtWorld;tycoon.objectiveArrow.pointAtWorld=point=>{target=point;};
    tycoon.updateObjective();tycoon.objectiveArrow.pointAtWorld=pointAtWorld;
    assert.equal(target.x,carPosition.x);assert.equal(target.z,carPosition.z);
    while(s.car.status==='repair') { if (!M.job(s)?.started) { next(); advance(()=>M.job(s)?.started || s.car.status!=='repair',60); } advance(()=>!M.job(s)?.started || s.car.status!=='repair',30); }
    assert.equal(s.car.status,'ready'); next(); advance(()=>M.has(s,'sales'),60); next(); advance(()=>M.has(s,'salesdesk'),60);
    advance(()=>s.car.status==='buyer'); next(); advance(()=>!!s.car.quote && tycoon.hud.isOpen,60);
    assert.ok(tycoon.dispatch({type:'Accept',carId:s.car.id,revision:s.car.quote.revision,amount:s.car.quote.accepted}).ok); tycoon.hud.close();
    advance(()=>s.sales===1); assert.equal(s.cash,7050);assert.equal(s.partsStock,30); assert.equal(s.history.length,1);
    assert.ok(tycoon.environment.root.children.filter(o=>o instanceof InstancedMesh).length<100,'Instancing bounds the number of draw batches');
    assert.ok(camera.position.toArray().every(Number.isFinite));
    tycoon.hud.open('wallet'); assert.equal(tycoon.hud.isOpen,true); tycoon.hud.close(); assert.equal(tycoon.hud.isOpen,false);
    // Exercise the manual reveal-skip path with the real controller. Auto-finish alone misses a stuck input lock.
    s.car = undefined; assert.ok(M.arrive(s,4,true));
    const discoveryCamera={position:camera.position.toArray(),quaternion:camera.quaternion.toArray()};tycoon.tick(1/60);
    assert.deepEqual({position:camera.position.toArray(),quaternion:camera.quaternion.toArray()},discoveryCamera,'Rare-car discovery preserves the current camera');
    assert.equal(driving.controlsEnabled,false); assert.ok(tycoon.dispatch({type:'Discover'}).ok);
    assert.equal(driving.controlsEnabled,true); assert.equal(s.car.status,'seller');
  } finally { tycoon.dispose(); driving.dispose(); }
});

test('Sell Cars tutorial purchases, repair interactions and first sale work through the real player controller', async () => {
  globalThis.location.search = '?save=off';
  const json = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
  for (const image of json.images ?? []) image.url = { data:[255,255,255,255], width:1, height:1, type:'Uint8Array' };
  const scene = await new ObjectLoader().parseAsync(json), camera = scene.getObjectByName('MainCamera');
  const driving = new DrivingSystem(scene,camera,new Element());
  const tycoon = await TycoonSystem.create(scene,driving,camera,'/');
  const s = tycoon.state; s.journey.intakePaused = true;
  const advance = (done,seconds=90) => {
    for(let i=0;i<seconds*60;i++){driving.tick(1/60);tycoon.tick(1/60);exerciseManualRepair(s, input => tycoon.dispatch({type:'RepairInput',input}).ok);if(done())return;}
    assert.fail('Journey world timeout: '+JSON.stringify({car:s.car?.status,job:M.job(s),journey:s.journey,player:driving.player.mesh.position.toArray(),guide:guidance(s),notice:s.notice}));
  };
  const next = () => tycoon.navigate(guidance(s));
  try {
    advance(()=>driving.player.grounded,5);
    assert.equal(s.cash,400); next(); advance(()=>s.journey.step===1); next(); advance(()=>s.journey.step===2);
    advance(()=>s.car?.status==='seller'); next(); advance(()=>!!s.car.quote && tycoon.hud.isOpen);
    assert.ok(tycoon.dispatch({type:'Accept',carId:s.car.id,revision:s.car.quote.revision,amount:25}).ok); tycoon.hud.close();
    next(); advance(()=>s.journey.step===3); advance(()=>s.car.status==='repair');
    while(s.car.status==='repair'){
      if(!M.job(s)?.started){next();advance(()=>M.job(s)?.started || s.car.status!=='repair');}
      advance(()=>!M.job(s)?.started || s.car.status!=='repair',30);
    }
    for(const step of [4,5,6]){next();advance(()=>s.journey.step===step);}
    advance(()=>s.car.status==='buyer');next();advance(()=>!!s.car.quote && tycoon.hud.isOpen);
    assert.ok(tycoon.dispatch({type:'Accept',carId:s.car.id,revision:s.car.quote.revision,amount:1000}).ok);tycoon.hud.close();
    advance(()=>s.sales===1);assert.equal(s.cash,1225);assert.ok(s.journey.tutorialComplete);
    // Exercise the same world instance's durable transaction and page lifecycle.
    const { TycoonSave, SAVE_KEY, LEGACY_SAVE_KEY } = await importTypescript(new URL('../src/world/tycoon/TycoonSave.ts',import.meta.url));
    const { worldPoint } = await importTypescript(new URL('../src/world/tycoon/TycoonCoordinates.ts',import.meta.url));
    let now=100000000,failWrite=false;const records=new Map();
    tycoon.save=new TycoonSave({getItem:key=>records.get(key)??null,setItem(key,value){if(failWrite)throw Error('quota');records.set(key,value);},removeItem:key=>records.delete(key)},{now:()=>now,sessionId:'world'});
    assert.ok(tycoon.save.write(s));
    const nextPurchase=M.nextPad(s);driving.placePlayer(worldPoint(nextPurchase.pos,6));
    failWrite=true;assert.equal(tycoon.dispatch({type:'Pad',id:nextPurchase.id}).ok,false);
    assert.equal(s.journey.step,6);assert.equal(s.cash,1225,'Failed durable purchase rolls back cash and construction together');
    failWrite=false;s.journey.step=40;s.worker.hired=true;
    tycoon.suspend();now+=3600000;tycoon.tick(60);assert.equal(s.cash,1225);
    tycoon.resume();assert.equal(s.cash,2917);assert.equal(tycoon.hud.cameraMode,'offline');
    assert.equal(driving.controlsEnabled,false);tycoon.hud.close();assert.equal(driving.controlsEnabled,true);
    assert.equal(tycoon.save.offline,undefined,'Receipt dismissal does not issue another credit');
    // Source pad placement at early and late build milestones must stay on supported ground.
    const { entries } = await importTypescript(new URL('../src/world/tycoon/FullJourneyCatalog.ts',import.meta.url));
    for(const step of [24,64,140,196,237]){
      s.journey.step=step;s.journey.padPosition=undefined;tycoon.syncEnvironment();
      const position = s.journey.padPosition;
      assert.ok(position.every(Number.isFinite)); assert.ok(position[1]<=4.62);
      assert.ok(tycoon.environment.cameraObstacles.length>0);
      assert.ok(entries[step]);
    }
    assert.equal(driving.cars.length,14);assert.ok(camera.position.toArray().every(Number.isFinite));
    records.set(LEGACY_SAVE_KEY,JSON.stringify({version:1,state:M.fresh()}));
    assert.ok(tycoon.resetSave()); assert.equal(driving.controlsEnabled,false);
    const clock=s.clock;tycoon.tick(10);assert.equal(s.clock,clock);
    tycoon.dispose();
    window.dispatchEvent(new Event('pagehide'));window.dispatchEvent(new Event('pageshow'));
    document.hidden=true;document.dispatchEvent(new Event('visibilitychange'));
    document.hidden=false;document.dispatchEvent(new Event('visibilitychange'));
    tycoon.tick(10);
    assert.equal(records.has(SAVE_KEY),false);assert.equal(records.has(LEGACY_SAVE_KEY),false);
    assert.equal(s.clock,clock,'Shutdown and lifecycle callbacks cannot advance or resave the old session');
  } finally {tycoon.dispose();driving.dispose();}
});

test('race winnings commit once, survive reload and roll back a failed save',async()=>{
  location.search='?save=off&opening=integration';const json=JSON.parse(await readFile(new URL('../public/scenes/main.scene.json',import.meta.url),'utf8'));
  for(const image of json.images??[])image.url={data:[255,255,255,255],width:1,height:1,type:'Uint8Array'};
  const scene=await new ObjectLoader().parseAsync(json),camera=scene.getObjectByName('MainCamera'),driving=new DrivingSystem(scene,camera,new Element()),tycoon=await TycoonSystem.create(scene,driving,camera,'/');
  const {TycoonSave}=await importTypescript(new URL('../src/world/tycoon/TycoonSave.ts',import.meta.url));const records=new Map();let fail=false;
  try{
    tycoon.save=new TycoonSave({getItem:key=>records.get(key)??null,setItem(key,value){if(fail)throw Error('quota');records.set(key,value);},removeItem:key=>records.delete(key)},{sessionId:'race-payout',legacy:true});
    const s=tycoon.state;s.onboarding={welcomed:true,phonePrompted:true};assert.ok(tycoon.save.write(s));const cash=s.cash;
    for(const amount of [0,249,3501,NaN,Infinity,250.5])assert.equal(tycoon.awardRace('invalid',amount),false);
    assert.equal(tycoon.awardRace('x'.repeat(101),250),false);assert.ok(tycoon.awardRace('first',250));assert.equal(s.cash,cash+250);
    assert.equal(tycoon.awardRace('first',250),false);assert.ok(tycoon.awardRace('second',3500));assert.equal(s.cash,cash+3750);
    const restored=tycoon.save.load();assert.equal(restored.cash,s.cash);assert.deepEqual(restored.raceClaims,['first','second']);assert.deepEqual(restored.onboarding,s.onboarding);
    fail=true;assert.equal(tycoon.awardRace('failed',1000),false);assert.equal(s.cash,cash+3750);assert.deepEqual(s.raceClaims,['first','second']);assert.equal(s.ledger.filter(e=>e.kind==='race').length,2);
    fail=false;assert.ok(tycoon.awardRace('failed',1000));assert.equal(s.cash,cash+4750);
    tycoon.save.readOnly=true;assert.equal(tycoon.awardRace('readonly',1000),false);
  }finally{tycoon.dispose();driving.dispose();}
});
