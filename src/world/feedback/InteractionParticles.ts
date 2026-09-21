import { BoxGeometry, Color, DynamicDrawUsage, InstancedMesh, MeshBasicMaterial, Object3D, Vector3 } from 'three';
import type { Scene } from 'three';

export type ParticleKind = 'dust' | 'spark' | 'celebrate' | 'cash' | 'spray' | 'flash' | 'poof';
const palettes: Record<ParticleKind, number[]> = {
  dust: [0xc1b7a4, 0xa69b88, 0xd6cebb], spark: [0xffd45c, 0xff8c36, 0xfff4c5],
  celebrate: [0x65e6ad, 0xffd461, 0x6bcafa], cash: [0x79e6a4, 0xffd461],
  spray: [0x8cddf1, 0xc5f5ff, 0xffffff], flash: [0xffffff, 0xfff1ca],
  poof: [0xf1f3ed, 0xc5dfd8, 0xdde9f3],
};
interface Particle { position: Vector3; velocity: Vector3; age: number; life: number; size: number; gravity: number; spin: number; kind: ParticleKind; color: Color }

/** A single bounded draw call; particles never enter the physics world. */
export class InteractionParticles {
  readonly mesh = new InstancedMesh(new BoxGeometry(1, 1, 1), new MeshBasicMaterial({ vertexColors: false, toneMapped: false }), 320);
  private particles: Particle[] = [];
  private readonly dummy = new Object3D();
  constructor(scene: Scene) {
    this.mesh.name = 'Interaction particles'; this.mesh.count = 0; this.mesh.frustumCulled = false;
    // Allocate instance colors before the first render so Three enables the color shader variant.
    this.mesh.setColorAt(0, new Color(0xffffff)); this.mesh.instanceColor!.setUsage(DynamicDrawUsage);
    this.mesh.instanceMatrix.setUsage(DynamicDrawUsage); scene.add(this.mesh);
  }
  burst(kind: ParticleKind, position: Vector3, strength = 1, normal?: Vector3) {
    if (!Number.isFinite(strength) || strength <= 0) return;
    const amount = Math.min(2, strength), count = Math.ceil((kind === 'poof' ? 55 : kind === 'dust' ? 7 : kind === 'flash' ? 10 : 20) * amount);
    const colors = palettes[kind];
    for (let i = 0; i < count && this.particles.length < 320; i++) {
      const velocity = new Vector3((Math.random() - .5) * 2, Math.random() * 1.2 + .4, (Math.random() - .5) * 2)
        .multiplyScalar((kind === 'spark' ? 12 : kind === 'celebrate' ? 9 : 4) * Math.sqrt(amount));
      if (normal) velocity.addScaledVector(normal, 5 * amount);
      const origin = position.clone();
      if (kind === 'poof') { origin.add(new Vector3((Math.random() - .5) * 9, (Math.random() - .5) * 4, (Math.random() - .5) * 12)); velocity.multiplyScalar(1.8); }
      this.particles.push({ position: origin, velocity, age: 0,
        life: (kind === 'flash' ? .18 : kind === 'spark' ? .35 : .65) + Math.random() * .45,
        size: (kind === 'poof' ? 1.6 : kind === 'spark' ? .14 : kind === 'dust' ? .45 : .25) * (.7 + Math.random()),
        gravity: kind === 'poof' || kind === 'dust' ? -1 : kind === 'flash' ? 0 : 15,
        spin: Math.random() * 8 - 4, kind, color: new Color(colors[i % colors.length]) });
    }
  }
  tick(dt: number) {
    if (!this.particles.length && !this.mesh.count) return;
    dt = Math.max(0, Math.min(.1, dt));
    this.particles = this.particles.filter(p => {
      p.age += dt; if (p.age >= p.life) return false;
      p.velocity.y -= p.gravity * dt; p.velocity.multiplyScalar(Math.exp(-dt * (p.kind === 'dust' ? 3 : .5)));
      p.position.addScaledVector(p.velocity, dt); return true;
    });
    this.mesh.count = this.particles.length;
    this.particles.forEach((p, i) => {
      const fade = 1 - p.age / p.life, size = p.size * Math.sqrt(fade) * (p.kind === 'dust' ? 1 + p.age * 3 : 1);
      this.dummy.position.copy(p.position); this.dummy.rotation.set(p.age * p.spin, p.spin, p.age * p.spin * .7);
      this.dummy.scale.set(size, size * (p.kind === 'spark' ? 3 : 1), size * (p.kind === 'celebrate' ? .2 : 1));
      this.dummy.updateMatrix(); this.mesh.setMatrixAt(i, this.dummy.matrix); this.mesh.setColorAt(i, p.color);
    });
    this.mesh.instanceMatrix.needsUpdate = true;
    if (this.mesh.instanceColor) this.mesh.instanceColor.needsUpdate = true;
  }
  dispose() { this.particles = []; this.mesh.removeFromParent(); this.mesh.dispose(); this.mesh.geometry.dispose(); (this.mesh.material as MeshBasicMaterial).dispose(); }
}
