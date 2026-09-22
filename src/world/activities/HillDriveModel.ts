export const HILL_CONFIG = { seconds: 30, rewardMultiplier: 2, bonusSeconds: 5, gravity: 22, acceleration: 14, airTorque: 5, maxSpeed: 24 };
interface HillPoint { x: number; y: number }
export interface TimePickup { x: number; y: number; collected: boolean }
/** Small rigid-body simulation with two spring contacts, pitch inertia and roof collisions. */
export class HillDriveModel {
  readonly hills: HillPoint[] = [{ x: -100, y: 0 }, { x: 18, y: 0 }];
  readonly pickups: TimePickup[] = [];
  x = 5; y = 1.5; vx = 0; vy = 0; angle = 0; spin = 0;
  remaining = HILL_CONFIG.seconds;
  distance = 0;
  ended: 'crashed' | 'time' | undefined;
  grounded = false;
  private accumulator = 0;
  private nextPickup = 48;
  constructor(private random = Math.random) { this.extend(250); }
  get reward() { return Math.floor(this.distance) * HILL_CONFIG.rewardMultiplier; }
  private extend(to: number) {
    while (this.hills[this.hills.length - 1].x < to) {
      const previous = this.hills[this.hills.length - 1];
      this.hills.push({ x: previous.x + 16 + this.random() * 14, y: (this.random() * 2 - .7) * Math.min(9, 2 + previous.x / 90) });
    }
    while (this.nextPickup < to - 30) {
      const x = this.nextPickup; this.pickups.push({ x, y: this.height(x) + 2, collected: false }); this.nextPickup += 42 + this.random() * 32;
    }
  }
  height(x: number) {
    const i = this.hills.findIndex(p => p.x >= x);
    if (i <= 0) return this.hills[Math.max(0, i)].y;
    const a = this.hills[i - 1], b = this.hills[i], t = (x - a.x) / (b.x - a.x);
    return a.y + (b.y - a.y) * (.5 - Math.cos(t * Math.PI) / 2);
  }
  tick(delta: number, direction: number) {
    if (this.ended) return;
    this.accumulator += Math.min(.25, Math.max(0, delta));
    while (this.accumulator >= 1 / 120 && !this.ended) { this.step(1 / 120, Math.sign(direction)); this.accumulator -= 1 / 120; }
  }
  private step(dt: number, input: number) {
    this.extend(this.x + 160); this.remaining = Math.max(0, this.remaining - dt);
    let ax = -this.vx * .08, ay = -HILL_CONFIG.gravity, torque = -this.spin * .6;
    this.grounded = false;
    const cos = Math.cos(this.angle), sin = Math.sin(this.angle);
    for (const side of [-1, 1]) {
      const rx = side * 1.3 * cos + .45 * sin, ry = side * 1.3 * sin - .45 * cos;
      const wx = this.x + rx, wy = this.y + ry;
      const slope = (this.height(wx + .05) - this.height(wx - .05)) / .1, norm = Math.hypot(slope, 1), nx = -slope / norm, ny = 1 / norm;
      const penetration = (this.height(wx) + .48 - wy) / norm;
      if (penetration > 0) {
        this.grounded = true;
        const normalVelocity = (this.vx - this.spin * ry) * nx + (this.vy + this.spin * rx) * ny;
        const force = Math.max(0, Math.min(180, penetration * 180 - normalVelocity * 16));
        ax += nx * force; ay += ny * force; torque += (rx * ny - ry * nx) * force / 2.4;
        const drive = input * HILL_CONFIG.acceleration / 2;
        ax += drive * ny; ay -= drive * nx; torque += drive * .08;
      }
    }
    if (!this.grounded) torque -= input * HILL_CONFIG.airTorque;
    this.vx = Math.max(-HILL_CONFIG.maxSpeed, Math.min(HILL_CONFIG.maxSpeed, this.vx + ax * dt)); this.vy += ay * dt;
    this.spin = Math.max(-7, Math.min(7, this.spin + torque * dt));
    this.x = Math.max(-12, this.x + this.vx * dt); if (this.x === -12 && this.vx < 0) this.vx = 0;
    this.y += this.vy * dt; this.angle += this.spin * dt;
    this.distance = Math.max(this.distance, this.x - 5);
    // Roof corners collide independently of wheels; inversion only ends a run on impact.
    for (const side of [-1, 1]) {
      const roofX = this.x + side * .85 * cos - .75 * sin, roofY = this.y + side * .85 * sin + .75 * cos;
      if (roofY < this.height(roofX) + .08) this.ended = 'crashed';
    }
    for (const pickup of this.pickups) if (!pickup.collected && Math.hypot(this.x - pickup.x, this.y - pickup.y) < 2.8) { pickup.collected = true; this.remaining += HILL_CONFIG.bonusSeconds; }
    if (!this.remaining && !this.ended) this.ended = 'time';
  }
}
