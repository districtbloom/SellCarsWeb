import test from 'node:test';
import assert from 'node:assert/strict';
import { Group, Scene, PerspectiveCamera, Vector3 } from 'three';
import { World as PhysicsWorld } from 'cannon-es';
import { Element } from './test-dom.mjs';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/activities/', import.meta.url);
const { RuntimeMap, roadGraph, raceRoute } = await importTypescript(new URL('RuntimeMap.ts', root));
const { HillDriveModel } = await importTypescript(new URL('HillDriveModel.ts', root));
const { RaceSystem, raceDifficulty } = await importTypescript(new URL('RaceSystem.ts', root));
const { BackgroundMusic } = await importTypescript(new URL('../feedback/BackgroundMusic.ts', root));
const { OpenWorldTown } = await importTypescript(new URL('../OpenWorldTown.ts', root));
const random = seed => () => ((seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0) / 4294967296);
const roads = [...[140,360,580,800,1020].map(x=>({x,z:70,width:28,depth:1150,vertical:true})), ...[-480,-260,-40,180,400,620].map(z=>({x:580,z,width:908,depth:28,vertical:false}))];
function dom() {
  globalThis.window = new EventTarget(); globalThis.HTMLElement = Element; globalThis.innerWidth = 1280; globalThis.innerHeight = 720;
  globalThis.document = Object.assign(new EventTarget(), { hidden:false, body:new Element(), createElement(tag) { const e=new Element();e.tagName=tag.toUpperCase();return e; } });
}
test('runtime map discovers changes, transformed POIs and hidden/deleted places',()=>{
  const scene=new Scene(),parent=new Group(),poi=new Group(),road=new Group();parent.position.set(10,0,20);poi.position.set(3,0,4);poi.userData.mapPOI={label:'Garage'};
  road.userData.mapRoad=roads[0];parent.add(poi);scene.add(parent,road);const map=new RuntimeMap(scene);
  assert.equal(map.roads.length,1);assert.deepEqual([map.pois[0].x,map.pois[0].z],[13,24]);parent.visible=false;map.refresh();assert.equal(map.pois.length,0);
  road.removeFromParent();map.refresh();assert.equal(map.roads.length,0);
});
test('1000 generated race routes stay on roads, never overlap, backtrack or cut across blocks',()=>{
  const graph=roadGraph(roads);assert.equal(graph.length,30);
  for(let seed=1;seed<=1000;seed++){
    const route=raceRoute(graph,random(seed));assert.equal(route.length,17);
    assert.equal(new Set(route.map(p=>p.x+':'+p.z)).size,route.length);
    for(let i=1;i<route.length;i++){
      const a=route[i-1],b=route[i];assert.ok((a.x===b.x)!==(a.z===b.z));assert.ok(Math.hypot(a.x-b.x,a.z-b.z)>=100);
      assert.ok(roads.some(r=>r.vertical ? a.x===r.x&&b.x===r.x&&Math.max(Math.abs(a.z-r.z),Math.abs(b.z-r.z))<=r.depth/2 : a.z===r.z&&b.z===r.z&&Math.max(Math.abs(a.x-r.x),Math.abs(b.x-r.x))<=r.width/2));
      if(i>1){const p=route[i-2];assert.ok((a.x-p.x)*(b.x-a.x)+(a.z-p.z)*(b.z-a.z)>=0,'No U-turns');}
    }
  }
  assert.deepEqual(raceRoute(roadGraph([])),[]);assert.deepEqual(raceRoute(roadGraph([roads[0]])),[]);
});
test('actual generated town supplies its roads and POIs to the runtime graph, including approach junctions',()=>{
  dom();const scene=new Scene(),town=new OpenWorldTown(scene,new PhysicsWorld(),()=>new Vector3());
  try{
    const map=new RuntimeMap(scene);assert.equal(map.roads.length,14);assert.equal(map.lots.length,20);assert.ok(map.pois.some(p=>p.label==='SELL CARS'));
    const graph=roadGraph(map.roads);assert.equal(graph.length,32);
    for(let seed=1;seed<=1000;seed++){
      const route=raceRoute(graph,random(seed));assert.equal(route.length,17);
      for(let i=0;i<route.length;i++)for(let j=i+1;j<route.length;j++)assert.ok(Math.hypot(route[i].x-route[j].x,route[i].z-route[j].z)>30,'Checkpoint hit volumes never overlap');
    }
  }finally{town.dispose();}
});
test('hill model is stable at rest, times out at 30s and uses maximum forward distance',()=>{
  const idle=new HillDriveModel(random(1));for(let i=0;i<3601;i++)idle.tick(1/120,0);
  assert.equal(idle.ended,'time');assert.equal(idle.reward,0);assert.ok(Math.abs(idle.angle)<.01);
  const a=new HillDriveModel(random(10));for(let i=0;i<240;i++)a.tick(1/120,1);assert.ok(a.x>15);const best=a.distance;
  for(let i=0;i<240;i++)a.tick(1/120,-1);assert.ok(a.distance>=best);assert.equal(a.reward,Math.floor(a.distance)*2);
});
test('air controls rotate in opposite directions, roof impacts crash and pickups collect only once',()=>{
  const a=new HillDriveModel(random(1)),b=new HillDriveModel(random(1));a.y=b.y=30;
  for(let i=0;i<30;i++){a.tick(1/120,1);b.tick(1/120,-1);}assert.ok(a.angle<0&&b.angle>0);
  const crash=new HillDriveModel(random(1));crash.angle=Math.PI;crash.y=.6;crash.tick(1/60,0);assert.equal(crash.ended,'crashed');
  const c=new HillDriveModel(random(1));c.pickups.push({x:c.x,y:c.y,collected:false});c.tick(1/120,0);assert.ok(c.remaining>34.9);c.tick(1/120,0);assert.ok(c.remaining<35);
});
test('procedural hills are deterministic per seed and repeated physics steps are frame-rate independent',()=>{
  const a=new HillDriveModel(random(12)),b=new HillDriveModel(random(12)),c=new HillDriveModel(random(13));assert.deepEqual(a.hills,b.hills);assert.notDeepEqual(a.hills,c.hills);
  for(let i=0;i<240;i++)a.tick(1/120,1);for(let i=0;i<60;i++)b.tick(1/30,1);assert.ok(Math.abs(a.x-b.x)<1e-8);assert.ok(Math.abs(a.angle-b.angle)<1e-8);
});
test('race events recur at five minutes, gate entry, pay a winner once and clean up cancellation',()=>{
  dom();let now=0,participant,prizes=[];const p=new Vector3();
  const body={get position(){return {x:p.x*.25,y:p.y*.25,z:p.z*.25};},velocity:{setZero(){}},poseRevision:0};
  const source={physics:{body,poseRevision:0},place(point){p.copy(point);p.y=3;}};
  const driving={isDriving:false,drivenCarId:14,get drivenCar(){return this.isDriving?source:undefined;},focusPosition:p,enabled:true,setControlsEnabled(v){this.enabled=v;},physics:{body},feedback:{audio:{play(){}}},addPhysicsParticipant(value){participant=value;return()=>{participant=undefined;};}};
  const map={map:{refresh(){},roads},route:[]};const races=new RaceSystem(new Scene(),driving,new PerspectiveCamera(),map,()=>false,()=>now,(id,amount)=>{prizes.push({id,amount});return true;},random(10));
  races.addOpponents=()=>{}; // Controller accounting fixture; real opponents are exercised in race-ai.test.mjs.
  const advance=seconds=>{if(participant)for(let i=0;i<Math.ceil(seconds*120);i++){participant?.beforeStep(1/120);participant?.afterStep(1/120);}now+=seconds*1000;races.tick();};
  const key=code=>window.dispatchEvent(Object.assign(new Event('keydown'),{code}));
  try{
    advance(299);assert.equal(races.event,undefined);advance(1);assert.ok(races.event);const first=races.event;
    assert.ok(first.prize>=250&&first.prize<=3500);assert.equal(first.expires,600);assert.ok(map.event);
    key('KeyF');assert.equal(races.active,false);driving.isDriving=true;key('KeyF');assert.equal(races.active,false);
    p.set(first.points[0].x,3,first.points[0].z);key('KeyF');assert.ok(races.active);assert.equal(races.event,undefined);assert.equal(driving.enabled,false);advance(3.1);assert.equal(driving.enabled,true);
    const points=[...races.run.points];
    for(const target of points.slice(1)){const origin=p.clone();for(let step=1;step<=6;step++){p.set(origin.x+(target.x-origin.x)*step/6,3,origin.z+(target.z-origin.z)*step/6);advance(.2);}}
    assert.equal(races.active,false);assert.match(races.announcement.textContent,/FINISH/);assert.equal(map.route.length,0);assert.deepEqual(prizes,[{id:first.id,amount:first.prize}]);advance(1);assert.equal(prizes.length,1);
    now=600000;races.tick();assert.ok(races.event);assert.notEqual(races.event,first);assert.equal(races.event.expires,900);
    const second=races.event;now=900000;races.tick();assert.notEqual(races.event,second);assert.equal(races.event.expires,1200);
    p.set(races.event.points[0].x,3,races.event.points[0].z);key('KeyF');assert.ok(races.active);key('KeyX');assert.equal(races.active,false);assert.equal(prizes.length,1);assert.equal(participant,undefined);
    now=1200000;races.tick();p.set(races.event.points[0].x,3,races.event.points[0].z);key('KeyF');assert.ok(races.active);source.physics.poseRevision++;advance(.1);assert.equal(races.active,false);assert.match(races.announcement.textContent,/reset/);assert.equal(prizes.length,1);
  }finally{races.dispose();}assert.equal(document.body.children.length,0);
});
test('music loops exclusively, retries gesture activation, pauses hidden/muted tracks and disposes',async()=>{
  dom();const audios=[];globalThis.Audio=class{paused=true;constructor(src){this.src=src;audios.push(this);}play(){this.paused=false;return Promise.resolve();}pause(){this.paused=true;}removeAttribute(){}load(){}};
  const music=new BackgroundMusic('/');const settle=()=>{for(let i=0;i<14;i++)music.tick(.1);};assert.equal(audios.length,0);window.dispatchEvent(new Event('pointerdown'));assert.equal(audios.length,1);assert.ok(audios[0].loop);
  for(const name of ['city','racing','moneyearnminigame','tycoon']){music.setLocation(name);settle();assert.equal(audios.filter(a=>!a.paused).length,1);assert.ok(audios.find(a=>!a.paused).src.endsWith(name+'.mp3'));}
  document.hidden=true;document.dispatchEvent(new Event('visibilitychange'));assert.ok(audios.every(a=>a.paused));document.hidden=false;document.dispatchEvent(new Event('visibilitychange'));
  music.button.onclick();assert.ok(audios.every(a=>a.paused));music.dispose();assert.equal(document.body.children.length,0);delete globalThis.Audio;
});

