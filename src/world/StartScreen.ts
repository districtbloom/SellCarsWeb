import { Quaternion, Vector3 } from 'three';
import type { PerspectiveCamera } from 'three';
import './start-screen.css';

/** Keeps the panorama camera separate from gameplay until the player chooses Start. */
export class StartScreen {
  active = true;
  private root = document.createElement('main');
  private button = document.createElement('button');
  private camera?: PerspectiveCamera;
  private position = new Vector3();
  private rotation = new Quaternion();
  private fov = 60;
  private center = new Vector3();
  private angle = Math.PI * 1.15;
  private ready = false;
  private target = new Vector3();

  constructor(private onStart: () => void) {
    document.body.classList.add('on-title-screen');
    this.root.className = 'start-screen'; this.root.setAttribute('aria-label', 'Sell Cars title screen');
    const content = document.createElement('div'); content.className = 'start-screen-content';
    const title = document.createElement('h1'); title.textContent = 'SELL CARS';
    this.button.className = 'start-screen-button'; this.button.textContent = 'LOADING…'; this.button.disabled = true;
    this.button.onclick = this.begin;
    content.append(title, this.button); this.root.append(content); document.body.append(this.root);
    // Capture before gameplay listeners: title-screen keys cannot move, buy, or open menus.
    window.addEventListener('keydown', this.key, true);
    window.addEventListener('keyup', this.blockKey, true);
  }

  showPanorama(camera: PerspectiveCamera, center: Vector3) {
    this.camera = camera; this.position.copy(camera.position); this.rotation.copy(camera.quaternion); this.fov = camera.fov;
    this.center.copy(center); camera.position.copy(center); camera.fov = 65; camera.updateProjectionMatrix();
    this.tick(0); this.ready = true; this.button.disabled = false; this.button.textContent = 'START'; this.button.focus();
  }

  tick(dt: number) {
    if (!this.active || !this.camera) return;
    if (!document.hidden) this.angle = (this.angle + Math.max(0, Math.min(.1, dt)) * .055) % (Math.PI * 2);
    // Fixed position in the environment's center, turning through a full 360-degree panorama.
    this.camera.position.copy(this.center);
    this.target.set(this.center.x + Math.sin(this.angle) * 350, this.center.y - 65, this.center.z + Math.cos(this.angle) * 350);
    this.camera.lookAt(this.target);
  }

  private key = (event: KeyboardEvent) => {
    if (!this.active) return;
    event.stopImmediatePropagation();
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    if (['Enter', 'Space'].includes(event.code)) { event.preventDefault(); if (!event.repeat) this.begin(); }
    else if (event.code === 'Tab') { event.preventDefault(); if (this.ready) this.button.focus(); }
    else event.preventDefault();
  };
  private blockKey = (event: KeyboardEvent) => { if (this.active) event.stopImmediatePropagation(); };
  private begin = () => { if (!this.active || !this.ready) return; this.dispose(); this.onStart(); };

  dispose() {
    if (!this.active) return;
    this.active = false;
    if (this.camera) { this.camera.position.copy(this.position); this.camera.quaternion.copy(this.rotation); this.camera.fov = this.fov; this.camera.updateProjectionMatrix(); }
    window.removeEventListener('keydown', this.key, true); window.removeEventListener('keyup', this.blockKey, true);
    this.root.remove(); document.body.classList.remove('on-title-screen');
  }
}
