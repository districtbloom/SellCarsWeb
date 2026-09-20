import { MathUtils, Object3D, PerspectiveCamera, Quaternion, Raycaster, Spherical, Vector3 } from 'three';
import { cameraPoseState, consumeCameraPose, restoreCameraPose } from './CameraPoseLock.js';

export class SmartFollowCamera {
  private readonly target = new Vector3();
  private readonly ray = new Raycaster();
  private readonly orbit = new Spherical();
  private mouseIdle = Infinity;
  private orbiting = false;
  private lockError = '';
  private initialized = false;
  readonly idleDelay = 2;
  private onFoot = false;
  private inputEnabled = true;
  private resumeCenter?: Vector3;
  private readonly resumeOffset = new Vector3();
  private readonly lastCenter = new Vector3();
  setInputEnabled(enabled: boolean) { this.inputEnabled = enabled; }

  setOnFoot(value: boolean) {
    if (this.onFoot !== value) {
      this.resumeCenter = undefined; this.resumeOffset.set(0, 0, 0);
      // Entering/exiting a vehicle is an explicit camera change, even before the first resumed tick.
      if (cameraPoseState(this.camera) === 'released') consumeCameraPose(this.camera);
    }
    this.onFoot = value;
    this.orbiting = false;
    this.initialized = false;
  }

  constructor(private camera: PerspectiveCamera, private canvas: HTMLElement, private obstacles: Object3D[]) {
    canvas.addEventListener('click', this.capturePointer);
    document.addEventListener('mousemove', this.pointerMove);
    document.addEventListener('pointerlockchange', this.lockChanged);
    document.addEventListener('pointerlockerror', this.lockFailed);
    canvas.addEventListener('wheel', this.wheel, { passive: false });
    window.addEventListener('blur', this.blur);
  }

  get mode(): 'orbit' | 'follow' { return this.orbiting ? 'orbit' : 'follow'; }
  get pointerLocked(): boolean { return document.pointerLockElement === this.canvas; }
  get pointerHint(): string {
    return this.pointerLocked ? 'Mouse captured · Esc releases cursor' : this.lockError || 'Click the game to capture the mouse';
  }

  private capturePointer = async () => {
    if (this.pointerLocked || !this.inputEnabled) return;
    try {
      if (!this.canvas.requestPointerLock) throw new Error('Pointer lock unavailable');
      // Browsers require a real click. Pointer lock hides the cursor and gives
      // unlimited relative movement instead of a cursor that hits screen edges.
      await this.canvas.requestPointerLock();
    } catch {
      this.lockFailed();
    }
  };
  private lockFailed = () => { this.lockError = 'Mouse capture failed — click the game to retry'; };
  private lockChanged = () => {
    this.lockError = '';
    if (!this.pointerLocked) this.blur();
  };

  private beginOrbit() {
    if (!this.initialized) return;
    this.resumeCenter = undefined;
    if (!this.orbiting) this.orbit.setFromVector3(this.camera.position.clone().sub(this.target));
    this.orbiting = true;
    this.mouseIdle = 0;
  }

  private pointerMove = (event: MouseEvent) => {
    if (!this.pointerLocked || !this.initialized || !this.inputEnabled) return;
    const dx = event.movementX;
    const dy = event.movementY;
    if (!Number.isFinite(dx) || !Number.isFinite(dy) || (dx === 0 && dy === 0)) return;
    this.beginOrbit();
    this.orbit.theta -= dx * 0.005;
    this.orbit.phi = MathUtils.clamp(this.orbit.phi - dy * 0.005, 0.15, Math.PI / 2 - 0.05);
  };

  private blur = () => {
    this.mouseIdle = this.idleDelay;
  };
  private wheel = (event: WheelEvent) => {
    if (!this.pointerLocked || !this.initialized || !this.inputEnabled || event.ctrlKey || event.deltaY === 0) return;
    event.preventDefault();
    this.beginOrbit();
    const delta = event.deltaY * (event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? 800 : 1);
    this.orbit.radius = MathUtils.clamp(this.orbit.radius * Math.exp(MathUtils.clamp(delta * 0.001, -1, 1)), 12, 80);
  };

