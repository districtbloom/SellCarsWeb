import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Box3, ObjectLoader, PerspectiveCamera, Scene, Vector3 } from 'three';
import { Quaternion, Vec3 } from 'cannon-es';
import { importTypescript } from './import-typescript.mjs';

const { VehiclePhysics } = await importTypescript(new URL('../src/world/driving/VehiclePhysics.ts', import.meta.url));
const { readCarRig } = await importTypescript(new URL('../src/world/driving/CarRig.ts', import.meta.url));
const { PlayerController } = await importTypescript(new URL('../src/world/driving/PlayerController.ts', import.meta.url));
const { carProfile } = await importTypescript(new URL('../src/world/driving/CarProfiles.ts', import.meta.url));
const idle = { throttle: 0, steering: 0, brake: false };
const drive = { ...idle, throttle: 1 };

function createVehicle(ground = true) {
  const physics = new VehiclePhysics({
    position: new Vec3(0, ground ? 0.5 : 100, 0), quaternion: new Quaternion(),
    halfExtents: new Vec3(0.95, 0.5, 2), shapeOffset: new Vec3(0, 0.35, 0),
    wheels: [[-0.7875, -0.225, -1.28], [0.7875, -0.225, -1.28], [-0.7875, -0.225, 1.28], [0.7875, -0.225, 1.28]]
      .map((center, index) => ({ center: new Vec3(...center), radius: 0.2625, front: index < 2 })),
  });
  if (ground) physics.addStaticBox(new Vec3(500, 1, 500), new Vec3(0, -1, 0));
  return physics;
}
function simulate(physics, seconds, input = idle, fps = 120) {
  for (let frame = 0; frame < Math.round(seconds * fps); frame++) physics.update(1 / fps, input);
}

test('player collides with walls, cannot enter through them, and finds alternate safe exits', () => {
  const physics = createVehicle();
  simulate(physics, 2);
  const player = new PlayerController(physics.world, new Scene());
  try {
    const spawn = player.findExit(physics.body);
    assert.ok(spawn);
    player.place(spawn);
    assert.equal(player.canEnter(physics.body), true);
    const wall = physics.addStaticBox(new Vec3(0.1, 2, 3), new Vec3(1.25, 2, 0));
    assert.equal(player.canEnter(physics.body), false, 'Wall blocks the interaction ray');
    const camera = new PerspectiveCamera();
    camera.lookAt(-10, 0, 0);
    for (let i = 0; i < 240; i++) physics.update(1 / 120, idle, dt => player.step(dt, drive, camera));
    assert.ok(player.body.position.x > 1.6, 'Walking motor cannot pass through a wall');
    physics.world.removeBody(wall);
    const block = physics.addStaticBox(new Vec3(0.6, 2, 3), new Vec3(spawn.x, 2, 0));
    const alternative = player.findExit(physics.body);
    assert.ok(alternative && alternative.x < 0, 'Blocked first side falls back to opposite side');
    physics.world.removeBody(block);
    physics.addStaticBox(new Vec3(10, 6, 10), new Vec3(0, 3, 0));
    assert.equal(player.findExit(physics.body), undefined, 'Fully obstructed exits are rejected');
  } finally { player.dispose(); }
});

test('four loaded suspension springs support the chassis at equilibrium', () => {
  const physics = createVehicle();
  simulate(physics, 3);
  assert.equal(physics.vehicle.wheelInfos.filter(wheel => wheel.isInContact).length, 4);
  const force = physics.vehicle.wheelInfos.reduce((sum, wheel) => sum + wheel.suspensionForce, 0);
  assert.ok(Math.abs(force - physics.tuning.mass * 9.81) < 1);
  for (const wheel of physics.vehicle.wheelInfos) {
    assert.ok(wheel.suspensionLength > 0 && wheel.suspensionLength < wheel.suspensionRestLength);
  }
  assert.ok(physics.body.velocity.length() < 0.01);
});

