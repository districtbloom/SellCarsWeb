import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { ObjectLoader, Vector3 } from 'three';
import { Vec3 } from 'cannon-es';
import { Element } from './test-dom.mjs';
import { importTypescript } from './import-typescript.mjs';
const root=new URL('../src/world/',import.meta.url);
const {CarInstance}=await importTypescript(new URL('driving/CarInstance.ts',root));
const {AIRacer}=await importTypescript(new URL('activities/AIRacer.ts',root));
const {OpenWorldTown}=await importTypescript(new URL('OpenWorldTown.ts',root));
const {RuntimeMap,roadGraph,raceRoute}=await importTypescript(new URL('activities/RuntimeMap.ts',root));
globalThis.document={createElement(){return new Element();}};
const json=JSON.parse(await readFile(new URL('../public/scenes/main.scene.json',import.meta.url),'utf8'));
for(const image of json.images??[])image.url={data:[255,255,255,255],width:1,height:1,type:'Uint8Array'};
test('AI racers share player physics, steer through real town routes, and clean up their bodies',async()=>{
  const scene=await new ObjectLoader().parseAsync(json),source=new CarInstance(scene,14),world=source.physics.world;
  source.physics.addStaticBox(new Vec3(500,.5,500),new Vec3(0,-.5,0));source.place(new Vector3(-500,0,100),0);
  const town=new OpenWorldTown(scene,world,()=>new Vector3(500,0,0)),map=new RuntimeMap(scene);
  try{
    for(const seed of [1,5,20,31,42]){
      let state=seed;const random=()=>((state=(Math.imul(state,1664525)+1013904223)>>>0)/4294967296);
      const points=raceRoute(roadGraph(map.roads),random,seed>20?13:6).slice(1),a=points[0],b=points[1],count=world.bodies.length;
      const racer=new AIRacer(scene,source,'Rival',new Vector3(a.x,0,a.z),Math.atan2(a.x-b.x,a.z-b.z),points,.92);
      assert.equal(racer.car.physics.world,world);assert.equal(racer.car.physics.body.mass,source.physics.body.mass);
      for(const key of Object.keys(source.physics.tuning))assert.equal(racer.car.physics.tuning[key],source.physics.tuning[key]*(key==='maxSpeedKmh'?.92:1),key);
      for(let step=0;step<120*240&&racer.finishedAt===undefined;step++){
        racer.beforeStep(1/120,step>=120);world.step(1/120);racer.afterStep((step-120)/120,step>=120);
      }
      assert.ok(racer.finishedAt!==undefined,JSON.stringify({seed,index:racer.index,points,position:racer.position(),speed:racer.car.physics.speed,segment:racer.segment}));
      racer.dispose();assert.equal(world.bodies.length,count);
    }
  }finally{town.dispose();source.dispose();}
});

test('three slower opponents drive a full hard route together with shared collisions',async()=>{
  const scene=await new ObjectLoader().parseAsync(json),source=new CarInstance(scene,14),world=source.physics.world;
  source.physics.addStaticBox(new Vec3(500,.5,500),new Vec3(0,-.5,0));source.place(new Vector3(-500,0,100),0);
  const town=new OpenWorldTown(scene,world,()=>new Vector3(500,0,0)),map=new RuntimeMap(scene),racers=[];
  try{
    let state=44;const random=()=>((state=(Math.imul(state,1664525)+1013904223)>>>0)/4294967296);
    const points=raceRoute(roadGraph(map.roads),random,13).slice(1),[a,b]=points,length=Math.hypot(b.x-a.x,b.z-a.z),dx=(b.x-a.x)/length,dz=(b.z-a.z)/length;
    for(let i=0;i<3;i++){const side=i%2===0?6:-6,back=i===0?0:22;racers.push(new AIRacer(scene,source,'Rival '+i,new Vector3(a.x+dz*side-dx*back,0,a.z-dx*side-dz*back),Math.atan2(-dx,-dz),points,.96));}
    for(let step=0;step<120*300&&!racers.every(r=>r.finishedAt!==undefined);step++){
      for(const r of racers)r.beforeStep(1/120,step>=360);world.step(1/120);for(const r of racers)r.afterStep((step-360)/120,step>=360);
    }
    assert.ok(racers.some(r=>r.finishedAt<180),'At least one rival finishes within the hard-race deadline');
    assert.ok(racers.every(r=>r.finishedAt!==undefined),JSON.stringify(racers.map(r=>({name:r.name,index:r.index,position:r.position(),speed:r.car.physics.speed,finished:r.finishedAt}))));
  }finally{racers.forEach(r=>r.dispose());town.dispose();source.dispose();}
});
