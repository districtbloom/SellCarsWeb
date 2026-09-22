import test from 'node:test';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';
import { exerciseManualRepair } from './repair-test-driver.mjs';
import { Element } from './test-dom.mjs';
import { PerspectiveCamera, Scene } from 'three';
import { World } from 'cannon-es';
const root = new URL('../src/world/tycoon/', import.meta.url);
const M = await importTypescript(new URL('TycoonModel.ts', root));
const { repairProgress, performRepair, drainProgress, OIL_DRAIN_SECONDS, REPAIR_OPEN_SECONDS } = await importTypescript(new URL('RepairGame.ts', root));
const { TycoonSession } = await importTypescript(new URL('TycoonSession.ts', root));
const { moveVehicle } = await importTypescript(new URL('VehicleRoute.ts', root));

function repairFixture(id) {
  const state = M.fresh(); M.arrive(state, 1);
  state.car.status = 'repair'; state.car.owned = true; state.car.route = undefined;
  state.car.plan = { cost: 0, seconds: 5, funded: true, jobs: [{ id, name: id, cost: 0, seconds: 5, done: false, started: false, progress: 0 }] };
  assert.ok(M.startJob(state));
  return state;
}
function open(state) { for (let i = 0; i < REPAIR_OPEN_SECONDS * 10; i++) M.tick(state, .1); }

test('manual repairs wait for two-second opening and actual inputs; remote, seated and duplicate work is rejected', () => {
  const s = repairFixture('RunningGear'), session = new TycoonSession(s), context = { position: [...s.car.pos], onFoot: true };
  const action = { type: 'RepairInput', input: { kind: 'wheel', index: 0 } };
  assert.equal(session.dispatch(action, context).ok, false);
  for (let i = 0; i < 19; i++) M.tick(s, .1);
  assert.equal(session.dispatch(action, context).ok, false);
  M.tick(s, .1);
  assert.equal(session.dispatch(action, { ...context, onFoot: false }).ok, false);
  assert.equal(session.dispatch(action, { ...context, position: [1000, 1000] }).ok, false);
  assert.ok(session.dispatch(action, context).ok);
  assert.equal(session.dispatch(action, context).ok, false);
  for (let i = 0; i < 200; i++) M.tick(s, .1);
  assert.equal(M.job(s).progress, 1 / 32, 'Waiting never substitutes for wheel or bolt work');
  assert.equal(performRepair(s, { kind: 'bolt', index: 7 }), false, 'Cannot fasten an empty hub');
  for (const index of [-1, 4, NaN, .5]) assert.equal(performRepair(s, { kind: 'wheel', index }), false);
  for (let i = 0; i < 7; i++) assert.ok(performRepair(s, { kind: 'bolt', index: i }), 'Rapid bolt clicks complete immediately');
  assert.equal(M.job(s).progress, 8 / 32);
  exerciseManualRepair(s, input => session.dispatch({ type: 'RepairInput', input }, context).ok);
  const job = M.job(s); M.tick(s, .1);
  assert.ok(job.done); assert.equal(s.car.status, 'ready');
});

test('oil service needs timed drainage, separate old-filter removal and new-filter installation, then full oil', () => {
  const s = repairFixture('Mechanical'); open(s);
  const game=repairProgress(M.job(s),s.clock);assert.equal(game.bolts.length,2);assert.equal(game.filterInstalled,false);
  assert.equal(performRepair(s,{kind:'oil-filter'}),false);
  assert.equal(performRepair(s,{kind:'pour',amount:.05}),false);
  assert.equal(performRepair(s,{kind:'bolt',index:1}),false);
  assert.equal(performRepair(s,{kind:'bolt',index:2}),false);
  assert.ok(performRepair(s,{kind:'bolt',index:0}));
  assert.equal(performRepair(s,{kind:'bolt',index:0}),false);
  assert.equal(drainProgress(game,s.clock),0);
  for(let i=0;i<23;i++)M.tick(s,.1);
  assert.ok(drainProgress(game,s.clock)<1);assert.equal(performRepair(s,{kind:'bolt',index:1}),false);
  assert.equal(performRepair(s,{kind:'pour',amount:.05}),false);
  M.tick(s,.100001);assert.equal(drainProgress(game,s.clock),1);
  assert.equal(performRepair(s,{kind:'oil-filter'}),false,'Old filter must be removed before installing the replacement');
  assert.ok(performRepair(s,{kind:'bolt',index:1}));
  assert.equal(game.filterInstalled,false);assert.equal(performRepair(s,{kind:'pour',amount:.05}),false,'An empty filter socket cannot accept oil');
  assert.ok(performRepair(s,{kind:'oil-filter'}));assert.equal(game.filterInstalled,true);assert.equal(performRepair(s,{kind:'oil-filter'}),false);
  for(const amount of [0,-1,.061,Infinity,NaN])assert.equal(performRepair(s,{kind:'pour',amount}),false);
  for(let i=0;i<19;i++)assert.ok(performRepair(s,{kind:'pour',amount:.05}));
  assert.ok(M.job(s).progress<1);assert.ok(performRepair(s,{kind:'pour',amount:.05}));
  assert.equal(M.job(s).progress,1);assert.equal(performRepair(s,{kind:'pour',amount:.05}),false);
});

