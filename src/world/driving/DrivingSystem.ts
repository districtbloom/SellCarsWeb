import { Object3D, PerspectiveCamera, Quaternion, Scene, Vector3 } from 'three';
import { Quaternion as PhysicsQuaternion, Vec3 } from 'cannon-es';
import { DrivingInput } from './DrivingInput.js';
import { PlayerController } from './PlayerController.js';
import { CarInstance } from './CarInstance.js';
import { SmartFollowCamera } from './SmartFollowCamera.js';
import { localBounds, METERS_PER_UNIT, physicsVector } from './CarRig.js';

export class DrivingSystem {
  readonly cars: CarInstance[] = [];
  private selected: CarInstance;
  private scriptedCar?: CarInstance;
  get drivenCarId() { return this.driving ? this.selected.id : undefined; }
  get physics() { return this.selected.physics; }
  private get car() { return this.selected.car; }
  private accumulator = 0;
  private nearby?: CarInstance;
  readonly player: PlayerController;
  private driving = false;
  get isDriving() { return this.driving; }
  get focusPosition() { return this.driving ? this.car.position : this.player.mesh.position; }
  private readonly input = new DrivingInput();
  private readonly followCamera: SmartFollowCamera;
  private readonly obstacles: Object3D[] = [];
  private readonly prompt = document.createElement('div');
  private exitBlockedTime = 0;
  private controlsEnabled = true;
  private presentation = false;
  private walkTargets: Vector3[] = [];
  private walkStall = 0;
  private lastWalkPosition = new Vector3();
  onInteract?: () => boolean;
  onFootSpawn?: () => Vector3;
  get walkingToTarget() { return this.walkTargets.length > 0; }

  setControlsEnabled(enabled: boolean, presentation = false) {
    if (this.controlsEnabled !== enabled) this.input.clear();
    this.controlsEnabled = enabled; this.presentation = presentation;
    this.followCamera.setInputEnabled(enabled);
    if (!enabled) this.walkTargets = [];
  }
  walkTo(points: Vector3[]) { this.walkTargets = points.map(p => p.clone()); this.walkStall = 0; this.lastWalkPosition.copy(this.player.mesh.position); }
  stopWalking() { this.walkTargets = []; }
  placePlayer(position: Vector3) {
    this.player.place(new Vec3(position.x * METERS_PER_UNIT, position.y * METERS_PER_UNIT, position.z * METERS_PER_UNIT));
    this.updateCamera(0, true);
  }
  setTycoonObstacles(previous: Object3D[], next: Object3D[]) {
    for (const object of previous) { const i = this.obstacles.indexOf(object); if (i >= 0) this.obstacles.splice(i, 1); }
    this.obstacles.push(...next);
  }

  setScriptedCar(id?: number) {
    const next = this.cars.find(car => car.id === id);
    if (next === this.scriptedCar) return;
    if (this.scriptedCar) this.scriptedCar.physics.vehicle.addToWorld(this.physics.world);
    this.scriptedCar = next;
    if (next) next.physics.vehicle.removeFromWorld(this.physics.world);
  }

  constructor(private scene: Scene, private camera: PerspectiveCamera, private canvas: HTMLElement = document.body) {
    // All chassis and wheel suspensions share one world and one fixed clock.
    this.selected = new CarInstance(scene, 14);
    this.cars.push(this.selected);
    for (let id = 1; id <= 13; id++) this.cars.push(new CarInstance(scene, id, this.physics.world));
    this.addSceneColliders();
    this.player = new PlayerController(this.physics.world, scene);
    const spawn = this.player.findExit(this.physics.body);
    if (!spawn) throw new Error('Car 14 needs a clear, grounded space beside it for the player spawn');
    this.player.place(spawn);
    camera.fov = 60;
    camera.near = 0.2;
    camera.far = 2500;
    camera.updateProjectionMatrix();
    this.followCamera = new SmartFollowCamera(camera, canvas, this.obstacles);
    this.followCamera.setOnFoot(true);
    this.syncVisuals();
    this.updateCamera(0, true);
    this.prompt.className = 'vehicle-prompt';
    this.prompt.hidden = true;
    document.body.append(this.prompt);
  }

  private addSceneColliders() {
    const candidates: Object3D[] = [];
    this.scene.traverse(object => {
      if (object.userData.collider !== 'box') return;
      let ancestor: Object3D | null = object;
      while (ancestor) {
        if (/^Car \d+$/.test(ancestor.name)) return;
        ancestor = ancestor.parent;
      }
      candidates.push(object);
    });
    for (const object of candidates) {
      const bounds = localBounds(object, object);
      if (bounds.isEmpty()) continue;
      const scale = object.getWorldScale(new Vector3());
      const half = bounds.getSize(new Vector3()).multiply(scale).multiplyScalar(METERS_PER_UNIT / 2);
      const center = object.localToWorld(bounds.getCenter(new Vector3())).multiplyScalar(METERS_PER_UNIT);
      const q = object.getWorldQuaternion(new Quaternion());
      this.physics.addStaticBox(physicsVector(half), physicsVector(center), new PhysicsQuaternion(q.x, q.y, q.z, q.w));
      this.obstacles.push(object);
    }
    if (!candidates.some(object => object.userData.drivingGround)) {
      throw new Error('The scene needs a ground mesh with user data collider: "box" and drivingGround: true');
    }
  }

