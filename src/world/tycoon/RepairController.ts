import type { PerspectiveCamera } from 'three';
import type { PlayerController } from '../driving/PlayerController.js';
import { drainProgress, repairProgress, restartOpening, REPAIR_OPEN_SECONDS } from './RepairGame.js';
import { aboveFunnel, bottleTip } from './RepairGeometry.js';
import type { RepairInput, RepairProgress } from './RepairGame.js';
import type { Job, TycoonState } from './types.js';
import { worldPoint } from './TycoonCoordinates.js';
import { lockCameraPose, restoreCameraPose } from '../driving/CameraPoseLock.js';

const icons = {
  wheel: '<svg viewBox="0 0 80 80"><circle cx="40" cy="40" r="35" fill="#233039" stroke="#52616c" stroke-width="5"/><circle cx="40" cy="40" r="22" fill="#bdccd2"/><path d="M40 18v44M18 40h44M24 24l32 32M24 56l32-32" stroke="#546976" stroke-width="6"/><circle cx="40" cy="40" r="8" fill="#dce9eb"/></svg>',
  tool: '<svg viewBox="0 0 100 80"><path d="M12 16h57v28H45l-3 29H24l4-34H12z" fill="#ffc658" stroke="#8c591f" stroke-width="3"/><path d="M69 23h25v12H69" fill="#a9c4cf"/><path d="M31 45h13v19H31" fill="#263e49"/></svg>',
  bottle: '<svg viewBox="0 0 70 90"><path d="M43 5h18v17H43z" fill="#52606c"/><ellipse cx="52" cy="5" rx="9" ry="2" fill="#142a34"/><path d="M25 21h33l4 57H9V37z" fill="#ecb84c" stroke="#9a6626" stroke-width="3"/><path d="M22 31h15v15H22z" fill="#172e3c"/><path d="M42 46q-15 18 0 20q15-2 0-20" fill="#795326"/></svg>',
  filter: '<svg viewBox="0 0 110 75" aria-hidden="true"><rect x="6" y="9" width="98" height="57" rx="9" fill="currentColor" stroke="#c6e2e9" stroke-width="4"/><path d="M20 17v41m12-41v41m12-41v41m12-41v41m12-41v41m12-41v41m12-41v41" stroke="#122c3a" stroke-width="5"/></svg>',
  plug: '<svg viewBox="0 0 50 100" aria-hidden="true"><path d="M21 3h8v12h-8z" fill="#d7e6ed"/><path d="M17 15h16v43H17z" fill="currentColor"/><path d="M15 22h20m-20 9h20m-20 9h20" stroke="#ffffff99" stroke-width="4"/><path d="M13 55h24v14H13zM18 69h14v22H18z" fill="#b7c5cf"/><path d="M18 74h14m-14 6h14m-14 6h14" stroke="#476071" stroke-width="2"/><path d="M25 91v6h9v-7" fill="none" stroke="currentColor" stroke-width="4"/></svg>',
  oilFilter: '<svg viewBox="0 0 64 84" aria-hidden="true"><path d="M6 12v59c0 12 52 12 52 0V12" fill="#f5f8fa" stroke="#a8b9c3" stroke-width="2"/><ellipse cx="32" cy="12" rx="26" ry="9" fill="#fff" stroke="#a8b9c3" stroke-width="2"/><ellipse cx="32" cy="12" rx="7" ry="3" fill="#748b98"/><path d="M15 30v34M49 30v34" stroke="#d4dfe5" stroke-width="3"/><path d="M22 46h20M22 52h20" stroke="#638a9c" stroke-width="3"/></svg>',
};
const titles = { wheels: 'Fit & fasten', engine: 'Fresh oil, fresh start', tuning: 'Build better performance', body: 'Restore the body', wash: 'Wash away the road', paint: 'A fresh finish', detail: 'Final inspection', photo: 'Frame the listing' };
const instructions = { wheels: 'Place four wheels on the hubs. Click all seven bolts on each wheel.', engine: 'Remove the drain bolt and let the oil drain. Remove the dark used filter, then fit a new white filter.', tuning: 'Remove the old air filter and four spark plugs. Select an upgrade below, then fit it into the matching empty socket.', body: 'Tap each dent to straighten the panel.', wash: 'Wipe each dirty area with the sponge.', paint: 'Apply a coat to each highlighted panel.', detail: 'Inspect and polish each marked area.', photo: 'Capture each of the six marked views.' };

