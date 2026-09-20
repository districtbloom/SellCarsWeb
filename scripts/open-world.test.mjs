import test from 'node:test';
import assert from 'node:assert/strict';
import { Body, Box, SAPBroadphase, Vec3, World } from 'cannon-es';
import { Box3, Group, InstancedMesh, PerspectiveCamera, Scene, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';
const root=new URL('../src/world/',import.meta.url);
const {PlayerController,PLAYER_STEP_HEIGHT}=await importTypescript(new URL('driving/PlayerController.ts',root));
const {createBlockCharacter,BlockCharacterAnimator,disposeBlockCharacter}=await importTypescript(new URL('components/blockCharacter.ts',root));
const {OpenWorldTown,TOWN_ROAD_X,TOWN_ROAD_Z}=await importTypescript(new URL('OpenWorldTown.ts',root));

function box(world,x,y,z,w,h,d){const b=new Body({mass:0,material:world.defaultMaterial,shape:new Box(new Vec3(w/2,h/2,d/2)),position:new Vec3(x,y,z)});world.addBody(b);return b;}
function walkFixture(height,ceiling=false){
  const world=new World({gravity:new Vec3(0,-9.81,0)});world.broadphase=new SAPBroadphase(world);
  box(world,0,-.5,0,30,1,30);box(world,0,height/2,-2.5,5,height,3);
  if(ceiling)box(world,0,2,-2.5,5,.2,3);
  const player=new PlayerController(world,new Scene()),camera=new PerspectiveCamera();player.place(new Vec3(0,.92,1));
  const simulate=(seconds,throttle)=>{for(let i=0;i<seconds*120;i++){player.step(1/120,{throttle,steering:0,brake:false},camera);world.step(1/120);player.sync(1/120);}};
  simulate(.4,0);return{world,player,simulate};
}
test('player walks onto a half-scene-unit step and back down without jumping',()=>{
  assert.equal(PLAYER_STEP_HEIGHT,.5);
  const {player,simulate}=walkFixture(.5*.25);
  simulate(.8,1);assert.ok(player.body.position.z < -1.5,`Reached step: ${player.body.position.z}`);
  assert.ok(player.body.position.y>.99&&player.body.position.y<1.06,`Stood on step: ${player.body.position.y}`);
  simulate(.7,-1);assert.ok(player.body.position.z > -.4);assert.ok(Math.abs(player.body.position.y-.9)<.04);
  player.dispose();
});
test('step assistance refuses taller ledges and insufficient headroom',()=>{
  for(const [height,ceiling] of [[.7*.25,false],[.5*.25,true],[1,false]]){
    const {player,simulate}=walkFixture(height,ceiling);simulate(1.2,1);
    assert.ok(player.body.position.z > -.75,`Blocked by ${height}m ledge, ceiling ${ceiling}: ${player.body.position.z}`);
    assert.ok(player.body.position.y<.96);player.dispose();
  }
});

test('a successful physics jump keeps its airborne pose through apex and descent, then resets on landing, teleport or seating',()=>{
  const world=new World({gravity:new Vec3(0,-9.81,0)});box(world,0,-.5,0,40,1,40);
  const player=new PlayerController(world,new Scene()),camera=new PerspectiveCamera(),dt=1/120;
  const limbs=['Left arm pivot','Right arm pivot','Left leg pivot','Right leg pivot'].map(name=>player.mesh.getObjectByName(name));
  const tick=(frames=1)=>{for(let i=0;i<frames;i++){player.step(dt,{throttle:0,steering:0,brake:false},camera);world.step(dt);player.sync(dt);}};
  const airbornePose=()=>{assert.ok(limbs[0].rotation.x>1.8&&limbs[1].rotation.x>1.8,'Both arms stay raised');assert.ok(limbs[2].rotation.x>.1&&limbs[3].rotation.x>.1,'Legs retain their airborne tuck');};
  try{
    player.place(new Vec3(0,.92,0));tick(60);assert.ok(player.grounded);assert.equal(player.jumping,false);
    const floorHeight=player.body.position.y;player.requestJump();tick();assert.ok(player.jumping);assert.ok(player.body.velocity.y>5);
    tick(20);assert.equal(player.grounded,false);airbornePose();assert.ok(player.body.position.y>floorHeight+.5);
    const elapsed=player.jumpTime,velocity=player.body.velocity.y;player.requestJump();tick();
    assert.ok(player.jumpTime>elapsed,'An airborne jump request cannot restart the pose');assert.ok(player.body.velocity.y<velocity,'An airborne request cannot add another impulse');
    player.openingProgress=.3;player.sync(0);assert.ok(Math.abs(limbs[0].rotation.x-Math.PI/3)<1e-8,'Repair pose overrides jump pose');player.openingProgress=undefined;
    player.typingTime=.2;player.sync(0);assert.equal(limbs[2].rotation.x,0,'Typing remains the higher-priority action pose');player.typingTime=undefined;player.sync(0);airbornePose();
    let sawApex=false,sawDescent=false;
    for(let i=0;i<240&&player.jumping;i++){
      tick();
      if(player.jumping&&Math.abs(player.body.velocity.y)<.12){sawApex=true;airbornePose();}
      if(player.jumping&&player.body.velocity.y< -1){sawDescent=true;airbornePose();}
    }
    assert.ok(sawApex&&sawDescent);assert.ok(player.grounded);assert.equal(player.jumping,false);
    assert.ok(limbs.every(limb=>Math.abs(limb.rotation.x)<1e-8&&Math.abs(limb.rotation.z)<1e-8),'Landing restores the idle pose');
    player.requestJump();tick(20);assert.ok(player.jumping);player.requestJump();player.place(new Vec3(2,.92,0));
    assert.equal(player.jumping,false);assert.equal(player.jumpTime,0);assert.equal(player.jumpPending,false);assert.ok(limbs.every(limb=>limb.rotation.x===0));
    tick(60);player.requestJump();tick(20);assert.ok(player.jumping);player.setSeated(true);player.sync(0);
    assert.equal(player.jumping,false);assert.equal(player.jumpTime,0);assert.equal(player.mesh.visible,false);assert.ok(limbs.every(limb=>limb.rotation.x===0));
    player.setSeated(false);player.place(new Vec3(2,.92,0));tick(30);assert.equal(player.jumping,false);
  }finally{player.dispose();}
});
test('walking rig swings opposite limbs, idles smoothly, and ignores teleports',()=>{
  const character=createBlockCharacter('Walker',0x56b5ef),animator=new BlockCharacterAnimator(character,character,true);
  animator.update(1/60);
  for(let i=0;i<12;i++){character.position.z-=.2;animator.update(1/60);}
  const arm=character.getObjectByName('Left arm pivot'),leg=character.getObjectByName('Left leg pivot');
  assert.ok(Math.abs(arm.rotation.x)>.2);assert.equal(arm.rotation.x,-leg.rotation.x);
  for(let i=0;i<80;i++)animator.update(1/60);
  assert.ok(Math.abs(arm.rotation.x)<.001);
  character.position.x+=1000;animator.update(1/60);assert.ok(Math.abs(arm.rotation.x)<.001);
  const player=new PlayerController(new World(),new Scene());assert.ok(player.mesh instanceof Group);
  assert.ok(player.mesh.getObjectByName('Head'));assert.ok(player.mesh.getObjectByName('Face'));
  assert.ok(Math.abs(new Box3().setFromObject(player.mesh).getSize(new Vector3()).y-7.2)<.01);
  player.dispose();disposeBlockCharacter(character);
});
test('seeded town has separate zones, open road lanes, bounded batches, and disposable collision',()=>{
  const old=globalThis.document;globalThis.document={createElement:()=>({getContext:()=>({fillText(){}})})};
  const world=new World(),scene=new Scene(),focus=new Vector3(500,0,100);
  try {
    const town=new OpenWorldTown(scene,world,()=>focus);
    assert.equal(town.lots.length,20);assert.deepEqual([...new Set(town.lots.map(l=>l.zone))].sort(),['commercial','park','residential','service']);
    const meshes=town.root.children.filter(c=>c instanceof InstancedMesh);assert.ok(meshes.length<110,`${meshes.length} render batches`);
    assert.ok(world.bodies.length<250,`${world.bodies.length} colliders`);
    assert.ok(town.cameraObstacles.every(o=>o.position.x>140||o.position.y<=0),'Keeps the dealership expansion clear');
    for(const x of TOWN_ROAD_X)for(const z of TOWN_ROAD_Z)for(const b of world.bodies){
      b.updateAABB();const lo=b.aabb.lowerBound,hi=b.aabb.upperBound;
      assert.ok(!(hi.y>.05 && lo.y<1.5 && lo.x<x*.25+1 && hi.x>x*.25-1 && lo.z<z*.25+2 && hi.z>z*.25-2),'Intersection stays driveable');
    }
    const digest=meshes.map(m=>Array.from(m.instanceMatrix.array));
    const other=new OpenWorldTown(new Scene(),new World(),()=>focus);
    assert.deepEqual(other.root.children.filter(c=>c instanceof InstancedMesh).map(m=>Array.from(m.instanceMatrix.array)),digest,'Stable randomized layout');
    other.dispose();town.dispose();assert.equal(world.bodies.length,0);assert.equal(scene.children.length,0);
  }finally{globalThis.document=old;}
});

test('sprint increases actual ground speed and animation cadence, then returns to walking',()=>{
  const world=new World({gravity:new Vec3(0,-9.81,0)});box(world,0,-.5,0,100,1,100);
  const player=new PlayerController(world,new Scene()),camera=new PerspectiveCamera();player.place(new Vec3(0,.92,0));
  const simulate=(seconds,sprint)=>{for(let i=0;i<seconds*120;i++){player.step(1/120,{throttle:1,steering:0,brake:false,sprint},camera);world.step(1/120);player.sync(1/120);}};
  try {
    simulate(1,false);const walk=Math.abs(player.body.velocity.z);simulate(1,true);const sprint=Math.abs(player.body.velocity.z);
    assert.ok(walk>4.5&&walk<5.1);assert.ok(sprint>8&&sprint<8.6);assert.ok(sprint>walk*1.6);
    simulate(1,false);assert.ok(Math.abs(player.body.velocity.z)<5.1);
    const cycles=speed=>{
      const rig=createBlockCharacter('Cadence',0x56b5ef),animator=new BlockCharacterAnimator(rig);animator.update(1/60);
      const arm=rig.getObjectByName('Left arm pivot');let crossings=0,previous=0;
      for(let i=0;i<240;i++){rig.position.z-=speed/60;animator.update(1/60);if(previous*arm.rotation.x<0)crossings++;previous=arm.rotation.x;}
      disposeBlockCharacter(rig);return crossings;
    };
    assert.ok(cycles(34)>cycles(20)*1.5,'Distance-driven sprint gait cycles faster');
  } finally {player.dispose();}
});

test('opening animation reaches with both hands, lifts arms before torso and restores idle pose',()=>{
  const rig=createBlockCharacter('Mechanic',0x56b5ef),animator=new BlockCharacterAnimator(rig);
  const left=rig.getObjectByName('Left arm pivot'),right=rig.getObjectByName('Right arm pivot'),torso=rig.getObjectByName('Character rig'),head=rig.getObjectByName('Head');
  animator.opening(.3);assert.ok(Math.abs(left.rotation.x-Math.PI/3)<.001);assert.equal(left.rotation.x,right.rotation.x);assert.ok(head.rotation.x<0);
  const before=left.rotation.x;animator.opening(.7);assert.ok(left.rotation.x>before);assert.equal(left.rotation.x,right.rotation.x);assert.ok(Math.abs(torso.rotation.x)<Math.abs(left.rotation.x));
  animator.update(1/60,false);assert.ok(left.rotation.x===0);assert.ok(right.rotation.x===0);assert.equal(torso.rotation.x,0);assert.equal(head.rotation.x,0);
  disposeBlockCharacter(rig);
});

test('typing moves both hands rapidly while torso, head and legs remain still',()=>{
  const rig=createBlockCharacter('Typist',0x56b5ef),animator=new BlockCharacterAnimator(rig);
  const left=rig.getObjectByName('Left arm pivot'),right=rig.getObjectByName('Right arm pivot');
  const stable=['Character rig','Head','Left leg pivot','Right leg pivot'].map(name=>rig.getObjectByName(name));
  try {
    animator.typing(.1);const hands=[left.rotation.x,right.rotation.x];
    const poses=stable.map(node=>({position:node.position.toArray(),rotation:node.rotation.toArray()}));
    animator.typing(.2);assert.notEqual(left.rotation.x,hands[0]);assert.notEqual(right.rotation.x,hands[1]);
    assert.deepEqual(stable.map(node=>({position:node.position.toArray(),rotation:node.rotation.toArray()})),poses);
    assert.ok(Math.abs((left.rotation.x-1.15)+(right.rotation.x-1.15))<1e-10,'Hands alternate');
  } finally {disposeBlockCharacter(rig);}
});

test('built NPCs use player proportions and visibly walk, talk and repair instead of static imported figures',async()=>{
  const {createNPCCharacter}=await importTypescript(new URL('components/blockCharacter.ts',root));
  const {NPCRoutine,importedNPCs,BuiltNPCRoutines}=await importTypescript(new URL('tycoon/NPCRoutines.ts',root));
  const {freshJourney}=await importTypescript(new URL('tycoon/TycoonModel.ts',root));
  const {readFile}=await import('node:fs/promises');
  const source=JSON.parse(await readFile(new URL('../public/tycoon/dealership.json',import.meta.url),'utf8'));
  const npc=createNPCCharacter('Staff',0x56b5ef),player=new PlayerController(new World(),new Scene()),routine=new NPCRoutine(npc);
  const castRoot=new Group();new BuiltNPCRoutines(castRoot,source.parts);
  try {
    const npcSize=new Box3().setFromObject(npc).getSize(new Vector3()),playerSize=new Box3().setFromObject(player.mesh).getSize(new Vector3());
    assert.ok(npcSize.distanceTo(playerSize)<1e-9);
    assert.ok(importedNPCs(source.parts).length>50,'Authored cast is detected by complete humanoid stems');
    assert.ok(castRoot.children.every(person=>person.getObjectByName('Face')&&person.getObjectByName('Left arm pivot')));
    const target=new Vector3(12,0,0);routine.walk(target,.1,new Vector3());routine.animate(.1,0);
    const start=npc.position.clone();for(let i=0;i<30;i++){routine.walk(target,.1);routine.animate(.1,i*.1);}
    assert.ok(npc.position.distanceTo(start)>5);assert.ok(npc.position.distanceTo(target)<.5);
    const arm=npc.getObjectByName('Left arm pivot');routine.animate(.1,1,'talk',new Vector3(12,0,-10));const talk=arm.rotation.x;
    routine.animate(.1,1.3,'talk');assert.notEqual(arm.rotation.x,talk);
    routine.animate(.1,2,'repair');assert.ok(arm.rotation.x>.9);assert.ok(npc.getObjectByName('Character rig').rotation.x<0);
    const cast=new BuiltNPCRoutines(new Group(),source.parts),state=freshJourney();cast.sync(state,.1);
    const early=cast.cast.filter(actor=>actor.person.visible).length;state.journey.step=240;cast.sync(state,.1);
    assert.ok(cast.cast.filter(actor=>actor.person.visible).length>early,'NPCs honor construction gates');
    for(const actor of cast.cast)disposeBlockCharacter(actor.person);
  } finally {player.dispose();disposeBlockCharacter(npc);for(const person of [...castRoot.children])disposeBlockCharacter(person);}
});
