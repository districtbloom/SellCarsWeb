import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { readFileSync } from 'node:fs';
import { Box3, Color, LoadingManager, MathUtils, PerspectiveCamera, Scene, Texture, Vector3 } from 'three';
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js';
import { MTLLoader } from 'three/examples/jsm/loaders/MTLLoader.js';
import { importTypescript } from './import-typescript.mjs';

const root = new URL('../', import.meta.url);
const { arrangeCars } = await importTypescript(new URL('src/world/objects/cars.ts', root));
const { createLights } = await importTypescript(new URL('src/world/lights.ts', root));
const manager = new LoadingManager();
const textures = new Map();
// Embed the original PNGs, avoiding browser/canvas dependencies and local paths.
manager.addHandler(/\.png$/i, {
  load(path) {
    if (textures.has(path)) return textures.get(path);
    const texture = new Texture();
    const url = `data:image/png;base64,${readFileSync(new URL(`public/carAssets/textures/${path}`, root)).toString('base64')}`;
    texture.source.toJSON = function (meta) {
      const image = { uuid: this.uuid, url };
      if (meta && typeof meta !== 'string') meta.images[this.uuid] = image;
      return image;
    };
    textures.set(path, texture);
    return texture;
  },
});
const materials = new MTLLoader(manager).parse(
  await readFile(new URL('public/carAssets/models/everything.mtl', root), 'utf8'), '',
);
for (const info of Object.values(materials.materialsInfo)) {
  if (info.map_d === info.map_kd) delete info.map_d;
  if (info.map_bump?.endsWith('_nmap.png')) {
    info.norm = info.map_bump;
    delete info.map_bump;
  }
}
const cars = arrangeCars(new OBJLoader().setMaterials(materials).parse(
  await readFile(new URL('public/carAssets/models/everything.obj', root), 'utf8'),
));
const scene = new Scene();
scene.name = 'Car showroom';
scene.background = new Color(0x252b35);
const lights = createLights();
lights.name = 'Lighting';
lights.children[0].name = 'Sky light';
lights.children[1].name = 'Sun';
scene.add(cars, lights);
const bounds = new Box3().setFromObject(cars);
const size = bounds.getSize(new Vector3());
const center = bounds.getCenter(new Vector3());
const camera = new PerspectiveCamera(35, 16 / 9, 0.1, 2000);
camera.name = 'MainCamera';
const elevation = MathUtils.degToRad(20);
const verticalFov = MathUtils.degToRad(camera.fov);
const horizontalFov = 2 * Math.atan(Math.tan(verticalFov / 2) * camera.aspect);
const height = size.y * Math.cos(elevation) + size.z * Math.sin(elevation);
const depth = size.z * Math.cos(elevation) + size.y * Math.sin(elevation);
const distance = 1.15 * Math.max(size.x / (2 * Math.tan(horizontalFov / 2)), height / (2 * Math.tan(verticalFov / 2))) + depth / 2;
camera.position.copy(center).add(new Vector3(0, distance * Math.sin(elevation), -distance * Math.cos(elevation)));
camera.lookAt(center);
camera.far = distance * 10;
camera.userData.focusDistance = distance;
scene.add(camera);
scene.updateMatrixWorld(true);
await mkdir(new URL('public/scenes/', root), { recursive: true });
// Regeneration must never silently overwrite an artist's edits.
await writeFile(new URL('public/scenes/main.scene.json', root), JSON.stringify(scene.toJSON()), {
  flag: process.argv.includes('--force') ? 'w' : 'wx',
});
console.log(`Created main.scene.json: ${cars.children.length} cars, ${textures.size} embedded textures, lights and MainCamera.`);
await import('./add-driving-course.mjs');
