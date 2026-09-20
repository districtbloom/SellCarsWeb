import { Box3, Matrix4, Mesh, Object3D, Quaternion, Scene, Vector3 } from 'three';
import { Quaternion as PhysicsQuaternion, Vec3 } from 'cannon-es';
import type { VehicleSpec, VehicleTuning } from './VehiclePhysics.js';

export const METERS_PER_UNIT = 0.25;
export const wheelNames = ['Wheelfl14', 'Wheelfr14', 'Wheelrl14', 'Wheelrr14'];
export const carWheelNames = (id: number) => ['Wheelfl', 'Wheelfr', 'Wheelrl', 'Wheelrr'].map(prefix => `${prefix}${id}`);
export const physicsVector = (v: Vector3) => new Vec3(v.x, v.y, v.z);

export function localBounds(object: Object3D, reference: Object3D): Box3 {
  const inverse = reference.matrixWorld.clone().invert();
  const box = new Box3();
  object.traverse(child => {
    if (!(child instanceof Mesh)) return;
    child.geometry.computeBoundingBox();
    box.union(child.geometry.boundingBox!.clone().applyMatrix4(new Matrix4().multiplyMatrices(inverse, child.matrixWorld)));
  });
  return box;
}

export function readCarRig(scene: Scene, id = 14) {
  const name = `Car ${id}`;
  const cars: Object3D[] = [];
  scene.traverse(object => { if (object.name === name) cars.push(object); });
  if (cars.length !== 1) throw new Error(`Driving requires exactly one group named ${name}`);
  const car = cars[0];
  scene.updateMatrixWorld(true);
  const scale = car.getWorldScale(new Vector3());
  if (scale.x <= 0 || Math.abs(scale.x - scale.y) > 0.001 || Math.abs(scale.x - scale.z) > 0.001) {
    throw new Error(`${name} needs a positive uniform scale for its wheels`);
  }
  const tuning: Partial<VehicleTuning> = car.userData.vehicle ?? {};
  const wheels = carWheelNames(id).map(wheelName => {
    const matches: Object3D[] = [];
    car.traverse(object => { if (object.name === wheelName) matches.push(object); });
    if (matches.length !== 1) throw new Error(`${name} needs exactly one wheel named ${wheelName}`);
    return matches[0];
  });
  const wheelBounds = wheels.map(mesh => localBounds(mesh, car));
  if (wheelBounds.some(bounds => bounds.isEmpty())) throw new Error('Each wheel needs mesh geometry');
  const centers = wheelBounds.map(bounds => bounds.getCenter(new Vector3()));
  const centerOfMass = centers.reduce((center, next) => center.add(next), new Vector3()).multiplyScalar(0.25);
  centerOfMass.y += 0.9;
  const bodyBounds = localBounds(car, car);
  // Exclude decorative low bumpers from the approximate chassis collision box.
  bodyBounds.min.y = centers[0].y + 0.3;
  const unitsToMeters = scale.x * METERS_PER_UNIT;
  const halfExtents = bodyBounds.getSize(new Vector3()).multiplyScalar(unitsToMeters / 2);
  halfExtents.x *= 0.94;
  halfExtents.z *= 0.94;
  const shapeOffset = bodyBounds.getCenter(new Vector3()).sub(centerOfMass).multiplyScalar(unitsToMeters);
  const position = car.localToWorld(centerOfMass.clone()).multiplyScalar(METERS_PER_UNIT);
  const rotation = car.getWorldQuaternion(new Quaternion());
  const spec: VehicleSpec = {
    position: physicsVector(position), quaternion: new PhysicsQuaternion(rotation.x, rotation.y, rotation.z, rotation.w),
    halfExtents: physicsVector(halfExtents), shapeOffset: physicsVector(shapeOffset),
    wheels: centers.map((center, index) => {
      const size = wheelBounds[index].getSize(new Vector3());
      return {
        center: physicsVector(center.clone().sub(centerOfMass).multiplyScalar(unitsToMeters)),
        radius: (size.y + size.z) * unitsToMeters / 4, front: index < 2,
      };
    }),
  };
  return { car, scale, rotation, centerOfMass, centers, wheels, spec, tuning };
}