test('suspension finds ground throughout its configured extension and clears contact beyond it', () => {
  const physics = createVehicle();
  physics.body.position.y = 0.65;
  const wheel = physics.vehicle.wheelInfos[2];
  physics.vehicle.castRay(wheel);
  assert.equal(wheel.isInContact, true, 'Ground beyond rest length remains within the suspension travel');
  assert.ok(wheel.suspensionLength > wheel.suspensionRestLength);
  assert.ok(wheel.suspensionLength <= wheel.suspensionRestLength + wheel.maxSuspensionTravel);
  const pose = physics.wheelTransform(2);
  assert.equal(wheel.isInContact, true, 'Rendering must preserve solved contact');
  assert.ok(Math.abs(pose.position.y - wheel.radius) < 1e-6);
  physics.body.position.y = 1;
  physics.vehicle.castRay(wheel);
  assert.equal(wheel.isInContact, false);
  assert.equal(wheel.raycastResult.body, null);
  assert.equal(wheel.suspensionLength, wheel.suspensionRestLength + wheel.maxSuspensionTravel);
});

test('grounded rear tires drive forward and backward while airborne front wheels still steer visually', () => {
  for (const direction of [-1, 1]) {
    const physics = createVehicle(false);
    physics.body.position.y = 0.4;
    // A ledge ends between the axles: rear tires are supported, fronts are over air.
    physics.addStaticBox(new Vec3(50, 1, 50), new Vec3(0, -1, 50));
    simulate(physics, 0.25, { ...idle, throttle: direction, steering: 1 });
    assert.deepEqual(physics.vehicle.wheelInfos.map(wheel => wheel.isInContact), [false, false, true, true]);
    assert.ok(physics.body.velocity.z * direction < -0.1, 'Rear contact must provide propulsion without front contact');
    for (let index = 0; index < 4; index++) {
      const wheel = physics.vehicle.wheelInfos[index];
      const pose = physics.wheelTransform(index);
      if (index < 2) {
        assert.ok(wheel.steering > 0.4);
        const relativeRotation = physics.body.quaternion.inverse().mult(pose.quaternion);
        const axle = relativeRotation.vmult(new Vec3(1, 0, 0));
        assert.ok(Math.abs(axle.z) > 0.3, 'Steering must reach the rendered front wheel orientation in the air');
        assert.equal(wheel.engineForce, 0);
        assert.equal(wheel.forwardImpulse, 0);
      } else {
        assert.ok(wheel.engineForce * direction > 0);
        assert.ok(wheel.forwardImpulse * direction > 0);
        assert.ok(Math.abs(wheel.rotation) > 0.01);
        assert.equal(wheel.steering, 0);
      }
    }
    assert.deepEqual(physics.vehicle.wheelInfos.map(wheel => wheel.isInContact), [false, false, true, true]);
    assert.ok(Math.abs(physics.body.angularVelocity.y) < 1e-5, 'Airborne steering tires cannot generate a fake yaw force');
  }
});

test('rear tire forces accelerate, coasting slows, and brakes stop the chassis', () => {
  const physics = createVehicle();
  simulate(physics, 3);
  simulate(physics, 5, drive);
  assert.ok(physics.speed > 15 && physics.body.position.z < -30);
  assert.equal(physics.vehicle.wheelInfos[0].engineForce, 0);
  assert.ok(physics.vehicle.wheelInfos[2].engineForce > 0);
  assert.ok(Math.abs(physics.vehicle.wheelInfos[2].rotation) > 10);
  const beforeCoast = physics.speed;
  const rotationBeforeCoast = physics.vehicle.wheelInfos[2].rotation;
  simulate(physics, 2);
  assert.ok(physics.speed < beforeCoast - 0.5);
  assert.ok(Math.abs(physics.vehicle.wheelInfos[2].rotation - rotationBeforeCoast) > 1, 'Coasting wheels keep rolling');
  simulate(physics, 3, { ...idle, brake: true });
  assert.ok(Math.abs(physics.speed) < 0.2);
});

test('backward input applies opposing tire force without a brake or gear transition', () => {
  const physics = createVehicle();
  simulate(physics, 2);
  simulate(physics, 4, drive);
  simulate(physics, 0.5, { ...idle, throttle: -1 });
  assert.ok(physics.speed > 0);
  assert.ok(physics.vehicle.wheelInfos[2].engineForce < 0);
  assert.ok(physics.vehicle.wheelInfos.every(wheel => wheel.brake === 0));
  simulate(physics, 6, { ...idle, throttle: -1 });
  assert.ok(physics.speed < -3);
});

