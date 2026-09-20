import type { PerspectiveCamera } from 'three';
import { Vec3 } from 'cannon-es';
import { METERS_PER_UNIT } from '../driving/CarRig.js';
import type { PlayerController } from '../driving/PlayerController.js';
import type { TycoonState } from './types.js';
import { PARTS_POSITION, PARTS_SECONDS } from './PartsStation.js';
import { worldPoint } from './TycoonCoordinates.js';
import { lockCameraPose, restoreCameraPose } from '../driving/CameraPoseLock.js';

/** A world interaction, with no modal or progress card. Payout is gated by active typing. */
export class PartsTyping {
  active = false;
  private releaseCamera?: () => void;
  constructor(private state: TycoonState, private player: PlayerController, private camera: PerspectiveCamera, private lock: (active: boolean) => void) {
    window.addEventListener('keydown', this.key, true);
  }
  begin() {
    if (this.active || this.state.parts?.remaining === undefined) return;
    this.releaseCamera = lockCameraPose(this.camera);
    this.active = true; this.state.parts.manual = true; this.lock(true); this.player.body.velocity.setZero();
    const standing = worldPoint([PARTS_POSITION[0], PARTS_POSITION[1] + 1.12], 5.5).multiplyScalar(METERS_PER_UNIT);
    this.player.place(new Vec3(standing.x, standing.y, standing.z));
    const target = worldPoint(PARTS_POSITION, 5), offset = this.player.mesh.position.clone().sub(target);
    this.player.mesh.rotation.y = Math.atan2(offset.x, offset.z);
    this.player.typingTime = PARTS_SECONDS - this.state.parts.remaining;
    if (document.pointerLockElement) document.exitPointerLock();
  }
  tick(_dt: number) {
    if (!this.active) return;
    restoreCameraPose(this.camera);
    if (this.state.parts?.remaining === undefined || this.state.parts.manual === false) { this.close(); return; }
    this.player.typingTime = PARTS_SECONDS - this.state.parts.remaining;
  }
  private key = (e: KeyboardEvent) => {
    if (!this.active) return;
    if (['KeyP', 'Enter', 'Escape'].includes(e.code)) { e.preventDefault(); e.stopImmediatePropagation(); }
    if (e.code === 'Escape') this.close();
  };
  close() { this.active = false; this.player.typingTime = undefined; this.lock(false); this.releaseCamera?.(); this.releaseCamera = undefined; }
  dispose() { if (this.active) this.close(); window.removeEventListener('keydown', this.key, true); }
}
