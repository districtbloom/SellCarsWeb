import { Color, Group, Vector3 } from 'three';
import { BlockCharacterAnimator, createNPCCharacter } from '../components/blockCharacter.js';
import { frameMatrix, worldPoint } from './TycoonCoordinates.js';
import { openingStep, partPose } from './BuildingProgression.js';
import { ownsCosmetic } from './FullJourney.js';
import { COSMETIC_STEPS } from './PurchaseCategories.js';
import { nameNPC } from './NPCNameplate.js';
import type { ImportedPart } from './BuildingProgression.js';
import type { TycoonState } from './types.js';

export type NPCPath = (from: Vector3, to: Vector3) => Vector3[];
export function importedNPCs(parts: ImportedPart[]): { stem: string; torso: ImportedPart }[] {
  const byPath = new Map(parts.map(p => [p.path, p]));
  return parts.filter(p => p.path.endsWith('.Head')).flatMap(head => {
    const stem = head.path.slice(0, -5), torso = byPath.get(stem + '.Torso');
    return torso ? [{ stem, torso }] : [];
  });
}

/** Reusable feet-on-ground walking with pathfinding and task-specific hand poses. */
export class NPCRoutine {
  readonly animator: BlockCharacterAnimator;
  private target?: Vector3;
  private points: Vector3[] = [];
  private shown = false;
  private moving = false;
  constructor(readonly person: Group, private path?: NPCPath) {
    nameNPC(person, person.name);
    this.animator = new BlockCharacterAnimator(person, person, true);
  }
  walk(target: Vector3, dt: number, spawn = target, speed = 8) {
    if (!this.person.visible) { this.shown = false; return; }
    if (!this.shown) { this.person.position.copy(spawn); this.shown = true; this.target = undefined; }
    if (!this.target || this.target.distanceToSquared(target) > 1) {
      this.target = target.clone(); this.points = this.path ? this.path(this.person.position.clone(), target.clone()) : [target.clone()];
    }
    while (this.points.length && this.person.position.distanceToSquared(this.points[0]) < .16) this.points.shift();
    const next = this.points[0]; this.moving = !!next;
    if (next) {
      const displacement = next.clone().sub(this.person.position), distance = displacement.length();
      this.person.position.addScaledVector(displacement, Math.min(1, dt * speed / Math.max(.001, distance)));
    }
  }
  ride(position: Vector3, yaw: number, dt: number) {
    this.person.userData.npcActivity = 'ride';
    this.person.position.copy(position); this.shown = true; this.target = undefined; this.points = []; this.moving = false;
    this.animator.update(dt, false); this.person.rotation.y = yaw;
    for (const side of ['Left', 'Right']) {
      this.person.getObjectByName(`${side} arm pivot`)!.rotation.x = 1.1;
      this.person.getObjectByName(`${side} leg pivot`)!.rotation.x = Math.PI / 2;
    }
  }
  animate(dt: number, clock: number, activity: 'idle' | 'talk' | 'repair' | 'carry' | 'inspect' | 'photo' = 'idle', lookAt?: Vector3) {
    this.animator.update(dt);
    this.person.userData.npcActivity = this.moving ? 'walk' : activity;
    if (!this.person.visible || this.moving && activity !== 'carry') return;
    if (lookAt && this.person.position.distanceToSquared(lookAt) > .01) {
      const yaw = Math.atan2(this.person.position.x - lookAt.x, this.person.position.z - lookAt.z);
      const turn = yaw - this.person.rotation.y;
      this.person.rotation.y += Math.atan2(Math.sin(turn), Math.cos(turn)) * (1 - Math.exp(-8 * dt));
    }
    const arms = ['Left arm pivot', 'Right arm pivot'].map(n => this.person.getObjectByName(n)!);
    const rig = this.person.getObjectByName('Character rig')!;
    if (activity === 'talk') {
      const emphasis = Math.pow(Math.max(0, Math.sin(clock * 1.4)), 2);
      arms[0].rotation.x = .35 + emphasis * .6 + Math.sin(clock * 3) * .12;
      arms[1].rotation.x = .2 + Math.sin(clock * 2.4) * .14;
      arms[0].rotation.z = -.12 - emphasis * .18; arms[1].rotation.z = .1;
      this.animator.look(Math.sin(clock * 3.2) * .07, Math.sin(clock * .8) * .09, Math.sin(clock * 1.3) * .04);
    } else if (activity === 'repair') {
      arms[0].rotation.x = 1.15 + Math.sin(clock * 9) * .16;
      arms[1].rotation.x = 1.04 + Math.sin(clock * 9 + 1.4) * .2;
      rig.rotation.x = -.16;
      this.animator.look(-.25 + Math.sin(clock * 4.5) * .025);
    } else if (activity === 'photo') {
      arms.forEach((arm, i) => { arm.rotation.x = 2 + Math.sin(clock * 2) * .06; arm.rotation.z = i ? .35 : -.35; });
      this.animator.look(-.03);
    } else if (activity === 'carry') arms.forEach(arm => { arm.rotation.x = 1.1; });
    else if (activity === 'inspect') {
      arms[0].rotation.x = .75; arms[1].rotation.x = .55;
      rig.rotation.x = -.08;
      this.animator.look(-.12, Math.sin(clock * 1.1) * .16);
    }
  }
}