test('an empty oil-filter socket survives saves and older completed replacement stages migrate without repeating work',async()=>{
  const {validState}=await importTypescript(new URL('TycoonSave.ts',root));
  const s=repairFixture('Mechanical');open(s);performRepair(s,{kind:'bolt',index:0});
  for(let i=0;i<25;i++)M.tick(s,.1);performRepair(s,{kind:'bolt',index:1});
  const restored=M.copy(s),game=repairProgress(M.job(restored),restored.clock);assert.ok(validState(restored));
  assert.equal(game.filterInstalled,false);assert.equal(performRepair(restored,{kind:'pour',amount:.05}),false);
  assert.ok(performRepair(restored,{kind:'oil-filter'}));exerciseManualRepair(restored);M.tick(restored,.1);assert.equal(restored.car.status,'ready');
  const old=M.copy(s);delete M.job(old).repair.filterInstalled;
  assert.ok(repairProgress(M.job(old),old.clock).filterInstalled,'Earlier saves treated removal as completed replacement');
  assert.ok(performRepair(old,{kind:'pour',amount:.05}));assert.ok(validState(old));
  M.job(old).repair.filterInstalled='forged';assert.equal(validState(old),false);
});

test('drainage resumes from saved progress and old five-bolt repairs migrate',()=>{
  const s=repairFixture('Mechanical');open(s);performRepair(s,{kind:'bolt',index:0});
  for(let i=0;i<12;i++)M.tick(s,.1);
  const restored=M.copy(s),g=repairProgress(M.job(restored),restored.clock);
  assert.ok(drainProgress(g,restored.clock)>.49&&drainProgress(g,restored.clock)<.51);
  assert.equal(performRepair(restored,{kind:'bolt',index:1}),false);
  for(let i=0;i<13;i++)M.tick(restored,.1);
  assert.ok(performRepair(restored,{kind:'bolt',index:1}));
  const old=repairFixture('Mechanical');open(old);M.job(old).repair.bolts=[true,true,true,true,false];
  const migrated=repairProgress(M.job(old),old.clock);assert.deepEqual(migrated.bolts,[true,false]);
  assert.equal(drainProgress(migrated,old.clock),1);assert.ok(performRepair(old,{kind:'bolt',index:1}));
});

test('partial repair work survives a state snapshot without repeating wheels or bolts', () => {
  const s = repairFixture('RunningGear'); open(s);
  assert.ok(performRepair(s, { kind: 'wheel', index: 2 }));
  assert.ok(performRepair(s, { kind: 'bolt', index: 14 }));
  const restored = M.copy(s), game = repairProgress(M.job(restored), restored.clock);
  assert.ok(game.wheels[2]); assert.ok(game.bolts[14]);
  assert.equal(performRepair(restored, { kind: 'wheel', index: 2 }), false);
  exerciseManualRepair(restored); M.tick(restored, .1);
  assert.equal(restored.car.status, 'ready');
});

