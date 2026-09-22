import { Box3, PerspectiveCamera, Scene, Vector3, WebGLRenderer } from 'three';
import { loadAuthoredScene, sceneCamera } from './authoredScene.js';
import { DrivingSystem } from './driving/DrivingSystem.js';
import { TycoonSystem } from './tycoon/TycoonSystem.js';
import { Loop } from './systems/loop.js';
import { createRenderer } from './systems/renderer.js';
import { Resizer } from './systems/resizer.js';
import { bindResetAndClose } from './systems/resetAndClose.js';
import { OpenWorldTown } from './OpenWorldTown.js';
import { BackgroundMusic } from './feedback/BackgroundMusic.js';
import { RuntimeMap } from './activities/RuntimeMap.js';
import { Minimap } from './activities/Minimap.js';
import { RaceSystem } from './activities/RaceSystem.js';
import { StartScreen } from './StartScreen.js';

export class World {
  private camera!: PerspectiveCamera;
  private scene!: Scene;
  private renderer: WebGLRenderer;
  private loop!: Loop;
  private driving!: DrivingSystem;
  private tycoon?: TycoonSystem;
  private town?: OpenWorldTown;
  private minimap?: Minimap;
  private music?: BackgroundMusic;
  private races?: RaceSystem;
  private resizer!: Resizer;
  private unbindReset?: () => void;
  private closed = false;
  private readonly startScreen: StartScreen;

  constructor(private container: HTMLElement) {
    this.renderer = createRenderer();
    this.startScreen = new StartScreen(() => this.enterGame());
    container.append(this.renderer.domElement);
  }

  async init() {
    try {
      this.scene = await loadAuthoredScene(`${import.meta.env.BASE_URL}scenes/main.scene.json`);
      const { camera } = sceneCamera(this.scene);
      this.camera = camera;
      this.driving = new DrivingSystem(this.scene, camera, this.renderer.domElement, import.meta.env.BASE_URL);
      this.town = new OpenWorldTown(this.scene, this.driving.physics.world, () => this.startScreen.active ? this.camera.position : this.driving.focusPosition);
      this.driving.setTycoonObstacles([], this.town.cameraObstacles);
      if (new URLSearchParams(location.search).get('tycoon') !== 'off') {
        this.tycoon = await TycoonSystem.create(this.scene, this.driving, camera, import.meta.env.BASE_URL);
      }
      this.music = new BackgroundMusic(import.meta.env.BASE_URL);
      this.minimap = new Minimap(new RuntimeMap(this.scene), () => this.driving.focusPosition, () => {
        const car = this.driving.cars.find(car => car.id === this.driving.drivenCarId);
        const direction = new Vector3(0, 0, -1).applyQuaternion((car?.car ?? this.driving.player.mesh).quaternion);
        return Math.atan2(direction.x, -direction.z);
      });
      this.loop = new Loop(camera, this.scene, this.renderer, () => this.render());
      this.driving.setControlsEnabled(false, true);
      const center = new Box3().setFromObject(this.town.root).getCenter(new Vector3()); center.y = 85;
      this.startScreen.showPanorama(camera, center);
      this.loop.updatables.push({ tick: (dt: number) => { this.startScreen.tick(dt); this.town?.tick(dt); this.music?.tick(dt); } });
      // Resize changes aspect and canvas size, without changing authored placements.
      this.resizer = new Resizer(this.container, camera, this.renderer);
    } catch (error) { this.startScreen.dispose(); throw error; }
  }

  private enterGame() {
    if (this.closed) return;
    const blocked = this.tycoon?.activityBlocked ?? false;
    this.driving.setControlsEnabled(!blocked, blocked);
    this.races = new RaceSystem(this.scene, this.driving, this.camera, this.minimap!, () => this.tycoon?.activityBlocked ?? false, undefined, (id, amount) => this.tycoon?.awardRace(id, amount) ?? false);
    this.loop.updatables.length = 0;
    this.loop.updatables.push(this.driving);
    if (this.tycoon) this.loop.updatables.push(this.tycoon);
    this.loop.updatables.push(this.town!, this.races, this.minimap!, { tick: (dt: number) => { this.music?.setLocation(this.tycoon?.minigameActive ? 'moneyearnminigame' : this.races?.active ? 'racing' : this.driving.focusPosition.x < 100 ? 'tycoon' : 'city'); this.music?.tick(dt); } });
    this.unbindReset = bindResetAndClose(() => this.tycoon?.resetSave() ?? true, () => this.close());
  }

  render() {
    if (this.closed) return;
    if (this.startScreen.active || !this.tycoon?.renderPreview(this.renderer)) this.renderer.render(this.scene, this.camera);
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
    this.startScreen.dispose();
    this.unbindReset?.();
    this.tycoon?.dispose();
    this.races?.dispose(); this.music?.dispose(); this.minimap?.dispose();
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