  update(delta: number, center: Vector3, rotation: Quaternion, snap = false) {
    const pose = cameraPoseState(this.camera);
    if (pose === 'locked') { restoreCameraPose(this.camera); return; }
    const forward = new Vector3(0, 0, -1).applyQuaternion(rotation);
    forward.y = 0;
    if (forward.lengthSq() < 0.01) forward.set(0, 0, -1);
    forward.normalize();
    const nextTarget = center.clone().add(new Vector3(0, this.onFoot ? 2 : 3, 0)).addScaledVector(forward, this.onFoot ? 0 : 5);
    if (pose === 'released') {
      restoreCameraPose(this.camera);
      const distance = Math.max(1, this.camera.position.distanceTo(this.target));
      this.target.copy(this.camera.position).addScaledVector(this.camera.getWorldDirection(new Vector3()), distance);
      this.resumeOffset.copy(this.target).sub(nextTarget);
      this.orbit.setFromVector3(this.camera.position.clone().sub(this.target));
      this.orbiting = true; this.initialized = true; this.mouseIdle = 0;
      this.resumeCenter = center.clone(); this.lastCenter.copy(center);
      consumeCameraPose(this.camera); return;
    }
    // An animation may turn or place the character. Closing it must not turn the camera.
    if (this.resumeCenter && center.distanceToSquared(this.resumeCenter) < .0004) return;
    this.resumeCenter = undefined;
    const distanceMoved = center.distanceTo(this.lastCenter); this.lastCenter.copy(center);
    this.resumeOffset.multiplyScalar(Math.exp(-Math.min(distanceMoved, 5) * .12));
    if (snap) {
      this.orbiting = false;
      this.mouseIdle = Infinity;
      this.resumeOffset.set(0, 0, 0);
    }
    this.mouseIdle += delta;
    if (!this.onFoot && this.mouseIdle >= this.idleDelay) this.orbiting = false;
    nextTarget.add(this.resumeOffset);
    if (this.onFoot && !this.orbiting) {
      this.orbit.set(18, 1.05, Math.atan2(-forward.x, -forward.z));
      this.orbiting = true;
    }
    // On foot, keep the camera attached to the player without follow or orbit lag.
    const blend = this.onFoot || snap || !this.initialized ? 1 : 1 - Math.exp(-7 * delta);
    const previousTarget = this.target.clone();
    this.target.lerp(nextTarget, blend);
    // Move the orbit with its car, preserving the player's world-space angle
    // even while the chassis turns. Keyboard driving does not restart the timer.
    if (this.orbiting) this.camera.position.add(this.target.clone().sub(previousTarget));
    const desired = this.orbiting
      ? this.target.clone().add(new Vector3().setFromSpherical(this.orbit))
      : center.clone().addScaledVector(forward, -30).add(new Vector3(0, 13, 0));
    this.camera.position.lerp(desired, blend);
    // Clip the final smoothed position, so transitions cannot pass through scenery.
    const direction = this.camera.position.clone().sub(this.target);
    this.ray.set(this.target, direction.clone().normalize());
    this.ray.far = direction.length();
    const hit = this.ray.intersectObjects(this.obstacles, true)[0];
    if (hit) this.camera.position.copy(this.target).addScaledVector(direction.normalize(), Math.max(0.2, hit.distance - 1));
    this.camera.lookAt(this.target);
    this.initialized = true;
  }

  dispose() {
    this.canvas.removeEventListener('click', this.capturePointer);
    document.removeEventListener('mousemove', this.pointerMove);
    document.removeEventListener('pointerlockchange', this.lockChanged);
    document.removeEventListener('pointerlockerror', this.lockFailed);
    this.canvas.removeEventListener('wheel', this.wheel);
    window.removeEventListener('blur', this.blur);
    if (this.pointerLocked) document.exitPointerLock();
  }
}