test('tuning replaces one air filter and four spark plugs with matching upgrades and preserves partial work', async () => {
  const { validState } = await importTypescript(new URL('TycoonSave.ts', root));
  for (const id of ['Tune', 'Tune_Performance']) {
    const s = repairFixture(id), session = new TycoonSession(s), context = { position: [...s.car.pos], onFoot: true };
    const send = input => session.dispatch({ type: 'RepairInput', input }, context).ok;
    assert.equal(send({ kind: 'remove', index: 0 }), false, 'Tuning requires its opening animation');
    open(s); const game = repairProgress(M.job(s), s.clock);
    assert.equal(game.kind, 'tuning'); assert.equal(game.bolts.length, 5); assert.equal(game.targets.length, 5);
    assert.equal(send({ kind: 'install', index: 0, part: 'filter' }), false, 'Old part must be removed first');
    for (const index of [-1, 5, .5, NaN]) assert.equal(send({ kind: 'remove', index }), false);
    assert.equal(send({ kind: 'bolt', index: 0 }), false); assert.equal(send({ kind: 'pour', amount: .05 }), false);
    assert.equal(send({ kind: 'target', index: 0 }), false, 'Generic service clicks cannot skip component replacement');
    assert.ok(send({ kind: 'remove', index: 0 })); assert.equal(M.job(s).progress, .1);
    assert.equal(send({ kind: 'remove', index: 0 }), false);
    assert.equal(send({ kind: 'install', index: 0, part: 'plug' }), false);
    assert.ok(send({ kind: 'install', index: 0, part: 'filter' })); assert.equal(M.job(s).progress, .2);
    assert.equal(send({ kind: 'install', index: 0, part: 'filter' }), false);
    assert.ok(send({ kind: 'remove', index: 3 }));
    assert.equal(send({ kind: 'install', index: 3, part: 'filter' }), false);
    assert.equal(send({ kind: 'install', index: 3, part: 'forged' }), false);
    const restored = M.copy(s); assert.ok(validState(restored));
    const resumed = repairProgress(M.job(restored), restored.clock);
    assert.deepEqual(resumed.bolts, [true, false, false, true, false]);
    assert.deepEqual(resumed.targets, [true, false, false, false, false]);
    assert.equal(performRepair(restored, { kind: 'remove', index: 3 }), false);
    exerciseManualRepair(restored); M.tick(restored, .1); assert.equal(restored.car.status, 'ready');
    assert.ok(validState(restored));
  }
});

test('saved oil-based tuning work migrates to component replacement without becoming finished early', async () => {
  const { validState } = await importTypescript(new URL('TycoonSave.ts', root));
  const s = repairFixture('Tune'); open(s); const job = M.job(s);
  job.progress = .65; job.repair = { kind: 'engine', openedAt: 0, wheels: [false, false, false, false], bolts: [true, true], targets: Array(6).fill(false), oil: .125, complete: false, drainStarted: 0 };
  assert.ok(validState(s));
  const restored = M.copy(s), migrated = repairProgress(M.job(restored), restored.clock);
  assert.equal(migrated.kind, 'tuning'); assert.equal(M.job(restored).progress, .6); assert.equal(migrated.complete, false);
  assert.deepEqual(migrated.bolts, [true, true, true, false, false]);
  assert.deepEqual(migrated.targets, [true, true, true, false, false]);
  assert.equal(migrated.drainStarted, undefined); assert.equal(migrated.oil, 0); assert.ok(validState(restored));
  exerciseManualRepair(restored); M.tick(restored, .1); assert.equal(restored.car.status, 'ready');
});

test('each non-wheel service has six distinct tasks and rejects invalid/repeated task indices', () => {
  for (const id of ['Body', 'Wash', 'Paint_Exterior', 'Detail_QC', 'Photo_Listing']) {
    const s = repairFixture(id); open(s);
    assert.equal(performRepair(s, { kind: 'target', index: 6 }), false);
    for (let index = 0; index < 6; index++) {
      assert.ok(performRepair(s, { kind: 'target', index }));
      assert.equal(performRepair(s, { kind: 'target', index }), false);
    }
    M.tick(s, .1); assert.equal(s.car.status, 'ready');
  }
});

