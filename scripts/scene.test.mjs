import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { BoxGeometry, DataTexture, DirectionalLight, Group, Mesh, MeshPhongMaterial, ObjectLoader, PerspectiveCamera, Scene, Vector3 } from 'three';
import { importTypescript } from './import-typescript.mjs';
import { editorProject } from './editor-project.mjs';

const { sceneDocument, sceneCamera } = await importTypescript(new URL('../src/world/authoredScene.ts', import.meta.url));
const fixture = new Scene();
const fixtureCars = new Group();
fixtureCars.name = 'Car lineup';
for (let i = 0; i < 2; i++) {
  const car = new Group();
  car.name = `Car ${i + 1}`;
  const mesh = new Mesh(new BoxGeometry(), new MeshPhongMaterial({
    map: new DataTexture(new Uint8Array([255, 255, 255, 255]), 1, 1),
  }));
  mesh.name = `Body ${i + 1}`;
  car.add(mesh);
  fixtureCars.add(car);
}
const fixtureCamera = new PerspectiveCamera();
fixtureCamera.name = 'MainCamera';
const fixtureSun = new DirectionalLight();
fixtureSun.name = 'Sun';
fixture.add(fixtureCars, fixtureCamera, fixtureSun);
const json = fixture.toJSON();

test('accepts scene and editor project exports; rejects individual objects', () => {
  assert.equal(sceneDocument(json), json);
  assert.equal(sceneDocument({ scene: json, scripts: {} }), json);
  for (const invalid of [null, 1, {}, { object: { type: 'Mesh' } }, { scene: false }]) {
    assert.throws(() => sceneDocument(invalid));
  }
});

test('checked-in scene has a valid camera and complete asset references', async () => {
  // Do not constrain artist choices such as car count, names, layout or colors.
  const scene = sceneDocument(JSON.parse(await readFile(new URL('../public/scenes/main.scene.json', import.meta.url), 'utf8')));
  editorProject(scene);
  const imageIds = new Set((scene.images ?? []).map(image => image.uuid));
  const textureIds = new Set((scene.textures ?? []).map(texture => texture.uuid));
  for (const texture of scene.textures ?? []) assert.ok(imageIds.has(texture.image));
  for (const material of scene.materials ?? []) {
    for (const [key, value] of Object.entries(material)) {
      if (key === 'map' || key.endsWith('Map')) assert.ok(textureIds.has(value), key);
    }
  }
});

test('artist transforms, materials, lighting and camera survive a JSON round trip', async () => {
  const data = structuredClone(sceneDocument(json));
  // Browser image decoding is outside this Node test. Keep all texture UUIDs,
  // replacing only image payloads with a tiny DataTexture-compatible fixture.
  for (const image of data.images) image.url = { data: [255, 255, 255, 255], width: 1, height: 1, type: 'Uint8Array' };
  const scene = await new ObjectLoader().parseAsync(data);
  const lineup = scene.getObjectByName('Car lineup');
  assert.equal(lineup.children.length, 2);
  assert.equal(lineup.children.reduce((sum, car) => sum + car.children.length, 0), 2);
  const car = lineup.children[0];
  car.position.set(12, 4, -7);
  car.rotation.y = 0.7;
  car.scale.setScalar(1.2);
  const mesh = car.children.find(object => object.isMesh);
  const material = Array.isArray(mesh.material) ? mesh.material[0] : mesh.material;
  material.color.setHex(0x2255aa);
  scene.getObjectByName('Sun').intensity = 0.6;
  scene.getObjectByName('MainCamera').position.set(3, 40, -150);
  scene.updateMatrixWorld(true);
  const restored = await new ObjectLoader().parseAsync(sceneDocument({ scene: scene.toJSON() }));
  const restoredCar = restored.getObjectByName(car.name);
  assert.deepEqual(restoredCar.position.toArray(), [12, 4, -7]);
  assert.ok(Math.abs(restoredCar.rotation.y - 0.7) < 1e-10);
  assert.ok(Math.abs(restoredCar.scale.x - 1.2) < 1e-10);
  const restoredMesh = restored.getObjectByName(mesh.name);
  const restoredMaterial = Array.isArray(restoredMesh.material) ? restoredMesh.material[0] : restoredMesh.material;
  assert.equal(restoredMaterial.color.getHex(), 0x2255aa);
  assert.equal(restored.getObjectByName('Sun').intensity, 0.6);
  assert.deepEqual(sceneCamera(restored).camera.position.toArray(), [3, 40, -150]);
});

test('parented MainCamera keeps world position and viewing direction in runtime and editor', () => {
  const scene = new Scene();
  const parent = new Group();
  parent.position.set(5, 2, 3);
  parent.rotation.y = 0.8;
  const source = new PerspectiveCamera(50, 1, 0.1, 1000);
  source.name = 'MainCamera';
  source.position.set(4, 8, 12);
  source.lookAt(0, 0, 0);
  source.userData.focusDistance = 30;
  parent.add(source);
  scene.add(parent);
  const { camera, target } = sceneCamera(scene);
  assert.ok(camera.position.distanceTo(source.getWorldPosition(new Vector3())) < 1e-10);
  assert.ok(camera.getWorldDirection(new Vector3()).distanceTo(source.getWorldDirection(new Vector3())) < 1e-10);
  assert.ok(Math.abs(target.distanceTo(camera.position) - 30) < 1e-10);
  const project = editorProject(scene.toJSON());
  assert.deepEqual(project.camera.object.matrix, source.matrixWorld.toArray());
  assert.equal(project.scene.object.type, 'Scene');
});

test('missing, duplicated and invalid cameras produce actionable errors', () => {
  const scene = new Scene();
  assert.throws(() => sceneCamera(scene), /MainCamera/);
  const camera = new PerspectiveCamera();
  camera.name = 'MainCamera';
  scene.add(camera, camera.clone());
  assert.throws(() => sceneCamera(scene), /exactly one/);
  scene.remove(scene.children[1]);
  camera.userData.focusDistance = -1;
  assert.throws(() => sceneCamera(scene), /focusDistance/);
});
