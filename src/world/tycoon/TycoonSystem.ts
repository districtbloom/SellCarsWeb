import { PartsTyping } from './PartsTyping.js';
import { RepairController } from './RepairController.js';
import './repair.css';
import { PerspectiveCamera, Scene, Vector3 } from 'three';
import type { Object3D, WebGLRenderer } from 'three';
import { Vec3 } from 'cannon-es';
import type { Body } from 'cannon-es';
import { DrivingSystem } from '../driving/DrivingSystem.js';
import { METERS_PER_UNIT } from '../driving/CarRig.js';
import { TycoonEnvironment } from './TycoonEnvironment.js';
import { TycoonActors } from './TycoonActors.js';
import { TycoonSession } from './TycoonSession.js';
import type { Action, ActionResult } from './TycoonSession.js';
import { TycoonSave } from './TycoonSave.js';
import { TycoonHUD } from './TycoonHUD.js';
import { CarShowroom } from './CarShowroom.js';
import { PersonalCarController } from './PersonalCarController.js';
import { PartsWorld } from './PartsWorld.js';
import { personalCars } from './PersonalCars.js';
import { guidance, guidanceAnchor, money, nearestPad } from './TycoonGuidance.js';
import type { Guidance } from './TycoonGuidance.js';
import * as M from './TycoonModel.js';
import { nextEntry } from './FullJourneyCatalog.js';
import { legacyPadCategory } from './PurchaseCategories.js';
import { PARTS_POSITION, PARTS_SECONDS, partsUnlocked, partsAutomated } from './PartsStation.js';
import { logicalPoint, LOT_ORIGIN, worldPoint } from './TycoonCoordinates.js';
import type { TycoonState } from './types.js';
import './tycoon.css';
import { assetUrl } from '../../runtimeAssets.js';

