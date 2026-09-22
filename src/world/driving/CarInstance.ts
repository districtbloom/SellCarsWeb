import { Group, Mesh, Quaternion, Scene, Vector3 } from 'three';
import type { Object3D } from 'three';
import type { World } from 'cannon-es';
import { METERS_PER_UNIT, readCarRig } from './CarRig.js';
import { carProfile } from './CarProfiles.js';
import { VehiclePhysics } from './VehiclePhysics.js';
import type { VehicleTuning } from './VehiclePhysics.js';

export class CarInstance {
  readonly rig: ReturnType<typeof readCarRig>;
  readonly physics: VehiclePhysics;
  readonly wheels: Group[] = [];
  readonly label: string;
  private readonly modelTemplate: Object3D;
  readonly renderCenter = new Vector3();
  private readonly wheelPoses: { previous: Vector3; current: Vector3; before: Quaternion; after: Quaternion }[] = [];
  private poseRevision = -1;
  get car() { return this.rig.car; }

  constructor(scene: Scene, readonly id: number, world?: World, tuning?: Partial<VehicleTuning>) {
    this.rig = readCarRig(scene, id);
    // Capture the complete authored model before physics detaches the four wheels.
    this.modelTemplate = this.car.clone(true);
    this.modelTemplate.position.set(0, 0, 0); this.modelTemplate.quaternion.identity(); this.modelTemplate.scale.copy(this.rig.scale);
    const profile = carProfile(id);
    this.label = profile.label;
    this.physics = new VehiclePhysics(this.rig.spec, { ...profile.tuning, ...this.rig.tuning, ...tuning }, world);
    scene.attach(this.car);
    this.rig.wheels.forEach((mesh, index) => {
      const pivot = new Group();
      pivot.name = `${mesh.name} physics pivot`;
      pivot.position.copy(this.car.localToWorld(this.rig.centers[index].clone()));
      pivot.quaternion.copy(this.rig.rotation);
      scene.add(pivot);
      pivot.attach(mesh);
      this.wheels.push(pivot);
    });
    for (const root of [this.car, ...this.wheels]) {
      root.traverse(object => { if (object instanceof Mesh) object.castShadow = true; });
    }
  }

  capturePhysicsPose(reset = false) {
    reset ||= this.poseRevision !== this.physics.poseRevision; this.poseRevision = this.physics.poseRevision;
    this.wheels.forEach((_, index) => {
      const { position, quaternion } = this.physics.wheelTransform(index);
      let pose = this.wheelPoses[index];
      if (!pose) { pose = { previous: new Vector3(), current: new Vector3(), before: new Quaternion(), after: new Quaternion() }; this.wheelPoses[index] = pose; reset = true; }
      pose.previous.copy(pose.current); pose.before.copy(pose.after);
      pose.current.set(position.x, position.y, position.z); pose.after.set(quaternion.x, quaternion.y, quaternion.z, quaternion.w);
      if (reset) { pose.previous.copy(pose.current); pose.before.copy(pose.after); }
    });
  }

  sync(alpha = 1) {
    const { body } = this.physics;
    const q = body.previousQuaternion, p = body.previousPosition;
    this.car.quaternion.set(q.x, q.y, q.z, q.w).slerp(new Quaternion(body.quaternion.x, body.quaternion.y, body.quaternion.z, body.quaternion.w), alpha);
    this.renderCenter.set(p.x, p.y, p.z).lerp(new Vector3(body.position.x, body.position.y, body.position.z), alpha).multiplyScalar(1 / METERS_PER_UNIT);
    const offset = this.rig.centerOfMass.clone().multiply(this.rig.scale).applyQuaternion(this.car.quaternion);
    this.car.position.copy(this.renderCenter).sub(offset);
    if (alpha === 1 || !this.wheelPoses.length || this.poseRevision !== this.physics.poseRevision) this.capturePhysicsPose(true);
    this.wheels.forEach((pivot, index) => {
      const pose = this.wheelPoses[index];
      pivot.position.copy(pose.previous).lerp(pose.current, alpha).multiplyScalar(1 / METERS_PER_UNIT);
      pivot.quaternion.copy(pose.before).slerp(pose.after, alpha);
    });
  }

  cloneModel() { return this.modelTemplate.clone(true); }

  /** Place the chassis center over a world-space ground point, retaining this car's wheel geometry. */
  place(ground: Vector3, yaw: number, remember = false) {
    const clearance = Math.max(...this.rig.spec.wheels.map(wheel => wheel.radius - wheel.center.y));
    const { body } = this.physics;
    this.physics.reset();
    body.position.set(ground.x * METERS_PER_UNIT, ground.y * METERS_PER_UNIT + clearance + .08, ground.z * METERS_PER_UNIT);
    body.quaternion.setFromEuler(0, yaw, 0);
    body.previousPosition.copy(body.position); body.interpolatedPosition.copy(body.position);
    body.previousQuaternion.copy(body.quaternion); body.interpolatedQuaternion.copy(body.quaternion);
    body.aabbNeedsUpdate = true;
    if (remember) this.physics.setResetPose(body.position, body.quaternion);
    this.sync();
  }

  restoreAuthoredPose() { this.physics.setResetPose(this.rig.spec.position, this.rig.spec.quaternion); this.physics.reset(); this.sync(); }

  dispose() { this.physics.vehicle.removeFromWorld(this.physics.world); }
}
