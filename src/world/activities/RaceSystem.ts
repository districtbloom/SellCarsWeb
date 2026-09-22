import { ArrowHelper, CylinderGeometry, Group, Mesh, MeshBasicMaterial, Vector3 } from 'three';
import type { PerspectiveCamera, Scene } from 'three';
import type { DrivingSystem } from '../driving/DrivingSystem.js';
import type { Minimap } from './Minimap.js';
import { raceRoute, roadGraph } from './RuntimeMap.js';
import { AIRacer, crossesCheckpoint } from './AIRacer.js';
import type { CarInstance } from '../driving/CarInstance.js';

export const RACE_INTERVAL = 300;
export const RACE_JOIN_WINDOW = 300;
type Point = { x: number; z: number };
export function raceDifficulty(prize: number) {
  const difficulty = Math.max(0, Math.min(1, (prize - 250) / 3250));
  return { nodes: 6 + Math.round(difficulty * 7), opponents: difficulty > .5 ? 3 : 2, speedFactor: .88 + difficulty * .08, seconds: 300 - Math.round(difficulty * 120), label: difficulty < .34 ? 'EASY' : difficulty < .67 ? 'CHALLENGING' : 'EXPERT' };
}
interface RaceEvent { points: Point[]; expires: number; prize: number; id: string }
/** Events use monotonic time; hidden tabs cannot extend a join window or race deadline. */
export class RaceSystem {
  private clock = 0;
  private lastTime: number;
  private nextEvent = RACE_INTERVAL;
  private event?: RaceEvent;
  private run?: { points: Point[]; index: number; started: number; carId: number; previous: Vector3; prize: number; id: string; seconds: number; elapsed: number; poseRevision: number };
  private opponents: AIRacer[] = [];
  private removeParticipant?: () => void;
  private root = new Group();
  private beams = new Group();
  private startMarker = new Mesh(new CylinderGeometry(13, 13, .4, 32), new MeshBasicMaterial({ color: 0xffd36b, transparent: true, opacity: .65 }));
  private announcement = document.createElement('div');
  private billboard = document.createElement('div');
  private message = '';
  private messageUntil = 0;
  private countdownLocked = false;
  get active() { return !!this.run; }
  constructor(private scene: Scene, private driving: DrivingSystem, private camera: PerspectiveCamera, private map: Minimap, private blocked: () => boolean, private now = () => performance.now(), private reward: (id: string, amount: number) => boolean = () => false, private random = Math.random) {
    this.lastTime = this.now();
    this.root.name = 'City race events'; this.root.add(this.beams, this.startMarker); this.startMarker.visible = false; scene.add(this.root);
    this.announcement.className = 'race-announcement'; this.announcement.setAttribute('role', 'status');
    this.billboard.className = 'race-billboard'; this.billboard.hidden = true;
    document.body.append(this.announcement, this.billboard); window.addEventListener('keydown', this.key);
  }
  private say(text: string, seconds = 9) { this.message = text; this.messageUntil = this.clock + seconds; }
  private spawn() {
    const prize = 250 + Math.floor(Math.min(.999999, Math.max(0, this.random())) * 3251), difficulty = raceDifficulty(prize);
    this.map.map.refresh(); const points = raceRoute(roadGraph(this.map.map.roads), this.random, difficulty.nodes).slice(1);
    if (points.length < 2) return;
    this.event = { points, expires: this.clock + RACE_JOIN_WINDOW, prize, id: `race-${Date.now()}-${this.clock}` };
    this.say(`CITY SPRINT HAS APPEARED · $${prize} TO WIN\n${difficulty.label} · Reach the gold flag within 5 minutes.`);
  }
  private key = (event: KeyboardEvent) => {
    if (event.repeat || event.ctrlKey || event.metaKey || event.altKey || this.blocked()) return;
    if (event.code === 'KeyX' && this.run) { this.finish('Race cancelled'); return; }
    if (event.code !== 'KeyF' || !this.event || this.run || !this.driving.isDriving || this.clock >= this.event.expires) return;
    const p = this.event.points[0], current = this.driving.focusPosition;
    if (Math.hypot(current.x - p.x, current.z - p.z) > 24) return;
    const source = this.driving.drivenCar; if (!source) return;
    const offer = this.event, next = offer.points[1], dx = next.x - p.x, dz = next.z - p.z, length = Math.hypot(dx, dz), yaw = Math.atan2(-dx, -dz);
    source.place(new Vector3(p.x - dz / length * 6, 0, p.z + dx / length * 6), yaw);
    const body = source.physics.body;
    this.run = { points: offer.points, index: 1, started: this.clock + 3, carId: this.driving.drivenCarId!, previous: new Vector3(body.position.x, body.position.y, body.position.z).multiplyScalar(4), prize: offer.prize, id: offer.id, seconds: raceDifficulty(offer.prize).seconds, elapsed: -3, poseRevision: source.physics.poseRevision };
    this.addOpponents(source);
    this.removeParticipant = this.driving.addPhysicsParticipant({
      beforeStep: dt => { const run = this.run; if (run) { run.elapsed += dt; for (const rival of this.opponents) rival.beforeStep(dt, run.elapsed >= 0); } },
      afterStep: () => this.checkProgress(),
      render: alpha => this.opponents.forEach(rival => rival.render(alpha)),
    });
    this.countdownLocked = true; this.driving.setControlsEnabled(false); this.driving.physics.body.velocity.setZero();
    this.event = undefined; this.map.route = this.run.points; this.drawCheckpoints(); event.preventDefault();
  };
  private addOpponents(source: CarInstance) {
    const run = this.run!, [a, b] = run.points, length = Math.hypot(b.x - a.x, b.z - a.z), dx = (b.x - a.x) / length, dz = (b.z - a.z) / length;
    const difficulty = raceDifficulty(run.prize);
    for (let i = 0; i < difficulty.opponents; i++) {
      const side = i % 2 === 0 ? 6 : -6, back = i === 0 ? 0 : 22;
      const ground = new Vector3(a.x + dz * side - dx * back, 0, a.z - dx * side - dz * back);
      this.opponents.push(new AIRacer(this.scene, source, ['Riley', 'Alex', 'Sam'][i], ground, Math.atan2(-dx, -dz), run.points, difficulty.speedFactor));
    }
  }
  private checkProgress() {
    const run = this.run, source = this.driving.drivenCar; if (!run || !source) return;
    if (source.physics.poseRevision !== run.poseRevision) { this.finish('Race ended · Vehicle reset'); return; }
    for (const rival of this.opponents) rival.afterStep(run.elapsed, run.elapsed >= 0);
    const body = source.physics.body, p = new Vector3(body.position.x, body.position.y, body.position.z).multiplyScalar(4);
    if (p.distanceTo(run.previous) > 100) { this.finish('Race ended · Vehicle reset'); return; }
    if (run.elapsed >= 0 && p.y > -3 && p.y < 20 && crossesCheckpoint(run.previous, p, run.points[run.index])) {
      run.index++; this.driving.feedback.audio.play('repair.complete');
      if (run.index === run.points.length) {
        const rank = 1 + this.opponents.filter(rival => rival.finishedAt !== undefined && rival.finishedAt < run.elapsed).length;
        const paid = rank === 1 && this.reward(run.id, run.prize);
        this.finish(`FINISH! · ${rank}/${this.opponents.length + 1} · ${run.elapsed.toFixed(1)} seconds\n${rank > 1 ? 'Win first place to earn the prize' : paid ? '+$' + run.prize : 'Prize could not be saved'}`);
      } else this.drawCheckpoints();
    }
    run.previous.copy(p);
  }
  private clearBeams() {
    this.beams.traverse(object => {
      const mesh = object as Mesh; mesh.geometry?.dispose();
      if (mesh.material) { for (const material of Array.isArray(mesh.material) ? mesh.material : [mesh.material]) material.dispose(); }
    }); this.beams.clear();
  }
  private drawCheckpoints() {
    this.clearBeams(); const run = this.run; if (!run) return;
    for (let i = run.index; i < run.points.length; i++) {
      const p = run.points[i], active = i === run.index, color = active ? 0xffd36b : 0x60d5f3;
      const beam = new Mesh(new CylinderGeometry(12, 12, active ? 70 : 32, 24, 1, true), new MeshBasicMaterial({ color, transparent: true, opacity: active ? .38 : .12, depthWrite: false, side: 2, fog: false }));
      beam.position.set(p.x, active ? 35 : 16, p.z); this.beams.add(beam);
      const next = run.points[i + 1];
      if (next) { const direction = new Vector3(next.x - p.x, 0, next.z - p.z).normalize(); this.beams.add(new ArrowHelper(direction, new Vector3(p.x, 10, p.z), 24, color, 9, 7)); }
      else { const ring = new Mesh(new CylinderGeometry(12, 12, 1, 24), new MeshBasicMaterial({ color: 0x9fffaf })); ring.position.set(p.x, .6, p.z); this.beams.add(ring); }
    }
    this.map.route = run.points.slice(Math.max(0, run.index - 1));
  }
  private releaseCountdown() { if (this.countdownLocked) { this.countdownLocked = false; if (!this.blocked()) this.driving.setControlsEnabled(true); } }
  private finish(message: string) { this.releaseCountdown(); this.run = undefined; this.removeParticipant?.(); this.removeParticipant = undefined; this.opponents.forEach(rival => rival.dispose()); this.opponents = []; this.clearBeams(); this.map.route = []; this.map.checkpoint = undefined; this.say(message, 12); }
  tick() {
    this.clock = Math.max(this.clock, (this.now() - this.lastTime) / 1000);
    if (this.event && this.clock >= this.event.expires) this.event = undefined;
    if (this.clock >= this.nextEvent) { this.nextEvent = this.clock + RACE_INTERVAL; this.spawn(); }
    const event = this.event;
    this.map.event = event ? { id: 'race', label: 'RACE', color: '#ffd36b', ...event.points[0] } : undefined;
    this.billboard.hidden = !event;
    this.startMarker.visible = !!event;
    if (event) {
      this.startMarker.position.set(event.points[0].x, .3, event.points[0].z);
      const p = event.points[0], screen = new Vector3(p.x, 35, p.z).project(this.camera);
      const distance = Math.round(Math.hypot(this.driving.focusPosition.x - p.x, this.driving.focusPosition.z - p.z) * .25);
      const time = Math.max(0, Math.ceil(event.expires - this.clock));
      this.billboard.textContent = `⚑ CITY SPRINT · WIN $${event.prize}\n${raceDifficulty(event.prize).label} · ${Math.floor(time / 60)}:${String(time % 60).padStart(2, '0')}\n${distance} m · ${this.run ? 'Next event' : distance < 7 ? this.driving.isDriving ? '[F] Join race' : 'Bring a car to race' : 'Drive to the gold flag'}`;
      this.billboard.style.left = Math.max(100, Math.min(innerWidth - 100, (screen.z > 1 ? .92 : screen.x * .5 + .5) * innerWidth)) + 'px';
      this.billboard.style.top = Math.max(130, Math.min(innerHeight - 60, (-screen.y * .5 + .5) * innerHeight)) + 'px';
    }
    const run = this.run;
    if (run) {
      const elapsed = run.elapsed, body = this.driving.drivenCar?.physics.body;
      const p = body ? new Vector3(body.position.x, body.position.y, body.position.z).multiplyScalar(4) : this.driving.focusPosition;
      if (elapsed >= 0) this.releaseCountdown();
      if (!this.driving.isDriving || this.driving.drivenCarId !== run.carId) this.finish('Race ended · Stay in your race car');
      else if (this.clock - run.started > run.seconds) this.finish('Race time expired');
      else if (p.distanceTo(run.previous) > 100) this.finish('Race ended · Vehicle reset');
      if (this.run) {
        this.map.checkpoint = { id: 'checkpoint', label: 'NEXT', color: '#fff4a5', ...run.points[run.index] };
        const target = run.points[run.index], remaining = Math.hypot(target.x - p.x, target.z - p.z);
        const rank = 1 + this.opponents.filter(rival => rival.index > run.index || rival.index === run.index && Math.hypot(target.x - rival.position().x, target.z - rival.position().z) < remaining).length;
        this.announcement.textContent = (elapsed < 0 ? `CITY SPRINT · ${Math.ceil(-elapsed)}\nWIN $${run.prize} · Get ready!` : `${rank}/${this.opponents.length + 1} · CHECKPOINT ${run.index}/${run.points.length - 1} · $${run.prize}\n${Math.max(0, Math.ceil(run.seconds - (this.clock - run.started)))}s left · X to cancel`) + (this.clock < this.messageUntil && event ? '\n' + this.message : '');
      }
    }
    if (!this.run) this.announcement.textContent = this.clock < this.messageUntil ? this.message : '';
  }
  dispose() { this.finish(''); window.removeEventListener('keydown', this.key); this.startMarker.geometry.dispose(); this.startMarker.material.dispose(); this.root.removeFromParent(); this.announcement.remove(); this.billboard.remove(); }
}