/** Authored cast keeps its build gates, but uses the player's rig and active routines. */
export class BuiltNPCRoutines {
  private readonly cast;
  constructor(root: Group, parts: ImportedPart[], path?: NPCPath) {
    // The active sales advisor is owned by TycoonActors, with listing responsibilities.
    this.cast = importedNPCs(parts).filter(({ stem }) => !/^salesadvisor$/i.test(stem.slice(stem.lastIndexOf('.') + 1).replace(/_/g, ''))).map(({ stem, torso }, index) => {
      const role = stem.slice(stem.lastIndexOf('.') + 1), person = createNPCCharacter(role.replace(/_/g, ' '), new Color(...torso.color).getHex());
      const names = ['Alex', 'Morgan', 'Sam', 'Robin', 'Jamie', 'Taylor', 'Quinn', 'Jordan', 'Drew', 'Blake', 'Cameron', 'Reese', 'Parker', 'Sage', 'Skyler', 'Rowan', 'Finley', 'Emery', 'Dakota', 'Harper', 'Elliot', 'Charlie', 'Logan', 'Casey', 'Remy', 'Nico', 'Jules'];
      person.name = names[index % names.length];
      person.visible = false; root.add(person);
      return { role, torso, person, index, routine: new NPCRoutine(person, path) };
    });
  }
  sync(s: TycoonState, dt: number) {
    const seen = new Set<string>(), step = s.journey?.step ?? openingStep(s);
    const car = s.car, carPoint = car && worldPoint(car.pos, 5.5);
    for (const actor of this.cast) {
      const first = actor.torso.attributes.FJ_First;
      const owned = !s.journey || ownsCosmetic(s, first);
      const partStep = s.journey && owned && COSMETIC_STEPS.has(first) ? Math.max(step, first) : step;
      const pose = partPose(actor.torso, partStep, s.journey ? undefined : s), key = actor.role.toLowerCase().replace(/_/g, '');
      actor.person.visible = owned && pose.visible && !seen.has(key);
      if (!actor.person.visible) { actor.routine.walk(new Vector3(), dt); continue; }
      seen.add(key);
      const home = new Vector3().setFromMatrixPosition(frameMatrix(pose.cf));
      // Torso centres from both authored rig generations are close to body centres.
      home.y += .6;
      const nearby = carPoint && Math.abs(home.y - carPoint.y) < 3 && home.distanceTo(carPoint) < 55;
      const customers = /seller|buyer|advisor|host|apprais|reception/i.test(actor.role);
      const working = nearby && car && ['repair', 'seller', 'buyer', 'photo', 'ready'].includes(car.status);
      const phase = Math.floor((s.clock + actor.index * 2.1) / 7) % 4;
      const offsets = [[0, 0], [3, 0], [3, 3], [0, 3]];
      const target = working ? carPoint!.clone().add(new Vector3(actor.index % 2 ? 7 : -7, 0, 4 + actor.index % 3 * 2))
        : home.clone().add(new Vector3(offsets[phase][0], 0, offsets[phase][1]));
      target.y = home.y;
      actor.routine.walk(target, dt, home, 6);
      actor.routine.animate(dt, s.clock + actor.index, working ? customers ? 'talk' : car!.status === 'repair' ? 'repair' : 'inspect' : 'idle', carPoint);
      actor.person.userData.activity = working ? customers ? 'Helping customer' : 'Inspecting vehicle' : 'Checking workstation';
    }
  }
}
