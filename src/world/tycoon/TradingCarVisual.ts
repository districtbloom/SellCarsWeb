import { Box3, BoxGeometry, Color, Euler, Group, Material, Mesh, MeshBasicMaterial, MeshPhongMaterial, MeshStandardMaterial, Object3D, Vector3 } from 'three';
import { DecalGeometry } from 'three/examples/jsm/geometries/DecalGeometry.js';
import type { CarInstance } from '../driving/CarInstance.js';
import { def, job, originalLook } from './TycoonModel.js';
import { repairKind } from './RepairGame.js';
import { worldPoint } from './TycoonCoordinates.js';
import type { CarDefinition, Look, TradingCar, TycoonState } from './types.js';

// Story IDs and recurring business templates are separate from the garage prices.
// Keep ordinary commuters common, a coupe uncommon, and the roadster exclusive to Phoenix.
const models: Record<string, number> = {
  rusty: 9, Rusty: 9, hatch: 10, HondoCivixEK: 10,
  desert: 12, Bavora: 14, Gblock: 11, phoenix: 6,
};
export function tradingModelId(car: TradingCar, definition: CarDefinition): number {
  return models[car.business?.templateId ?? definition.id]
    ?? (definition.rarity.toUpperCase() === 'RARE' ? 6 : definition.rarity.toUpperCase() === 'UNCOMMON' ? 12 : 9);
}

type PaintMaterial = MeshPhongMaterial | MeshStandardMaterial;
const paintable = (material: Material): material is PaintMaterial => material instanceof MeshPhongMaterial || material instanceof MeshStandardMaterial;

/** Scripted deal cars reuse complete authored models without sharing mutable materials. */
export class TradingCarVisual {
  readonly root = new Group();
  private model?: Object3D;
  private selected?: number;
  private materials: Material[] = [];
  private paint: PaintMaterial[] = [];
  private wheels: { material: PaintMaterial; color: Color }[] = [];
  private stripes: Mesh[] = [];
  private frontLeft?: Object3D;
  private lookKey = '';
  private readonly areas = new Group();
  private readonly areaMaterial = new MeshBasicMaterial({ color: 0x75f4c4, transparent: true, opacity: .22, depthWrite: false, depthTest: false });

  constructor(private cars: readonly Pick<CarInstance, 'id' | 'cloneModel'>[]) {
    this.root.name = 'Trading car'; this.root.visible = false;
    this.areas.name = 'Repair work areas'; this.root.add(this.areas);
  }

  private select(id: number) {
    if (this.selected === id) return;
    this.clear();
    const source = this.cars.find(car => car.id === id);
    if (!source) throw new Error(`Missing authored trading model: Car ${id}`);
    const model = source.cloneModel();
    const bounds = new Box3().setFromObject(model), size = bounds.getSize(new Vector3());
    // Preserve each model's proportions and authored scale; center it on the route and ground its tires.
    model.position.sub(bounds.getCenter(new Vector3())); model.position.y += size.y / 2;
    model.updateMatrixWorld(true);
    const shells: Mesh[] = [];
    model.traverse(object => {
      if (!(object instanceof Mesh)) return;
      object.castShadow = true; object.receiveShadow = true;
      const shell = /^(?:Body|Chassis)\d*$/.test(object.name);
      const wheel = /^Wheel(?:fl|fr|rl|rr)\d+$/.test(object.name);
      if (object.name === `Wheelfl${id}`) this.frontLeft = object;
      const clone = (original: Material) => {
        const material = original.clone(); this.materials.push(material);
        if (paintable(material)) {
          if (shell) this.paint.push(material);
          if (wheel) this.wheels.push({ material, color: material.color.clone() });
        }
        return material;
      };
      object.material = Array.isArray(object.material) ? object.material.map(clone) : clone(object.material);
      if (shell) shells.push(object);
    });
    // Project the optional stripe onto the actual body instead of floating a box over the car.
    const stripeMaterial = new MeshStandardMaterial({ color: 0xf2e5bd, roughness: .6,
      polygonOffset: true, polygonOffsetFactor: -4, depthWrite: false });
    this.materials.push(stripeMaterial);
    for (const shell of shells) {
      const geometry = new DecalGeometry(shell, new Vector3(0, size.y * .72, 0),
        new Euler(-Math.PI / 2, 0, 0), new Vector3(size.x * .09, size.z, size.y * .58));
      const stripe = new Mesh(geometry, stripeMaterial); stripe.name = 'Trading stripe';
      stripe.visible = false; stripe.receiveShadow = true; this.stripes.push(stripe);
    }
    this.model = model; this.selected = id; this.root.userData.modelId = id;
    this.root.add(model, ...this.stripes);
    const region = (name: string, dimensions: number[], position: number[]) => {
      const area = new Mesh(new BoxGeometry(...dimensions as [number, number, number]), this.areaMaterial);
      area.name = name; area.position.set(...position as [number, number, number]); area.renderOrder = 20; this.areas.add(area);
    };
    region('engine', [size.x * .8, size.y * .48, size.z * .3], [0, size.y * .6, -size.z * .3]);
    for (const x of [-1, 1]) for (const z of [-1, 1]) region('wheels', [size.x * .25, size.y * .55, size.z * .2], [x * size.x * .45, size.y * .28, z * size.z * .31]);
    region('body', [size.x * 1.03, size.y * .7, size.z * .92], [0, size.y * .6, 0]);
  }

  sync(state: TycoonState, draft?: Look) {
    const car = state.car; this.root.visible = !!car;
    if (!car) return;
    const definition = def(state), look = draft ?? car.custom ?? originalLook();
    this.select(tradingModelId(car, definition));
    this.root.position.copy(worldPoint(car.pos, 1.9));
    // Authored models face -Z; route headings use atan2(-dx, dz).
    this.root.rotation.y = Math.PI - (car.angle ?? 0);
    if (this.frontLeft) this.frontLeft.visible = !(car.business?.tutorial && car.condition.RunningGear !== 'Good');
    const active = job(state), kind = active ? repairKind(active) : undefined;
    this.areas.visible = car.status === 'repair' && !!active;
    this.areaMaterial.opacity = .16 + (Math.sin(state.clock * 3) + 1) * .06;
    for (const area of this.areas.children) area.visible = area.name === (kind === 'tuning' ? 'engine' : kind === 'engine' || kind === 'wheels' ? kind : 'body');
    const key = `${definition.color}:${look.paint}:${look.wheels}:${look.stripe}`;
    if (key === this.lookKey) return;
    this.lookKey = key;
    const colors = { cream: '#e8d9b2', blue: '#609fb6', red: '#bd594a', green: '#648b71', original: definition.color };
    for (const material of this.paint) material.color.set(colors[look.paint]);
    for (const { material, color } of this.wheels) material.color.copy(color).multiplyScalar(look.wheels === 'sport' ? .55 : 1);
    for (const stripe of this.stripes) stripe.visible = look.stripe;
  }

  private clear() {
    for (const area of [...this.areas.children]) { (area as Mesh).geometry.dispose(); area.removeFromParent(); }
    this.model?.removeFromParent();
    for (const stripe of this.stripes) { stripe.removeFromParent(); stripe.geometry.dispose(); }
    for (const material of this.materials) material.dispose();
    // The source cars still own the shared geometry and textures.
    this.materials = []; this.paint = []; this.wheels = []; this.stripes = [];
    this.model = undefined; this.frontLeft = undefined; this.selected = undefined; this.lookKey = '';
  }
  dispose() { this.clear(); this.areaMaterial.dispose(); this.root.removeFromParent(); }
}
