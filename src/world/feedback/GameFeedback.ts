import { Vector3 } from 'three';
import type { PerspectiveCamera, Scene } from 'three';
import type { Body, ContactEquation } from 'cannon-es';
import type { CarInstance } from '../driving/CarInstance.js';
import type { PlayerController } from '../driving/PlayerController.js';
import { METERS_PER_UNIT } from '../driving/CarRig.js';
import { GameAudio } from './GameAudio.js';
import type { SoundId } from './GameAudio.js';
import { InteractionParticles } from './InteractionParticles.js';
import type { ParticleKind } from './InteractionParticles.js';

export class GameFeedback {
  readonly audio: GameAudio;
  readonly particles: InteractionParticles;
  private clock = 0;
  private nextAmbient = 2;
  private nextTires = 0;
  private stride = 0;
  private readonly lastFoot = new Vector3();
  private footInitialized = false;
  private readonly focus = new Vector3();
  private cooldowns = new Map<string, number>();
  private unbind: (() => void)[] = [];
  constructor(private scene: Scene, camera: PerspectiveCamera, baseUrl = '/') {
    this.audio = new GameAudio(camera, baseUrl); this.particles = new InteractionParticles(scene);
  }
  cue(sound: SoundId, position?: Vector3, kind?: ParticleKind, strength = 1) {
    this.audio.play(sound, position, strength);
    if (position && kind && position.distanceToSquared(this.focus) < 150 * 150 && this.clock >= (this.cooldowns.get(sound) ?? 0)) {
      this.cooldowns.set(sound, this.clock + (sound === 'repair.pour' ? .3 : .12));
      this.particles.burst(kind, position, strength);
    }
  }
  bindCars(cars: CarInstance[]) {
    const carBodies = new Set(cars.map(car => car.physics.body));
    for (const car of cars) {
      const body = car.physics.body;
      const collide = (event: { body: Body; contact: ContactEquation }) => {
        // Both cars receive this callback. The lower ID owns the one impact effect.
        if (carBodies.has(event.body) && body.id > event.body.id) return;
        const contact = event.contact, speed = Math.abs(contact.getImpactVelocityAlongNormal());
        if (!contact.enabled || speed < 1.4 || event.body.collisionFilterGroup === 2) return;
        const key = [Math.min(body.id, event.body.id), Math.max(body.id, event.body.id)].join(':');
        if (this.clock < (this.cooldowns.get(key) ?? 0)) return;
        const offset = contact.bi === body ? contact.ri : contact.rj;
        const position = new Vector3(body.position.x + offset.x, body.position.y + offset.y, body.position.z + offset.z).multiplyScalar(1 / METERS_PER_UNIT);
        if (position.distanceToSquared(this.focus) > 150 * 150) return;
        this.cooldowns.set(key, this.clock + .25);
        const heavy = speed > 5, strength = Math.min(2, .5 + speed / 9);
        const normal = new Vector3(contact.ni.x, contact.ni.y, contact.ni.z).multiplyScalar(contact.bi === body ? -1 : 1);
        this.audio.play(heavy ? 'car.impact.heavy' : 'car.impact.light', position, Math.min(1, strength));
        this.particles.burst('dust', position, strength);
        if (speed > 2.5) this.particles.burst('spark', position, strength, normal);
      };
      body.addEventListener('collide', collide); this.unbind.push(() => body.removeEventListener('collide', collide));
    }
  }
  tick(delta: number, focus: Vector3, player: PlayerController, driven?: CarInstance) {
    const dt = Math.max(0, Math.min(.1, delta)); this.clock += dt; this.focus.copy(focus); this.audio.tick(dt, focus);
    this.particles.tick(dt);
    for (const [key, expiry] of this.cooldowns) if (this.clock > expiry) this.cooldowns.delete(key);
    const foot = player.mesh.position.clone(); foot.y -= 3.5;
    const distance = this.footInitialized ? Math.hypot(foot.x - this.lastFoot.x, foot.z - this.lastFoot.z) : 0;
    this.lastFoot.copy(foot); this.footInitialized = true;
    if (player.mesh.visible && player.grounded && !driven && distance < 6 && distance > .01) {
      this.stride += distance;
      if (this.stride > 4.5) { this.stride %= 4.5; this.cue('player.footstep', foot, distance / Math.max(.001, dt) > 25 ? 'dust' : undefined, .65); }
    } else this.stride = 0;
    if (driven && this.clock >= this.nextTires) {
      this.nextTires = this.clock + .12;
      const speed = driven.physics.body.velocity.length();
      const sliding = driven.physics.vehicle.wheelInfos.filter(w => w.isInContact && (w.skidInfo < .8 || w.sliding));
      if (speed > 4 && sliding.length) {
        for (const wheel of sliding) {
          const p = wheel.raycastResult.hitPointWorld;
          this.particles.burst('dust', new Vector3(p.x, p.y, p.z).multiplyScalar(1 / METERS_PER_UNIT), .4);
        }
      }
    }
    if (this.clock >= this.nextAmbient) {
      this.nextAmbient = this.clock + 2.4;
      let nearest: { position: Vector3; activity: string } | undefined, distance = 45 * 45;
      this.scene.traverseVisible(object => {
        const activity = object.userData.npcActivity;
        if (activity !== 'talk' && activity !== 'repair') return;
        const position = object.getWorldPosition(new Vector3()), d = position.distanceToSquared(focus);
        if (d < distance) { nearest = { position, activity }; distance = d; }
      });
      if (nearest) {
        if (nearest.activity === 'talk') this.audio.play('npc.chatter', nearest.position, .55);
        else this.cue('repair.tool', nearest.position.clone().add(new Vector3(0, 0, -1)), 'spark', .3);
      }
    }
  }
  dispose() { this.unbind.forEach(remove => remove()); this.unbind = []; this.cooldowns.clear(); this.audio.dispose(); this.particles.dispose(); }
}
