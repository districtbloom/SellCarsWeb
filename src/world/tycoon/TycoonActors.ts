import { BoxGeometry, CanvasTexture, Group, Mesh, MeshBasicMaterial, MeshStandardMaterial, Sprite, SpriteMaterial, Vector3 } from 'three';
import { catalog } from './catalog.js';
import { eligible, has, def, job, staffedJob, buyer } from './TycoonModel.js';
import { nameNPC } from './NPCNameplate.js';
import { GARAGE_ENTRY } from './PersonalCars.js';
import { TradingCarVisual } from './TradingCarVisual.js';
import type { CarInstance } from '../driving/CarInstance.js';
import { createNPCCharacter } from '../components/blockCharacter.js';
import { BuiltNPCRoutines, NPCRoutine } from './NPCRoutines.js';
import type { NPCPath } from './NPCRoutines.js';
import type { ImportedPart } from './BuildingProgression.js';
import { guidance, guidanceAnchor } from './TycoonGuidance.js';
import { purchasePad, purchaseGate, cosmeticPads, staffedListing, staffedPhoto, salesPreparationPoint } from './FullJourney.js';
import { legacyPadCategory, padColor } from './PurchaseCategories.js';
import { sourcePoint } from './FullJourneyCatalog.js';
import { PARTS_POSITION, partsUnlocked, partsPayout } from './PartsStation.js';
import { actorPosition } from './TycoonSession.js';
import { LOT_ORIGIN, SOURCE_ORIGIN, worldPoint } from './TycoonCoordinates.js';
import type { Look, TycoonState } from './types.js';