test('steering reaches 90 percent lock within 0.1 seconds and recenters as quickly', () => {
  const physics = createVehicle(false);
  simulate(physics, 0.1, { ...idle, steering: 1 });
  assert.ok(physics.vehicle.wheelInfos[0].steering > physics.tuning.maxSteer * 0.9);
  simulate(physics, 0.1);
  assert.ok(physics.vehicle.wheelInfos[0].steering < physics.tuning.maxSteer * 0.1);
});

test('forward and backward use the same drive force and speed limit', () => {
  const forward = createVehicle();
  const backward = createVehicle();
  simulate(forward, 2);
  simulate(backward, 2);
  simulate(forward, 5, drive);
  simulate(backward, 5, { ...idle, throttle: -1 });
  assert.ok(Math.abs(forward.speed + backward.speed) < 0.01);
  assert.ok(backward.speed < -11, 'No separate reverse gear speed cap');
});

test('reverse-to-forward stops opposing motion about three times faster through tire forces', () => {
  function transition(initialDirection) {
    const physics = createVehicle();
    simulate(physics, 2);
    simulate(physics, 2, { ...idle, throttle: initialDirection });
    const startSpeed = Math.abs(physics.speed);
    let elapsed = 0;
    while (physics.speed * initialDirection > 0 && elapsed < 5) {
      physics.update(1 / 120, { ...idle, throttle: -initialDirection });
      elapsed += 1 / 120;
    }
    assert.ok(elapsed > 0.1, 'Direction changes physically rather than instantly');
    assert.ok(physics.vehicle.wheelInfos.every(wheel => wheel.brake === 0));
    return { elapsed, startSpeed };
  }
  const reverseToForward = transition(-1);
  const forwardToReverse = transition(1);
  assert.ok(Math.abs(reverseToForward.startSpeed - forwardToReverse.startSpeed) < 0.01);
  const ratio = reverseToForward.elapsed / forwardToReverse.elapsed;
  assert.ok(ratio > 0.25 && ratio < 0.42, `Transition time ratio: ${ratio}`);
});

test('front steering turns left and right through tire contact forces', () => {
  for (const direction of [-1, 1]) {
    const physics = createVehicle();
    simulate(physics, 2);
    simulate(physics, 3, { ...drive, steering: direction });
    assert.ok(physics.body.position.x * direction < -5);
    assert.ok(physics.vehicle.wheelInfos[0].steering * direction > 0);
    assert.equal(physics.vehicle.wheelInfos[2].steering, 0);
    assert.ok(Math.abs(physics.body.quaternion.y) > 0.2);
  }
});

test('airborne powered wheels spin but cannot propel or steer the chassis', () => {
  const physics = createVehicle(false);
  simulate(physics, 1, { ...drive, steering: 1 });
  assert.equal(physics.vehicle.wheelInfos.filter(wheel => wheel.isInContact).length, 0);
  assert.ok(Math.abs(physics.body.position.x) < 1e-10 && Math.abs(physics.body.position.z) < 1e-10);
  assert.ok(Math.abs(physics.body.quaternion.y) < 1e-10);
  assert.ok(physics.body.position.y < 99);
  assert.ok(Math.abs(physics.vehicle.wheelInfos[2].rotation) > 1);
});

test('fixed simulation steps give matching results at 30 and 144 render FPS', () => {
  const slow = createVehicle();
  const fast = createVehicle();
  simulate(slow, 2, idle, 30);
  simulate(fast, 2, idle, 144);
  simulate(slow, 4, drive, 30);
  simulate(fast, 4, drive, 144);
  assert.ok(slow.body.position.distanceTo(fast.body.position) < 1e-6);
  assert.ok(Math.abs(slow.speed - fast.speed) < 1e-6);
});

