import { readFile, writeFile } from 'node:fs/promises';
import { BoxGeometry, GridHelper, Group, Matrix4, Mesh, MeshStandardMaterial, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';

const file = new URL('../public/scenes/main.scene.json', import.meta.url);
const document = JSON.parse(await readFile(file, 'utf8'));
const scene = document.scene ?? document;
const { defaultTuning } = await importTypescript(new URL('../src/world/driving/VehiclePhysics.ts', import.meta.url));
const { carProfile } = await importTypescript(new URL('../src/world/driving/CarProfiles.ts', import.meta.url));
let car;
let carWorld;
function visit(object, parent = new Matrix4()) {
  const world = parent.clone().multiply(new Matrix4().fromArray(object.matrix ?? new Matrix4().elements));
  if (object.name === 'Car 14') { car = object; carWorld = world; }
  const match = /^Car (\d+)$/.exec(object.name ?? '');
  if (match) {
    const profile = carProfile(Number(match[1]));
    object.userData = { ...object.userData, vehicle: { ...profile.tuning, ...object.userData?.vehicle } };
  }
  if (object.name === 'Sun' && object.shadow?.mapSize?.[0] === 8192) {
    // The template's tiny shadow frustum misses the cars, and 8K is excessive.
    object.shadow.mapSize = [2048, 2048];
    Object.assign(object.shadow.camera, { left: -140, right: 140, top: 140, bottom: -140 });
    object.shadow.normalBias = 0.04;
  }
  for (const child of object.children ?? []) visit(child, world);
}
visit(scene.object);
if (!car) throw new Error('Car 14 is missing');
car.userData = { ...car.userData, vehicle: { ...defaultTuning, ...car.userData?.vehicle } };
if (!scene.object.children.some(object => object.name === 'Driving course')) {
  const center = new Vector3().setFromMatrixPosition(carWorld);
  const course = new Group();
  course.name = 'Driving course';
  const ground = new Mesh(new BoxGeometry(1200, 2, 1200), new MeshStandardMaterial({ color: 0x3f494b, roughness: 1 }));
  ground.name = 'Driving ground';
  ground.position.set(0, -1, 0);
  ground.receiveShadow = true;
  ground.userData = { collider: 'box', drivingGround: true };
  course.add(ground);
  const grid = new GridHelper(1200, 120, 0x748180, 0x596465);
  grid.name = 'Ground markings';
  grid.position.y = 0.02;
  course.add(grid);
  for (let index = 0; index < 3; index++) {
    const bump = new Mesh(new BoxGeometry(14, 0.6, 2), new MeshStandardMaterial({ color: 0xd4a43c, roughness: 0.9 }));
    bump.name = `Suspension bump ${index + 1}`;
    bump.position.set(center.x, 0.3, center.z - 40 - index * 8);
    bump.userData.collider = 'box';
    bump.receiveShadow = bump.castShadow = true;
    course.add(bump);
  }
  const ramp = new Mesh(new BoxGeometry(16, 1, 24), new MeshStandardMaterial({ color: 0x69787e, roughness: 0.9 }));
  ramp.name = 'Test ramp';
  ramp.position.set(center.x, 1.45, center.z - 100);
  ramp.rotation.x = 0.12;
  ramp.userData.collider = 'box';
  ramp.receiveShadow = ramp.castShadow = true;
  course.add(ramp);
  course.updateMatrixWorld(true);
  const exported = course.toJSON();
  scene.object.children.push(exported.object);
  for (const key of ['geometries', 'materials', 'textures', 'images']) {
    if (exported[key]) scene[key] = [...(scene[key] ?? []), ...exported[key]];
  }
}
await writeFile(file, JSON.stringify(document));
console.log('Driving course and individual tuning for every car saved without replacing authored edits.');