function box(group: Group, name: string, size: number[], position: number[], color: string | number) {
  const mesh = new Mesh(new BoxGeometry(size[0], size[1], size[2]), new MeshStandardMaterial({ color, roughness: .8 }));
  mesh.name = name; mesh.position.set(position[0], position[1], position[2]); mesh.castShadow = true; mesh.receiveShadow = true; group.add(mesh); return mesh;
}
export function createPurchasePad(parent: Group, name: string, category: string) {
  const group = new Group(); group.name = name; group.userData.category = category;
  box(group, 'Base', [6, .16, 6], [0, 0, 0], 0x3a4750);
  box(group, 'Button', [5.1, .2, 5.1], [0, .18, 0], padColor(category));
  parent.add(group); return group;
}
export function textSprite(text: string, width = 18, nameOnly = false) {
  const canvas = document.createElement('canvas'); canvas.width = 512; canvas.height = 128;
  const ctx = canvas.getContext('2d')!;
  if (!nameOnly) {
    ctx.fillStyle = '#f6f1e1'; ctx.fillRect(0, 0, 512, 128);
    ctx.strokeStyle = '#203030'; ctx.lineWidth = 8; ctx.strokeRect(4, 4, 504, 120);
  } else {
    ctx.shadowColor = '#203030'; ctx.shadowBlur = 5; ctx.shadowOffsetY = 2;
  }
  ctx.fillStyle = nameOnly ? '#ffffff' : '#203030'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.font = 'bold 30px system-ui';
  const lines = text.split('\n'); lines.forEach((line, i) => ctx.fillText(line, 256, 64 + (i - (lines.length - 1) / 2) * 40, 480));
  const sprite = new Sprite(new SpriteMaterial({ map: new CanvasTexture(canvas), depthTest: false, depthWrite: false })); sprite.scale.set(width, width / 4, 1); return sprite;
}
function partsSaleLabel(amount: number) {
  const canvas = document.createElement('canvas'); canvas.width = 768; canvas.height = 192;
  const ctx = canvas.getContext('2d')!; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.lineJoin = 'round';
  ctx.font = '900 66px system-ui'; ctx.strokeStyle = '#080c08'; ctx.lineWidth = 12;
  ctx.strokeText('SELL CARS PART', 384, 68); ctx.fillStyle = '#65f279'; ctx.fillText('SELL CARS PART', 384, 68);
  ctx.font = '700 38px system-ui'; ctx.lineWidth = 7; ctx.strokeText(amount + '$/sell', 384, 144); ctx.fillStyle = '#fff'; ctx.fillText(amount + '$/sell', 384, 144);
  const label = new Sprite(new SpriteMaterial({ map: new CanvasTexture(canvas), depthTest: false, depthWrite: false })); label.scale.set(23, 5.75, 1); return label;
}
export class TycoonActors {
  readonly root = new Group();
  readonly pads = new Map<string, Group>();
  readonly trading: Group;
  private readonly tradingVisual: TradingCarVisual;
  readonly worker = createNPCCharacter('Jo', 0x3f7581);
  readonly actor = createNPCCharacter('Deal person', 0x4a8c8a);
  private targetLabel?: Sprite;
  private targetName = '';
  private padLabels = new Map<string, Sprite>();
  private readonly journeyPad = createPurchasePad(this.root, 'Next purchase', 'Money-making');
  private readonly cosmetics = new Map<string, { pad: Group; label: Sprite }>();
  private journeyLabel?: Sprite;
  private journeyLabelId?: string;
  private readonly staff = [createNPCCharacter('Manny', 0x47866b), createNPCCharacter('Car buyer', 0x798646), createNPCCharacter('Sales advisor', 0x495d8d)];
  private partsLabel = partsSaleLabel(28);
  private partsAmount = 28;
  private readonly partsComputer = new Group();
  private readonly garageKiosk = new Group();
  private readonly routines: NPCRoutine[];
  private readonly builtNPCs: BuiltNPCRoutines;
  private lastClock = 0;
  constructor(cars: readonly Pick<CarInstance, 'id' | 'cloneModel'>[], parts: ImportedPart[] = [], path?: NPCPath) {
    this.tradingVisual = new TradingCarVisual(cars); this.trading = this.tradingVisual.root;
    this.routines = [this.worker, this.actor, ...this.staff].map(character => new NPCRoutine(character, path));
    this.staff.forEach((person, i) => nameNPC(person, ['Manny', 'Riley', 'Avery'][i]));
    const camera = box(this.staff[2].getObjectByName('Character rig') as Group, 'Listing camera', [1.2, .65, .45], [0, 2, -1.8], 0x263543);
    camera.visible = false;
    this.builtNPCs = new BuiltNPCRoutines(this.root, parts, path);
    this.worker.rotation.y = this.actor.rotation.y = Math.PI;
    this.root.name = 'Tycoon activity'; this.root.add(this.trading, this.worker, this.actor);
    this.garageKiosk.name = 'Personal garage entrance'; this.garageKiosk.position.copy(worldPoint(GARAGE_ENTRY, 1.48));
    box(this.garageKiosk, 'Garage sign post', [.5, 5, .5], [0, 2.5, 0], 0x34464b);
    const sign = textSprite('PERSONAL GARAGE\n[E] Browse collection', 13); sign.position.y = 5.5; this.garageKiosk.add(sign);
    this.root.add(this.garageKiosk);
    this.journeyPad.visible = false; this.root.add(...this.staff, this.partsLabel);
    this.partsLabel.position.copy(worldPoint(PARTS_POSITION, 8));
    this.partsComputer.name = 'Parts sales computer'; this.partsComputer.position.copy(worldPoint(PARTS_POSITION, 1.9)); this.root.add(this.partsComputer);
    box(this.partsComputer, 'Desk', [5.6, .25, 3.2], [0, 4.3, 0], 0x856b4f);
    for (const x of [-2.3, 2.3]) for (const z of [-1.2, 1.2]) box(this.partsComputer, 'Desk leg', [.3, 4.3, .3], [x, 2.15, z], 0x34464b);
    box(this.partsComputer, 'Laptop keyboard', [3.1, .14, 1.6], [0, 4.51, .25], 0x242d35);
    box(this.partsComputer, 'Laptop display', [3.1, 2, .16], [0, 5.5, -.65], 0x202a32);
    box(this.partsComputer, 'Laptop screen', [2.8, 1.65, .03], [0, 5.5, -.55], 0x51c590);
    for (let row = 0; row < 3; row++) for (let col = 0; col < 9; col++) box(this.partsComputer, 'Key', [.21, .02, .18], [-1.05 + col * .26, 4.59, -.08 + row * .29], 0x92a7ae);
    for (const p of catalog.pads) {
      const mesh = createPurchasePad(this.root, p.id, legacyPadCategory(p.name));
      mesh.position.copy(new Vector3(...p.sourcePosition).sub(SOURCE_ORIGIN).add(LOT_ORIGIN)); mesh.userData.tycoonPad = p.id; this.pads.set(p.id, mesh);
      const label = textSprite(p.name, 14, true); label.position.copy(mesh.position).add(new Vector3(0, 6, 0)); this.root.add(label); this.padLabels.set(p.id, label);
    }
  }
  alignFixtures(groundHeight: (point: Vector3) => number | undefined) {
    const height = groundHeight(this.partsComputer.position);
    if (height !== undefined) this.partsComputer.position.y = height;
    const garageHeight = groundHeight(this.garageKiosk.position);
    if (garageHeight !== undefined) this.garageKiosk.position.y = garageHeight;
  }
  sync(s: TycoonState, player: Vector3, draft?: Look, showTarget = true) {
    const c = s.car, g = guidance(s);
    this.garageKiosk.visible = has(s, 'lot');
    const delta = Math.min(.1, Math.max(0, s.clock - this.lastClock)); this.lastClock = s.clock;
    const tutorial = s.journey ? !s.journey.tutorialComplete : s.sales === 0;
    // One green flash per second; tint the existing text without rebuilding its texture.
    const targetColor = tutorial && s.clock % 1 < .5 ? 0x50ff70 : 0xffffff;
    const targetName = g.point && g.kind !== 'pad'
      ? g.kind === 'repair' ? job(s)?.name ?? '' : c ? def(s).name : '' : '';
    if (targetName && this.targetName !== targetName) {
      this.targetLabel?.material.map?.dispose(); this.targetLabel?.material.dispose(); this.targetLabel?.removeFromParent();
      this.targetLabel = textSprite(targetName, 18, true); this.targetName = targetName; this.root.add(this.targetLabel);
    }
    if (this.targetLabel) {
      this.targetLabel.visible = !!targetName && showTarget;
      this.targetLabel.material.color.setHex(targetColor);
      const anchor = guidanceAnchor(s, g);
      if (anchor) this.targetLabel.position.copy(worldPoint(anchor, 10));
    }
    const payout = partsPayout(s.parts?.level ?? 1);
    if (payout !== this.partsAmount) {
      this.partsLabel.material.map?.dispose(); this.partsLabel.material.dispose(); this.partsLabel.removeFromParent();
      this.partsLabel = partsSaleLabel(payout); this.partsLabel.position.copy(worldPoint(PARTS_POSITION, 8)); this.root.add(this.partsLabel); this.partsAmount = payout;
    }
    this.partsLabel.visible = partsUnlocked(s) && this.partsLabel.position.distanceTo(player) < 45;
    this.partsComputer.visible = partsUnlocked(s);
    const pad = s.journey ? purchasePad(s) : undefined;
    this.journeyPad.visible = !!pad && !purchaseGate(s);
    if (pad) {
      this.journeyPad.userData.category = pad.category;
      this.journeyPad.position.copy(new Vector3(...pad.sourcePosition).sub(SOURCE_ORIGIN).add(LOT_ORIGIN));
      if (this.journeyLabelId !== pad.id) {
        this.journeyLabel?.material.map?.dispose(); this.journeyLabel?.material.dispose(); this.journeyLabel?.removeFromParent();
        this.journeyLabel = textSprite(pad.name, 22, true);
        this.root.add(this.journeyLabel); this.journeyLabelId = pad.id;
      }
      this.journeyLabel!.position.copy(this.journeyPad.position).add(new Vector3(0, 6, 0));
    }
    if (this.journeyLabel) {
      const target = showTarget && g.kind === 'pad' && g.id === pad?.id;
      this.journeyLabel.visible = this.journeyPad.visible && (target || this.journeyPad.position.distanceTo(player) < 65);
      this.journeyLabel.material.color.setHex(target ? targetColor : 0xffffff);
    }
    for (const visual of this.cosmetics.values()) { visual.pad.visible = false; visual.label.visible = false; }
    for (const optional of cosmeticPads(s)) {
      let visual = this.cosmetics.get(optional.id);
      if (!visual) {
        const button = createPurchasePad(this.root, optional.id, 'Cosmetic'), label = textSprite(optional.name, 18, true);
        this.root.add(label); visual = { pad: button, label }; this.cosmetics.set(optional.id, visual);
      }
      visual.pad.visible = true; visual.pad.userData.tycoonPad = optional.id;
      visual.pad.position.copy(new Vector3(...optional.sourcePosition).sub(SOURCE_ORIGIN).add(LOT_ORIGIN));
      visual.label.position.copy(visual.pad.position).add(new Vector3(0, 6, 0));
      visual.label.visible = showTarget && visual.pad.position.distanceTo(player) < 28;
    }
    for (let i = 0; i < this.staff.length; i++) {
      const person = this.staff[i]; person.visible = has(s, ['salesdesk', 'carbuyer', 'salesrep'][i]);
      const home = worldPoint([sourcePoint(3055, 89), sourcePoint(3017, 96), sourcePoint(3066, 86)][i], 5.5);
      if (i === 0 && c?.route?.target === 'sales') {
        const yaw = Math.PI - (c.angle ?? 0);
        const seat = new Vector3(-1.4, 0, 0).applyAxisAngle(new Vector3(0, 1, 0), yaw).add(worldPoint(c.pos, 5));
        this.routines[i + 2].ride(seat, yaw, delta); person.userData.activity = 'Driving car to sale point'; continue;
      }
      const customer = c && ['seller', 'buyer', 'sold'].includes(c.status);
      const preparation = salesPreparationPoint(s);
      const preparing = !!preparation && (i === 0 || i === 2 && staffedListing(s));
      const publishing = i === 2 && staffedListing(s) && !!c && (['ready', 'photo'].includes(c.status) || c.status === 'repair' && staffedPhoto(s));
      if (i === 2) person.getObjectByName('Listing camera')!.visible = publishing;
      const helping = !!c && !c.remote && (i === 0 ? c.status === 'ready' : i === 1 ? c.status === 'seller' : publishing || ['buyer', 'sold'].includes(c.status));
      const target = preparing ? worldPoint(preparation!, 5.5).add(new Vector3(i === 0 ? -6 : 6, 0, 4))
        : helping ? worldPoint(customer ? actorPosition(s) : c!.pos, 5.5).add(new Vector3(i % 2 ? -5 : 5, 0, 3))
        : home.clone().add(new Vector3(Math.floor((s.clock + i * 4) / 9) % 2 ? 4 : 0, 0, 0));
      this.routines[i + 2].walk(target, delta, home);
      this.routines[i + 2].animate(delta, s.clock + i, publishing ? 'photo' : preparing ? 'inspect' : helping ? customer ? 'talk' : 'inspect' : 'idle', helping || preparing ? worldPoint(c!.pos, 5.5) : undefined);
      person.userData.activity = publishing ? 'Photographing and listing' : preparing && c?.status !== 'ready' ? i === 0 ? 'Waiting beside repair for handover' : 'Preparing listing beside repair' : helping ? i === 0 ? 'Collecting car for sale point' : customer ? 'Assisting customer' : 'Checking vehicle' : 'Checking desk';
    }
    for (const p of catalog.pads) {
      const mesh = this.pads.get(p.id)!, available = eligible(s, p); mesh.visible = available;
      const label = this.padLabels.get(p.id)!, target = showTarget && g.kind === 'pad' && g.id === p.id;
      label.visible = available && (target || mesh.position.distanceTo(player) < 42);
      label.material.color.setHex(target ? targetColor : 0xffffff);
    }
    this.tradingVisual.sync(s, draft);
    this.actor.visible = !!c && ['seller', 'buyer', 'sold'].includes(c.status);
    if (c) {
      nameNPC(this.actor, c.status === 'seller' ? def(s).seller : c.soldTo?.name ?? buyer(s).name);
      const target = worldPoint(c.status === 'sold' ? [c.pos[0] + 2, c.pos[1]] : actorPosition(s), 5.5);
      this.routines[1].walk(target, delta, worldPoint([c.pos[0] + 2, c.pos[1]], 5.5));
      this.routines[1].animate(delta, s.clock, c.quote ? 'talk' : 'inspect', c.quote ? player : worldPoint(c.pos, 5.5));
    } else this.routines[1].walk(new Vector3(), delta);
    this.worker.visible = s.worker.hired || has(s, 'mechanic') || staffedJob(s);
    if (this.worker.visible) this.worker.position.copy(worldPoint(s.worker.pos, 5.5));
    this.routines[0].animate(delta, s.clock, s.worker.activity === 'Working' && job(s)?.started && !staffedPhoto(s) ? 'repair' : s.worker.activity === 'Inspecting vehicle' ? 'inspect' : 'idle', c && !s.worker.route ? worldPoint(c.pos, 5.5) : undefined);
    this.builtNPCs.sync(s, delta);
    this.root.userData.built = s.pads.length; this.root.userData.power = has(s, 'power');
  }
  dispose() {
    this.tradingVisual.dispose();
    this.root.traverse(o => { if (o instanceof Mesh || o instanceof Sprite) {
      if (o instanceof Mesh) o.geometry.dispose();
      const materials = Array.isArray(o.material) ? o.material : [o.material];
      materials.forEach(m => { if ('map' in m) (m as MeshBasicMaterial).map?.dispose(); m.dispose(); });
    } }); this.root.removeFromParent();
  }
}
