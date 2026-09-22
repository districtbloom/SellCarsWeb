import test from 'node:test';
import assert from 'node:assert/strict';
import { PerspectiveCamera, Vector3 } from 'three';
import { Element } from './test-dom.mjs';
import { importTypescript } from './import-typescript.mjs';
const { StartScreen } = await importTypescript(new URL('../src/world/StartScreen.ts', import.meta.url));
function dom() {
  globalThis.window = new EventTarget();
  globalThis.document = { body:new Element(), hidden:false, createElement(tag) { const e=new Element(); e.tagName=tag.toUpperCase(); return e; } };
}
const key = (code, repeat = false) => window.dispatchEvent(Object.assign(new Event('keydown', {cancelable:true}), {code, repeat}));

test('title panorama rotates in place, pauses while hidden and restores the gameplay camera on Start',()=>{
  dom();let starts=0;const camera=new PerspectiveCamera(60,1.7);camera.position.set(-320,18,144);camera.lookAt(-300,4,110);
  const position=camera.position.clone(),rotation=camera.quaternion.clone(),center=new Vector3(260,85,0),screen=new StartScreen(()=>starts++);
  screen.showPanorama(camera,center);const initial=camera.quaternion.clone();
  for(let i=0;i<120;i++)screen.tick(.1);
  assert.ok(camera.position.equals(center));assert.ok(camera.quaternion.angleTo(initial)>.5);assert.equal(camera.fov,65);
  document.hidden=true;const paused=camera.quaternion.clone();screen.tick(.1);assert.ok(camera.quaternion.angleTo(paused)<1e-7);
  document.hidden=false;camera.aspect=.7;screen.button.onclick();screen.button.onclick();
  assert.equal(starts,1);assert.equal(screen.active,false);assert.ok(camera.position.equals(position));assert.ok(camera.quaternion.angleTo(rotation)<1e-7);
  assert.equal(camera.fov,60);assert.equal(camera.aspect,.7,'Resizing on the title screen is preserved');
  assert.equal(document.body.children.length,0);assert.equal(document.body.classList.contains('on-title-screen'),false);
});

test('title consumes gameplay shortcuts while loading and accepts one non-repeated Enter after loading',()=>{
  dom();let starts=0,gameKeys=0;const screen=new StartScreen(()=>starts++);window.addEventListener('keydown',()=>gameKeys++);
  key('KeyW');key('KeyP');key('Enter');screen.button.onclick();assert.equal(gameKeys,0);assert.equal(starts,0);
  assert.equal(screen.button.disabled,true);screen.showPanorama(new PerspectiveCamera(),new Vector3(0,85,0));
  assert.equal(screen.button.textContent,'START');assert.equal(document.activeElement,screen.button);
  key('Enter',true);assert.equal(starts,0);key('Enter');assert.equal(starts,1);assert.equal(gameKeys,0);
  key('KeyW');assert.equal(gameKeys,1,'Gameplay keys are released after Start');screen.dispose();
});
