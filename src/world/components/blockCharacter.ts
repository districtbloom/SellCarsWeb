import { BoxGeometry, BufferGeometry, Float32BufferAttribute, Group, Mesh, MeshBasicMaterial, MeshStandardMaterial, Vector3 } from 'three';

/** Shared block-person model for sellers, staff, and the player's UI portrait. */
export function createBlockCharacter(name: string, shirtColor: number): Group {
  const group = new Group(); group.name = name;
  const rig = new Group(); rig.name = 'Character rig'; group.add(rig);
  const box = (name: string, size: number[], position: number[], color: number, parent = rig) => {
    const mesh = new Mesh(new BoxGeometry(size[0], size[1], size[2]), new MeshStandardMaterial({ color, roughness: .8 }));
    mesh.name = name; mesh.position.set(position[0], position[1], position[2]);
    mesh.castShadow = true; mesh.receiveShadow = true; parent.add(mesh);
  };
  box('Root', [2, 3, 1], [0, 0, 0], shirtColor);
  box('Head', [2, 2, 2], [0, 2.5, 0], 0xdaa675);
  for (const sign of [-1, 1]) {
    const side = sign < 0 ? 'Right' : 'Left';
    const arm = new Group(); arm.name = `${side} arm pivot`; arm.position.set(sign * 1.4, 1.5, 0); rig.add(arm);
    const leg = new Group(); leg.name = `${side} leg pivot`; leg.position.set(sign * .55, -1.4, 0); rig.add(leg);
    box('Arm', [.8, 3, .8], [0, -1.4, 0], 0xdaa675, arm);
    box('Leg', [.85, 3, .9], [0, -1.5, 0], 0x181b1e, leg);
  }
  // Pixel face: a single tiny mesh, with no canvas texture or browser dependency.
  const vertices: number[] = [];
  for (const [x, y, w, h] of [[-.38, .17, .16, .2], [.38, .17, .16, .2], [0, -.35, .42, .09], [-.25, -.27, .09, .16], [.25, -.27, .09, .16]]) {
    const l = x - w / 2, r = x + w / 2, b = y - h / 2, t = y + h / 2;
    vertices.push(l,b,0, l,t,0, r,t,0, l,b,0, r,t,0, r,b,0);
  }
  const geometry = new BufferGeometry(); geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3)); geometry.computeVertexNormals();
  const face = new Mesh(geometry, new MeshBasicMaterial({ color: 0x203030 }));
  face.name = 'Face'; face.position.set(0, 2.5, -1.006); rig.add(face);
  return group;
}