  tick(delta: number) {
    this.exitBlockedTime = Math.max(0, this.exitBlockedTime - delta);
    let reset = this.input.consumeReset() && this.controlsEnabled;
    for (const car of this.cars) {
      if (car.physics.body.position.y < -30) car.physics.reset();
    }
    if (reset && this.driving) this.physics.reset();
    this.nearby = this.findNearby();
    if (!this.driving && (reset || this.player.body.position.y < -30)) {
      const home = this.onFootSpawn?.();
      let spawn = home ? new Vec3(home.x * METERS_PER_UNIT, home.y * METERS_PER_UNIT, home.z * METERS_PER_UNIT) : this.player.findExit(this.physics.body);
      if (!spawn) { this.physics.reset(); spawn = this.player.findExit(this.physics.body); }
      if (spawn) this.player.place(spawn);
      reset = true;
    }
    const interact = this.input.consumeInteract() && this.controlsEnabled;
    const handled = interact && !this.driving && this.onInteract?.();
    // Interactions can disable controls synchronously; never also enter a car or reset its camera.
    if (interact && !handled && this.controlsEnabled) {
      if (this.driving) {
        const exit = this.player.findExit(this.physics.body);
        if (exit) {
          this.driving = false;
          this.player.place(exit);
          this.player.setSeated(false);
        } else this.exitBlockedTime = 3;
      } else if (this.nearby) {
        this.selected = this.nearby;
        this.driving = true;
        this.player.setSeated(true);
      }
      this.input.clear();
      this.followCamera.setOnFoot(!this.driving);
      reset = true;
    }
    const input = this.controlsEnabled ? this.input.read() : { throttle: 0, steering: 0, brake: true };
    if (this.walkTargets.length && !this.driving && this.controlsEnabled) {
      if (input.throttle || input.steering || input.brake) this.walkTargets = [];
      else {
        const target = this.walkTargets[0], position = this.player.mesh.position;
        const direction = target.clone().sub(position); direction.y = 0;
        if (direction.length() < 2.8) this.walkTargets.shift();
        else {
          direction.normalize(); const forward = this.camera.getWorldDirection(new Vector3()); forward.y = 0; forward.normalize();
          input.throttle = direction.dot(forward); input.steering = -direction.dot(new Vector3(-forward.z, 0, forward.x));
        }
        this.walkStall = position.distanceTo(this.lastWalkPosition) < .01 ? this.walkStall + delta : 0;
        this.lastWalkPosition.copy(position); if (this.walkStall > 3) this.walkTargets = [];
      }
    }
    if (this.input.consumeJump() && !this.driving && this.controlsEnabled) this.player.requestJump();
    this.accumulator += Math.min(Math.max(delta, 0), 0.1);
    while (this.accumulator + 1e-9 >= this.physics.fixedStep) {
      for (const car of this.cars) {
        if (car !== this.scriptedCar) car.physics.applyInput(this.driving && car === this.selected ? input : { throttle: 0, steering: 0, brake: true });
      }
      if (!this.driving) this.player.step(this.physics.fixedStep, input, this.camera);
      this.physics.world.step(this.physics.fixedStep);
      this.accumulator -= this.physics.fixedStep;
    }
    this.player.sync(delta);
    this.syncVisuals();
    if (!this.presentation) this.updateCamera(delta, reset);
    this.updatePrompt();
  }

  private findNearby(): CarInstance | undefined {
    if (this.driving) return undefined;
    return this.cars.filter(car => car !== this.scriptedCar && this.player.canEnter(car.physics.body))
      .sort((a, b) => this.player.body.position.distanceSquared(a.physics.body.position)
        - this.player.body.position.distanceSquared(b.physics.body.position))[0];
  }

  private updatePrompt() {
    this.nearby = this.findNearby();
    this.prompt.hidden = !this.nearby || !this.controlsEnabled;
    if (!this.controlsEnabled) return;
    if (!this.nearby) return;
    this.camera.updateMatrixWorld(true);
    const body = this.nearby.physics.body;
    body.updateAABB();
    const anchor = new Vector3(body.position.x, body.aabb.upperBound.y + 0.7, body.position.z).multiplyScalar(1 / METERS_PER_UNIT);
    anchor.project(this.camera);
    this.prompt.hidden = anchor.z < -1 || anchor.z > 1 || Math.abs(anchor.x) > 1 || Math.abs(anchor.y) > 1;
    if (this.prompt.hidden) return;
    this.prompt.textContent = `[ E ]  Drive ${this.nearby.car.name} · ${this.nearby.physics.tuning.horsepower} hp`;
    const bounds = this.canvas.getBoundingClientRect();
    this.prompt.style.left = (bounds.left + (anchor.x + 1) * bounds.width / 2) + 'px';
    this.prompt.style.top = (bounds.top + (1 - anchor.y) * bounds.height / 2) + 'px';
  }

  private syncVisuals() {
    this.cars.forEach(car => car.sync());
    this.scene.updateMatrixWorld(true);
  }

  private updateCamera(delta: number, snap = false) {
    for (const car of this.cars) {
      const index = this.obstacles.indexOf(car.car);
      const include = !this.driving || car !== this.selected;
      if (include && index < 0) this.obstacles.push(car.car);
      if (!include && index >= 0) this.obstacles.splice(index, 1);
    }
    if (!this.driving) {
      this.followCamera.update(delta, this.player.mesh.position, this.player.mesh.quaternion, snap);
      return;
    }
    const body = this.physics.body;
    const center = new Vector3(body.position.x, body.position.y, body.position.z).multiplyScalar(1 / METERS_PER_UNIT);
    this.followCamera.update(delta, center, this.car.quaternion, snap);
  }

  dispose() {
    this.setScriptedCar();
    this.input.dispose();
    this.followCamera.dispose();
    
    this.prompt.remove();
    this.player.dispose();
    this.cars.forEach(car => car.dispose());
  }
}
