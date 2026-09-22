import { Scene, Vector3 } from 'three';
import { Vec3 } from 'cannon-es';
import { CarInstance } from '../driving/CarInstance.js';
import type { DriverInput } from '../driving/VehiclePhysics.js';
import { METERS_PER_UNIT } from '../driving/CarRig.js';

export interface RacePoint { x: number; z: number }
export function crossesCheckpoint(a: RacePoint, b: RacePoint, target: RacePoint, radius = 15) {
  const dx = b.x - a.x, dz = b.z - a.z;
  const t = Math.max(0, Math.min(1, ((target.x - a.x) * dx + (target.z - a.z) * dz) / (dx * dx + dz * dz || 1)));
  return Math.hypot(a.x + dx * t - target.x, a.z + dz * t - target.z) <= radius;
}
/** Rounded intersection paths remain inside the paved road union. */
export function racingLine(points: RacePoint[]): RacePoint[] {
  const result = [points[0]];
  for (let i = 1; i < points.length - 1; i++) {
    const a = points[i - 1], b = points[i], c = points[i + 1], before = Math.hypot(b.x - a.x, b.z - a.z), after = Math.hypot(c.x - b.x, c.z - b.z);
    const radius = Math.min(24, before * .4, after * .4);
    const start = { x: b.x + (a.x - b.x) * radius / before, z: b.z + (a.z - b.z) * radius / before };
    const end = { x: b.x + (c.x - b.x) * radius / after, z: b.z + (c.z - b.z) * radius / after };
    if (Math.abs((b.x - a.x) * (c.z - b.z) - (b.z - a.z) * (c.x - b.x)) < .01) { result.push(b); continue; }
    for (let j = 0; j <= 8; j++) { const t = j / 8, u = 1 - t; result.push({ x: u * u * start.x + 2 * u * t * b.x + t * t * end.x, z: u * u * start.z + 2 * u * t * b.z + t * t * end.z }); }
  }
  result.push(points[points.length - 1]); return result;
}

