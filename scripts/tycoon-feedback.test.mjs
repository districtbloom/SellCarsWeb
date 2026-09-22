import test from 'node:test';
import assert from 'node:assert/strict';
import { Element } from './test-dom.mjs';
import { importTypescript } from './import-typescript.mjs';
const root=new URL('../src/world/tycoon/',import.meta.url);
const M=await importTypescript(new URL('TycoonModel.ts',root));
const P=await importTypescript(new URL('PartsStation.ts',root));
const E=await importTypescript(new URL('PartsEconomy.ts',root));
const O=await importTypescript(new URL('OfflineEarnings.ts',root));
const {padColor}=await importTypescript(new URL('PurchaseCategories.ts',root));
const {TycoonHUD}=await importTypescript(new URL('TycoonHUD.ts',root));
const {CashGainEffects}=await importTypescript(new URL('CashGainEffects.ts',root));
function dom(){
  globalThis.HTMLElement=Element;globalThis.window=Object.assign(new EventTarget(),{innerWidth:1280,innerHeight:720});
  globalThis.document={body:new Element(),activeElement:new Element(),pointerLockElement:null,createElement(tag){const node=new Element();node.tagName=tag.toUpperCase();return node;}};
}
const hudFor=(state,extra={})=>new TycoonHUD({state,dispatch(){return{ok:false};},navigate(){},setMenu(){},saveStatus:()=>'',...extra});
const gains=()=>document.body.querySelectorAll('.tycoon-cash-gain');

test('category billboard colors match the actual green or blue purchase pads and clear between prompts',()=>{
  dom();const hud=hudFor(M.freshJourney());
  try{
    const colors=[];
    for(const category of ['Money-making','Architectural','Cosmetic']){
      hud.showHint('[ E ] Build upgrade\nCategory: '+category,{x:320,y:200});
      const line=hud.root.querySelector('.tycoon-hint-category');assert.ok(line);assert.equal(line.textContent,'Category: '+category);
      assert.equal(line.style.color,'#'+padColor(category).toString(16).padStart(6,'0'));colors.push(line.style.color);
      assert.equal(line.parentElement.children[0].textContent,'[ E ] Build upgrade');
      assert.equal(line.parentElement.style.left,'320px');assert.equal(line.parentElement.style.top,'200px');
    }
    assert.equal(colors[0],colors[1]);assert.notEqual(colors[0],colors[2]);
    hud.showHint('[ E ] Meet seller',{x:450,y:300});assert.ok(hud.root.querySelector('.tycoon-hint-category').hidden);
    hud.showHint('');assert.equal(hud.hint.hidden,true);
  }finally{hud.dispose();}
});

test('cash feedback clones the wallet, flies from the player toward its live destination, pauses when hidden and removes itself',()=>{
  dom();const wallet=document.createElement('button');wallet.className='tycoon-wallet';wallet.textContent='$123';wallet.setAttribute('id','wallet');wallet.onclick=()=>assert.fail('A cosmetic clone must not retain wallet actions');
  let bounds={left:100,top:20,width:100,height:40};wallet.getBoundingClientRect=()=>bounds;
  const effects=new CashGainEffects(wallet);
  try{
    effects.setOrigin({x:900,y:500});for(const amount of [0,-1,NaN,Infinity])effects.credit(amount);effects.tick(0,true);assert.equal(gains().length,0);
    effects.credit(28);effects.tick(0,true);const clone=gains()[0];assert.ok(clone);assert.notEqual(clone,wallet);assert.ok(clone.classList.contains('tycoon-wallet'));
    assert.equal(clone.textContent,'+$28');assert.equal(wallet.textContent,'$123');assert.equal(clone.getAttribute('id'),null);
    assert.equal(clone.getAttribute('tabindex'),'-1');assert.equal(clone.getAttribute('aria-hidden'),'true');assert.equal(clone.getAttribute('disabled'),'');assert.equal(clone.onclick,undefined);
    assert.equal(clone.style.left,'900px');assert.equal(clone.style.top,'500px');effects.tick(.1,true);effects.tick(.1,true);
    assert.ok(parseFloat(clone.style.left)<900);assert.ok(parseFloat(clone.style.top)<500);
    const paused={...clone.style};effects.tick(10,false);assert.ok(effects.root.hidden);assert.deepEqual(clone.style,paused);
    bounds={left:300,top:40,width:100,height:40};for(let i=0;i<8;i++)effects.tick(.1,true);
    assert.ok(Math.abs(parseFloat(clone.style.left)-350)<8,'A resized wallet remains the destination');assert.ok(Number(clone.style.opacity)<1);
    effects.tick(.1,true);assert.equal(gains().length,0);assert.equal(clone.parentElement,null);
  }finally{effects.dispose();}
  assert.equal(document.body.querySelector('.tycoon-cash-effects'),null);
});

