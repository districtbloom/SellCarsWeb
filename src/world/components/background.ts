import { CubeTextureLoader } from "three";

export function createBackground() {
  return new CubeTextureLoader().setPath('cubemaps/sydney/').load([
    'posx.jpg',
    'negx.jpg',
    'posy.jpg',
    'negy.jpg',
    'posz.jpg',
    'negz.jpg'
  ]);
}