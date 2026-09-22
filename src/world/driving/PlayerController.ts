import { AABB, Body, Box, ContactMaterial, Material, RaycastResult, Vec3, World } from 'cannon-es';
import { Group, PerspectiveCamera, Scene, Vector3 } from 'three';
import { BlockCharacterAnimator, createBlockCharacter, disposeBlockCharacter } from '../components/blockCharacter.js';
import { METERS_PER_UNIT } from './CarRig.js';
import type { DriverInput } from './VehiclePhysics.js';

export const PLAYER_STEP_HEIGHT = .5;
/** Seller-style character with a separate upright physics capsule approximation. */
export class PlayerController {
  readonly body = new Body({ mass: 80, fixedRotation: true, linearDamping: 0,
    shape: new Box(new Vec3(0.35, 0.9, 0.35)), material: new Material('player'), collisionFilterGroup: 2 });
  private readonly contacts: ContactMaterial[] = [];
  readonly mesh = new Group();
  private readonly character = createBlockCharacter('Player model', 0x56b5ef);
  private readonly animator = new BlockCharacterAnimator(this.character, this.mesh);
  private readonly stepBounds = new AABB();
  private readonly stepCandidates: Body[] = [];
  private jumpPending = false;
  private jumping = false;
  private jumpTime = 0;
  private facingYaw?: number;
  private previousYaw = 0;
  openingProgress?: number;
  typingTime?: number;
  onMotion?: (kind: 'jump' | 'land') => void;

  constructor(private world: World, scene: Scene) {
    // The movement motor handles acceleration/stopping. Contact friction would
    // fight it and snag the upright block against walls and floor corners.
    for (const material of new Set(world.bodies.map(body => body.material ?? world.defaultMaterial))) {
      const contact = new ContactMaterial(this.body.material!, material, { friction: 0, restitution: 0 });
      world.addContactMaterial(contact);
      this.contacts.push(contact);
    }
    this.mesh.name = 'Player';
    const scale = 7.2 / 7.9;
    this.character.scale.setScalar(scale); this.character.position.y = .45 * scale;
    this.mesh.add(this.character);
    scene.add(this.mesh);
    world.addBody(this.body);
  }

  get grounded() {
    return this.world.contacts.some(contact => contact.enabled && (
      (contact.bi === this.body && contact.ni.y < -0.5) ||
      (contact.bj === this.body && contact.ni.y > 0.5)));
  }

  requestJump() { this.jumpPending = true; }

  step(dt: number, input: DriverInput, camera: PerspectiveCamera) {
    const forward = camera.getWorldDirection(new Vector3());
    forward.y = 0;
    if (forward.lengthSq() < 0.001) forward.set(0, 0, -1);
    forward.normalize();
    const right = new Vector3(-forward.z, 0, forward.x);
    const desired = forward.multiplyScalar(input.throttle).addScaledVector(right, -input.steering);
    if (desired.lengthSq() > 1) desired.normalize();
    desired.multiplyScalar(input.sprint ? 8.5 : 5);
    const blend = 1 - Math.exp(-(this.grounded ? 20 : 5) * dt);
    this.body.velocity.x += (desired.x - this.body.velocity.x) * blend;
    this.body.velocity.z += (desired.z - this.body.velocity.z) * blend;
    if (!this.jumpPending) this.tryStep(desired, dt);
    if (this.jumpPending && this.grounded && !this.jumping) {
      this.body.velocity.y = 5.5; this.jumping = true; this.jumpTime = 0;
      this.onMotion?.('jump');
    }
    this.jumpPending = false;
    if (desired.lengthSq() > 0.01) {
      this.previousYaw = this.facingYaw ?? this.mesh.rotation.y;
      const targetYaw = Math.atan2(-desired.x, -desired.z);
      const difference = targetYaw - this.previousYaw;
      // Smooth along the shortest arc, including across the -PI/PI boundary.
      const shortestTurn = Math.atan2(Math.sin(difference), Math.cos(difference));
      this.facingYaw = this.previousYaw + shortestTurn * (1 - Math.exp(-12 * dt));
      this.mesh.rotation.y = this.facingYaw;
    } else { this.facingYaw = undefined; }
  }

  private tryStep(desired: Vector3, dt: number) {
    if (!this.grounded || this.body.velocity.y > .1 || desired.lengthSq() < .01) return;
    // Only query nearby geometry after a side contact, not on every clear walking step.
    if (!this.world.contacts.some(c => c.enabled && (c.bi === this.body || c.bj === this.body) && Math.abs(c.ni.y) < .5)) return;
    const p = this.body.position, feet = p.y - .9, maxStep = PLAYER_STEP_HEIGHT * METERS_PER_UNIT;
    const x = p.x + desired.x * dt, z = p.z + desired.z * dt, radius = .35, skin = .003;
    this.stepBounds.lowerBound.set(Math.min(p.x, x) - radius, feet - skin, Math.min(p.z, z) - radius);
    this.stepBounds.upperBound.set(Math.max(p.x, x) + radius, p.y + .9 + maxStep + skin, Math.max(p.z, z) + radius);
    this.stepCandidates.length = 0;
    this.world.broadphase.aabbQuery(this.world, this.stepBounds, this.stepCandidates);
    let top = feet;
    const overlaps = (b: Body, lowY: number, highY: number) => {
      const low = b.aabb.lowerBound, high = b.aabb.upperBound;
      return x + radius - skin > low.x && x - radius + skin < high.x && z + radius - skin > low.z && z - radius + skin < high.z
        && high.y > lowY + skin && low.y < highY - skin;
    };
    for (const b of this.stepCandidates) {
      if (b === this.body || !b.collisionResponse || !(b.collisionFilterGroup & this.body.collisionFilterMask)) continue;
      if (!overlaps(b, feet, feet + maxStep)) continue;
      if (b.mass !== 0 || b.aabb.upperBound.y - feet > maxStep + skin) return;
      top = Math.max(top, b.aabb.upperBound.y);
    }
    if (top - feet < skin) return;
    // Refuse steps beneath a low ceiling or into a taller wall.
    if (this.stepCandidates.some(b => b !== this.body && b.collisionResponse && (b.collisionFilterGroup & this.body.collisionFilterMask)
      && overlaps(b, top + skin, top + 1.8 + skin))) return;
    const rise = top + skin - feet;
    p.y += rise; this.body.previousPosition.y += rise; this.body.interpolatedPosition.y += rise;
    this.body.velocity.y = Math.max(0, this.body.velocity.y); this.body.aabbNeedsUpdate = true;
  }

