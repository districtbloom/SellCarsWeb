import type { Vector3 } from 'three';
import { RuntimeMap } from './RuntimeMap.js';
import type { MapPOI } from './RuntimeMap.js';
import './activities.css';

export class Minimap {
  private root = document.createElement('section');
  private canvas = document.createElement('canvas');
  private context: CanvasRenderingContext2D;
  private clock = 0;
  route: { x: number; z: number }[] = [];
  event?: MapPOI;
  checkpoint?: MapPOI;
  constructor(readonly map: RuntimeMap, private focus: () => Vector3, private heading: () => number) {
    this.root.className = 'runtime-minimap'; this.root.setAttribute('aria-label', 'Live map of Maple County');
    const title = document.createElement('div'); title.textContent = 'MAPLE COUNTY                 N ↑';
    this.canvas.width = 480; this.canvas.height = 360; this.context = this.canvas.getContext('2d')!;
    const legend = document.createElement('small'); legend.textContent = '● You   ◆ Places   ⚑ Race';
    this.root.append(title, this.canvas, legend); document.body.append(this.root); this.tick(2);
  }
  tick(dt: number) {
    this.clock += dt; if (this.clock >= 2) { this.clock = 0; this.map.refresh(); }
    const c = this.context, p = this.focus(), scale = .29;
    const x = (v: number) => (v - p.x) * scale + 240, z = (v: number) => (v - p.z) * scale + 180;
    c.fillStyle = '#273c35'; c.fillRect(0, 0, 480, 360);
    for (const lot of this.map.lots) { c.fillStyle = lot.zone === 'park' ? '#415e40' : '#53615a'; c.fillRect(x(lot.x - lot.width / 2), z(lot.z - lot.depth / 2), lot.width * scale, lot.depth * scale); }
    for (const r of this.map.roads) { c.fillStyle = '#b1b4a6'; c.fillRect(x(r.x - r.width / 2), z(r.z - r.depth / 2), r.width * scale, r.depth * scale); }
    c.strokeStyle = '#ffd36b'; c.lineWidth = 4; c.beginPath(); this.route.forEach((v, i) => { if (!i) c.moveTo(x(v.x), z(v.z)); else c.lineTo(x(v.x), z(v.z)); }); c.stroke();
    const occupied: { x: number; y: number; width: number }[] = [];
    for (const poi of [...(this.checkpoint ? [this.checkpoint] : []), ...(this.event ? [this.event] : []), ...this.map.pois]) {
      const priority = poi === this.event || poi === this.checkpoint;
      if (!priority && (x(poi.x) < 8 || x(poi.x) > 472 || z(poi.z) < 8 || z(poi.z) > 352)) continue;
      const X = Math.max(16, Math.min(464, x(poi.x))), Z = Math.max(18, Math.min(337, z(poi.z)));
      c.fillStyle = poi.color; c.fillRect(X - 4, Z - 4, 8, 8); c.font = 'bold 18px monospace';
      const width = poi.label.length * 11, right = X + 8 + width > 475, left = right ? X - 8 - width : X + 8;
      if (!priority && occupied.some(r => Math.abs(r.y - Z) < 23 && r.x < left + width && r.x + r.width > left)) continue;
      occupied.push({ x: left, y: Z, width }); c.textAlign = right ? 'right' : 'left';
      c.strokeStyle = '#162820'; c.lineWidth = 4; c.strokeText(poi.label, X + (right ? -8 : 8), Z - 7); c.fillText(poi.label, X + (right ? -8 : 8), Z - 7);
    }
    c.save(); c.translate(240, 180); c.rotate(this.heading()); c.fillStyle = '#8cffd0'; c.strokeStyle = '#10251e'; c.lineWidth = 3;
    c.beginPath(); c.moveTo(0, -12); c.lineTo(8, 9); c.lineTo(0, 5); c.lineTo(-8, 9); c.closePath(); c.fill(); c.stroke(); c.restore();
  }
  dispose() { this.root.remove(); }
}