test('a bump under one wheel changes suspension independently', () => {
  const physics = createVehicle();
  physics.addStaticBox(new Vec3(0.45, 0.075, 0.5), new Vec3(-0.7875, 0.075, -7));
  simulate(physics, 2);
  let maxDifference = 0;
  for (let frame = 0; frame < 480; frame++) {
    physics.update(1 / 120, { ...drive, throttle: 0.5 });
    maxDifference = Math.max(maxDifference, Math.abs(physics.vehicle.wheelInfos[0].suspensionLength - physics.vehicle.wheelInfos[1].suspensionLength));
  }
  assert.ok(maxDifference > 0.04);
  assert.ok(Number.isFinite(physics.body.position.y));
});

test('chassis collision prevents driving through a solid wall', () => {
  const physics = createVehicle();
  physics.addStaticBox(new Vec3(5, 5, 0.5), new Vec3(0, 5, -15));
  simulate(physics, 2);
  simulate(physics, 5, drive);
  assert.ok(physics.body.position.z > -14);
});

test('reset clears velocity, steering and drive forces', () => {
  const physics = createVehicle();
  simulate(physics, 3, { ...drive, steering: 1 });
  physics.reset();
  assert.equal(physics.body.position.x, 0);
  assert.equal(physics.body.position.z, 0);
  assert.equal(physics.body.velocity.length(), 0);
  assert.equal(physics.body.angularVelocity.length(), 0);
  for (const wheel of physics.vehicle.wheelInfos) {
    assert.equal(wheel.engineForce, 0);
    assert.equal(wheel.steering, 0);
    assert.equal(wheel.rotation, 0);
  }
});

test('high-speed handbrake with yaw creates rear slip while front tires keep steering', () => {
  const normal = createVehicle();
  const drift = createVehicle();
  for (const physics of [normal, drift]) {
    simulate(physics, 2);
    simulate(physics, 5, drive);
    simulate(physics, 0.25, { ...drive, steering: 1 });
  }
  simulate(normal, 0.5, { ...idle, steering: 1 });
  simulate(drift, 0.5, { ...idle, steering: 1, brake: true });
  const normalSideSpeed = Math.abs(normal.body.vectorToLocalFrame(normal.body.velocity).x);
  const driftSideSpeed = Math.abs(drift.body.vectorToLocalFrame(drift.body.velocity).x);
  assert.equal(drift.isDrifting, true);
  assert.ok(driftSideSpeed > normalSideSpeed + 2, 'Rear axle should slide, not just slow the car');
  assert.ok(drift.body.velocity.length() > 10, 'Drifting retains translational momentum');
  assert.ok(Math.abs(drift.body.angularVelocity.y) > Math.abs(normal.body.angularVelocity.y));
  for (const wheel of drift.vehicle.wheelInfos) {
    if (wheel.isFrontWheel) {
      assert.equal(wheel.brake, 0);
      assert.equal(wheel.frictionSlip, drift.tuning.tireGrip);
    } else {
      assert.ok(wheel.brake > 0);
      assert.ok(wheel.frictionSlip >= drift.tuning.tireGrip * 0.65);
      assert.ok(wheel.frictionSlip < drift.tuning.tireGrip * 0.75);
    }
  }
  const reducedGrip = drift.vehicle.wheelInfos[2].frictionSlip;
  drift.update(1 / 120, idle);
  assert.ok(drift.vehicle.wheelInfos[2].frictionSlip > reducedGrip);
  assert.ok(drift.vehicle.wheelInfos[2].frictionSlip < drift.tuning.tireGrip, 'Grip recovers gradually');
  assert.equal(drift.vehicle.wheelInfos[2].brake, 0);
  simulate(drift, 2, drive);
  assert.equal(drift.isDrifting, false);
  assert.ok(Math.abs(drift.vehicle.wheelInfos[2].frictionSlip - drift.tuning.tireGrip) < 0.01);
  drift.reset();
  assert.equal(drift.vehicle.wheelInfos[2].frictionSlip, drift.tuning.tireGrip);
});