test('prize raises route length, opponent count, speed and deadline difficulty',()=>{
  const easy=raceDifficulty(250),hard=raceDifficulty(3500);
  assert.ok(hard.nodes>easy.nodes&&hard.opponents>easy.opponents&&hard.speedFactor>easy.speedFactor&&hard.seconds<easy.seconds);
  assert.ok(easy.speedFactor>0&&hard.speedFactor<1);
  for(const prize of [250,750,1500,2500,3500])for(let seed=1;seed<=100;seed++)assert.equal(raceRoute(roadGraph(roads),random(seed),raceDifficulty(prize).nodes).length,raceDifficulty(prize).nodes*2-1);
});
test('music crossfades smoothly and can reverse a transition without a volume jump',()=>{
  dom();const tracks=[];globalThis.Audio=class{paused=true;volume=1;constructor(src){this.src=src;tracks.push(this);}play(){this.paused=false;return Promise.resolve();}pause(){this.paused=true;}removeAttribute(){}load(){}};
  const music=new BackgroundMusic('/');
  try{
    window.dispatchEvent(new Event('pointerdown'));assert.equal(tracks[0].volume,0);for(let i=0;i<13;i++)music.tick(.1);assert.equal(tracks[0].volume,.32);
    music.setLocation('city');assert.equal(tracks[0].volume,.32);assert.equal(tracks[1].volume,0);assert.ok(tracks.every(t=>!t.paused));
    for(let i=0;i<6;i++)music.tick(.1);const volumes=tracks.map(t=>t.volume);assert.ok(volumes.every(v=>v>0&&v<.32));assert.ok(Math.abs(volumes[0]+volumes[1]-.32)<1e-9);
    music.setLocation('tycoon');assert.deepEqual(tracks.map(t=>t.volume),volumes);music.tick(.1);assert.ok(tracks[0].volume>volumes[0]&&tracks[1].volume<volumes[1]);
    for(let i=0;i<13;i++)music.tick(.1);assert.equal(tracks[0].volume,.32);assert.equal(tracks[1].volume,0);assert.ok(tracks[1].paused);
  }finally{music.dispose();delete globalThis.Audio;}
});
