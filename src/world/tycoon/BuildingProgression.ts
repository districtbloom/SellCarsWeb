// SellCarsIntegrationOpeningComposer.desired + ApplyOpeningStations, ported to TS.
import type { TycoonState, Vec } from './types.js';
import { has } from './TycoonModel.js';
import { removedDisplayPart } from './PurchaseCategories.js';
export type Frame = [number, number, number, number, number, number, number, number, number, number, number, number];
export interface PartAttributes {
  FJ_First: number; FJ_Finish: number; FJ_Mid: number; FJ_Retire: number; FJ_MoveAt: number;
  FJ_Move: Vec; FJ_CF: Frame; FJ_Size: Vec; FJ_Color: Vec; FJ_Material: string;
  FJ_Transparency: number; FJ_Collide: boolean; FJ_Kind: string; FJ_Path?: string; FJ_Department?: string;
  FJ_PB_CFrame?: Frame; FJ_PB_Size?: Vec; FJ_PB_Transparency?: number; FJ_CIRC02_BirthCF?: Frame;
  FJ_StagePalette?: string; FJ_ArtFirst?: number; FJ_ArtColor?: Vec; FJ_ArtMaterial?: string;
  [key: string]: unknown;
}
export interface ImportedPart {
  id: number; path: string; shape: string; cf: Frame; size: Vec; color: Vec;
  material: string; transparency: number; collide: boolean; attributes: PartAttributes;
  labels?: { text: string; color: Vec; background: Vec; backgroundTransparency: number; face: string; size: number; position: number[]; dimensions: number[] }[];
  mesh?: { type: string; scale: Vec; offset: Vec; meshId: string; textureId: string };
}
export interface PartPose { visible: boolean; cf: Frame; size: Vec; color: Vec; material: string; transparency: number; collide: boolean }
const departments: Record<string, { second: number; shell: number; pro: number; z: number }> = {
  Wash: { shell: 72, second: 124, pro: 175, z: 144 }, Mechanical: { shell: 78, second: 126, pro: 157, z: 199 },
  Body_Restoration: { shell: 84, second: 129, pro: 161, z: 263 }, Tune_Performance: { shell: 90, second: 131, pro: 165, z: 331 },
  Paint_Exterior: { shell: 96, second: 134, pro: 170, z: 331 }, Detail_QC: { shell: 102, second: 136, pro: 177, z: 263 },
  Photo_Listing: { shell: 106, second: 138, pro: 180, z: 199 },
};
export const order = (n: number) => n === 233 ? 229 : n >= 229 && n < 233 ? n + 1 : n;
const rgb = (r: number, g: number, b: number): Vec => [r / 255, g / 255, b / 255];
function clip(p: PartPose, axis: 0 | 1 | 2, max: number) {
  const c = p.cf[axis], h = p.size[axis] / 2;
  if (c - h >= max) { p.visible = false; return; }
  if (c + h <= max) return;
  const size = Math.max(.04, max - (c - h)); p.cf[axis] += (size - p.size[axis]) / 2; p.size[axis] = size;
}
export function openingStep(s: TycoonState): number {
  return has(s, 'display') ? 22 : has(s, 'salesrep') ? 21 : has(s, 'carbuyer') ? 18 :
    has(s, 'power') || has(s, 'finish') || has(s, 'restoration') ? 16 : has(s, 'tools') ? 3 : has(s, 'intake') ? 2 : has(s, 'lot') ? 1 : 0;
}
export function openingAllowed(part: ImportedPart, s: TycoonState): boolean {
  const f = part.attributes.FJ_First;
  if (f === 3) return has(s, 'tools');
  if (f >= 7 && f <= 12) return has(s, ['restoration', 'finish', 'wheeltools', 'fluidkit', 'finishtrolley', 'partsshelves'][f - 7]);
  if (f === 4 || f === 14) return has(s, 'servicefloor');
  if (f === 5) return has(s, 'sales'); if (f === 6) return has(s, 'salesdesk');
  if (f === 13) return has(s, 'shade'); if (f === 15) return has(s, 'air'); if (f === 16) return has(s, 'power');
  return true;
}
export function partPose(part: ImportedPart, n: number, opening?: TycoonState): PartPose {
  const r = part.attributes, path = r.FJ_Path ?? part.path;
  const p: PartPose = { visible: n >= r.FJ_First && n < r.FJ_Retire,
    cf: [...r.FJ_CF], size: [...r.FJ_Size], color: [...r.FJ_Color], material: r.FJ_Material,
    transparency: r.FJ_Transparency, collide: r.FJ_Collide };
  if (n >= r.FJ_MoveAt) { p.cf[0] += r.FJ_Move[0]; p.cf[1] += r.FJ_Move[1]; p.cf[2] += r.FJ_Move[2]; }
  if (n < order(233)) {
    if (r.FJ_PB_CFrame) p.cf = [...r.FJ_PB_CFrame]; if (r.FJ_PB_Size) p.size = [...r.FJ_PB_Size];
    if (r.FJ_PB_Transparency === 1) p.visible = false;
  }
  const d = r.FJ_Department ? departments[r.FJ_Department] : undefined;
  if (r.FJ_Kind === 'parcelSoil' && n < 65) { p.color = rgb(151, 125, 91); p.material = 'Ground'; }
  else if (r.FJ_Kind === 'productionShell' && d) {
    if (n < order(d.second)) clip(p, 2, d.z);
    if (n < order(d.shell)) {
      const bottom = p.cf[1] - p.size[1] / 2;
      if (p.size[1] > 3) { p.size[1] *= .7; p.cf[1] = bottom + p.size[1] / 2; } else if (p.cf[1] > 10) p.cf[1] -= 4;
      p.material = 'CorrodedMetal'; p.color = rgb(121, 108, 87);
    }
  } else if (r.FJ_Kind === 'hq' && n < order(235)) {
    if (['SecondToTurn', 'TurnToCrown', 'UpperReturnLanding', 'Floor3'].some(s => path.includes(s))) p.visible = false;
    else clip(p, 1, 29.1);
  } else if (r.FJ_Kind === 'wing' && n < order(192)) {
    const front = p.cf[2] - p.size[2] / 2;
    if (p.cf[2] + p.size[2] / 2 <= 461) p.visible = false;
    else if (front < 461) { const depth = p.cf[2] + p.size[2] / 2 - 461; p.cf[2] += (p.size[2] - depth) / 2; p.size[2] = depth; }
    if (n < (path.includes('Parts_Logistics') ? 112 : 115)) {
      p.cf[1] = 1.63 + (p.cf[1] - 1.63) * .63; p.size[1] *= .63; p.material = 'CorrodedMetal'; p.color = rgb(116, 108, 92);
    }
  } else if (r.FJ_Kind === 'owner') { if (n < 62) clip(p, 0, 3193); clip(p, 2, n < 120 ? 66 : n < 183 ? 94 : 999); }
  else if (r.FJ_Kind === 'receiving' && n < 197) {
    if (n < 141 && p.cf[2] < 69) p.visible = false;
    if (p.size[1] > 8) { const bottom = p.cf[1] - p.size[1] / 2; p.size[1] = Math.min(p.size[1], n < 141 ? 10 : 15); p.cf[1] = bottom + p.size[1] / 2; }
    else if (p.cf[1] > 12) p.cf[1] += n < 141 ? -9 : -4;
  }
  if (n < r.FJ_Finish && r.FJ_Finish > r.FJ_First) {
    if (['Wood', 'WoodPlanks', 'Limestone', 'Marble'].includes(r.FJ_Material)) { p.material = 'Concrete'; p.color = rgb(141, 139, 127); }
    else if (['Metal', 'DiamondPlate'].includes(r.FJ_Material)) {
      const target = rgb(101, 110, 109), t = n >= r.FJ_Mid && r.FJ_Mid > 0 ? .12 : .3;
      p.color = r.FJ_Color.map((v, i) => v + (target[i] - v) * t) as Vec;
    }
  }
  if (r.FJ_Kind === 'productionShell' && d && n >= 123 && n < order(d.pro)) p.color = rgb(66, 79, 85);
  if (r.FJ_StagePalette) for (const stage of JSON.parse(r.FJ_StagePalette) as { step: number; color: Vec; material: string }[]) {
    if (n >= stage.step) { p.color = rgb(...stage.color); p.material = stage.material; }
  }
  if (r.FJ_ArtFirst !== undefined && n >= r.FJ_ArtFirst) { p.color = r.FJ_ArtColor ? [...r.FJ_ArtColor] : p.color; p.material = r.FJ_ArtMaterial ?? p.material; }
  if (n >= 1 && n <= 24 && r.FJ_CIRC02_BirthCF) p.cf = [...r.FJ_CIRC02_BirthCF];
  if (opening) {
    if (!openingAllowed(part, opening) || /SalesCar|First_Sale_Display/.test(part.path)) p.visible = false;
    if (r.FJ_First === 20 && Math.abs(r.FJ_CF[0] - 3090) < .1 && part.path.includes('P020_Rough_Boundary')) { p.cf = [...r.FJ_CF]; p.cf[0] += 16; }
  }
  if (removedDisplayPart(path)) p.visible = false;
  // The source stamps these ceiling fixtures with the parking purchase (22/43/...)
  // although their owner-workshop roof is not built until 62 and expands at 120/183.
  if (/Personal_Fleet_Setting_\d+[/.](?:FixtureSuspension|ShieldedPersonalLight)$/.test(path)) {
    const roofStep = p.cf[2] <= 66 ? 62 : p.cf[2] <= 94 ? 120 : 183;
    if (n < roofStep) p.visible = false;
  }
  return p;
}
