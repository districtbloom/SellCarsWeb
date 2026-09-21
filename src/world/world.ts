import { PerspectiveCamera, Scene, WebGLRenderer } from 'three';
import { loadAuthoredScene, sceneCamera } from './authoredScene.js';
import { DrivingSystem } from './driving/DrivingSystem.js';
import { TycoonSystem } from './tycoon/TycoonSystem.js';
import { Loop } from './systems/loop.js';
import { createRenderer } from './systems/renderer.js';
import { Resizer } from './systems/resizer.js';
import { bindResetAndClose } from './systems/resetAndClose.js';
import { OpenWorldTown } from './OpenWorldTown.js';

export class World {
  private camera!: PerspectiveCamera;
  private scene!: Scene;
  private renderer: WebGLRenderer;
  private loop!: Loop;
  private driving!: DrivingSystem;
  private tycoon?: TycoonSystem;
  private town?: OpenWorldTown;
  private resizer!: Resizer;
  private unbindReset?: () => void;
  private closed = false;

  constructor(private container: HTMLElement) {
    this.renderer = createRenderer();
    container.append(this.renderer.domElement);
  }

  async init() {
    this.scene = await loadAuthoredScene(`${import.meta.env.BASE_URL}scenes/main.scene.json`);
    const { camera } = sceneCamera(this.scene);
    this.camera = camera;
    this.driving = new DrivingSystem(this.scene, camera, this.renderer.domElement, import.meta.env.BASE_URL);
    this.town = new OpenWorldTown(this.scene, this.driving.physics.world, () => this.driving.focusPosition);
    this.driving.setTycoonObstacles([], this.town.cameraObstacles);
    if (new URLSearchParams(location.search).get('tycoon') !== 'off') {
      this.tycoon = await TycoonSystem.create(this.scene, this.driving, camera, import.meta.env.BASE_URL);
    }
    this.loop = new Loop(camera, this.scene, this.renderer, () => this.render());
    this.loop.updatables.push(this.driving);
    if (this.tycoon) this.loop.updatables.push(this.tycoon);
    this.loop.updatables.push(this.town);
    // Resize changes aspect and canvas size, without changing authored placements.
    this.resizer = new Resizer(this.container, camera, this.renderer);
    this.unbindReset = bindResetAndClose(() => this.tycoon?.resetSave() ?? true, () => this.close());
  }

  render() {
    if (this.closed) return;
    if (!this.tycoon?.renderPreview(this.renderer)) this.renderer.render(this.scene, this.camera);
  }

  start() {
    if (this.closed) return;
    this.loop.start();
  }

  stop() {
    this.loop.stop();
  }

  private close() {
    if (this.closed) return;
    this.closed = true;
    this.stop();
    this.unbindReset?.();
    this.tycoon?.dispose();
    this.town?.dispose();
    this.driving.dispose();
    this.resizer.dispose();
    if (document.pointerLockElement) document.exitPointerLock();
    this.renderer.dispose();
    this.renderer.forceContextLoss();
    const screen = document.createElement('div');
    screen.className = 'game-closed';
    const title = document.createElement('h1'); title.textContent = 'Game closed';
    const text = document.createElement('p'); text.textContent = 'You can close this tab. Reload to start a new game.';
    screen.append(title, text);
    this.container.replaceChildren(screen);
    // User-opened browser tabs may refuse window.close(); the game is already stopped.
    try { window.close(); } catch { /* The closed screen remains available. */ }
  }
}