  place(position: Vec3) {
    this.facingYaw = undefined;
    this.body.position.copy(position);
    this.body.previousPosition.copy(position);
    this.body.interpolatedPosition.copy(position);
    this.body.velocity.setZero();
    this.body.angularVelocity.setZero();
    this.body.force.setZero();
    this.body.aabbNeedsUpdate = true;
    this.jumpPending = false;
    this.jumping = false; this.jumpTime = 0;
    this.sync();
  }

  setSeated(seated: boolean) {
    if (seated) this.world.removeBody(this.body);
    else if (!this.world.bodies.includes(this.body)) this.world.addBody(this.body);
    this.mesh.visible = !seated;
    this.jumpPending = false;
    this.jumping = false; this.jumpTime = 0;
  }

  sync(delta = 0, alpha = 1) {
    this.mesh.position.copy(this.body.previousPosition as unknown as Vector3).lerp(this.body.position as unknown as Vector3, alpha).multiplyScalar(1 / METERS_PER_UNIT);
    if (this.facingYaw !== undefined) this.mesh.rotation.y = this.previousYaw + (this.facingYaw - this.previousYaw) * alpha;
    if (this.grounded && this.body.velocity.y <= .1) {
      if (this.jumping && this.jumpTime > .15) this.onMotion?.('land');
      this.jumping = false;
    }
    this.animator.update(delta, this.grounded && this.mesh.visible);
    if (this.jumping && this.mesh.visible) {
      this.jumpTime += Math.max(0, Math.min(delta, .1));
      this.animator.jump(this.jumpTime, this.body.velocity.y);
    }
    if (this.openingProgress !== undefined) this.animator.opening(this.openingProgress);
    if (this.typingTime !== undefined) this.animator.typing(this.typingTime);
  }

  /** Find supported clearance beside the car, trying both sides and both ends. */
  findExit(car: Body): Vec3 | undefined {
    car.updateAABB();
    const half = car.aabb.upperBound.vsub(car.aabb.lowerBound).scale(0.5);
    const center = car.aabb.upperBound.vadd(car.aabb.lowerBound).scale(0.5);
    const offsets = [new Vec3(half.x + 1, 0, 0), new Vec3(-half.x - 1, 0, 0),
      new Vec3(0, 0, half.z + 1), new Vec3(0, 0, -half.z - 1)];
    for (const offset of offsets) {
      const point = center.vadd(offset);
      const hit = new RaycastResult();
      this.world.raycastClosest(new Vec3(point.x, center.y + 3, point.z), new Vec3(point.x, center.y - 6, point.z),
        { collisionFilterMask: 1, skipBackfaces: true }, hit);
      if (!hit.hasHit || hit.body === car || hit.hitNormalWorld.y < 0.65) continue;
      point.y = hit.hitPointWorld.y + 0.95;
      const blocked = this.world.bodies.some(body => {
        if (body === this.body) return false;
        if (body.aabbNeedsUpdate) body.updateAABB();
        const { lowerBound: low, upperBound: high } = body.aabb;
        return point.x + 0.4 > low.x && point.x - 0.4 < high.x &&
          point.y + 0.9 > low.y && point.y - 0.9 < high.y &&
          point.z + 0.4 > low.z && point.z - 0.4 < high.z;
      });
      if (!blocked) return point;
    }
    return undefined;
  }

  canEnter(car: Body) {
    if (Math.abs(car.velocity.length()) > 2) return false;
    car.updateAABB();
    const position = this.body.position;
    const closest = new Vec3(
      Math.max(car.aabb.lowerBound.x, Math.min(car.aabb.upperBound.x, position.x)),
      Math.max(car.aabb.lowerBound.y, Math.min(car.aabb.upperBound.y, position.y)),
      Math.max(car.aabb.lowerBound.z, Math.min(car.aabb.upperBound.z, position.z)));
    if (position.distanceTo(closest) > 2) return false;
    const hit = new RaycastResult();
    const center = car.pointToWorldFrame((car.shapeOffsets[0] ?? new Vec3()));
    this.world.raycastClosest(position, center, { collisionFilterMask: 1 }, hit);
    return hit.hasHit && hit.body === car;
  }

  dispose() {
    this.contacts.forEach(contact => this.world.removeContactMaterial(contact));
    this.world.removeBody(this.body);
    this.mesh.removeFromParent();
    disposeBlockCharacter(this.character);
  }
}
