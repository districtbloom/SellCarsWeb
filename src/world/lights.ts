import { DirectionalLight, Group, HemisphereLight } from "three";

export function createLights() {
  const group = new Group()

  const hemisphereLight = new HemisphereLight(0xffeeb1, 0x080820, 2);
  group.add(hemisphereLight);

  const sun = new DirectionalLight(0xffffff, 4);
  sun.position.set(-10, 100, 20);
  sun.castShadow = true;
  sun.shadow.mapSize.width = 1024 * 8;
  sun.shadow.mapSize.height = 1024 * 8;
  group.add(sun);

  return group;
}