/** Distance-driven, opposite arm/leg swings; teleports and stationary actors settle to idle. */
export class BlockCharacterAnimator {
  private readonly last = new Vector3();
  private initialized = false;
  private wasVisible = false;
  private phase = 0;
  private amount = 0;
  private readonly rig;
  private readonly limbs;
  constructor(private character: Group, private motion = character, private faceMovement = false) {
    this.rig = character.getObjectByName('Character rig')!;
    this.limbs = ['Left arm pivot', 'Right arm pivot', 'Left leg pivot', 'Right leg pivot'].map(name => character.getObjectByName(name)!);
  }
  update(delta: number, canWalk = true) {
    const dt = Math.min(Math.max(delta, 0), .1), position = this.motion.position;
    const dx = position.x - this.last.x, dz = position.z - this.last.z, distance = Math.hypot(dx, dz);
    const moving = this.initialized && this.wasVisible && this.motion.visible && canWalk && dt > 0 && distance < Math.max(8, dt * 60);
    const speed = moving ? distance / dt : 0;
    this.last.copy(position); this.initialized = true; this.wasVisible = this.motion.visible;
    this.amount += (Math.min(1, speed / 10) - this.amount) * (1 - Math.exp(-14 * dt));
    if (moving) this.phase += distance * .65;
    const swing = Math.sin(this.phase) * .7 * this.amount;
    this.limbs.forEach((limb, i) => { limb.rotation.set(swing * [1, -1, -1, 1][i], 0, 0); });
    this.rig.position.y = Math.abs(Math.sin(this.phase * 2)) * .09 * this.amount;
    this.rig.rotation.x = 0;
    this.character.getObjectByName('Head')!.rotation.x = 0;
    this.character.getObjectByName('Face')!.rotation.x = 0;
    this.character.getObjectByName('Face')!.position.set(0, 2.5, -1.006);
    if (this.faceMovement && speed > .1) {
      const turn = Math.atan2(-dx, -dz) - this.character.rotation.y;
      this.character.rotation.y += Math.atan2(Math.sin(turn), Math.cos(turn)) * (1 - Math.exp(-12 * dt));
    }
  }
  /** Lift both arms and tuck the legs in flight; lower slightly on the way down. */
  jump(seconds: number, verticalSpeed: number) {
    const reach = Math.min(1, Math.max(0, seconds) / .12);
    const lift = reach * reach * (3 - 2 * reach);
    const rising = Math.max(0, Math.min(1, verticalSpeed / 5.5));
    this.rig.position.y = 0; this.rig.rotation.x = -.08 * lift;
    this.limbs[0].rotation.set((1.9 + .35 * rising) * lift, 0, -.18 * lift);
    this.limbs[1].rotation.set((1.9 + .35 * rising) * lift, 0, .18 * lift);
    this.limbs[2].rotation.set((.25 + .25 * rising) * lift, 0, -.04 * lift);
    this.limbs[3].rotation.set((.15 + .2 * rising) * lift, 0, .04 * lift);
  }
  /** Rapid typing with a stationary body. */
  typing(seconds: number) {
    // Only the hands/arms move; feet, torso and head remain completely still.
    this.rig.position.y = 0; this.rig.rotation.set(0, 0, 0);
    this.limbs[2].rotation.set(0, 0, 0); this.limbs[3].rotation.set(0, 0, 0);
    this.limbs[0].rotation.set(1.15 + Math.sin(seconds * 36) * .13, 0, -.08);
    this.limbs[1].rotation.set(1.15 + Math.sin(seconds * 36 + Math.PI) * .13, 0, .08);
    this.character.getObjectByName('Head')!.rotation.set(0, 0, 0);
    const face = this.character.getObjectByName('Face')!; face.rotation.set(0, 0, 0); face.position.set(0, 2.5, -1.006);
  }
  /** Two-handed latch reach, then a weighted lift; arms lead torso and knees. */
  opening(progress: number) {
    const ease = (n: number) => { const t = Math.max(0, Math.min(1, n)); return t * t * (3 - 2 * t); };
    const reach = ease(progress / .3), lift = ease((progress - .36) / .55);
    const follow = ease((progress - .48) / .5);
    this.limbs[0].rotation.x = this.limbs[1].rotation.x = reach * Math.PI / 3 + lift * Math.PI * .48;
    this.limbs[2].rotation.x = this.limbs[3].rotation.x = -.14 * reach * (1 - follow);
    this.rig.rotation.x = -.17 * reach * (1 - follow);
    this.rig.position.y = -.18 * reach + .34 * follow;
    for (const name of ['Head', 'Face']) this.character.getObjectByName(name)!.rotation.x = -.4 * reach + .3 * lift;
    const headAngle = -.4 * reach + .3 * lift;
    this.character.getObjectByName('Face')!.position.set(0, 2.5 + 1.006 * Math.sin(headAngle), -1.006 * Math.cos(headAngle));
  }
}

export function disposeBlockCharacter(character: Group) {
  character.traverse(object => {
    if (!(object instanceof Mesh)) return;
    object.geometry.dispose();
    for (const material of Array.isArray(object.material) ? object.material : [object.material]) material.dispose();
  });
  character.removeFromParent();
}

/** Same size and body-centre origin as PlayerController's visible character. */
export function createNPCCharacter(name: string, shirtColor: number): Group {
  const root = new Group(); root.name = name;
  const character = createBlockCharacter(name + ' model', shirtColor), scale = 7.2 / 7.9;
  character.scale.setScalar(scale); character.position.y = .45 * scale; root.add(character);
  return root;
}
