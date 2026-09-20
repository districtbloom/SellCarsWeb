import { PerspectiveCamera } from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { Updatable } from './loop.js';

export function createControls(camera: PerspectiveCamera, canvas: HTMLElement) {
  const controls: Updatable<OrbitControls> = new OrbitControls(camera, canvas);
  controls.enableDamping = true;

  controls.tick = () => controls.update();

  return controls;
}