test('handbrake does not invent yaw when straight, slow or airborne', () => {
  const straight = createVehicle();
  simulate(straight, 2);
  simulate(straight, 5, drive);
  simulate(straight, 0.5, { ...idle, brake: true });
  assert.equal(straight.isDrifting, false);
  assert.ok(Math.abs(straight.body.angularVelocity.y) < 1e-6);
  assert.equal(straight.vehicle.wheelInfos[2].frictionSlip, straight.tuning.tireGrip);
  const slow = createVehicle();
  simulate(slow, 2);
  simulate(slow, 0.5, { ...drive, steering: 1 });
  simulate(slow, 0.5, { ...idle, steering: 1, brake: true });
  assert.equal(slow.isDrifting, false);
  const air = createVehicle(false);
  air.body.velocity.set(0, 0, -20);
  air.body.angularVelocity.y = 1;
  simulate(air, 0.5, { ...idle, brake: true });
  assert.equal(air.isDrifting, false);
  assert.equal(air.vehicle.wheelInfos[2].frictionSlip, air.tuning.tireGrip);
  assert.ok(Math.abs(air.body.velocity.x) < 1e-6);
});

test('the authored Car 14 supplies four correctly placed physics wheels', async () => {
  const document = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
  const data = document.scene ?? document;
  // Keep geometry/material references while substituting image decoding in Node.
  for (const image of data.images ?? []) image.url = { data: [255, 255, 255, 255], width: 1, height: 1, type: 'Uint8Array' };
  const scene = await new ObjectLoader().parseAsync(data);
  const rig = readCarRig(scene);
  assert.equal(rig.wheels.length, 4);
  assert.ok(rig.spec.wheels.every(wheel => wheel.radius > 0));
  assert.ok(rig.spec.wheels[0].center.z < rig.spec.wheels[2].center.z);
  const physics = new VehiclePhysics(rig.spec, rig.tuning);
  physics.addStaticBox(new Vec3(500, 1, 500), new Vec3(0, -1, 0));
  simulate(physics, 3);
  assert.equal(physics.vehicle.wheelInfos.filter(wheel => wheel.isInContact).length, 4);
  assert.ok(physics.body.velocity.length() < 0.05);
});

test('cars in a shared world transfer collision impulses to an unoccupied car', () => {
  const first = createVehicle();
  const otherSpec = {
    position: new Vec3(0, 0.5, -8), quaternion: new Quaternion(),
    halfExtents: new Vec3(0.95, 0.5, 2), shapeOffset: new Vec3(0, 0.35, 0),
    wheels: first.vehicle.wheelInfos.map(wheel => ({
      center: wheel.chassisConnectionPointLocal.vsub(new Vec3(0, first.tuning.suspensionRestLength, 0)),
      radius: wheel.radius, front: wheel.isFrontWheel,
    })),
  };
  const second = new VehiclePhysics(otherSpec, {}, first.world);
  let collided = false;
  for (let step = 0; step < 600; step++) {
    first.applyInput(step < 120 ? idle : drive);
    second.applyInput({ ...idle, brake: true });
    first.world.step(first.fixedStep);
    collided ||= first.world.contacts.some(contact =>
      (contact.bi === first.body && contact.bj === second.body) ||
      (contact.bj === first.body && contact.bi === second.body));
  }
  assert.ok(collided, 'Dynamic chassis collide in the shared world');
  assert.ok(second.body.position.z < -8.2, 'An unoccupied car can be pushed');
  assert.ok(first.body.position.z > second.body.position.z + 3, 'Cars do not pass through each other');
  assert.equal(first.world.defaultContactMaterial.friction, 0.4 / 3);
});