test('HUD animates every new positive transaction once, including income offset by spending and credits while a menu is open',()=>{
  dom();const s=M.freshJourney();s.journey.step=1;s.journey.intakePaused=true;const hud=hudFor(s);
  const tick=frames=>{for(let i=0;i<frames;i++)hud.update(.1);};
  try{
    hud.setCashOrigin({x:600,y:400});assert.ok(P.startParts(s));P.completeHillRun(s,14);assert.ok(E.buyParts(s,'small'));
    assert.equal(s.cash,328,'Income and expense share the same observation frame');hud.update(0);assert.deepEqual(gains().map(node=>node.textContent),['+$28']);
    hud.update();hud.update();assert.equal(gains().length,1,'Repeated renders do not duplicate credit');tick(12);assert.equal(gains().length,0);
    assert.ok(E.buyParts(s,'small'));hud.update();assert.equal(gains().length,0,'Spending never creates a positive effect');
    O.applyOfflineReward(s,{seconds:100,rate:.75,amount:75,capped:false});hud.root.hidden=true;tick(20);assert.equal(gains().length,0);
    hud.root.hidden=false;hud.update();assert.deepEqual(gains().map(node=>node.textContent),['+$75']);tick(12);
    assert.ok(M.arrive(s,1));s.car.route=undefined;s.car.status='buyer';s.car.owned=true;assert.ok(M.openDeal(s));const sale=s.car.quote.accepted;assert.ok(M.sell(s));
    hud.open('wallet');hud.update();assert.ok(!hud.top.hidden&&hud.top.classList.contains('wallet-only'));assert.ok(gains().some(node=>node.textContent==='+$'+sale.toLocaleString('en-US')));
    tick(15);assert.equal(gains().length,0);hud.update();assert.equal(gains().length,0);
  }finally{hud.dispose();}
});

test('loading a save replays only its new offline receipt, while the selling bar stays independent of hidden menus',()=>{
  dom();const s=M.freshJourney();s.ledger.push({amount:1000,kind:'sale',subject:'Historic sale'});
  const receipt={seconds:100,rate:.75,amount:75,capped:false};O.applyOfflineReward(s,receipt);
  const hud=hudFor(s,{offline:()=>receipt});
  try{
    assert.deepEqual(gains().map(node=>node.textContent),['+$75'],'Historical ledger credits are not replayed on load');
    for(let i=0;i<15;i++)hud.update(.1);assert.equal(gains().length,0);hud.close();hud.update();assert.equal(gains().length,0);
    hud.root.hidden=true;hud.showSellingProgress(.375,{x:321,y:145});const progress=document.body.querySelector('.tycoon-selling-progress');
    assert.equal(progress.parentElement,document.body);assert.equal(progress.hidden,false);assert.equal(progress.getAttribute('role'),'progressbar');assert.equal(progress.getAttribute('aria-valuenow'),'38');
    assert.equal(progress.style.left,'321px');assert.equal(progress.style.top,'145px');assert.equal(progress.querySelector('.tycoon-selling-fill').style.width,'37.5%');
    hud.showSellingProgress(2,{x:1,y:2});assert.equal(progress.getAttribute('aria-valuenow'),'100');
    hud.showSellingProgress(.2);assert.ok(progress.hidden);hud.showSellingProgress();assert.ok(progress.hidden);
  }finally{hud.dispose();}
  assert.equal(document.body.querySelector('.tycoon-selling-progress'),null);
});

test('onboarding uses only welcome and phone dialogs, then targets actual controls',()=>{
  dom();const state=M.freshJourney(),hud=hudFor(state);let navigated=0;hud.host.navigate=()=>navigated++;
  try{
    assert.equal(hud.words.textContent,"Welcome to Sell Cars! I'll show you the ropes!");assert.equal(hud.guide.hidden,false);
    assert.equal(hud.objectiveTarget().element,hud.next);hud.next.onclick();assert.equal(state.onboarding.welcomed,true);assert.equal(navigated,0);assert.ok(hud.guide.hidden);
    const caller=M.fresh();M.lead(caller);state.lead=caller.lead;hud.update();assert.equal(hud.guide.hidden,false);assert.match(hud.words.textContent,/phone is ringing/);
    hud.next.onclick();assert.match(hud.words.textContent,/Answer the phone/);assert.equal(hud.objectiveTarget().element,hud.smartphone.answerTarget);
    hud.next.onclick();assert.ok(hud.guide.hidden);assert.ok(state.onboarding.phonePrompted);hud.update();assert.ok(hud.guide.hidden);
    hud.open('wallet');assert.match(hud.objectiveTarget().label,/Return to your objective/);hud.close();
    state.lead.status='answered';hud.update();assert.equal(hud.objectiveTarget(),undefined);assert.ok(hud.guide.hidden);
  }finally{hud.dispose();}
  const restored=hudFor(M.copy(state));assert.ok(restored.guide.hidden);restored.dispose();
});