test('automatic car routes roll through turns with distance-bounded steering and exact arrivals', () => {
  for (const fps of [30, 144]) {
    const car = { pos: [0, 0], angle: -Math.PI / 2, route: { target: 'repair', points: [[0, 0], [20, 0], [20, 20]], step: 1 } };
    let turnedWhileMoving = false, arrived;
    for (let i = 0; car.route && i < fps * 30; i++) {
      const old = [...car.pos], yaw = car.angle;
      arrived = moveVehicle(car, 1 / fps);
      const distance = Math.hypot(car.pos[0] - old[0], car.pos[1] - old[1]);
      const turn = Math.abs(Math.atan2(Math.sin(car.angle - yaw), Math.cos(car.angle - yaw)));
      assert.ok(turn <= distance * .85 + 1e-9, 'Heading changes require travel');
      if (turn > .001 && distance > .001) turnedWhileMoving = true;
      assert.ok(car.pos.every(Number.isFinite));
    }
    assert.equal(arrived, 'repair'); assert.deepEqual(car.pos, [20, 20]); assert.ok(turnedWhileMoving);
    const stopped = M.copy(car); moveVehicle(car, 1); assert.deepEqual(M.copy(car), stopped);
  }
});

test('saved vehicle routes resume forward without revisiting completed waypoints', () => {
  let car = { pos: [0, 0], angle: -Math.PI / 2, route: { target: 'repair', points: [[0, 0], [20, 0], [20, 20]], step: 1 } };
  for (let i = 0; car.pos[1] < 6 && i < 3000; i++) moveVehicle(car, 1 / 60);
  assert.ok(car.pos[1] >= 6); car = M.copy(car);
  const progress = car.pos[1];
  for (let i = 0; car.route && i < 1800; i++) {
    moveVehicle(car, 1 / 60);
    assert.ok(car.pos[1] >= progress - .01, 'Reload must not send the vehicle backwards around the route');
  }
  assert.deepEqual(car.pos, [20, 20]);
});

test('steered car travel stays aligned with its wheels even when departing a perpendicular bay', () => {
  const car={pos:[0,0],angle:0,route:{target:'sales',points:[[0,0],[20,0],[20,20],[35,20]],step:1}};
  let arrived;
  for(let i=0;car.route&&i<6000;i++){
    const previous=[...car.pos];arrived=moveVehicle(car,.1);
    const dx=car.pos[0]-previous[0],dz=car.pos[1]-previous[1],distance=Math.hypot(dx,dz);
    if(distance>.0001&&car.route){
      const movement=Math.atan2(-dx,dz),slip=Math.asin(Math.abs(Math.sin(movement-car.angle)));
      assert.ok(slip<Math.PI/12,`Car must drive along its facing/reverse direction: ${(slip*180/Math.PI).toFixed(1)} degrees of lateral slip`);
    }
  }
  assert.equal(arrived,'sales');assert.deepEqual(car.pos,[35,20]);
});