interface JourneyEntry { step: number; title: string; delta: string; chapter: string }
export class TycoonSystem {
  readonly session: TycoonSession;
  readonly actors: TycoonActors;
  readonly hud: TycoonHUD;
  private readonly save: TycoonSave;
  private readonly showroom: CarShowroom;
  private readonly personalCar: PersonalCarController;
  private readonly repair: RepairController;
  private readonly partsTyping: PartsTyping;
  private readonly partsWorld: PartsWorld;
  private obstacles: Object3D[] = [];
  private readonly staticBodies: Body[] = [];
  private readonly staticObstacles: Object3D[] = [];
  private pendingWalk?: Guidance;
  private menu = false;
  private riding = false;
  private heldW = false;
  private saveTimer = 0;
  private revealTime = 0;
  private reviewStep?: number;
  private reviewUI?: HTMLElement;
  private sound?: AudioContext;
  private previousJobs = 0;
  private suspended = false;
  private disposed = false;
  get state(): TycoonState { return this.session.state; }
  private constructor(scene: Scene, private driving: DrivingSystem, private camera: PerspectiveCamera,
    readonly environment: TycoonEnvironment, private baseUrl: string) {
    this.actors = new TycoonActors(driving.cars, environment.parts, (from, to) => environment.walkPath(from, to));
    const params = new URLSearchParams(location.search);
    let storage: Storage | undefined;
    try { if (params.get('save') !== 'off' && !params.has('journey')) storage = localStorage; } catch { /* Private browsing can deny storage. */ }
    this.save = new TycoonSave(storage, { legacy: params.get('opening') === 'integration' }); this.session = new TycoonSession(this.save.load());
    this.showroom = new CarShowroom(driving); this.personalCar = new PersonalCarController(driving);
    this.partsWorld = new PartsWorld(scene, camera, driving.cars, action => this.dispatch(action));
    this.hud = new TycoonHUD({ state: this.state, dispatch: action => this.dispatch(action), navigate: target => this.navigate(target),
      cars: personalCars.map(option => ({ ...option, tuning: driving.cars.find(car => car.id === option.id)!.physics.tuning })),
      previewCar: id => this.showroom.select(id), canChangeCar: () => !driving.isDriving && !this.riding && !this.save.readOnly,
      goToCar: () => this.goToPersonalCar(),
      setMenu: open => this.setMenu(open), saveStatus: () => this.save.status, offline: () => this.save.offline, dismissOffline: () => { this.save.offline = undefined; } });
    this.repair = new RepairController(this.state, driving.player, camera, input => this.dispatch({ type: 'RepairInput', input }).ok, open => {
      this.setMenu(open); this.hud.root.hidden = open;
    });
    this.partsTyping = new PartsTyping(this.state, driving.player, camera, active => {
      this.setMenu(active); this.hud.root.hidden = active;
      if (!active) this.hud.showSellingProgress();
    });
    scene.add(environment.root, this.actors.root);
    for (const object of this.actors.root.children) {
      const size = object.userData.tycoonStaticSize as [number, number, number] | undefined;
      if (!size) continue;
      this.staticBodies.push(driving.physics.addStaticBox(new Vec3(size[0] * METERS_PER_UNIT / 2, size[1] * METERS_PER_UNIT / 2, size[2] * METERS_PER_UNIT / 2),
        new Vec3(object.position.x * METERS_PER_UNIT, object.position.y * METERS_PER_UNIT, object.position.z * METERS_PER_UNIT)));
      this.staticObstacles.push(object);
    }
    this.driving.setTycoonObstacles([], this.staticObstacles); this.syncEnvironment();
    this.driving.onInteract = () => this.interact();
    this.driving.onFootSpawn = () => {
      const personal = this.state.personal;
      return personal ? worldPoint([personal.pos[0] + 3, personal.pos[1] + 1], 6) : worldPoint([0, 4], 6);
    };
    driving.placePlayer(this.driving.onFootSpawn());
    window.addEventListener('keydown', this.keyDown); window.addEventListener('keyup', this.keyUp); window.addEventListener('blur', this.blur);
    window.addEventListener('pagehide', this.suspend); window.addEventListener('pageshow', this.resume); document.addEventListener('visibilitychange', this.visibility);
    if (params.has('journey')) {
      const n = Number(params.get('journey'));
      this.reviewStep = Number.isInteger(n) ? Math.max(0, Math.min(240, n)) : 0;
      void this.initReview().catch(error => { console.error(error); if (this.reviewUI) this.reviewUI.textContent = 'Could not load the journey catalog.'; });
    }
    this.tick(0);
    if (this.save.offline) this.hud.open('offline');
  }
  static async create(scene: Scene, driving: DrivingSystem, camera: PerspectiveCamera, baseUrl: string) {
    const environment = await TycoonEnvironment.load(baseUrl, driving.physics.world);
    return new TycoonSystem(scene, driving, camera, environment, baseUrl);
  }
  private syncEnvironment() {
    const before = [...this.environment.cameraObstacles];
    this.environment.sync(this.state, this.reviewStep);
    const journey = this.state.journey, entry = journey && nextEntry(journey.step);
    if (journey && entry && !journey.padPosition) journey.padPosition = this.environment.purchasePosition(entry.padPosition, Object.values(journey.cosmeticPadPositions ?? {}));
    if (this.environment.cameraObstacles[0] !== before[0] || this.environment.cameraObstacles.length !== before.length) {
      this.driving.setTycoonObstacles(this.obstacles, this.environment.cameraObstacles);
      this.obstacles = [...this.environment.cameraObstacles];
    }
  }
  private setMenu(open: boolean) {
    this.menu = open; this.pendingWalk = undefined; this.heldW = false;
    this.driving.setControlsEnabled(!open && !this.riding, open || this.riding);
  }
  renderPreview(renderer: WebGLRenderer) { this.hud.renderAvatar(renderer); return this.showroom.render(renderer); }
  private goToPersonalCar() {
    this.personalCar.sync(this.state);
    const target = this.personalCar.walkingTarget();
    if (this.driving.isDriving) { this.hud.close(); return; }
    if (!target) { M.note(this.state, 'Bring your car back to the garage to get in.'); return; }
    this.hud.close(); this.driving.walkTo(this.environment.walkPath(this.driving.player.mesh.position, target));
  }
  dispatch(action: Action): ActionResult {
    if (this.save.readOnly || this.suspended) { M.note(this.state, this.save.status); return { ok: false }; }
    const before = this.state.pads.length, hadPersonal = !!this.state.personal;
    const snapshot = this.save.requiresCommit ? M.copy(this.state) : undefined;
    const result = this.session.dispatch(action, { position: logicalPoint(this.driving.player.mesh.position), onFoot: !this.driving.isDriving && !this.riding });
    if (result.ok) {
      if (!this.save.write(this.state) && snapshot) { this.replaceState(snapshot); M.note(this.state, this.save.status); return { ok: false }; }
      if (action.type === 'Discover') {
        this.revealTime = 0;
        this.driving.setControlsEnabled(!this.menu && !this.riding, this.menu || this.riding);
      }
      this.syncEnvironment(); this.personalCar.sync(this.state);
      if (action.type === 'Pad' && !hadPersonal && this.state.personal) {
        this.driving.stopWalking(); this.pendingWalk = undefined;
        this.driving.placePlayer(this.driving.onFootSpawn!());
        M.note(this.state, 'Your personal car is ready in the garage beside your dealership. Jo will call with a local lead.');
      }
      this.ping(action.type === 'Pad' || this.state.pads.length > before ? 660 : result.receipt ? 780 : 500);
    }
    else if (!this.state.notice || (this.state.noticeUntil ?? 0) <= this.state.clock) M.note(this.state, 'Come closer, or finish the current step first.');
    return result;
  }
  private ping(frequency: number) {
    // HubClient's pitch-shifted feedback cue, adapted without Roblox-only asset URLs.
    if (!(navigator as Navigator & { userActivation?: { hasBeenActive: boolean } }).userActivation?.hasBeenActive) return;
    try {
      this.sound ??= new AudioContext(); if (this.sound.state === 'suspended') void this.sound.resume();
      const osc = this.sound.createOscillator(), gain = this.sound.createGain(); osc.type = 'sine'; osc.frequency.value = frequency;
      gain.gain.setValueAtTime(.035, this.sound.currentTime); gain.gain.exponentialRampToValueAtTime(.001, this.sound.currentTime + .12);
      osc.connect(gain); gain.connect(this.sound.destination); osc.start(); osc.stop(this.sound.currentTime + .13);
    } catch { /* Audio may be disabled by the browser. Gameplay remains available. */ }
  }
  private activate(g: Guidance) {
    if (g.kind === 'pad' && g.id) this.hud.showResult(this.dispatch({ type: 'Pad', id: g.id }));
    else if (g.kind === 'deal') this.hud.showResult(this.dispatch({ type: 'Deal' }));
    else if (g.kind === 'build') this.hud.open('build');
    else if (g.kind === 'repair') { if (M.staffedJob(this.state)) this.hud.open('worker'); else { const j = M.job(this.state); if (j && (j.started || this.dispatch({ type: 'Repair' }).ok)) this.repair.begin(j); } }
    else if (g.kind === 'photo') this.hud.open('prepare');
    else if (g.kind === 'phone') this.hud.togglePhone();
    else if (g.kind === 'complete') this.hud.open(g.kind);
    else if (g.kind === 'discover') this.dispatch({ type: 'Discover' });
    else if (g.kind === 'parts') this.sellParts();
    else if (g.kind === 'drive') this.goToPersonalCar();
  }
  private sellParts() {
    if (partsAutomated(this.state)) { M.note(this.state, 'Your mechanic handles these sales.'); return; }
    if (this.state.parts?.remaining !== undefined || this.dispatch({ type: 'SellParts' }).ok) this.partsTyping.begin();
  }
  private navigate(g: Guidance) {
    if (g.kind === 'drive') { this.goToPersonalCar(); return; }
    if (this.driving.isDriving) { M.note(this.state, 'Exit the car to visit your dealership.'); return; }
    if (this.hud.isOpen) this.hud.close();
    if (!g.point) { this.activate(g); return; }
    const target = worldPoint(g.point, 6), from = this.driving.player.mesh.position;
    if (Math.hypot(target.x - from.x, target.z - from.z) < 10) { this.activate(g); return; }
    this.pendingWalk = g; this.driving.walkTo(this.environment.walkPath(from, target));
  }
  private interact(): boolean {
    if (this.menu || this.riding || this.reviewStep !== undefined) return false;
    const partsAction = this.partsWorld.key('KeyE', this.state, this.driving.player.mesh.position);
    if (partsAction) { this.dispatch(partsAction); return true; }
    const pos = logicalPoint(this.driving.player.mesh.position), p = nearestPad(this.state, pos);
    if (partsUnlocked(this.state) && Math.hypot(pos[0] - PARTS_POSITION[0], pos[1] - PARTS_POSITION[1]) < 5) { this.sellParts(); return true; }
    if (p && Math.hypot(p.pos[0] - pos[0], p.pos[1] - pos[1]) < 4) { this.activate({ text: '', label: '', kind: 'pad', id: p.id }); return true; }
    const g = guidance(this.state);
    if (g.point && Math.hypot(g.point[0] - pos[0], g.point[1] - pos[1]) * 3 < 20) { this.activate(g); return true; }
    if (g.kind === 'photo' && this.state.car && Math.hypot(this.state.car.pos[0] - pos[0], this.state.car.pos[1] - pos[1]) * 3 < 25) { this.activate(g); return true; }
    return false;
  }
  private keyDown = (e: KeyboardEvent) => {
    if (e.ctrlKey || e.metaKey || e.altKey || /^(INPUT|TEXTAREA|SELECT)$/.test((e.target as HTMLElement)?.tagName)) return;
    if (!e.repeat && !this.menu && !this.driving.isDriving && !this.riding && e.code !== 'KeyE') {
      const action = this.partsWorld.key(e.code, this.state, this.driving.player.mesh.position);
      if (action) { e.preventDefault(); this.dispatch(action); return; }
    }
    if (e.code === 'KeyW' && !this.menu) this.heldW = true;
    if (e.code === 'KeyS') this.heldW = false;
    if (['KeyW', 'KeyA', 'KeyS', 'KeyD', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) this.pendingWalk = undefined;
  };
  private keyUp = (e: KeyboardEvent) => { if (e.code === 'KeyW') this.heldW = false; };
  private blur = () => { this.heldW = false; this.hud.driveHeld = false; this.driving.stopWalking(); this.pendingWalk = undefined; };
  private replaceState(state: TycoonState) {
    for (const key of Object.keys(this.state)) delete (this.state as unknown as Record<string, unknown>)[key];
    Object.assign(this.state, state);
  }
  private suspend = () => {
    if (this.suspended || this.reviewStep !== undefined) return;
    if (this.repair.active) this.repair.close();
    if (this.partsTyping.active) this.partsTyping.close();
    this.personalCar.sync(this.state);
    this.suspended = true; this.blur(); this.save.release(this.state);
  };
  private resume = () => {
    if (this.disposed || !this.suspended || document.hidden || this.reviewStep !== undefined) return;
    this.suspended = false;
    const resumed = this.save.resume(this.state);
    if (resumed !== this.state) this.replaceState(resumed);
    this.syncEnvironment(); this.personalCar.sync(this.state);
    if (this.save.offline) this.hud.open('offline');
  };
  private visibility = () => { if (document.hidden) this.suspend(); else this.resume(); };
  private flush = () => { if (this.reviewStep === undefined) this.save.write(this.state); };
  tick(delta: number) {
    if (this.disposed) return;
    this.showroom.tick(delta);
    if (this.reviewStep !== undefined) { this.syncEnvironment(); return; }
    if (this.suspended) return;
    if (this.save.readOnly) { this.actors.sync(this.state, this.driving.player.mesh.position); this.hud.showHint(this.save.status); this.hud.update(); return; }
    const s = this.state, dt = Math.min(Math.max(0, delta), .1);
    const transactional = (s.couriers ?? []).some(d => !d.route && d.wait <= dt && ['idle', 'unloading'].includes(d.phase)) || (s.parts?.remaining !== undefined && s.parts.remaining <= dt + 1e-8) || s.car && (['seller', 'choose', 'buyer'].includes(s.car.status) || s.car.status === 'repair' && !s.car.plan?.funded);
    const before = transactional && this.save.requiresCommit ? M.copy(s) : undefined, cash = s.cash, stock = s.partsStock;
    this.session.tick(dt, !this.menu && (this.heldW || this.hud.driveHeld) ? 1 : 0, this.partsTyping.active);
    if ((s.cash !== cash || s.partsStock !== stock) && !this.save.write(s) && before) this.replaceState(before);
    this.repair.tick(dt); this.partsTyping.tick(dt);
    this.personalCar.sync(s);
    if (M.updatePersonalTravel(s, logicalPoint(this.driving.player.mesh.position), !this.driving.isDriving)) this.flush();
    const riding = !!s.personal?.route;
    if (riding !== this.riding) {
      this.riding = riding; this.driving.player.setSeated(riding); this.driving.setControlsEnabled(!riding && !this.menu, riding || this.menu);
      if (!riding && s.personal) this.driving.placePlayer(worldPoint([s.personal.pos[0] + 3, s.personal.pos[1] + 1], 6));
    }
    if (riding && s.personal) {
      const center = worldPoint(s.personal.pos);
      this.driving.player.mesh.position.copy(center);
      this.camera.position.lerp(center.clone().add(new Vector3(8, 24, 36)), 1 - Math.exp(-6 * dt)); this.camera.lookAt(center);
    }
    if (s.car?.status === 'discovery') {
      this.revealTime += dt; this.driving.setControlsEnabled(false, true);
      if (this.revealTime > 5) { this.dispatch({ type: 'Discover' }); this.revealTime = 0; this.driving.setControlsEnabled(!this.menu, this.menu); }
    }
    if (this.pendingWalk && !this.driving.walkingToTarget) {
      const g = this.pendingWalk; this.pendingWalk = undefined;
      if (g.point && this.driving.player.mesh.position.distanceTo(worldPoint(g.point, 6)) < 13) this.activate(g);
    }
    if (!this.menu && !this.driving.isDriving && !riding) {
      const pos = this.driving.player.mesh.position, logical = logicalPoint(pos), pad = nearestPad(s, logical);
      if (pad && Math.abs(worldPoint(pad.pos, pad.sourcePosition[1]).y - (pos.y - 3.6)) < 1.5 && Math.abs(logical[0] - pad.pos[0]) < 1 && Math.abs(logical[1] - pad.pos[1]) < 1) {
        // Retry only after leaving a pad, like HubServer's padContact debounce.
        if (this.contactPad !== pad.id) { this.contactPad = pad.id; this.dispatch({ type: 'Pad', id: pad.id }); }
      } else this.contactPad = undefined;
      const g = guidance(s), near = g.point && pos.distanceTo(worldPoint(g.point, 6)) < 22;
      const nearParts = partsUnlocked(s) && Math.hypot(logical[0] - PARTS_POSITION[0], logical[1] - PARTS_POSITION[1]) < 5;
      const text = nearParts ? partsAutomated(s) ? 'Automated parts sales' : '[ E ] Sell car part'
        : pad ? `[ E ] ${pad.name} · ${pad.cost ? money(pad.cost) : 'FREE'}\nCategory: ${s.journey ? pad.category : legacyPadCategory(pad.name)}`
        : near ? `[ E ] ${g.label}` : g.kind === 'photo' && s.car && pos.distanceTo(worldPoint(s.car.pos, 6)) < 25 ? '[ E ] Prepare for sale' : '';
      const anchorPoint = nearParts ? PARTS_POSITION : pad?.pos ?? guidanceAnchor(s, g);
      if (text && anchorPoint) {
        const anchor = worldPoint(anchorPoint, 12).project(this.camera);
        this.hud.showHint(anchor.z < -1 || anchor.z > 1 || Math.abs(anchor.x) > 1 || Math.abs(anchor.y) > 1 ? '' : text,
          { x: (anchor.x + 1) * window.innerWidth / 2, y: (1 - anchor.y) * window.innerHeight / 2 });
      } else this.hud.showHint('');
    } else this.hud.showHint('');
    this.actors.sync(s, this.driving.player.mesh.position, this.hud.draft, !this.menu && !riding);
    this.partsWorld.tick(s, this.driving.player.mesh.position, !this.menu && !riding && !this.driving.isDriving);
    const playerAnchor = this.driving.player.mesh.position.clone().add(new Vector3(0, 8, 0)).project(this.camera);
    const playerScreen = playerAnchor.z >= -1 && playerAnchor.z <= 1 && Math.abs(playerAnchor.x) <= 1 && Math.abs(playerAnchor.y) <= 1
      ? { x: (playerAnchor.x + 1) * window.innerWidth / 2, y: (1 - playerAnchor.y) * window.innerHeight / 2 } : undefined;
    this.hud.showSellingProgress(this.partsTyping.active ? 1 - (s.parts?.remaining ?? 0) / PARTS_SECONDS : undefined, playerScreen);
    this.hud.setCashOrigin(playerScreen);
    this.hud.update(dt);
    const travel = guidance(s);
    if (travel.kind === 'drive' && travel.point && !this.menu) {
      const goal = worldPoint(travel.point, 10), distance = Math.round(goal.distanceTo(this.driving.focusPosition) * METERS_PER_UNIT);
      const projection = goal.project(this.camera);
      const x = Math.max(100, Math.min(window.innerWidth - 100, (projection.x + 1) * window.innerWidth / 2));
      const y = Math.max(120, Math.min(window.innerHeight - 100, (1 - projection.y) * window.innerHeight / 2));
      this.hud.showDestination(`${projection.z > 1 ? 'Turn around · ' : '◆ '}${s.lead?.status === 'visiting' ? 'Elias’s garage' : 'Dealership'} · ${distance} m`, x, y);
    } else this.hud.showDestination('');
    if (s.worker.jobs > this.previousJobs) this.ping(850); this.previousJobs = s.worker.jobs;
    this.saveTimer += dt; if (this.saveTimer >= 5) { this.saveTimer = 0; this.flush(); }
  }
  private contactPad?: string;
  private async initReview() {
    this.hud.root.hidden = true; this.actors.root.visible = false; this.driving.setControlsEnabled(false, true);
    this.reviewUI = document.createElement('div'); this.reviewUI.className = 'tycoon-review'; document.body.append(this.reviewUI);
    const response = await fetch(assetUrl(`${this.baseUrl}tycoon/journey.json`)); if (!response.ok) throw new Error('Journey catalog unavailable');
    const data = await response.json() as { Entries: JourneyEntry[] };
    if (this.disposed) return;
    const render = () => {
      const n = this.reviewStep!, entry = data.Entries[n - 1]; this.reviewUI!.replaceChildren();
      const title = document.createElement('strong'); title.textContent = `${n} / 240 · ${entry?.chapter ?? 'UNCLAIMED'} · ${entry?.title ?? 'Unclaimed ground'}`;
      const text = document.createElement('p'); text.textContent = entry?.delta ?? 'The supported parcel before the first purchase.';
      this.reviewUI!.append(title, text);
      for (const [label, step] of [['Previous', n - 1], ['Birth', 24], ['Working', 64], ['Dedicated', 140], ['Professional', 196], ['Institution', 240], ['Next', n + 1]] as [string, number][]) {
        const b = document.createElement('button'); b.textContent = label; b.disabled = step < 0 || step > 240;
        b.onclick = () => { this.reviewStep = step; this.syncEnvironment(); render(); }; this.reviewUI!.append(b);
      }
      const play = document.createElement('a'); play.href = location.pathname; play.textContent = 'Play dealership'; this.reviewUI!.append(play);
      this.camera.up.set(0, 1, 0); this.camera.fov = 65; this.camera.updateProjectionMatrix();
      if (n <= 24) { this.camera.position.copy(worldPoint([38, -32], 110)); this.camera.lookAt(worldPoint([8, 0], 2)); }
      else { const center = LOT_ORIGIN.clone().add(new Vector3(70, 0, 155)); this.camera.position.copy(center).add(new Vector3(210, 300, -280)); this.camera.lookAt(center); }
    };
    render();
  }
  resetSave(): boolean {
    if (!this.save.reset()) return false;
    this.suspended = true; this.blur(); this.driving.setControlsEnabled(false, true);
    return true;
  }
  dispose() {
    if (this.disposed) return;
    this.disposed = true;
    this.personalCar.sync(this.state);
    if (!this.suspended && this.reviewStep === undefined) this.save.release(this.state);
    this.driving.onInteract = undefined; this.driving.onFootSpawn = undefined;
    this.driving.setTycoonObstacles(this.obstacles, []); this.driving.setControlsEnabled(true); if (this.riding) this.driving.player.setSeated(false);
    this.driving.setTycoonObstacles(this.staticObstacles, []); this.staticBodies.forEach(body => this.driving.physics.world.removeBody(body));
    window.removeEventListener('keydown', this.keyDown); window.removeEventListener('keyup', this.keyUp); window.removeEventListener('blur', this.blur);
    window.removeEventListener('pagehide', this.suspend); window.removeEventListener('pageshow', this.resume); document.removeEventListener('visibilitychange', this.visibility);
    this.partsTyping.dispose(); this.repair.dispose(); this.hud.dispose(); this.showroom.dispose(); this.personalCar.dispose(); this.partsWorld.dispose(); this.actors.dispose(); this.environment.dispose(); this.reviewUI?.remove(); void this.sound?.close();
  }
}