/** Changes driver input only. Suspension, tire forces, collisions and mass are the player's. */
export class AIRacer {
  readonly car: CarInstance;
  index = 1;
  finishedAt?: number;
  private line: RacePoint[];
  private segment = 0;
  private checkpointSegments: number[];
  private previous: RacePoint;
  private stuck = 0;
  private reversing = 0;
  constructor(scene: Scene, source: CarInstance, readonly name: string, ground: Vector3, yaw: number, private points: RacePoint[], speedFactor: number) {
    const staging = new Scene(), model = source.cloneModel(); model.name = `Car ${source.id}`; staging.add(model);
    this.car = new CarInstance(staging, source.id, source.physics.world, { ...source.physics.tuning, maxSpeedKmh: source.physics.tuning.maxSpeedKmh * speedFactor });
    this.car.car.name = name; scene.add(this.car.car, ...this.car.wheels); this.car.place(ground, yaw);
    this.car.car.userData.mapPOI = { label: name, color: '#f48e86' };
    this.line = racingLine(points); this.previous = this.position();
    this.checkpointSegments = points.map(point => {
      let nearest = 0, distance = Infinity;
      for (let i = 0; i < this.line.length - 1; i++) {
        const a = this.line[i], b = this.line[i + 1], dx = b.x - a.x, dz = b.z - a.z;
        const t = Math.max(0, Math.min(1, ((point.x - a.x) * dx + (point.z - a.z) * dz) / (dx * dx + dz * dz || 1)));
        const d = Math.hypot(a.x + dx * t - point.x, a.z + dz * t - point.z);
        if (d < distance) { distance = d; nearest = i; }
      }
      return nearest;
    });
  }
  position(): RacePoint { const p = this.car.physics.body.position; return { x: p.x / METERS_PER_UNIT, z: p.z / METERS_PER_UNIT }; }
  beforeStep(dt: number, racing: boolean) {
    this.car.physics.applyInput(racing && this.finishedAt === undefined ? this.input(dt) : { throttle: 0, steering: 0, brake: true });
  }
  afterStep(elapsed: number, racing: boolean) {
    const p = this.position(); this.car.capturePhysicsPose();
    if (racing && this.finishedAt === undefined && crossesCheckpoint(this.previous, p, this.points[this.index])) {
      this.index++; if (this.index === this.points.length) this.finishedAt = elapsed;
    }
    this.previous = p;
  }
  private input(dt: number): DriverInput {
    const p = this.position(), physics = this.car.physics, speed = physics.speed;
    // Project onto the next path segments without skipping distant branches of the route.
    let best = Infinity, progress = 0;
    const searchStart = this.segment;
    for (let i = searchStart; i < Math.min(this.line.length - 1, searchStart + 12); i++) {
      const a = this.line[i], b = this.line[i + 1], dx = b.x - a.x, dz = b.z - a.z, length2 = dx * dx + dz * dz;
      const t = Math.max(0, Math.min(1, ((p.x - a.x) * dx + (p.z - a.z) * dz) / (length2 || 1)));
      const distance = Math.hypot(a.x + dx * t - p.x, a.z + dz * t - p.z);
      if (distance < best) { best = distance; this.segment = i; progress = t; }
    }
    const a = this.line[this.segment], b = this.line[this.segment + 1];
    let goal = { x: a.x + (b.x - a.x) * progress, z: a.z + (b.z - a.z) * progress };
    let look = Math.max(10, Math.min(28, (2.5 + Math.abs(speed) * .45) / METERS_PER_UNIT));
    for (let i = this.segment + 1; i < this.line.length; i++) {
      const next = this.line[i], length = Math.hypot(next.x - goal.x, next.z - goal.z);
      if (length >= look) { goal = { x: goal.x + (next.x - goal.x) * look / length, z: goal.z + (next.z - goal.z) * look / length }; break; }
      goal = next; look -= length;
    }
    // A collision can push a rival outside a checkpoint. Recover it before advancing the racing line.
    const checkpoint = this.points[this.index], recovering = this.segment > this.checkpointSegments[this.index] + 1;
    if (recovering || Math.hypot(checkpoint.x - p.x, checkpoint.z - p.z) < 38) goal = checkpoint;
    const forward = physics.body.quaternion.vmult(new Vec3(0, 0, -1));
    const yaw = Math.atan2(-forward.x, -forward.z), desired = Math.atan2(-(goal.x - p.x), -(goal.z - p.z));
    const error = Math.atan2(Math.sin(desired - yaw), Math.cos(desired - yaw));
    const wheelbase = Math.abs(this.car.rig.spec.wheels[0].center.z - this.car.rig.spec.wheels[2].center.z);
    const steeringLimit = physics.tuning.maxSteer / (1 + Math.abs(speed) / 18);
    const steering = Math.max(-1, Math.min(1, Math.atan(2 * wheelbase * Math.sin(error) / Math.max(1, Math.hypot(goal.x - p.x, goal.z - p.z) * METERS_PER_UNIT)) / steeringLimit));
    let target = physics.tuning.maxSpeedKmh / 3.6;
    // Brake in advance of corners instead of arriving at an intersection at full speed.
    for (let i = Math.max(1, this.index); i < this.points.length - 1; i++) {
      const u = this.points[i - 1], v = this.points[i], w = this.points[i + 1];
      if (Math.abs((v.x - u.x) * (w.z - v.z) - (v.z - u.z) * (w.x - v.x)) < .01) continue;
      const distance = Math.max(0, Math.hypot(v.x - p.x, v.z - p.z) * METERS_PER_UNIT - 10);
      target = Math.min(target, Math.sqrt(16 + 2 * 2.5 * distance)); break;
    }
    if (recovering || Math.abs(error) > .6 || best > 10) target = Math.min(target, 3.5);
    const finish = this.points[this.points.length - 1]; target = Math.min(target, Math.sqrt(16 + 4 * Math.hypot(finish.x - p.x, finish.z - p.z) * METERS_PER_UNIT));
    this.stuck = Math.abs(speed) < .45 ? this.stuck + dt : 0;
    if (this.stuck > 3) { this.reversing = 1.5; this.stuck = 0; }
    if (this.reversing > 0) { this.reversing -= dt; return { throttle: -.6, steering: -steering, brake: false }; }
    return { throttle: Math.max(-1, Math.min(1, (target - speed) * .7)), steering, brake: false };
  }
  render(alpha: number) { this.car.sync(alpha); }
  dispose() { this.car.dispose(); this.car.car.removeFromParent(); this.car.wheels.forEach(wheel => wheel.removeFromParent()); }
}