test('real repair workbench gates controls, preserves canceled progress, saves button inputs and closes on completion', async () => {
  globalThis.HTMLElement=Element;globalThis.window=new EventTarget();
  globalThis.document={body:new Element(),activeElement:new Element(),createElement(tag){const e=new Element();e.tagName=tag.toUpperCase();return e;},pointerLockElement:null};
  const {RepairController}=await importTypescript(new URL('RepairController.ts',root));
  const {PlayerController}=await importTypescript(new URL('../driving/PlayerController.ts',root));
  const {TycoonSave}=await importTypescript(new URL('TycoonSave.ts',root));
  const state=repairFixture('RunningGear'),session=new TycoonSession(state),player=new PlayerController(new World(),new Scene());
  const records=new Map(),save=new TycoonSave({getItem:key=>records.get(key)??null,setItem:(key,value)=>records.set(key,value),removeItem:key=>records.delete(key)},{legacy:true,sessionId:'repair-ui'});
  let menu=false,savedInputs=0;
  const camera=new PerspectiveCamera();camera.position.set(37,22,-41);camera.lookAt(4,3,9);
  const cameraPose={position:camera.position.toArray(),quaternion:camera.quaternion.toArray()};
  const controller=new RepairController(state,player,camera,input=>{
    const result=session.dispatch({type:'RepairInput',input},{position:state.car.pos,onFoot:true});
    if(result.ok){assert.ok(save.write(state));savedInputs++;}return result.ok;
  },open=>menu=open);
  const advance=frames=>{for(let i=0;i<frames;i++){M.tick(state,.1);controller.tick(.1);}};
  const buttons=kind=>controller.root.querySelectorAll(`[data-${kind}]`);
  try {
    controller.begin(M.job(state));assert.ok(menu);assert.equal(controller.root.hidden,true);assert.equal(controller.root.children.length,0,'Opening pose has no accompanying UI');
    advance(19);assert.equal(buttons('wheel').length,0);assert.equal(controller.root.hidden,true);assert.ok(player.openingProgress>.9);
    advance(1);assert.equal(buttons('wheel').length,4);assert.equal(buttons('bolt').length,28);assert.equal(player.openingProgress,undefined);
    assert.deepEqual({position:camera.position.toArray(),quaternion:camera.quaternion.toArray()},cameraPose,'Opening animation preserves the player camera');
    assert.equal(controller.objectiveTarget().element,buttons('wheel')[0]);
    assert.ok(buttons('bolt').every(b=>b.disabled));buttons('wheel')[0].onclick();assert.equal(controller.objectiveTarget().element,buttons('wheel')[1]);
    buttons('bolt')[0].onclick();assert.equal(M.job(state).progress,2/32);assert.equal(controller.tool.hidden,false);
    controller.close();assert.equal(menu,false);assert.equal(controller.root.hidden,true);
    controller.begin(M.job(state));advance(20);
    assert.equal(buttons('wheel')[0].disabled,true);assert.equal(buttons('bolt')[0].disabled,true);
    const {openedAt:savedOpening,...savedWork}=save.load().car.plan.jobs[0].repair;
    const {openedAt:currentOpening,...currentWork}=M.job(state).repair;
    assert.deepEqual(savedWork,currentWork,'Saved state retains actual wheel and bolt inputs');
    assert.ok(currentOpening>savedOpening,'Reopening plays access animation again');
    for(const wheel of buttons('wheel'))if(!wheel.disabled)wheel.onclick();
    assert.equal(controller.objectiveTarget().element,buttons('bolt')[1]);
    for(const [index,bolt] of buttons('bolt').entries())if(!bolt.disabled){
      bolt.getBoundingClientRect=()=>({left:index*5,top:index*3,width:10,height:10});bolt.onclick();
      assert.equal(bolt.disabled,true,'Click commits before decorative power-tool motion');
      assert.equal(controller.tool.style.left,index*5+5+'px');
    }
    assert.equal(savedInputs,32);assert.equal(M.job(state).progress,1);advance(1);
    assert.equal(controller.active,false);assert.equal(menu,false);assert.equal(player.openingProgress,undefined);assert.equal(state.car.status,'ready');
  } finally {controller.dispose();player.dispose();}
});

