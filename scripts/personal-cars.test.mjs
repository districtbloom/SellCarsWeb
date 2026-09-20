import test from 'node:test';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';
const root=new URL('../src/world/tycoon/',import.meta.url);
const M=await importTypescript(new URL('TycoonModel.ts',root));
const {TycoonSession}=await importTypescript(new URL('TycoonSession.ts',root));
const {TycoonSave,validState,SAVE_KEY}=await importTypescript(new URL('TycoonSave.ts',root));
const {personalCars,ownedPersonalModels,personalModel}=await importTypescript(new URL('PersonalCars.ts',root));
const context={position:[0,0],onFoot:true};

test('all fourteen personal cars have distinct prices, with lightweight starters and performance premiums',()=>{
  assert.deepEqual(personalCars.map(c=>c.id).sort((a,b)=>a-b),Array.from({length:14},(_,i)=>i+1));
  assert.equal(new Set(personalCars.map(c=>c.price)).size,14);
  assert.equal(personalCars[0].id,9);assert.equal(personalCars.at(-1).id,1);
  assert.equal(personalCars[0].price,1500);assert.equal(personalCars.at(-1).price,65000);
  assert.equal(personalCars.at(-1).tuning.horsepower,650);
  assert.ok(personalCars.every(c=>Number.isInteger(c.price)&&c.price>0&&c.description&&c.name));
});

test('purchases protect work reserves and require valid, affordable, unowned models; owned selection is free',()=>{
  const s=M.freshJourney(),session=new TycoonSession(s);s.cash=100000;
  assert.equal(session.dispatch({type:'BuyPersonal',modelId:9},context).ok,false,'Tutorial purchases stay protected');
  s.journey.tutorialComplete=true;
  for(const modelId of [-1,0,15,1.5,NaN])assert.equal(session.dispatch({type:'BuyPersonal',modelId},context).ok,false);
  assert.equal(session.dispatch({type:'BuyPersonal',modelId:9},{...context,onFoot:false}).ok,false);
  s.cash=1499;assert.equal(session.dispatch({type:'BuyPersonal',modelId:9},context).ok,false);
  s.cash=M.leadBudget(s,false)[0]+1500-1;M.lead(s);assert.equal(session.dispatch({type:'BuyPersonal',modelId:9},context).ok,false,'Rare deal reserve stays protected');
  s.lead=undefined;const start=s.cash;
  assert.ok(session.dispatch({type:'BuyPersonal',modelId:9},context).ok);
  assert.equal(s.cash,start-1500);assert.equal(personalModel(s.personal),9);
  assert.equal(session.dispatch({type:'BuyPersonal',modelId:9},context).ok,false);
  assert.equal(session.dispatch({type:'SelectPersonal',modelId:1},context).ok,false);
  assert.ok(session.dispatch({type:'BuyPersonal',modelId:10},context).ok);
  assert.ok(session.dispatch({type:'SelectPersonal',modelId:9},context).ok);
  assert.equal(s.cash,start-3900);assert.deepEqual(ownedPersonalModels(s.personal),[9,10]);
  assert.equal(s.ledger.filter(row=>row.kind==='personal-car').length,2);
  s.personal.status='atLead';assert.equal(session.dispatch({type:'SelectPersonal',modelId:10},context).ok,false);
});

test('garage collection, selection and physical parking pose survive saves; old coupe ownership is preserved',()=>{
  const s=M.freshJourney();s.journey.tutorialComplete=true;s.cash=200000;
  for(const option of personalCars)assert.ok(M.selectPersonal(s,option.id,true));
  s.personal.pos=[21,-22];s.personal.yaw=.7;s.personal.height=.2;
  const data=new Map(),storage={getItem:k=>data.get(k)??null,setItem:(k,v)=>data.set(k,v),removeItem:k=>data.delete(k)};
  const save=new TycoonSave(storage,{sessionId:'garage'});assert.ok(save.write(s));
  assert.deepEqual(save.load().personal,s.personal);assert.equal(data.size,1);
  const old=M.fresh();old.personal={id:'your-coupe',pos:[43.66667,-27],home:[43.66667,-27],status:'parked'};
  assert.ok(validState(old));assert.equal(personalModel(old.personal),12);assert.deepEqual(ownedPersonalModels(old.personal),[12]);
  const cash=old.cash;assert.ok(M.selectPersonal(old,12,false));assert.equal(old.cash,cash);
  assert.deepEqual(old.personal.ownedModels,[12]);
  for(const personal of [{...s.personal,modelId:15},{...s.personal,ownedModels:[9,9]},
    {...s.personal,ownedModels:[9]},{...s.personal,ownedModels:[]},{...s.personal,height:NaN}]) {
    assert.equal(validState({...s,personal}),false);
  }
  assert.ok(JSON.parse(data.get(SAVE_KEY)).state.personal.ownedModels.includes(1));
});

test('buying the old display milestone keeps a car already bought from the garage and still unlocks the rare lead',()=>{
  const s=M.freshJourney();s.journey.tutorialComplete=true;s.cash=100000;
  assert.ok(M.selectPersonal(s,6,true));s.journey.step=21;
  assert.ok(M.buyPad(s,M.nextPad(s).id));assert.equal(personalModel(s.personal),6);
  assert.deepEqual(ownedPersonalModels(s.personal),[6]);assert.ok(s.rareCallAt>s.clock);
});
