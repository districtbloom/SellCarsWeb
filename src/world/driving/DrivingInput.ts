import type { DriverInput } from './VehiclePhysics.js';

export class DrivingInput {
  private keys = new Set<string>();
  private resetRequested = false;
  private interactRequested = false;
  private jumpRequested = false;
  private readonly allowed = new Set(['KeyW', 'KeyA', 'KeyS', 'KeyD', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'KeyR', 'KeyE', 'ShiftLeft', 'ShiftRight']);

  constructor() {
    window.addEventListener('keydown', this.keyDown);
    window.addEventListener('keyup', this.keyUp);
    window.addEventListener('blur', this.clear);
    document.addEventListener('visibilitychange', this.clear);
    document.addEventListener('pointerlockchange', this.clear);
  }

  private keyDown = (event: KeyboardEvent) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    const target = event.target;
    if (target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName))) return;
    if (!this.allowed.has(event.code)) return;
    event.preventDefault();
    this.keys.add(event.code);
    if (event.code === 'KeyR' && !event.repeat) this.resetRequested = true;
    if (event.code === 'KeyE' && !event.repeat) this.interactRequested = true;
    if (event.code === 'Space' && !event.repeat) this.jumpRequested = true;
  };
  private keyUp = (event: KeyboardEvent) => { this.keys.delete(event.code); };
  clear = () => { this.keys.clear(); this.resetRequested = false; this.interactRequested = false; this.jumpRequested = false; };

  consumeInteract() { const value = this.interactRequested; this.interactRequested = false; return value; }
  consumeJump() { const value = this.jumpRequested; this.jumpRequested = false; return value; }

  read(): DriverInput {
    return {
      throttle: Number(this.keys.has('KeyW') || this.keys.has('ArrowUp')) - Number(this.keys.has('KeyS') || this.keys.has('ArrowDown')),
      steering: Number(this.keys.has('KeyA') || this.keys.has('ArrowLeft')) - Number(this.keys.has('KeyD') || this.keys.has('ArrowRight')),
      brake: this.keys.has('Space'),
      sprint: this.keys.has('ShiftLeft') || this.keys.has('ShiftRight'),
    };
  }

  consumeReset(): boolean {
    const reset = this.resetRequested;
    this.resetRequested = false;
    return reset;
  }

  dispose() {
    window.removeEventListener('keydown', this.keyDown);
    window.removeEventListener('keyup', this.keyUp);
    window.removeEventListener('blur', this.clear);
    document.removeEventListener('visibilitychange', this.clear);
    document.removeEventListener('pointerlockchange', this.clear);
  }
}
