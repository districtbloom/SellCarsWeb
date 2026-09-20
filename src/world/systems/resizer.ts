import { PerspectiveCamera, WebGLRenderer } from "three";

function setSize(container: HTMLElement, camera: PerspectiveCamera, renderer: WebGLRenderer) {
  // Set the camera's aspect ratio
  camera.aspect = container.clientWidth / container.clientHeight;

  // update the camera's frustum
  camera.updateProjectionMatrix();

  // update the size of the renderer AND the canvas
  renderer.setSize(container.clientWidth, container.clientHeight);

  // set the pixel ratio (for mobile devices)
  renderer.setPixelRatio(window.devicePixelRatio);

}

export class Resizer {
  private readonly resize: () => void;
  constructor(container: HTMLElement, camera: PerspectiveCamera, renderer: WebGLRenderer) {
    setSize(container, camera, renderer);

    this.resize = () => {
      setSize(container, camera, renderer);
      this.onResize();
    };
    window.addEventListener('resize', this.resize);
  }

  onResize(): void {};

  dispose() { window.removeEventListener('resize', this.resize); }
}
