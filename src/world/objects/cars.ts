import { Box3, Group, Vector3 } from 'three';
import { MTLLoader } from 'three/examples/jsm/loaders/MTLLoader.js';
import { OBJLoader } from 'three/examples/jsm/loaders/OBJLoader.js';

export async function createCars(): Promise<Group> {
  const assetPath = `${import.meta.env.BASE_URL}carAssets/`;
  const materials = await new MTLLoader()
    .setResourcePath(`${assetPath}textures/`)
    .loadAsync(`${assetPath}models/everything.mtl`);

  for (const info of Object.values(materials.materialsInfo)) {
    // This export repeats the color image as an opacity map. Its RGB values
    // are not opacity; the diffuse texture already carries its alpha channel.
    if (info.map_d === info.map_kd) delete info.map_d;
    // The exported _nmap images are tangent-space normals, not height maps.
    if (info.map_bump?.endsWith('_nmap.png')) {
      info.norm = info.map_bump;
      delete info.map_bump;
    }
  }

  const model = await new OBJLoader()
    .setMaterials(materials)
    .loadAsync(`${assetPath}models/everything.obj`);

  return arrangeCars(model);
}

export function arrangeCars(model: Group): Group {
  const lineup = new Group();
  lineup.name = 'Car lineup';
  let currentCar: Group | undefined;
  let currentId: string | undefined;

  // In everything.obj each car starts with its four wheels, followed by all
  // its other parts. Wheel suffixes identify cars 1–14; other suffixes do not.
  // Copy the array because adding a part to a car changes its original parent.
  for (const part of [...model.children]) {
    const wheelId = /^Wheel(?:rl|rr|fl|fr)(\d+)$/.exec(part.name)?.[1];
    if (wheelId && wheelId !== currentId) {
      currentId = wheelId;
      currentCar = new Group();
      currentCar.name = `Car ${wheelId}`;
      lineup.add(currentCar);
    }
    if (!currentCar) throw new Error(`Car group missing for ${part.name}`);
    currentCar.add(part);
  }

  if (!lineup.children.length) throw new Error('The OBJ contains no cars');

  const gap = 3;
  let nextX = 0;
  for (const car of lineup.children) {
    const bounds = new Box3().setFromObject(car);
    const size = bounds.getSize(new Vector3());
    const center = bounds.getCenter(new Vector3());
    car.position.set(nextX - bounds.min.x, -bounds.min.y, -center.z);
    nextX += size.x + gap;
  }

  const totalWidth = nextX - gap;
  for (const car of lineup.children) car.position.x -= totalWidth / 2;
  lineup.updateMatrixWorld(true);
  return lineup;
}