/** DOM repair workbench; the world stays visible during the two-second opening pose. */
export class RepairController {
  private readonly root = document.createElement('section');
  private current?: Job;
  private opening = 0;
  private built = false;
  private held = false;
  private touch = false;
  private cursor = { x: 50, y: 25 };
  private previousFocus?: HTMLElement;
  private tool?: HTMLElement;
  private carry?: HTMLElement;
  private stream?: HTMLElement;
  private meter?: HTMLElement;
  private board?: HTMLElement;
  private tilt = 0;
  private drain?: HTMLElement;
  private funnel?: HTMLElement;
  private tuningPart?: 'filter' | 'plug';
  private holdingOilFilter = false;
  private releaseCamera?: () => void;
  private feedbackParticles: { node: HTMLElement; age: number }[] = [];
  private lastPourEffect = -Infinity;
  constructor(private state: TycoonState, private player: PlayerController, private camera: PerspectiveCamera,
    private submit: (input: RepairInput) => boolean, private setMenu: (open: boolean) => void) {
    this.root.className = 'repair-overlay'; this.root.hidden = true; this.root.setAttribute('role', 'dialog'); this.root.setAttribute('aria-modal', 'true');
    this.root.setAttribute('aria-label', 'Car repair workbench'); document.body.append(this.root);
    window.addEventListener('keydown', this.key, true); window.addEventListener('blur', this.release);
  }
  get active() { return !!this.current; }
  objectiveTarget() {
    if (!this.current || !this.built) return undefined;
    const g = repairProgress(this.current, this.state.clock);
    const pick = (attribute: string, index: number) => Array.from(this.root.querySelectorAll<HTMLElement>(`[data-${attribute}]`)).find(el => Number(el.dataset[attribute]) === index);
    let element: HTMLElement | undefined | null, label = '';
    if (g.kind === 'wheels') {
      const wheel = g.wheels.findIndex(done => !done), bolt = g.bolts.findIndex(done => !done);
      element = wheel >= 0 ? pick('wheel', wheel) : pick('bolt', bolt); label = wheel >= 0 ? 'Fit this wheel' : 'Fasten this bolt';
    } else if (g.kind === 'engine') {
      if (!g.bolts[0]) { element = pick('bolt', 0); label = 'Remove the drain bolt'; }
      else if (drainProgress(g, this.state.clock) < 1) return undefined;
      else if (!g.bolts[1]) { element = pick('bolt', 1); label = 'Remove the used filter'; }
      else if (!g.filterInstalled) { element = this.root.querySelector<HTMLElement>(this.holdingOilFilter ? '.repair-filter-socket' : '.repair-new-filter'); label = this.holdingOilFilter ? 'Fit the new filter' : 'Pick up a new filter'; }
      else { element = this.funnel; label = 'Hold the bottle over the funnel'; }
    } else if (g.kind === 'tuning') {
      const index = g.targets.findIndex(done => !done), part = index === 0 ? 'filter' : 'plug';
      if (index < 0) return undefined;
      if (!g.bolts[index] || this.tuningPart === part) { element = pick('component', index); label = !g.bolts[index] ? 'Remove this part' : 'Install the upgrade'; }
      else { element = Array.from(this.root.querySelectorAll<HTMLElement>('[data-upgrade]')).find(el => el.dataset.upgrade === part); label = 'Select this upgrade'; }
    } else { element = pick('target', g.targets.findIndex(done => !done)); label = 'Repair this area'; }
    return element ? { element, label } : undefined;
  }
  begin(job: Job) {
    if (this.current || !job.manual) return;
    this.releaseCamera = lockCameraPose(this.camera);
    this.current = job; restartOpening(job, this.state.clock); this.opening = 0; this.built = false;
    this.previousFocus = document.activeElement as HTMLElement;
    if (document.pointerLockElement) document.exitPointerLock();
    this.setMenu(true); this.player.body.velocity.setZero();
    const car = this.state.car!;
    const center = worldPoint(car.pos, 4), offset = this.player.mesh.position.clone().sub(center); offset.y = 0;
    if (offset.lengthSq() < 1) offset.set(0, 0, 1);
    this.player.mesh.rotation.y = Math.atan2(offset.x, offset.z);
    this.root.hidden = true; this.root.replaceChildren(); this.tilt = 0; this.tuningPart = undefined; this.holdingOilFilter = false;
  }
  private key = (e: KeyboardEvent) => {
    if (!this.active) return;
    if (e.code === 'Escape') { e.preventDefault(); e.stopImmediatePropagation(); this.close(); }
    if (e.code === 'KeyP' || e.code === 'Enter') { e.preventDefault(); e.stopImmediatePropagation(); }
    if (e.key === 'Tab' && this.built) {
      const nodes = Array.from(this.root.querySelectorAll<HTMLButtonElement>('button:not(:disabled)'));
      const first = nodes[0], last = nodes[nodes.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus(); }
      if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus(); }
    }
  };
  private release = () => { this.held = false; };
  private send(input: RepairInput) {
    const ok = this.submit(input);
    if (!ok || !this.board || !this.built) return ok;
    if (input.kind === 'pour' && this.state.clock - this.lastPourEffect < .25) return ok;
    if (input.kind === 'pour') this.lastPourEffect = this.state.clock;
    const kind = this.current?.repair?.kind;
    const selector = input.kind === 'target' ? `[data-target="${input.index}"]` : input.kind === 'bolt' ? `[data-bolt="${input.index}"]`
      : input.kind === 'wheel' ? `[data-wheel="${input.index}"]` : input.kind === 'remove' || input.kind === 'install' ? `[data-component="${input.index}"]`
      : input.kind === 'oil-filter' ? '.repair-filter-socket' : '.repair-funnel';
    const target = this.board.querySelector<HTMLElement>(selector), bounds = this.board.getBoundingClientRect(), hit = target?.getBoundingClientRect();
    const x = hit ? hit.left + hit.width / 2 - bounds.left : bounds.width / 2;
    const y = hit ? hit.top + hit.height / 2 - bounds.top : bounds.height / 2;
    const color = input.kind === 'pour' ? '#efb846' : kind === 'wash' || kind === 'paint' || kind === 'detail' ? '#92e9ff' : kind === 'photo' ? '#ffffff' : '#ffd277';
    for (let i = 0; i < 9 && this.feedbackParticles.length < 54; i++) {
      const node = document.createElement('i'), angle = i / 9 * Math.PI * 2, reach = 18 + Math.random() * 28;
      node.className = 'repair-feedback-particle'; node.setAttribute('aria-hidden', 'true');
      node.style.left = x + 'px'; node.style.top = y + 'px'; node.style.background = color;
      node.style.setProperty('--particle-x', Math.cos(angle) * reach + 'px'); node.style.setProperty('--particle-y', Math.sin(angle) * reach + 12 + 'px');
      this.board.append(node); this.feedbackParticles.push({ node, age: 0 });
    }
    return ok;
  }
  tick(dt: number) {
    this.feedbackParticles = this.feedbackParticles.filter(p => { p.age += Math.max(0, Math.min(.1, dt)); if (p.age < .6) return true; p.node.remove(); return false; });
    const j = this.current; if (!j) return;
    restoreCameraPose(this.camera);
    if (j.done || !j.manual || !this.state.car?.plan?.jobs.includes(j)) { this.close(); return; }
    const g = repairProgress(j, this.state.clock);
    if (!this.built) {
      this.opening = Math.min(REPAIR_OPEN_SECONDS, this.opening + dt);
      this.player.openingProgress = this.opening / REPAIR_OPEN_SECONDS;
      if (this.opening >= REPAIR_OPEN_SECONDS) { this.player.openingProgress = undefined; this.build(g); }
      return;
    }
    const filling = g.kind === 'engine' && g.filterInstalled && g.bolts.every(Boolean) && drainProgress(g, this.state.clock) >= 1;
    const board = this.board!.getBoundingClientRect(), funnel = this.funnel?.getBoundingClientRect();
    const x = this.cursor.x * board.width / 100, y = this.cursor.y * board.height / 100;
    const opening = funnel && { left: funnel.left - board.left, top: funnel.top - board.top, width: funnel.width, height: funnel.height };
    const over = !!opening && aboveFunnel(bottleTip(x, y, 45), opening);
    const pouring = filling && this.held && (!this.touch || over);
    this.tilt += Math.max(-dt * 300, Math.min(dt * 300, (pouring ? 45 : 0) - this.tilt));
    this.carry!.classList.toggle('tipped', this.tilt > 0);
    const flowing = pouring && this.tilt >= 40;
    this.stream!.hidden = !flowing;
    const tip = bottleTip(x, y, this.tilt), caught = !!opening && aboveFunnel(tip, opening);
    this.stream!.style.left = tip.x + 'px'; this.stream!.style.top = tip.y + 'px';
    this.stream!.style.height = Math.max(0, (caught ? opening!.top : board.height) - tip.y) + 'px';
    if (flowing && caught && dt > 0) this.send({ kind: 'pour', amount: Math.min(.06, dt / 2.5) });
    this.refresh(g);
    if (g.complete) this.close();
  }
  private build(g: RepairProgress) {
    this.built = true; this.root.hidden = false;
    this.root.innerHTML = `<div class="repair-workbench"><header><div><span class="repair-eyebrow">HANDS-ON SERVICE</span><h2>${titles[g.kind]}</h2></div><button class="repair-close" aria-label="Close repair">×</button></header><p class="repair-instruction">${instructions[g.kind]}</p><div class="repair-board ${g.kind}"></div><footer><span class="repair-status" aria-live="polite"></span><progress max="1" value="0"></progress></footer></div>`;
    this.root.querySelector<HTMLButtonElement>('.repair-close')!.onclick = () => this.close();
    this.board = this.root.querySelector('.repair-board')!;
    if (g.kind === 'wheels') {
      ['FRONT LEFT', 'FRONT RIGHT', 'REAR LEFT', 'REAR RIGHT'].forEach((label, wheel) => {
        const hub = document.createElement('div'); hub.className = 'repair-hub';
        hub.innerHTML = `<small>${label}</small><button class="repair-wheel" data-wheel="${wheel}" aria-label="Place ${label.toLowerCase()} wheel">${icons.wheel}<span>+ FIT WHEEL</span></button>`;
        const face = hub.querySelector<HTMLButtonElement>('button')!; face.onclick = () => { this.send({ kind: 'wheel', index: wheel }); this.refresh(g); };
        for (let bolt = 0; bolt < 7; bolt++) {
          const angle = bolt / 7 * Math.PI * 2, index = wheel * 7 + bolt;
          const button = this.bolt(index, `${label} bolt ${bolt + 1}`, g);
          button.style.left = 50 + Math.sin(angle) * 24 + '%'; button.style.top = 53 + Math.cos(angle) * 24 + '%'; hub.append(button);
        }
        this.board!.append(hub);
      });
    } else if (g.kind === 'engine') {
      this.board.innerHTML = '<div class="repair-engine"><div class="engine-ribs"></div><span>ENGINE · OIL SERVICE</span></div><div class="repair-funnel" aria-label="Oil funnel"><svg viewBox="0 0 100 100" preserveAspectRatio="none"><path d="M0 0H100L60 58V100H40V58Z" fill="#f4aa37"/><path d="M0 0H100V8H0Z" fill="#ffd574"/></svg><small>OIL FILL</small></div><div class="repair-drain"><i></i><i></i><i></i></div>';
      this.funnel = this.board.querySelector('.repair-funnel')!; this.drain = this.board.querySelector('.repair-drain')!;
      for (let i = 0; i < 2; i++) { const b = this.bolt(i, i === 1 ? 'Remove used oil filter' : 'Remove central drain bolt', g); b.style.left = (i === 0 ? 50 : 76) + '%'; b.style.top = (i === 0 ? 50 : 55) + '%'; if (i === 1) { b.classList.add('filter', 'used-filter'); b.textContent = 'USED FILTER'; } this.board.append(b); }
      const replacement = document.createElement('button'); replacement.className = 'repair-new-filter';
      replacement.innerHTML = icons.oilFilter + '<span>PICK UP NEW FILTER</span>'; replacement.setAttribute('aria-label', 'Pick up new oil filter');
      replacement.onclick = () => { this.holdingOilFilter = true; this.tool!.hidden = true; this.refresh(g); };
      const socket = document.createElement('button'); socket.className = 'repair-filter-socket'; socket.setAttribute('aria-label', 'Install new oil filter');
      socket.innerHTML = icons.oilFilter + '<span>FIT NEW FILTER</span>';
      socket.onclick = () => { if (this.holdingOilFilter && this.send({ kind: 'oil-filter' })) this.holdingOilFilter = false; this.refresh(g); };
      this.board.append(replacement, socket);
    } else if (g.kind === 'tuning') {
      for (let index = 0; index < 5; index++) {
        const part = index === 0 ? 'filter' : 'plug', button = document.createElement('button');
        button.className = `tuning-component tuning-${part}`; button.dataset.component = String(index);
        button.style.left = (index === 0 ? 50 : index * 20) + '%';
        button.innerHTML = `${icons[part]}<span></span>`;
        button.onclick = () => {
          if (!g.bolts[index]) {
            if (this.send({ kind: 'remove', index })) this.showTool(button);
          } else if (!g.targets[index]) {
            if (!this.tuningPart || !this.send({ kind: 'install', index, part: this.tuningPart })) {
              this.root.querySelector('.repair-instruction')!.textContent = `Select ${index === 0 ? 'the high-flow filter' : 'an iridium spark plug'} below, then click this empty socket.`;
            } else this.tool!.hidden = true;
          }
          this.refresh(g);
        };
        this.board.append(button);
      }
      const tray = document.createElement('div'); tray.className = 'tuning-tray';
      for (const part of ['filter', 'plug'] as const) {
        const button = document.createElement('button'); button.dataset.upgrade = part;
        button.innerHTML = `${icons[part]}<span>${part === 'filter' ? 'High-flow filter' : 'Iridium plugs'}</span>`;
        button.onclick = () => { this.tuningPart = part; this.tool!.hidden = true; this.root.querySelector('.repair-instruction')!.textContent = `Fit the ${part === 'filter' ? 'blue high-flow filter' : 'gold iridium plug'} into a matching empty socket.`; this.refresh(g); };
        tray.append(button);
      }
      this.board.append(tray);
    } else {
      this.board.innerHTML = '<div class="repair-car-outline"></div>';
      for (let i = 0; i < 6; i++) {
        const b = document.createElement('button'); b.className = 'repair-target'; b.dataset.target = String(i);
        b.style.left = 25 + i % 3 * 25 + '%'; b.style.top = 30 + Math.floor(i / 3) * 38 + '%';
        b.textContent = ({ body: '⌁', wash: '◌', paint: '▧', detail: '✧', photo: '▣' } as Record<string, string>)[g.kind];
        b.setAttribute('aria-label', `${g.kind} area ${i + 1}`); b.onclick = () => { this.send({ kind: 'target', index: i }); this.refresh(g); }; this.board.append(b);
      }
    }
    this.tool = document.createElement('div'); this.tool.className = 'repair-tool'; this.tool.innerHTML = icons.tool; this.tool.hidden = true;
    this.carry = document.createElement('div'); this.carry.className = 'repair-carry';
    this.stream = document.createElement('div'); this.stream.className = 'repair-oil'; this.stream.hidden = true;
    this.board.append(this.stream, this.tool, this.carry); this.meter = this.root.querySelector('.repair-status')!;
    const point = (e: PointerEvent) => { const r = this.board!.getBoundingClientRect(); this.cursor = { x: (e.clientX - r.left) / r.width * 100, y: (e.clientY - r.top) / r.height * 100 }; this.touch = e.pointerType === 'touch'; this.positionCursor(); };
    this.board.onpointermove = point;
    this.board.onpointerdown = e => { point(e); this.held = true; if (g.kind === 'engine' && g.filterInstalled) this.board!.setPointerCapture(e.pointerId); };
    this.board.onpointerup = this.board.onpointercancel = () => { this.held = false; };
    this.board.onpointerleave = () => { if (!this.touch) this.held = false; };
    this.refresh(g); this.root.querySelector<HTMLButtonElement>('.repair-close')!.focus();
  }
  private bolt(index: number, label: string, g: RepairProgress) {
    const button = document.createElement('button'); button.className = 'repair-bolt'; button.dataset.bolt = String(index); button.textContent = '⬡'; button.setAttribute('aria-label', label);
    button.onclick = () => {
      if (!this.send({ kind: 'bolt', index })) return;
      this.showTool(button);
      this.refresh(g);
    };
    return button;
  }
  private showTool(button: HTMLElement) {
    const r = button.getBoundingClientRect(), board = this.board!.getBoundingClientRect();
    this.tool!.hidden = false; this.tool!.style.left = r.left + r.width / 2 - board.left + 'px'; this.tool!.style.top = r.top + r.height / 2 - board.top + 'px';
  }
  private positionCursor() {
    if (!this.carry || !this.stream) return;
    this.carry.style.left = this.cursor.x + '%'; this.carry.style.top = this.cursor.y + '%';
    this.carry.style.transform = `translate(-50%, -50%) rotate(${this.tilt}deg)`;
  }
  private refresh(g: RepairProgress) {
    if (!this.built) return;
    this.root.querySelectorAll<HTMLButtonElement>('[data-wheel]').forEach(b => { const placed = g.wheels[Number(b.dataset.wheel)]; b.classList.toggle('fitted', placed); b.disabled = placed; });
    const drained = drainProgress(g, this.state.clock);
    this.root.querySelectorAll<HTMLButtonElement>('[data-bolt]').forEach(b => { const i = Number(b.dataset.bolt), done = g.bolts[i]; b.classList.toggle('done', done); b.disabled = done || (g.kind === 'wheels' ? !g.wheels[Math.floor(i / 7)] : i === 1 && drained < 1); if (g.kind === 'engine') b.hidden = done; });
    this.root.querySelectorAll<HTMLButtonElement>('[data-target]').forEach(b => { b.disabled = g.targets[Number(b.dataset.target)]; b.classList.toggle('done', b.disabled); });
    if (g.kind === 'tuning') {
      this.root.querySelectorAll<HTMLButtonElement>('[data-component]').forEach(b => {
        const i = Number(b.dataset.component), installed = g.targets[i], removed = g.bolts[i];
        b.disabled = installed; b.classList.toggle('upgraded', installed); b.classList.toggle('empty', removed && !installed);
        const name = i === 0 ? 'air filter' : `spark plug ${i}`;
        b.setAttribute('aria-label', `${installed ? 'Upgraded' : removed ? 'Install upgraded' : 'Remove old'} ${name}`);
        b.querySelector('span')!.textContent = installed ? i === 0 ? 'HIGH-FLOW' : 'IRIDIUM' : removed ? 'EMPTY SOCKET' : i === 0 ? 'OLD AIR FILTER' : `OLD PLUG ${i}`;
      });
      if (this.tuningPart && (this.tuningPart === 'filter' ? g.targets[0] : g.targets.slice(1).every(Boolean))) this.tuningPart = undefined;
      this.root.querySelectorAll<HTMLButtonElement>('[data-upgrade]').forEach(b => {
        b.disabled = b.dataset.upgrade === 'filter' ? g.targets[0] : g.targets.slice(1).every(Boolean);
        const selected = this.tuningPart === b.dataset.upgrade; b.classList.toggle('selected', selected); b.setAttribute('aria-pressed', String(selected));
      });
    }
    const carry = g.kind === 'wheels' && !g.wheels.every(Boolean) ? 'wheel' : g.kind === 'engine' && g.filterInstalled ? 'bottle' : g.kind === 'engine' && this.holdingOilFilter ? 'oilFilter' : g.kind === 'tuning' ? this.tuningPart ?? '' : '';
    if (g.kind === 'engine') {
      this.drain!.hidden = !g.bolts[0] || drained >= 1;
      this.drain!.style.opacity = String(1 - drained * .65);
      this.funnel!.hidden = carry !== 'bottle'; this.board!.classList.toggle('oil-fill', carry === 'bottle');
      const replacement = this.board!.querySelector<HTMLButtonElement>('.repair-new-filter')!, socket = this.board!.querySelector<HTMLButtonElement>('.repair-filter-socket')!;
      replacement.hidden = !g.bolts[1] || !!g.filterInstalled; replacement.classList.toggle('selected', this.holdingOilFilter);
      replacement.setAttribute('aria-pressed', String(this.holdingOilFilter));
      socket.hidden = !g.bolts[1]; socket.disabled = !!g.filterInstalled; socket.classList.toggle('installed', !!g.filterInstalled);
      socket.querySelector('span')!.textContent = g.filterInstalled ? 'NEW FILTER FITTED' : 'FIT NEW FILTER';
      if (carry === 'bottle') this.tool!.hidden = true;
      if (g.bolts[0] && drained < 1) this.root.querySelector('.repair-instruction')!.textContent = 'Old oil is draining…';
      else if (g.bolts[0] && !g.bolts[1]) this.root.querySelector('.repair-instruction')!.textContent = 'Drained. Remove the dark used oil filter.';
      else if (g.bolts[1] && !g.filterInstalled) this.root.querySelector('.repair-instruction')!.textContent = this.holdingOilFilter ? 'Click the empty filter socket to fit the new white filter.' : 'Pick up the new white filter, then fit it into the empty socket.';
    }
    this.carry!.hidden = !carry; this.board!.classList.toggle('carrying', !!carry);
    this.carry!.classList.toggle('tuning-upgrade', g.kind === 'tuning');
    if (this.carry!.dataset.icon !== carry) { this.carry!.dataset.icon = carry; this.carry!.innerHTML = carry ? icons[carry] : ''; }
    if (carry === 'bottle') this.root.querySelector('.repair-instruction')!.textContent = 'Bring the bottle tip above the funnel and hold to pour. Touch: drag into position to tip automatically.';
    this.meter!.textContent = Math.round(this.current!.progress * 100) + '% COMPLETE' + (carry === 'bottle' ? ' · Oil ' + Math.round(g.oil * 100) + '%' : '');
    this.root.querySelector('progress')!.value = this.current!.progress; this.positionCursor();
  }
  close() {
    this.feedbackParticles.forEach(p => p.node.remove()); this.feedbackParticles = []; this.lastPourEffect = -Infinity;
    this.current = undefined; this.held = false; this.player.openingProgress = undefined; this.root.hidden = true; this.root.replaceChildren(); this.setMenu(false); this.previousFocus?.focus();
    this.releaseCamera?.(); this.releaseCamera = undefined;
  }
  dispose() { if (this.active) this.close(); window.removeEventListener('keydown', this.key, true); window.removeEventListener('blur', this.release); this.root.remove(); }
}