test('all fourteen authored cars support their weight, drive on rear wheels and have distinct performance', async () => {
  const document = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
  const data = document.scene ?? document;
  for (const image of data.images ?? []) image.url = { data: [255, 255, 255, 255], width: 1, height: 1, type: 'Uint8Array' };
  const scene = await new ObjectLoader().parseAsync(data);
  const speeds = new Map();
  for (let id = 1; id <= 14; id++) {
    const rig = readCarRig(scene, id);
    const physics = new VehiclePhysics(rig.spec, { ...carProfile(id).tuning, ...rig.tuning });
    physics.addStaticBox(new Vec3(500, 1, 500), new Vec3(0, -1, 0));
    simulate(physics, 3);
    assert.equal(physics.vehicle.wheelInfos.filter(wheel => wheel.isInContact).length, 4, `Car ${id} suspension contacts`);
    assert.ok(physics.body.velocity.length() < 0.1, `Car ${id} settles`);
    simulate(physics, 4, drive);
    assert.ok(physics.speed > 4, `Car ${id} accelerates: ${physics.speed}`);
    speeds.set(id, physics.speed);
    assert.ok(physics.vehicle.wheelInfos.slice(0, 2).every(wheel => wheel.engineForce === 0));
    assert.ok(physics.vehicle.wheelInfos.slice(2).every(wheel => wheel.engineForce > 0));
    simulate(physics, 0.2, { ...drive, steering: 1 });
    assert.ok(physics.vehicle.wheelInfos[0].steering > 0, `Car ${id} steers`);
    assert.ok(Math.abs(physics.body.angularVelocity.y) > 0.01, `Car ${id} turns through tire forces`);
    physics.reset();
    assert.ok(physics.body.velocity.length() === 0);
  }
  assert.ok(speeds.get(1) > speeds.get(3) * 1.5, 'Race car accelerates substantially faster than tow truck');
  assert.ok(new Set([...speeds.values()].map(speed => speed.toFixed(1))).size > 10, 'Profiles produce distinct driving performance');
});