test('engine workbench uses a single drain bolt and pours only from the tilted bottle tip above the actual funnel', async () => {
  globalThis.HTMLElement=Element;globalThis.window=new EventTarget();
  globalThis.document={body:new Element(),activeElement:new Element(),createElement(tag){const e=new Element();e.tagName=tag.toUpperCase();return e;},pointerLockElement:null};
  const {RepairController}=await importTypescript(new URL('RepairController.ts',root));
  const {bottleTip,aboveFunnel}=await importTypescript(new URL('RepairGeometry.ts',root));
  const {PlayerController}=await importTypescript(new URL('../driving/PlayerController.ts',root));
  const state=repairFixture('Mechanical'),player=new PlayerController(new World(),new Scene());
  const controller=new RepairController(state,player,new PerspectiveCamera(),input=>performRepair(state,input),()=>{});
  const advance=frames=>{for(let i=0;i<frames;i++){M.tick(state,.1);controller.tick(.1);}};
  const r={left:100,top:50,width:800,height:400},f={left:650,top:200,width:100,height:100};
  const offset=bottleTip(0,0,45);
  assert.ok(Math.abs(offset.x-36.850)<.002&&Math.abs(offset.y+14.869)<.002,'SVG nozzle rotates about bottle center');
  const pointer=(tipX,tipY,type='mouse')=>({clientX:r.left+tipX-offset.x,clientY:r.top+tipY-offset.y,pointerType:type,pointerId:1});
  try {
    controller.begin(M.job(state));advance(20);assert.equal(controller.root.querySelector('.repair-pan'),null);
    const bolts=controller.root.querySelectorAll('[data-bolt]');assert.equal(bolts.length,2);assert.equal(bolts[0].style.left,'50%');assert.equal(bolts[0].style.top,'50%');
    assert.equal(bolts[1].disabled,true);assert.ok(bolts[1].classList.contains('filter'));assert.ok(bolts[1].classList.contains('used-filter'));assert.equal(bolts[1].getAttribute('aria-label'),'Remove used oil filter');
    assert.equal(controller.objectiveTarget().element,bolts[0]);bolts[0].onclick();assert.equal(controller.objectiveTarget(),undefined);assert.equal(controller.drain.hidden,false);assert.equal(bolts[0].hidden,true);
    advance(23);assert.equal(bolts[1].disabled,true);advance(2);assert.equal(controller.drain.hidden,true);assert.equal(bolts[1].disabled,false);bolts[1].onclick();
    const gameBeforeFit=repairProgress(M.job(state),state.clock);assert.equal(gameBeforeFit.filterInstalled,false);assert.equal(controller.funnel.hidden,true);
    let replacement=controller.root.querySelector('.repair-new-filter'),socket=controller.root.querySelector('.repair-filter-socket');
    assert.equal(replacement.hidden,false);assert.equal(socket.hidden,false);socket.onclick();assert.equal(gameBeforeFit.filterInstalled,false,'Empty socket cannot install a part that has not been picked up');
    controller.board.onpointerdown({clientX:500,clientY:100,pointerType:'mouse',pointerId:1});advance(2);assert.equal(gameBeforeFit.oil,0);assert.equal(controller.stream.hidden,true);
    replacement.onclick();assert.equal(controller.carry.dataset.icon,'oilFilter');controller.close();controller.begin(M.job(state));advance(20);
    replacement=controller.root.querySelector('.repair-new-filter');socket=controller.root.querySelector('.repair-filter-socket');
    socket.onclick();assert.equal(gameBeforeFit.filterInstalled,false,'Reopening retains the empty socket but clears held selection');
    assert.equal(controller.objectiveTarget().element,replacement);replacement.onclick();assert.equal(controller.objectiveTarget().element,socket);socket.onclick();assert.equal(controller.objectiveTarget().element,controller.funnel);assert.equal(gameBeforeFit.filterInstalled,true);assert.ok(socket.classList.contains('installed'));assert.ok(socket.disabled);assert.ok(replacement.hidden);
    const installedProgress=M.job(state).progress;socket.onclick();assert.equal(M.job(state).progress,installedProgress,'Repeated fitting cannot grant progress');
    assert.equal(controller.carry.dataset.icon,'bottle');assert.equal(controller.funnel.hidden,false);
    const game=repairProgress(M.job(state),state.clock),board=controller.board;
    board.getBoundingClientRect=()=>r;controller.funnel.getBoundingClientRect=()=>f;
    board.onpointerdown(pointer(100,100));advance(1);assert.equal(controller.stream.hidden,true,'Oil waits for visible tilt');advance(1);
    assert.equal(controller.stream.hidden,false);assert.equal(game.oil,0,'Missed funnel spills without credit');
    assert.ok(Math.abs(parseFloat(controller.stream.style.left)-100)<.01);assert.ok(Math.abs(parseFloat(controller.stream.style.top)-100)<.01,'Stream starts exactly at bottle tip');
    assert.ok(Math.abs(parseFloat(controller.stream.style.height)-300)<.01,'A miss falls to board bottom');
    board.onpointermove(pointer(400,180));advance(2);assert.equal(game.oil,0,'Being over engine alone gives no credit');
    board.onpointermove(pointer(600,180));advance(2);assert.equal(game.oil,0,'Bottle tip below funnel opening gives no credit');
    board.onpointermove(pointer(600,100));advance(2);assert.ok(game.oil>0);assert.equal(parseFloat(controller.stream.style.height),50,'Caught oil stops at funnel opening');
    board.onpointerup();const released=game.oil;advance(1);assert.equal(game.oil,released);assert.equal(controller.stream.hidden,true);
    board.onpointerdown(pointer(100,100,'touch'));advance(2);assert.equal(game.oil,released);assert.equal(controller.carry.classList.contains('tipped'),false);
    board.onpointermove(pointer(600,100,'touch'));advance(2);assert.ok(controller.carry.classList.contains('tipped'));assert.ok(game.oil>released);
    window.dispatchEvent(new Event('blur'));const blurred=game.oil;advance(1);assert.equal(game.oil,blurred,'Blur releases a held pour');
    assert.equal(aboveFunnel({x:552,y:100},{left:550,top:150,width:100,height:100}),false,'Rim is outside the catch opening');
    board.onpointerdown(pointer(600,100,'touch'));advance(30);assert.equal(controller.active,false);assert.equal(state.car.status,'ready');
  } finally {controller.dispose();player.dispose();}
});

