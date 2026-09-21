import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Body, Box, Vec3, World } from 'cannon-es';
import { Matrix4, PerspectiveCamera, Scene, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/', import.meta.url);
const { InteractionParticles } = await importTypescript(new URL('feedback/InteractionParticles.ts', root));
const { GameFeedback } = await importTypescript(new URL('feedback/GameFeedback.ts', root));
const { GameAudio, SOUND_CUES } = await importTypescript(new URL('feedback/GameAudio.ts', root));
const { BlockCharacterAnimator, createBlockCharacter, disposeBlockCharacter } = await importTypescript(new URL('components/blockCharacter.ts', root));
const manifest = JSON.parse(await readFile(new URL('../public/audio/sound-map.json', import.meta.url), 'utf8'));
const flush = () => new Promise(resolve => setImmediate(resolve));
function dom() {
  globalThis.window = new EventTarget();
  globalThis.document = Object.assign(new EventTarget(), { hidden: false });
  globalThis.fetch = async () => ({ ok: true, json: async () => manifest });
}

test('idle is alive and staggered; face remains attached through idle, talk, walking, jumping and action overrides', () => {
  const a = createBlockCharacter('A', 0xffffff), b = createBlockCharacter('B', 0xffffff);
  const animator = new BlockCharacterAnimator(a), other = new BlockCharacterAnimator(b);
  const head = a.getObjectByName('Head'), face = a.getObjectByName('Face'), torso = a.getObjectByName('Root');
  const samples = [], yaw = [], shifts = [], breaths = [];
  const attached = () => {
    const expected = new Vector3(0, 0, -1.006).applyEuler(head.rotation).add(head.position);
    assert.ok(face.position.distanceTo(expected) < 1e-10); assert.ok(face.quaternion.angleTo(head.quaternion) < 1e-7);
  };
  try {
    for (let i = 0; i < 900; i++) {
      animator.update(1 / 60); other.update(1 / 60); attached();
      samples.push(head.rotation.y - b.getObjectByName('Head').rotation.y);
      yaw.push(head.rotation.y); shifts.push(a.getObjectByName('Character rig').position.x); breaths.push(torso.scale.y);
    }
    assert.ok(Math.max(...yaw) - Math.min(...yaw) > .3);
    assert.ok(Math.max(...shifts) - Math.min(...shifts) > .09);
    assert.ok(Math.max(...breaths) - Math.min(...breaths) > .03);
    assert.ok(samples.some(n => Math.abs(n) > .1), 'Characters do not glance in lockstep');
    animator.look(.1, -.3, .08); attached();
    a.position.x += .2; animator.update(1 / 60); attached();
    animator.jump(.5, 2); attached(); assert.equal(torso.scale.y, 1);
    animator.typing(.2); attached(); assert.deepEqual(head.rotation.toArray().slice(0, 3), [0, 0, 0]);
    animator.opening(.7); attached(); assert.equal(head.rotation.y, 0);
    animator.update(.1, false); attached(); assert.equal(Math.abs(head.rotation.x), 0); assert.equal(torso.scale.y, 1);
  } finally { disposeBlockCharacter(a); disposeBlockCharacter(b); }
});

test('particle storms remain bounded, move and expire without touching gameplay bodies', () => {
  const scene = new Scene(), particles = new InteractionParticles(scene), origin = new Vector3(5, 2, 8);
  try {
    for (let i = 0; i < 100; i++) particles.burst('spark', origin, 2);
    particles.tick(0); assert.equal(particles.mesh.count, 320);
    const initial = new Matrix4(), moved = new Matrix4(); particles.mesh.getMatrixAt(0, initial);
    particles.tick(.1); particles.mesh.getMatrixAt(0, moved); assert.notDeepEqual(moved.elements, initial.elements);
    assert.deepEqual(origin.toArray(), [5, 2, 8]);
    for (let i = 0; i < 20; i++) particles.tick(.1);
    assert.equal(particles.mesh.count, 0);
    particles.burst('dust', origin, NaN); particles.tick(0); assert.equal(particles.mesh.count, 0);
  } finally { particles.dispose(); }
  assert.equal(scene.children.length, 0);
});

test('actual car-to-car contact emits once, scales to a heavy hit, ignores rest, and detaches on disposal', () => {
  dom(); const world = new World(), scene = new Scene(), feedback = new GameFeedback(scene, new PerspectiveCamera());
  const a = new Body({ mass: 1000, shape: new Box(new Vec3(1, 1, 1)), position: new Vec3(-.95, 0, 0), velocity: new Vec3(8, 0, 0) });
  const b = new Body({ mass: 1000, shape: new Box(new Vec3(1, 1, 1)), position: new Vec3(.95, 0, 0) });
  world.addBody(a); world.addBody(b); feedback.bindCars([{ physics: { body: a } }, { physics: { body: b } }]);
  const sounds = [], bursts = [];
  feedback.audio.play = (...args) => sounds.push(args);
  feedback.particles.burst = (...args) => bursts.push(args);
  world.step(1 / 120);
  assert.deepEqual(sounds.map(s => s[0]), ['car.impact.heavy']);
  assert.deepEqual(bursts.map(p => p[0]), ['dust', 'spark']);
  assert.ok(Math.abs(bursts[0][1].x) < 1, 'Effect originates at the contact, not the chassis center');
  const contact = world.contacts[0];
  for (let i = 0; i < 120; i++) world.step(1 / 120);
  assert.equal(sounds.length, 1);
  feedback.dispose();
  a.velocity.set(8, 0, 0); b.velocity.setZero();
  a.dispatchEvent({ type: 'collide', body: b, contact }); b.dispatchEvent({ type: 'collide', body: a, contact });
  assert.equal(sounds.length, 1, 'Disposed listeners cannot emit even when a contact is dispatched again');
});

test('audio manifest names every cue, and replacements load once without delayed event playback', async () => {
  assert.deepEqual(Object.keys(manifest.sounds).sort(), Object.keys(SOUND_CUES).sort());
  dom(); const nodes = [];
  class Param { value = 0; setValueAtTime(value) { this.value = value; } exponentialRampToValueAtTime(value) { this.value = value; } }
  class Node {
    gain = new Param(); pan = new Param(); frequency = new Param(); playbackRate = new Param();
    connections = []; starts = 0; stops = 0;
    connect(node) { this.connections.push(node); return node; } disconnect() { this.connections = []; }
    start() { this.starts++; } stop() { this.stops++; } finish() { this.onended?.(); }
  }
  class Context {
    currentTime = 0; sampleRate = 44100; state = 'running'; destination = new Node();
    make() { const node = new Node(); nodes.push(node); return node; }
    createGain() { return this.make(); } createStereoPanner() { return this.make(); }
    createOscillator() { return this.make(); } createBufferSource() { const n = this.make(); n.clip = true; return n; }
    createBuffer(channels, length) { return { getChannelData: () => new Float32Array(length) }; }
    async decodeAudioData() { return { duration: .3 }; }
    async resume() { this.state = 'running'; } async suspend() { this.state = 'suspended'; } async close() { this.state = 'closed'; }
  }
  globalThis.AudioContext = Context;
  let downloads = 0;
  globalThis.fetch = async url => url.endsWith('.json') ? { ok: true, json: async () => ({ sounds: { 'npc.greeting': { file: 'hello.mp3', volume: .8 }, 'car.door': { file: 'missing.mp3' } } }) }
    : (downloads++, { ok: url.endsWith('hello.mp3'), arrayBuffer: async () => new ArrayBuffer(8) });
  const audio = new GameAudio(new PerspectiveCamera());
  try {
    await flush(); audio.play('npc.greeting'); assert.equal(nodes.length, 0, 'No audio context before user input');
    window.dispatchEvent(new Event('pointerdown')); audio.tick(1, new Vector3());
    audio.play('npc.greeting'); const firstCount = nodes.length;
    audio.play('npc.greeting'); assert.equal(nodes.length, firstCount, 'Cue cooldown suppresses duplicate chatter');
    await flush(); assert.equal(downloads, 1); assert.equal(nodes.length, firstCount, 'Loading never replays stale events');
    nodes.forEach(n => n.finish()); audio.tick(1, new Vector3()); audio.play('npc.greeting');
    assert.ok(nodes.some(n => n.clip && n.buffer?.duration === .3 && n.starts === 1));
    assert.equal(downloads, 1);
    audio.play('car.door'); await flush(); audio.tick(1, new Vector3()); audio.play('car.door');
    assert.equal(downloads, 2, 'A missing replacement is not retried on every interaction');
    audio.tick(1, new Vector3()); const count = nodes.length; audio.play('npc.greeting', new Vector3(200, 0, 0)); assert.equal(nodes.length, count);
    document.hidden = true; document.dispatchEvent(new Event('visibilitychange')); assert.equal(audio.context.state, 'suspended');
    audio.tick(1, new Vector3()); audio.play('npc.greeting'); assert.equal(nodes.length, count);
  } finally { audio.dispose(); delete globalThis.AudioContext; }
  assert.equal(audio.context.state, 'closed');
});