test('driving integration follows the physics car and wheel poses, handles input and resets', async () => {
  class TestElement extends EventTarget {
    children = [];
    style = {};
    getBoundingClientRect() { return { left: 0, top: 0, width: 1280, height: 720 }; }
    tagName = 'DIV';
    append(...children) { this.children.push(...children); }
    remove() {}
  }
  const originalWindow = globalThis.window;
  const originalDocument = globalThis.document;
  const originalElement = globalThis.HTMLElement;
  globalThis.window = new EventTarget();
  globalThis.document = Object.assign(new EventTarget(), {
    createElement: () => new TestElement(), body: new TestElement(),
  });
  globalThis.HTMLElement = TestElement;
  let driving;
  try {
    const { DrivingSystem } = await importTypescript(new URL('../src/world/driving/DrivingSystem.ts', import.meta.url));
    const document = JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8'));
    const data = document.scene ?? document;
    for (const image of data.images ?? []) image.url = { data: [255, 255, 255, 255], width: 1, height: 1, type: 'Uint8Array' };
    const scene = await new ObjectLoader().parseAsync(data);
    const camera = new PerspectiveCamera();
    driving = new DrivingSystem(scene, camera);
    assert.equal(driving.cars.length, 14);
    assert.ok(driving.cars.every(car => car.physics.world === driving.physics.world));
    assert.equal(driving.physics.world.bodies.filter(body => body.mass > 100).length, 14);
    assert.equal(driving.isDriving, false);
    assert.equal(driving.player.mesh.visible, true);
    const originalZ = driving.physics.body.position.z;
    for (let i = 0; i < 120; i++) driving.tick(1 / 60);
    assert.equal(driving.physics.world.stepnumber, 240, 'The shared world advances once per fixed step, not once per car');
    assert.ok(driving.player.grounded);
    assert.ok(driving.player.canEnter(driving.physics.body));
    const playerStart = driving.player.body.position.clone();
    function press(code, repeat = false) {
      window.dispatchEvent(Object.assign(new Event('keydown', { cancelable: true }), { code, repeat }));
    }
    press('KeyW');
    for (let i = 0; i < 30; i++) driving.tick(1 / 60);
    window.dispatchEvent(new Event('blur'));
    assert.ok(driving.player.body.position.distanceTo(playerStart) > 1, `W walks the player: ${playerStart.toString()} -> ${driving.player.body.position.toString()}`);
    assert.ok(Math.abs(driving.physics.body.position.z - originalZ) < 0.1, 'Walking does not drive');
    driving.player.place(playerStart);
    for (let i = 0; i < 30; i++) driving.tick(1 / 60);
    press('Space');
    driving.tick(1 / 60);
    assert.ok(driving.player.body.velocity.y > 4, 'Space jumps on foot');
    window.dispatchEvent(new Event('blur'));
    for (let i = 0; i < 90; i++) driving.tick(1 / 60);
    press('KeyE');
    driving.tick(1 / 60);
    assert.equal(driving.isDriving, true);
    assert.equal(driving.player.mesh.visible, false);
    assert.equal(driving.physics.world.bodies.includes(driving.player.body), false);
    press('KeyE', true);
    driving.tick(1 / 60);
    assert.equal(driving.isDriving, true, 'Holding E does not immediately exit');
    const key = new Event('keydown', { cancelable: true });
    Object.assign(key, { code: 'KeyW', repeat: false });
    window.dispatchEvent(key);
    for (let i = 0; i < 90; i++) driving.tick(1 / 60);
    assert.ok(driving.physics.body.position.z < originalZ - 2);
    const bodyPosition = new Vector3().copy(driving.physics.body.position).multiplyScalar(4);
    assert.ok(camera.position.z > bodyPosition.z + 10, 'Camera follows behind the moving car');
    for (const [index, name] of ['Wheelfl14', 'Wheelfr14', 'Wheelrl14', 'Wheelrr14'].entries()) {
      const wheelCenter = new Box3().setFromObject(scene.getObjectByName(name)).getCenter(new Vector3());
      const physicsCenter = new Vector3().copy(driving.physics.vehicle.wheelInfos[index].worldTransform.position).multiplyScalar(4);
      assert.ok(wheelCenter.distanceTo(physicsCenter) < 1e-4, name);
    }
    window.dispatchEvent(new Event('blur'));
    for (let i = 0; i < 120; i++) driving.tick(1 / 60);
    assert.ok(driving.physics.vehicle.wheelInfos[2].engineForce < 0, 'Blur releases throttle and engages coasting resistance');
    const reset = new Event('keydown');
    Object.assign(reset, { code: 'KeyR', repeat: false });
    window.dispatchEvent(reset);
    driving.tick(1 / 60);
    assert.ok(Math.abs(driving.physics.body.position.z - originalZ) < 0.01);
    press('KeyE');
    driving.tick(1 / 60);
    assert.equal(driving.isDriving, false);
    assert.equal(driving.player.mesh.visible, true);
    assert.ok(driving.physics.world.bodies.includes(driving.player.body));
    for (let i = 0; i < 90; i++) driving.tick(1 / 60);
    assert.ok(driving.player.grounded, 'Exit places the player on supported ground');
    driving.player.place(new Vec3(100, 1, 100));
    press('KeyE');
    driving.tick(1 / 60);
    assert.equal(driving.isDriving, false, 'Cannot enter from far away');
    for (const car of driving.cars) {
      car.physics.body.updateAABB();
      const box = car.physics.body.aabb;
      driving.player.place(new Vec3(car.physics.body.position.x, 0.95, box.lowerBound.z - 0.8));
      press('KeyE');
      driving.tick(1 / 60);
      assert.equal(driving.isDriving, true, `${car.car.name} can be entered`);
      assert.ok(driving.physics === car.physics, `E selects ${car.car.name}, got ${driving.cars.find(other => other.physics === driving.physics)?.car.name}`);
      press('KeyW');
      for (let i = 0; i < 20; i++) driving.tick(1 / 60);
      assert.equal(driving.stateLabel, undefined, 'The old on-foot/driving HUD has been removed');
      assert.ok(car.physics.vehicle.wheelInfos[2].engineForce > 0, 'Selected car receives throttle');
      assert.ok(driving.cars.filter(other => other !== car).every(other => other.physics.vehicle.wheelInfos[2].engineForce === 0), 'Empty cars receive no throttle');
      press('KeyR');
      driving.tick(1 / 60);
      press('KeyE');
      driving.tick(1 / 60);
      assert.equal(driving.isDriving, false, `${car.car.name} can be exited`);
      for (let i = 0; i < 60; i++) driving.tick(1 / 60);
    }
  } finally {
    driving?.dispose();
    globalThis.window = originalWindow;
    globalThis.document = originalDocument;
    globalThis.HTMLElement = originalElement;
  }
});