test('tuning workbench removes five old parts and fits matching upgrades through its actual tray and sockets', async () => {
  globalThis.HTMLElement=Element;globalThis.window=new EventTarget();
  globalThis.document={body:new Element(),activeElement:new Element(),createElement(tag){const e=new Element();e.tagName=tag.toUpperCase();return e;},pointerLockElement:null};
  const {RepairController}=await importTypescript(new URL('RepairController.ts',root));
  const {PlayerController}=await importTypescript(new URL('../driving/PlayerController.ts',root));
  const state=repairFixture('Tune_Performance'),session=new TycoonSession(state),player=new PlayerController(new World(),new Scene());
  let accepted=0;
  const controller=new RepairController(state,player,new PerspectiveCamera(),input=>{
    const ok=session.dispatch({type:'RepairInput',input},{position:state.car.pos,onFoot:true}).ok;if(ok)accepted++;return ok;
  },()=>{});
  const advance=frames=>{for(let i=0;i<frames;i++){M.tick(state,.1);controller.tick(.1);}};
  const components=()=>controller.root.querySelectorAll('[data-component]');
  const upgrade=part=>controller.root.querySelectorAll('[data-upgrade]').find(button=>button.dataset.upgrade===part);
  try {
    controller.begin(M.job(state));advance(19);assert.equal(components().length,0);advance(1);
    assert.equal(components().length,5);assert.equal(controller.root.querySelector('.repair-funnel'),null);
    assert.equal(components()[0].getAttribute('aria-label'),'Remove old air filter');
    for(const button of components()){button.onclick();assert.ok(button.classList.contains('empty'));assert.equal(button.disabled,false);}
    assert.equal(accepted,5);assert.equal(M.job(state).progress,.5);assert.equal(controller.tool.hidden,false);
    assert.equal(controller.objectiveTarget().element,upgrade('filter'));components()[0].onclick();assert.equal(accepted,5,'An empty socket requires a selected replacement');
    upgrade('plug').onclick();assert.equal(controller.carry.dataset.icon,'plug');components()[0].onclick();assert.equal(accepted,5,'Plug cannot fill the air-filter socket');
    upgrade('filter').onclick();assert.equal(controller.objectiveTarget().element,components()[0]);assert.equal(controller.carry.dataset.icon,'filter');
    controller.board.getBoundingClientRect=()=>({left:100,top:50,width:800,height:400});
    controller.board.onpointermove({clientX:300,clientY:150,pointerType:'touch'});
    assert.equal(controller.carry.style.left,'25%');assert.equal(controller.carry.style.top,'25%');
    components()[0].onclick();assert.ok(components()[0].classList.contains('upgraded'));assert.ok(upgrade('filter').disabled);
    assert.equal(controller.carry.hidden,true);assert.equal(controller.tool.hidden,true);
    upgrade('plug').onclick();for(const index of [1,2,3])components()[index].onclick();
    assert.equal(accepted,9);assert.equal(M.job(state).progress,.9);
    controller.close();controller.begin(M.job(state));advance(20);
    assert.ok(components().slice(0,4).every(button=>button.disabled));assert.ok(components()[4].classList.contains('empty'));
    components()[4].onclick();assert.equal(accepted,9,'Reopening does not retain an invisible selected part');
    upgrade('plug').onclick();components()[4].onclick();assert.equal(accepted,10);assert.ok(upgrade('plug').disabled);
    advance(1);assert.equal(controller.active,false);assert.equal(state.car.status,'ready');
  }finally{controller.dispose();player.dispose();}
});
