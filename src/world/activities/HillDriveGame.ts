import { HillDriveModel, HILL_CONFIG } from './HillDriveModel.js';
import './activities.css';

export class HillDriveGame {
  active = false;
  private model?: HillDriveModel;
  private root = document.createElement('div');
  private canvas = document.createElement('canvas');
  private stats = document.createElement('span');
  private status = document.createElement('span');
  private finish = document.createElement('button');
  private left = false;
  private right = false;
  private settled = false;
  private previousFocus?: HTMLElement;
  constructor(private lock: (active: boolean) => void, private reward: (distance: number) => boolean, private cancel: () => void) {
    this.root.className = 'hill-overlay'; this.root.hidden = true; this.root.setAttribute('role', 'dialog'); this.root.setAttribute('aria-modal', 'true'); this.root.setAttribute('aria-label', 'Hill Drive laptop');
    const laptop = document.createElement('div'); laptop.className = 'hill-laptop';
    const header = document.createElement('div'); header.className = 'hill-header';
    const title = document.createElement('strong'); title.textContent = 'HILL DRIVE / PARTS RUN'; this.stats.setAttribute('aria-live', 'off');
    const close = document.createElement('button'); close.textContent = '×'; close.setAttribute('aria-label', 'Close minigame'); close.onclick = () => this.close();
    header.append(title, this.stats, close); this.canvas.width = 960; this.canvas.height = 450; this.canvas.tabIndex = -1;
    const footer = document.createElement('div'); footer.className = 'hill-footer';
    this.status.textContent = 'Hold LMB: forward · RMB: reverse / air rotation · Clocks: +5s · Esc: forfeit';
    const controls = document.createElement('div'); controls.className = 'hill-touch';
    for (const [text, forward] of [['◀ Reverse', false], ['Forward ▶', true]] as const) {
      const b = document.createElement('button'); b.textContent = text;
      b.onpointerdown = e => { e.preventDefault(); e.stopPropagation(); b.setPointerCapture(e.pointerId); if (forward) this.left = true; else this.right = true; };
      b.onpointerup = b.onpointercancel = () => { if (forward) this.left = false; else this.right = false; }; controls.append(b);
    }
    this.finish.textContent = 'Start driving'; this.finish.onclick = () => this.start();
    footer.append(this.status, controls, this.finish); laptop.append(header, this.canvas, footer); this.root.append(laptop); document.body.append(this.root);
    this.canvas.onpointerdown = e => { if (!this.active || !this.model || this.model.ended) return; e.preventDefault(); this.canvas.setPointerCapture(e.pointerId); if (e.button === 0) this.left = true; if (e.button === 2) this.right = true; };
    this.root.oncontextmenu = e => e.preventDefault();
    window.addEventListener('pointerup', this.up); window.addEventListener('pointercancel', this.clear);
    window.addEventListener('blur', this.clear); window.addEventListener('keydown', this.key, true);
  }
  begin() {
    if (this.active) return; this.active = true; this.model = undefined; this.settled = false;
    this.previousFocus = document.activeElement as HTMLElement; this.lock(true); this.root.hidden = false;
    if (document.pointerLockElement) document.exitPointerLock();
    this.finish.hidden = false; this.finish.textContent = 'Start driving'; this.finish.onclick = () => this.start();
    this.status.textContent = 'Hold LMB: forward · RMB: reverse / air rotation · Clocks: +5s · Esc: forfeit'; this.stats.textContent = '30s · Distance × $2';
    this.draw(new HillDriveModel(() => .5)); this.finish.focus();
  }
  private start() { this.model = new HillDriveModel(); this.settled = false; this.clear(); this.finish.hidden = true; this.canvas.focus(); }
  private up = (e: PointerEvent) => { if (e.button === 0) this.left = false; if (e.button === 2) this.right = false; };
  private clear = () => { this.left = false; this.right = false; };
  private key = (e: KeyboardEvent) => {
    if (!this.active || e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.code === 'Escape') { e.preventDefault(); e.stopImmediatePropagation(); this.close(); return; }
    if (e.code === 'Tab') { const buttons = Array.from(this.root.querySelectorAll('button')).filter(b => !b.hidden), index = buttons.indexOf(document.activeElement as HTMLButtonElement); e.preventDefault(); buttons[(index + (e.shiftKey ? buttons.length - 1 : 1)) % buttons.length].focus(); return; }
    if (e.code !== 'Enter' && e.code !== 'Space') { e.preventDefault(); e.stopImmediatePropagation(); }
  };
  tick(dt: number) {
    if (!this.active || !this.model || document.hidden) return;
    const m = this.model; m.tick(dt, Number(this.left) - Number(this.right)); this.draw(m);
    this.stats.textContent = `${Math.ceil(m.remaining)}s  |  ${Math.floor(m.distance)}m  |  $${m.reward}`;
    if (m.ended && !this.settled) {
      this.settled = true; this.clear(); const paid = this.reward(Math.floor(m.distance));
      this.status.textContent = `${m.ended === 'crashed' ? 'Flipped over!' : 'Time is up!'} ${Math.floor(m.distance)}m × $${HILL_CONFIG.rewardMultiplier} = $${m.reward}${paid ? ' earned' : ' · could not save reward'}`;
      this.finish.hidden = false; this.finish.textContent = 'Back to dealership'; this.finish.onclick = () => this.close(); this.finish.focus();
    }
  }
  private draw(m: HillDriveModel) {
    const c = this.canvas.getContext('2d')!, scale = 23, cameraX = m.x - 11, cameraY = m.y + 5;
    const x = (v: number) => (v - cameraX) * scale, y = (v: number) => 170 + (cameraY - v) * scale;
    c.fillStyle = '#b4dee1'; c.fillRect(0, 0, 960, 450);
    c.fillStyle = '#ebf4dc'; c.fillRect(735, 45, 55, 55);
    c.fillStyle = '#89b8ae'; c.beginPath(); c.moveTo(0, 320); for (let i = 0; i <= 960; i += 40) c.lineTo(i, 230 + Math.sin((i + m.x * 4) / 120) * 38); c.lineTo(960, 450); c.lineTo(0, 450); c.fill();
    c.fillStyle = '#735d46'; c.strokeStyle = '#57934e'; c.lineWidth = 9; c.beginPath();
    for (let pixel = -5; pixel <= 965; pixel += 5) { const h = y(m.height(cameraX + pixel / scale)); if (pixel === -5) c.moveTo(pixel, h); else c.lineTo(pixel, h); }
    c.stroke(); c.lineTo(965, 450); c.lineTo(-5, 450); c.fill();
    for (const p of m.pickups) if (!p.collected && x(p.x) > -30 && x(p.x) < 990) {
      const X = x(p.x), Y = y(p.y); c.fillStyle = '#ffe192'; c.fillRect(X - 15, Y - 15, 30, 30); c.strokeStyle = '#735d46'; c.lineWidth = 3; c.strokeRect(X - 15, Y - 15, 30, 30);
      c.beginPath(); c.moveTo(X, Y - 9); c.lineTo(X, Y); c.lineTo(X + 7, Y); c.stroke(); c.fillStyle = '#263f39'; c.font = 'bold 15px monospace'; c.fillText('+5s', X - 14, Y - 22);
    }
    // Original block car built entirely from canvas primitives, with independently spinning wheels.
    c.save(); c.translate(x(m.x), y(m.y)); c.rotate(-m.angle);
    c.fillStyle = '#ec954b'; c.fillRect(-39, -12, 78, 22); c.fillStyle = '#b75932'; c.fillRect(-25, -30, 42, 21);
    c.fillStyle = '#d4f3ed'; c.fillRect(-19, -26, 13, 14); c.fillRect(-1, -26, 13, 14); c.fillStyle = '#fff2bc'; c.fillRect(32, -9, 8, 8);
    for (const side of [-1, 1]) { c.save(); c.translate(side * 1.3 * scale, .45 * scale); c.rotate(-m.x * 2); c.fillStyle = '#233139'; c.beginPath(); c.arc(0, 0, .48 * scale, 0, Math.PI * 2); c.fill(); c.fillStyle = '#c6d4cb'; c.fillRect(-6, -3, 12, 6); c.fillRect(-3, -6, 6, 12); c.restore(); }
    c.restore();
  }
  close() { if (!this.active) return; this.active = false; this.clear(); if (!this.settled) this.cancel(); this.model = undefined; this.root.hidden = true; this.lock(false); this.previousFocus?.focus(); }
  dispose() { this.close(); window.removeEventListener('pointerup', this.up); window.removeEventListener('pointercancel', this.clear); window.removeEventListener('blur', this.clear); window.removeEventListener('keydown', this.key, true); this.root.remove(); }
}
