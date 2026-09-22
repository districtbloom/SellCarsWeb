import { Vector3 } from 'three';
import type { Scene } from 'three';
export interface MapRoad { x: number; z: number; width: number; depth: number; vertical: boolean }
export interface MapPOI { id: string; label: string; x: number; z: number; color: string }
export interface MapLot { x: number; z: number; width: number; depth: number; zone: string }
export interface RoadNode { x: number; z: number; neighbors: number[] }

/** Reads current scene metadata, including additions/removals, independently of town generation. */
export class RuntimeMap {
  roads: MapRoad[] = [];
  lots: MapLot[] = [];
  pois: MapPOI[] = [];
  constructor(private scene: Scene) { this.refresh(); }
  refresh() {
    this.roads = []; this.lots = []; this.pois = [];
    this.scene.updateMatrixWorld(true);
    this.scene.traverse(object => {
      const road = object.userData.mapRoad as MapRoad | undefined;
      if (road) this.roads.push({ ...road });
      const lot = object.userData.mapLot as MapLot | undefined;
      if (lot) this.lots.push({ ...lot });
      const poi = object.userData.mapPOI as { label: string; color?: string } | undefined;
      if (poi) {
        let visible = true; for (let p = object; p; p = p.parent!) if (!p.visible) visible = false;
        if (visible) { const pos = object.getWorldPosition(new Vector3()); this.pois.push({ id: object.uuid, label: poi.label, x: pos.x, z: pos.z, color: poi.color ?? '#a6e9bf' }); }
      }
    });
  }
}

/** Centerline graph: edges only connect consecutive intersections on an actual road. */
export function roadGraph(roads: MapRoad[]): RoadNode[] {
  const nodes: RoadNode[] = [];
  for (const a of roads.filter(r => r.vertical)) for (const b of roads.filter(r => !r.vertical)) {
    if (Math.abs(a.x - b.x) > b.width / 2 || Math.abs(b.z - a.z) > a.depth / 2) continue;
    if (!nodes.some(n => n.x === a.x && n.z === b.z)) nodes.push({ x: a.x, z: b.z, neighbors: [] });
  }
  for (const r of roads) {
    const ids = nodes.map((_, i) => i).filter(i => r.vertical ? nodes[i].x === r.x && Math.abs(nodes[i].z - r.z) <= r.depth / 2 : nodes[i].z === r.z && Math.abs(nodes[i].x - r.x) <= r.width / 2);
    ids.sort((a, b) => r.vertical ? nodes[a].z - nodes[b].z : nodes[a].x - nodes[b].x);
    for (let i = 1; i < ids.length; i++) { const a = ids[i - 1], b = ids[i]; if (!nodes[a].neighbors.includes(b)) { nodes[a].neighbors.push(b); nodes[b].neighbors.push(a); } }
  }
  return nodes;
}
export function raceRoute(nodes: RoadNode[], random = Math.random, length = 9): { x: number; z: number }[] {
  // Self-avoiding graph walks cannot cross or retrace a city block. Retry dead ends.
  for (let attempt = 0; attempt < 80 && nodes.length; attempt++) {
    const route = [Math.floor(random() * nodes.length)];
    while (route.length < length) {
      const current = nodes[route[route.length - 1]];
      const choices = current.neighbors.filter(i => !route.includes(i));
      if (!choices.length) break;
      route.push(choices[Math.floor(random() * choices.length)]);
    }
    if (route.length === length) {
      const points: { x: number; z: number }[] = [];
      route.forEach((id, i) => { const a = nodes[id]; if (i) { const b = nodes[route[i - 1]]; points.push({ x: (a.x + b.x) / 2, z: (a.z + b.z) / 2 }); } points.push({ x: a.x, z: a.z }); });
      return points;
    }
  }
  return []; // Never fall back to an unvalidated straight line through buildings.
}
