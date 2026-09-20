import { Clock, PerspectiveCamera, Scene, WebGLRenderer } from "three";

export type Updatable<T = unknown> = T & { tick?: (delta: number) => void };

export class Loop {
  updatables: Updatable[] = [];
  private camera: PerspectiveCamera;
  private scene: Scene;
  private renderer: WebGLRenderer;
  private clock = new Clock();

  constructor(camera: PerspectiveCamera, scene: Scene, renderer: WebGLRenderer, private renderFrame?: () => void) {
    this.camera = camera;
    this.scene = scene;
    this.renderer = renderer;
  }

  start() {
    this.clock.start();
    this.renderer.setAnimationLoop(() => {
      this.tick();
      if (this.renderFrame) this.renderFrame(); else this.renderer.render(this.scene, this.camera);
    })
  }

  stop() {
    this.renderer.setAnimationLoop(null);
    this.clock.stop();
  }

  tick() {
    const delta = Math.min(this.clock.getDelta(), 0.1);
    for (const object of this.updatables) {
      object.tick?.(delta);
    }
  }
}
