import test from 'node:test';
import assert from 'node:assert/strict';
import { BoxGeometry, Mesh, MeshBasicMaterial, PerspectiveCamera, Quaternion, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';

const { SmartFollowCamera } = await importTypescript(new URL('../src/world/driving/SmartFollowCamera.ts', import.meta.url));
const { lockCameraPose, cameraPoseState } = await importTypescript(new URL('../src/world/driving/CameraPoseLock.ts', import.meta.url));

function harness(obstacles = [], locked = true) {
  const oldWindow = globalThis.window;
  const oldDocument = globalThis.document;
  globalThis.window = new EventTarget();
  globalThis.document = new EventTarget();
  const canvas = new EventTarget();
  document.pointerLockElement = null;
  canvas.requestPointerLock = () => {
    document.pointerLockElement = canvas;
    document.dispatchEvent(new Event('pointerlockchange'));
  };
  document.exitPointerLock = () => {
    document.pointerLockElement = null;
    document.dispatchEvent(new Event('pointerlockchange'));
  };
  const camera = new PerspectiveCamera();
  const follow = new SmartFollowCamera(camera, canvas, obstacles);
  const center = new Vector3();
  const rotation = new Quaternion();
  follow.update(0, center, rotation, true);
  if (locked) canvas.dispatchEvent(new Event('click'));
  function event(type, properties) {
    const mouse = type === 'pointermove' && properties.pointerType === 'mouse';
    (mouse ? document : canvas).dispatchEvent(Object.assign(new Event(mouse ? 'mousemove' : type, { cancelable: true }), properties));
  }
  function step(seconds) {
    for (let i = 0; i < Math.round(seconds * 120); i++) follow.update(1 / 120, center, rotation);
  }
  return { camera, canvas, follow, center, rotation, event, step, dispose() { follow.dispose(); globalThis.window = oldWindow; globalThis.document = oldDocument; } };
}

test('on-foot orbit preserves its angle after idle and switching back restores car follow', () => {
  const h = harness();
  try {
    h.follow.setOnFoot(true);
    h.follow.update(0, h.center, h.rotation, true);
    h.event('pointermove', { pointerType: 'mouse', movementX: 140, movementY: 0 });
    h.step(1);
    const before = h.camera.position.clone().sub(h.center);
    h.rotation.setFromAxisAngle(new Vector3(0, 1, 0), Math.PI / 2);
    h.center.x += 12;
    h.step(4);
    const after = h.camera.position.clone().sub(h.center);
    assert.equal(h.follow.mode, 'orbit');
    assert.ok(Math.abs(Math.atan2(before.x, before.z) - Math.atan2(after.x, after.z)) < 0.01);
    h.follow.setOnFoot(false);
    h.follow.update(0, h.center, h.rotation, true);
    assert.equal(h.follow.mode, 'follow');
    assert.ok(h.camera.position.x > h.center.x + 25);
  } finally { h.dispose(); }
});

test('vehicle entry clears a released action camera both before and after its first resumed frame',()=>{
  for(const resumeFirst of [false,true]){
    const h=harness();
    try{
      h.follow.setOnFoot(true);h.follow.update(0,h.center,h.rotation,true);
      const release=lockCameraPose(h.camera),captured=h.camera.position.clone();release();release();
      assert.equal(cameraPoseState(h.camera),'released');
      if(resumeFirst){h.follow.update(1/60,h.center,h.rotation);assert.deepEqual(h.camera.position.toArray(),captured.toArray());}
      h.follow.setOnFoot(false);h.center.set(80,2,30);h.rotation.setFromAxisAngle(new Vector3(0,1,0),Math.PI/2);
      h.follow.update(0,h.center,h.rotation,true);
      assert.equal(cameraPoseState(h.camera),undefined);assert.equal(h.follow.mode,'follow');
      assert.ok(h.camera.position.distanceTo(captured)>20);assert.ok(h.camera.position.x>h.center.x+25,'Vehicle entry adopts the chase view immediately');
    }finally{h.dispose();}
  }
});

test('an active action lock still takes priority over a vehicle-mode change and a camera snap',()=>{
  const h=harness();let release;
  try{
    h.follow.setOnFoot(true);h.follow.update(0,h.center,h.rotation,true);
    const position=h.camera.position.toArray(),rotation=h.camera.quaternion.toArray();release=lockCameraPose(h.camera);
    h.follow.setOnFoot(false);h.center.set(90,4,-30);h.follow.update(0,h.center,h.rotation,true);
    assert.equal(cameraPoseState(h.camera),'locked');assert.deepEqual(h.camera.position.toArray(),position);assert.deepEqual(h.camera.quaternion.toArray(),rotation);
  }finally{release?.();h.dispose();}
});

test('mouse capture needs a click and uses relative movement with fixed cursor coordinates', () => {
  const h = harness([], false);
  try {
    assert.equal(h.follow.pointerLocked, false);
    h.event('pointermove', { pointerType: 'mouse', clientX: 500, clientY: 300, movementX: 50, movementY: 0 });
    assert.equal(h.follow.mode, 'follow');
    h.event('click', {});
    assert.equal(h.follow.pointerLocked, true);
    for (let i = 0; i < 10; i++) {
      h.event('pointermove', { pointerType: 'mouse', clientX: 500, clientY: 300, movementX: 20, movementY: 0 });
      h.step(0.05);
    }
    assert.equal(h.follow.mode, 'orbit');
    assert.ok(Math.abs(h.camera.position.x) > 10, 'Fixed absolute cursor position must not swallow relative movement');
    document.exitPointerLock();
    h.step(0.01);
    assert.equal(h.follow.pointerLocked, false);
    assert.equal(h.follow.mode, 'follow');
    h.event('pointermove', { pointerType: 'mouse', movementX: 50, movementY: 0 });
    assert.equal(h.follow.mode, 'follow');
    h.event('click', {});
    assert.equal(h.follow.pointerLocked, true);
  } finally { h.dispose(); }
});

test('rejected mouse capture shows a retry hint without hiding an unlocked cursor', async () => {
  const h = harness([], false);
  try {
    h.canvas.requestPointerLock = () => Promise.reject(new Error('Denied'));
    h.event('click', {});
    await Promise.resolve();
    assert.equal(h.follow.pointerLocked, false);
    assert.match(h.follow.pointerHint, /failed/);
  } finally { h.dispose(); }
});

test('mouse movement orbits immediately; idle mouse returns smoothly to chase after two seconds', () => {
  const h = harness();
  try {
    const start = h.camera.position.clone();
    h.event('pointermove', { pointerType: 'mouse', clientX: 200, clientY: 100, movementX: 200, movementY: 0 });
    h.step(0.5);
    assert.equal(h.follow.mode, 'orbit');
    assert.ok(Math.abs(h.camera.position.x) > 10);
    h.step(1.4);
    assert.equal(h.follow.mode, 'orbit');
    const orbitPosition = h.camera.position.clone();
    h.step(0.2);
    assert.equal(h.follow.mode, 'follow');
    assert.ok(h.camera.position.distanceTo(start) < orbitPosition.distanceTo(start));
    assert.ok(h.camera.position.distanceTo(start) > 1, 'Return is blended rather than snapped');
    h.step(1.5);
    assert.ok(h.camera.position.distanceTo(start) < 0.01);
  } finally { h.dispose(); }
});

test('an orbit tracks car movement while preserving the player view angle', () => {
  const h = harness();
  try {
    h.event('pointermove', { pointerType: 'mouse', clientX: 120, clientY: 0, movementX: 120, movementY: 0 });
    h.step(1);
    const before = h.camera.position.clone();
    h.center.x += 20;
    h.step(0.8);
    assert.equal(h.follow.mode, 'orbit');
    assert.ok(Math.abs(h.camera.position.x - before.x - 20) < 0.2);
    assert.ok(Math.abs(h.camera.position.z - before.z) < 0.1);
  } finally { h.dispose(); }
});

test('scroll zoom restarts the idle timer; zero motion and touch do not', () => {
  const h = harness();
  try {
    const target = new Vector3(0, 3, -5);
    const startDistance = h.camera.position.distanceTo(target);
    h.event('wheel', { deltaY: -300, deltaMode: 0, ctrlKey: false });
    h.step(1.5);
    assert.ok(h.camera.position.distanceTo(target) < startDistance - 5);
    h.event('wheel', { deltaY: 50, deltaMode: 0, ctrlKey: false });
    h.step(1);
    assert.equal(h.follow.mode, 'orbit');
    h.event('pointermove', { pointerType: 'touch', clientX: 50, clientY: 50, movementX: 50, movementY: 50 });
    h.event('pointermove', { pointerType: 'mouse', clientX: 50, clientY: 50, movementX: 0, movementY: 0 });
    h.step(1.1);
    assert.equal(h.follow.mode, 'follow');
  } finally { h.dispose(); }
});

test('reset returns directly to chase and disposal removes camera input listeners', () => {
  const h = harness();
  try {
    h.event('pointermove', { pointerType: 'mouse', clientX: 200, clientY: 50, movementX: 200, movementY: 50 });
    h.step(0.5);
    h.follow.update(0, h.center, h.rotation, true);
    assert.equal(h.follow.mode, 'follow');
    assert.ok(h.camera.position.distanceTo(new Vector3(0, 13, 30)) < 1e-10);
    h.follow.dispose();
    h.event('wheel', { deltaY: -100, deltaMode: 0 });
    assert.equal(h.follow.mode, 'follow');
  } finally { h.dispose(); }
});

test('camera avoids scenery during follow/orbit transitions', () => {
  const wall = new Mesh(new BoxGeometry(100, 100, 2), new MeshBasicMaterial());
  wall.position.z = 15;
  wall.updateMatrixWorld(true);
  const h = harness([wall]);
  try {
    assert.ok(h.camera.position.z < 14);
    h.event('pointermove', { pointerType: 'mouse', clientX: 30, clientY: 0, movementX: 30, movementY: 0 });
    for (let i = 0; i < 400; i++) {
      h.follow.update(1 / 120, h.center, h.rotation);
      assert.ok(h.camera.position.z < 14);
    }
  } finally { h.dispose(); }
});
