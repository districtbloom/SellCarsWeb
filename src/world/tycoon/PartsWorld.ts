import { Box3, BoxGeometry, Group, Mesh, MeshStandardMaterial, PerspectiveCamera, Scene, Vector3 } from 'three';
import type { CarInstance } from '../driving/CarInstance.js';
import { createNPCCharacter, disposeBlockCharacter } from '../components/blockCharacter.js';
import { NPCRoutine } from './NPCRoutines.js';
import { PART_SHOPS, COURIER_DEPOT } from '../TownPlaces.js';
import { PARTS_PACKAGES, courierCost } from './PartsEconomy.js';
import { worldPoint } from './TycoonCoordinates.js';
import type { TycoonState } from './types.js';
import type { Action } from './TycoonSession.js';

/** In-world shop choices stay together over the storefront, including on touch screens. */
export class PartsWorld {
  readonly root = new Group();
  private readonly panels: { element: HTMLDivElement; anchor: Vector3; shopId?: string }[] = [];
  private readonly drivers = new Map<number, { root: Group; person: Group; routine: NPCRoutine; crate: Mesh }>();
  private readonly hire: HTMLButtonElement;
  private clock = 0;
  constructor(scene: Scene, private camera: PerspectiveCamera, private cars: readonly Pick<CarInstance, 'id' | 'cloneModel'>[], dispatch: (action: Action) => unknown) {
    this.root.name = 'Parts delivery fleet'; scene.add(this.root);
    const panel = (title: string, anchor: Vector3, shopId?: string) => {
      const element = document.createElement('div'); element.className = 'parts-world-prompt'; element.hidden = true;
      const label = document.createElement('strong'); label.textContent = title; element.append(label); document.body.append(element);
      this.panels.push({ element, anchor, shopId }); return element;
    };
    for (const shop of PART_SHOPS) {
      const element = panel('Car Part Shop', new Vector3(shop.x, 12, shop.z), shop.id);
      for (const [index, pack] of PARTS_PACKAGES.entries()) {
        const button = document.createElement('button'); button.textContent = `[ ${index + 1} ]  ${pack.parts} Parts · $${pack.cost}`;
        button.onclick = () => dispatch({ type: 'BuyParts', shopId: shop.id, packageId: pack.id }); element.append(button);
      }
    }
    const depot = panel('Parts delivery drivers', new Vector3(COURIER_DEPOT.x, 13, COURIER_DEPOT.z));
    this.hire = document.createElement('button'); this.hire.onclick = () => dispatch({ type: 'HireCourier' }); depot.append(this.hire);
    const detail = document.createElement('small'); detail.textContent = 'Own car · 50 Parts / $400 per run'; depot.append(detail);
  }
  key(code: string, s: TycoonState, player: Vector3): Action | undefined {
    if (code === 'KeyE' && player.distanceTo(new Vector3(COURIER_DEPOT.x, player.y, COURIER_DEPOT.z)) < 22 && (s.couriers?.length ?? 0) < 3) return { type: 'HireCourier' };
    const pack = PARTS_PACKAGES.find(p => p.key === code); if (!pack) return;
    const shop = PART_SHOPS.find(p => player.distanceTo(new Vector3(p.x, player.y, p.z)) < 22);
    return shop ? { type: 'BuyParts', shopId: shop.id, packageId: pack.id } : undefined;
  }
  tick(s: TycoonState, player: Vector3, interactive: boolean) {
    this.hire.textContent = (s.couriers?.length ?? 0) >= 3 ? 'All 3 drivers hired' : `[ E ] Hire driver · $${courierCost(s)}`;
    this.hire.disabled = (s.couriers?.length ?? 0) >= 3 || s.cash < courierCost(s);
    for (const p of this.panels) {
      const distance = Math.hypot(player.x - p.anchor.x, player.z - p.anchor.z), projected = p.anchor.clone().project(this.camera);
      p.element.hidden = !interactive || distance > 22 || projected.z < -1 || projected.z > 1;
      p.element.style.left = `${(projected.x * .5 + .5) * innerWidth}px`;
      p.element.style.top = `${(-projected.y * .5 + .5) * innerHeight}px`;
      if (p.shopId) p.element.querySelectorAll('button').forEach((button, i) => { button.disabled = s.cash < PARTS_PACKAGES[i].cost; });
    }
    const dt = Math.max(0, Math.min(.1, s.clock - this.clock)); this.clock = s.clock;
    for (const d of s.couriers ?? []) {
      let visual = this.drivers.get(d.id);
      if (!visual) {
        const root = new Group(), model = this.cars.find(c => c.id === [7, 4, 8][d.id - 1])?.cloneModel();
        if (model) { const box = new Box3().setFromObject(model), size = box.getSize(new Vector3()); model.position.sub(box.getCenter(new Vector3())); model.position.y += size.y / 2; root.add(model); }
        const person = createNPCCharacter(`Delivery driver ${d.id}`, [0xd68c44, 0x568dbe, 0x76a675][d.id - 1]);
        const crate = new Mesh(new BoxGeometry(2, 1.4, 1.5), new MeshStandardMaterial({ color: 0x9b764c, roughness: .95 }));
        crate.name = 'Parts delivery box'; crate.position.set(0, -.3, -1.65); person.add(crate);
        this.root.add(root, person); visual = { root, person, routine: new NPCRoutine(person), crate }; this.drivers.set(d.id, visual);
      }
      visual.root.position.copy(worldPoint(d.pos, 1.5)); visual.root.rotation.y = Math.PI - (d.angle ?? 0);
      visual.person.visible = !d.route;
      const handling = d.phase === 'loading' || d.phase === 'unloading';
      const door = visual.root.position.clone().add(new Vector3(6, 3.6, 0));
      const target = door.clone().add(new Vector3(handling && d.wait > 2 ? 6 : 0, 0, handling ? 4 : 0));
      visual.routine.walk(target, dt, door, 5);
      visual.crate.visible = handling;
      visual.routine.animate(dt, s.clock, handling ? 'carry' : 'idle', visual.root.position);
      visual.person.userData.activity = handling ? d.phase === 'loading' ? 'Loading parts into car' : 'Unloading parts delivery' : 'Waiting for next delivery';
    }
  }
  dispose() {
    for (const p of this.panels) p.element.remove();
    for (const visual of this.drivers.values()) disposeBlockCharacter(visual.person);
    this.root.removeFromParent();
  }
}
