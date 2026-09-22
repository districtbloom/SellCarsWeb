import { Vector3 } from 'three';
import type { PerspectiveCamera } from 'three';
import './objective-arrow.css';

export interface UIObjective { element: HTMLElement; label: string }
/** One pointer switches between the real world objective and the next actionable UI control. */
export class ObjectiveArrow {
  private root = document.createElement('div');
  private arrow = document.createElement('div');
  private label = document.createElement('span');
  constructor() {
    this.root.className = 'objective-pointer'; this.root.hidden = true;
    this.arrow.className = 'objective-pointer-arrow'; this.arrow.textContent = '➜'; this.arrow.setAttribute('aria-hidden', 'true');
    this.root.setAttribute('role', 'status'); this.root.append(this.arrow, this.label); document.body.append(this.root);
  }
  hide() { this.root.hidden = true; }
  pointAtElement(target: UIObjective) {
    const rect = target.element.getBoundingClientRect();
    if (target.element.hidden || !rect.width || !rect.height) { this.hide(); return; }
    const below = rect.top < 100; this.root.classList.toggle('below-target', below);
    this.show(rect.left + rect.width / 2, below ? rect.bottom + 30 : rect.top - 26, below ? -Math.PI / 2 : Math.PI / 2, target.label);
  }
  pointAtWorld(point: Vector3, camera: PerspectiveCamera, label: string) {
    this.root.classList.remove('below-target'); camera.updateMatrixWorld(true);
    const p = point.clone().project(camera), behind = point.clone().applyMatrix4(camera.matrixWorldInverse).z > 0;
    let x = (p.x + 1) * innerWidth / 2, y = (1 - p.y) * innerHeight / 2, angle = Math.PI / 2;
    if (behind || x < 65 || x > innerWidth - 65 || y < 100 || y > innerHeight - 100) {
      let dx = x - innerWidth / 2, dy = y - innerHeight / 2;
      if (behind) { dx = -dx; dy = -dy; }
      if (Math.hypot(dx, dy) < 1) dx = 1;
      const scale = Math.min((innerWidth / 2 - 65) / Math.max(1, Math.abs(dx)), (innerHeight / 2 - 100) / Math.max(1, Math.abs(dy)));
      x = innerWidth / 2 + dx * scale; y = innerHeight / 2 + dy * scale; angle = Math.atan2(dy, dx);
    } else y -= 38;
    this.show(x, y, angle, label);
  }
  private show(x: number, y: number, angle: number, label: string) {
    this.root.hidden = false; this.root.style.left = Math.max(48, Math.min(innerWidth - 48, x)) + 'px'; this.root.style.top = Math.max(44, Math.min(innerHeight - 70, y)) + 'px';
    this.arrow.style.transform = `rotate(${angle}rad)`; this.label.textContent = label;
  }
  dispose() { this.root.remove(); }
}
