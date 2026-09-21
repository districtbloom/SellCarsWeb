import * as M from './TycoonModel.js';
import { workOrderRange } from './RepairWorkOrders.js';
import { catalog } from './catalog.js';
import { guidance, money } from './TycoonGuidance.js';
import { entries, milestones, departments, nextEntry } from './FullJourneyCatalog.js';
import { purchaseGate, purchasePad, cosmeticPads } from './FullJourney.js';
import { offlineRate, offlineUnlocked, revenuePerMinute } from './OfflineEarnings.js';
import { PARTS_POSITION, PARTS_MAX_LEVEL, partsUnlocked, partsPayout, partsUpgradeCost, partsAutomated } from './PartsStation.js';
import type { Guidance } from './TycoonGuidance.js';
import type { Action, ActionResult } from './TycoonSession.js';
import { RESET_AND_CLOSE_SHORTCUT } from '../systems/resetAndClose.js';
import { garageUnlocked, garageVehicles, GARAGE_PAINTS, personalCars, personalCarOption, personalModel } from './PersonalCars.js';
import type { PersonalCarOption } from './PersonalCars.js';
import type { Depth, Look, OfflineReceipt, Receipt, TycoonState } from './types.js';
import type { WebGLRenderer } from 'three';
import { renderGuideAvatar } from './GuideAvatar.js';
import { repairCost } from './PartsEconomy.js';
import { Smartphone } from './Smartphone.js';
import { CashGainEffects } from './CashGainEffects.js';
import { padColor } from './PurchaseCategories.js';
import './phone.css';

type Panel = 'world' | 'deal' | 'build' | 'prepare' | 'custom' | 'worker' | 'phone' | 'call' | 'journal' | 'wallet' | 'result' | 'complete' | 'personal' | 'collection' | 'journey' | 'offline' | 'index' | 'parts' | 'cosmetics';
export interface HUDHost {
  state: TycoonState; dispatch(action: Action): ActionResult; navigate(target: Guidance): void; setMenu(open: boolean): void; saveStatus(): string;
  offline?(): OfflineReceipt | undefined; dismissOffline?(): void;
  cars?: readonly PersonalCarOption[]; previewCar?(id?: number, paint?: string): void; canChangeCar?(): boolean; goToCar?(): void;
}
function element<K extends keyof HTMLElementTagNameMap>(tag: K, className?: string, text?: string) {
  const node = document.createElement(tag); if (className) node.className = className; if (text) node.textContent = text; return node;
}
export class TycoonHUD {
  readonly root = element('section', 'tycoon-ui');
  private readonly top = element('div', 'tycoon-top');
  private readonly wallet = element('button', 'tycoon-wallet');
  private readonly gains: CashGainEffects;
  private ledgerLength: number;
  private readonly sellingProgress = element('div', 'tycoon-selling-progress');
  private readonly sellingFill = element('div', 'tycoon-selling-fill');
  private readonly stock = element('span', 'tycoon-stock');
  private readonly stockCount = element('span');
  private readonly phone = element('button', 'tycoon-phone', 'Phone');
  private readonly smartphone: Smartphone;
  private readonly building = element('button', 'tycoon-phone', 'Build');
  private readonly garage = element('button', 'tycoon-phone', 'Garage');
  private readonly guide = element('div', 'tycoon-guide');
  private readonly guideAvatar = element('canvas', 'tycoon-guide-avatar');
  private avatarRendered = false;
  private readonly words = element('p');
  private readonly next = element('button');
  private readonly panel = element('section', 'tycoon-panel');
  private readonly header = element('div', 'tycoon-panel-header');
  private readonly content = element('div', 'tycoon-panel-content');
  private readonly progress = element('div', 'tycoon-work');
  private readonly toast = element('div', 'tycoon-toast');
  private readonly hint = element('div', 'tycoon-hint');
  private readonly hintAction = element('span');
  private readonly hintCategory = element('span', 'tycoon-hint-category');
  private readonly destination = element('div', 'tycoon-destination');
  private readonly routeDrive = element('button', 'tycoon-route-drive', 'Drive');
  private page: Panel = 'world';
  private tab = 'Home';
  private signature = '';
  private receipt?: Receipt;
  private counterAmount?: number;
  private carIndex = 0;
  private get cars() { return this.host.cars ?? personalCars; }
  draft?: Look;
  driveHeld = false;
  get isOpen() { return this.page !== 'world'; }
  get cameraMode() { return this.page; }
  constructor(private host: HUDHost) {
    this.ledgerLength = host.state.ledger.length;
    this.gains = new CashGainEffects(this.wallet);
    if (host.offline?.()?.amount) this.gains.credit(host.offline()!.amount);
    this.sellingProgress.hidden = true; this.sellingProgress.setAttribute('role', 'progressbar');
    this.sellingProgress.setAttribute('aria-label', 'Selling car parts'); this.sellingProgress.setAttribute('aria-valuemin', '0'); this.sellingProgress.setAttribute('aria-valuemax', '100');
    const sellingTrack = element('div', 'tycoon-selling-track'); sellingTrack.append(this.sellingFill);
    this.sellingProgress.append(element('span', '', 'SELLING CAR PARTS'), sellingTrack); document.body.append(this.sellingProgress);
    this.hint.append(this.hintAction, this.hintCategory); this.hintCategory.hidden = true;
    this.root.setAttribute('aria-label', 'Sell Cars dealership'); this.panel.setAttribute('role', 'dialog'); this.panel.setAttribute('aria-label', 'Dealership panel');
    const title = element('div', 'tycoon-brand', 'SELL CARS'); title.append(element('small', '', 'Your dealership'));
    this.wallet.onclick = () => this.open('wallet'); this.phone.onclick = () => this.togglePhone();
    this.smartphone = new Smartphone(this.root, () => this.answerCall(), () => this.remindCall(), () => { this.smartphone.hide(); this.tab = 'Home'; this.open('phone'); });
    this.building.onclick = () => this.open('journey');
    this.garage.onclick = () => this.open('collection');
    const stockIcon = element('span');
    stockIcon.innerHTML = '<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M9 3h14l7 13-7 13H9L2 16z" fill="#c5d6dc" stroke="#526975" stroke-width="2"/><circle cx="16" cy="16" r="6" fill="#263b47"/></svg>';
    this.stock.append(stockIcon, this.stockCount);
    this.top.append(title, this.wallet, this.stock, this.building, this.garage, this.phone);
    this.next.onclick = () => this.host.navigate(guidance(this.host.state));
    this.guideAvatar.setAttribute('role', 'img'); this.guideAvatar.setAttribute('aria-label', 'Player avatar');
    this.guide.append(this.guideAvatar, this.words, this.next);
    this.panel.append(this.header, this.content); this.root.append(this.top, this.guide, this.panel, this.progress, this.toast, this.hint, this.routeDrive, this.destination);
    this.destination.hidden = true;
    this.routeDrive.onpointerdown = e => { this.driveHeld = true; this.routeDrive.setPointerCapture(e.pointerId); };
    this.routeDrive.onpointerup = this.routeDrive.onpointercancel = () => { this.driveHeld = false; };
    document.body.append(this.root); document.body.classList.add('has-tycoon');
    window.addEventListener('keydown', this.keyDown); window.addEventListener('blur', this.release);
    this.update();
  }
  private release = () => { this.driveHeld = false; };
  renderAvatar(renderer: WebGLRenderer) {
    if (this.avatarRendered || this.root.hidden || this.guide.hidden) return;
    renderGuideAvatar(renderer, this.guideAvatar); this.avatarRendered = true;
  }
  private keyDown = (e: KeyboardEvent) => {
    if (this.root.hidden) return;
    if (e.ctrlKey || e.altKey || e.metaKey || /^(INPUT|TEXTAREA|SELECT)$/.test((e.target as HTMLElement)?.tagName)) return;
    if (['personal', 'collection'].includes(this.page) && !e.repeat && ['ArrowLeft', 'ArrowRight'].includes(e.code)) {
      e.preventDefault(); this.changeCar(e.code === 'ArrowLeft' ? -1 : 1); return;
    }
    if (e.code === 'Escape' && this.isOpen) this.close();
    if (e.code === 'Enter' && !e.repeat && !this.isOpen && this.host.state.lead && ['ringing', 'missed', 'answered'].includes(this.host.state.lead.status)) { e.preventDefault(); this.answerCall(); }
    if (e.code === 'KeyP' && !e.repeat) { if (this.isOpen) this.close(); else this.togglePhone(); }
  };
  togglePhone() { this.smartphone.toggle(); this.update(); }
  private answerCall() { if (this.host.dispatch({ type: 'AnswerCall' }).ok) { this.smartphone.hide(); this.open('call'); } }
  private remindCall() { if (this.host.dispatch({ type: 'RemindCall' }).ok) { this.smartphone.hide(); this.close(); } }
  open(page: Panel) {
    if (document.pointerLockElement) document.exitPointerLock();
    if (page === 'personal' && this.page !== 'personal') this.carIndex = Math.max(0, this.cars.findIndex(car => car.id === personalModel(this.host.state.personal)));
    if (page === 'collection' && this.page !== 'collection') this.carIndex = Math.max(0, garageVehicles(this.host.state).findIndex(car => car.id === this.host.state.personal?.id));
    this.page = page; this.counterAmount = undefined;
    this.draft = page === 'custom' ? M.copy(this.host.state.car?.custom ?? M.originalLook()) : undefined;
    this.host.setMenu(page !== 'world'); this.render();
  }
  close() { if (this.page === 'offline') this.host.dismissOffline?.(); this.page = 'world'; this.draft = undefined; this.host.setMenu(false); this.render(); }
  showResult(result: ActionResult) {
    if (result.receipt) { this.receipt = result.receipt; this.open('result'); }
    else if (result.openDeal) this.open('deal');
  }
  showHint(text: string, screen?: { x: number; y: number }) {
    const [action, category] = text.split('\nCategory: ');
    this.hintAction.textContent = action; this.hintCategory.hidden = category === undefined;
    if (category !== undefined) {
      this.hintCategory.textContent = 'Category: ' + category;
      this.hintCategory.style.color = '#' + padColor(category).toString(16).padStart(6, '0');
    }
    this.hint.hidden = !text;
    this.hint.classList.toggle('world-billboard', !!screen);
    this.hint.style.left = screen ? screen.x + 'px' : '';
    this.hint.style.top = screen ? screen.y + 'px' : '';
  }
  showSellingProgress(progress?: number, screen?: { x: number; y: number }) {
    this.sellingProgress.hidden = progress === undefined || !screen;
    if (progress === undefined || !screen) return;
    const percent = Math.max(0, Math.min(100, progress * 100));
    this.sellingFill.style.width = percent + '%'; this.sellingProgress.setAttribute('aria-valuenow', String(Math.round(percent)));
    this.sellingProgress.style.left = screen.x + 'px'; this.sellingProgress.style.top = screen.y + 'px';
  }
  setCashOrigin(screen?: { x: number; y: number }) { this.gains.setOrigin(screen); }
  showDestination(text: string, x = 0, y = 0) {
    this.destination.hidden = !text || this.isOpen;
    this.destination.textContent = text;
    this.destination.style.left = x + 'px'; this.destination.style.top = y + 'px';
  }
  private action(action: Action, next?: Panel) {
    const result = this.host.dispatch(action); this.showResult(result);
    if (result.ok && next) this.open(next); else this.render();
  }
  private button(label: string, click: () => void, disabled = false, secondary = false) {
    const b = element('button', secondary ? 'secondary' : '', label); b.disabled = disabled; b.onclick = click; this.content.append(b); return b;
  }
  private title(title: string, sub = '') {
    const h = element('div'); h.append(element('h2', '', title), element('p', '', sub));
    const close = element('button', 'tycoon-close', '×'); close.setAttribute('aria-label', 'Close panel'); close.onclick = () => this.close(); this.header.append(h, close);
  }
  private text(text: string, style = '') { const p = element('p', style, text); this.content.append(p); return p; }
  private category(category: string) {
    const label = this.text('Category: ' + category, 'tycoon-category');
    label.style.color = '#' + padColor(category).toString(16).padStart(6, '0');
  }
  private quote(text: string) { this.text(text, 'tycoon-quote'); }
  private offer(type: 'Accept' | 'Counter', amount?: number) {
    const c = this.host.state.car; if (!c?.quote) return;
    this.action({ type, carId: c.id, revision: c.quote.revision, amount: amount ?? c.quote.accepted });
  }
  update(dt = 0) {
    const s = this.host.state, c = s.car, g = guidance(s);
    this.wallet.textContent = money(s.cash);
    for (const entry of s.ledger.slice(this.ledgerLength)) if (entry.amount > 0) this.gains.credit(entry.amount);
    this.ledgerLength = s.ledger.length;
    this.stockCount.textContent = (s.partsStock ?? 40).toLocaleString() + ' Parts';
    this.building.hidden = !s.journey;
    const construction = entries.filter(e => e.category !== 'Cosmetic');
    this.building.textContent = 'Build ' + construction.filter(e => e.step <= (s.journey?.step ?? 0)).length + '/' + construction.length;
    this.phone.textContent = 'Phone [P]'; this.smartphone.update(s, this.isOpen);
    this.words.textContent = g.text; this.next.textContent = g.label; this.next.hidden = !g.label || !!s.personal?.route;
    this.guide.hidden = this.isOpen;
    this.panel.hidden = !this.isOpen;
    this.top.hidden = false; this.top.classList.toggle('wallet-only', this.isOpen);
    this.toast.textContent = (s.noticeUntil ?? 0) > s.clock ? s.notice ?? '' : ''; this.toast.hidden = !this.toast.textContent;
    const j = M.job(s); this.progress.hidden = this.isOpen || c?.status !== 'repair';
    if (c?.status === 'repair' && j) { this.progress.textContent = `${j.name} · ${Math.floor(j.progress * 100)}%${M.staffedJob(s) ? ' · ' + s.worker.activity : ' · [E] Repair'}`; }
    this.routeDrive.hidden = this.isOpen || !s.personal?.route;
    const sig = JSON.stringify([this.page, c?.id, c?.status, c?.quote, s.cash, s.worker.level, s.worker.jobs, s.worker.activity, s.lead, s.personal?.status, s.personal?.id, s.personal?.modelId, s.personal?.ownedModels, s.garage, this.host.canChangeCar?.(), s.pads.length, s.sales, s.journey?.step, s.journey?.intakePaused, s.journey?.automation, Math.ceil(s.parts?.remaining ?? -1), s.parts?.level]);
    if (sig !== this.signature) { this.signature = sig; if (this.isOpen) this.render(); }
    this.gains.tick(dt, !this.root.hidden);
  }
  private render() {
    this.header.replaceChildren(); this.content.replaceChildren();
    const s = this.host.state, c = s.car, d = c ? M.def(s) : undefined;
    this.panel.hidden = !this.isOpen;
    this.guide.hidden = this.isOpen; this.top.hidden = false; this.top.classList.toggle('wallet-only', this.isOpen);
    this.panel.classList.toggle('tycoon-garage', ['personal', 'collection'].includes(this.page));
    this.panel.classList.toggle('tycoon-call-dialog', this.page === 'call');
    document.body.classList.toggle('has-garage', ['personal', 'collection'].includes(this.page));
    const garageCar = this.page === 'collection' ? garageVehicles(s)[this.carIndex] : undefined;
    this.host.previewCar?.(this.page === 'personal' ? this.cars[this.carIndex].id : garageCar?.modelId, garageCar?.paint);
    const panels: Partial<Record<Panel, () => void>> = {
      'call': () => {
        const lead = s.lead; if (!lead) { this.close(); return; }
        this.title(lead.caller + ' · Connected', lead.kind === 'rare' ? 'A rare-car lead' : 'Incoming seller'); this.quote(lead.text);
        if (lead.kind === 'rare') {
          const [budget, short] = M.leadBudget(s, false);
          this.text(`${money(M.PHOENIX_PRICE)} delivered · ${money(M.PHOENIX_PRICE - 300)} if collected`, 'tycoon-price');
          this.text(`${money(budget)} covers the delivered car, repairs and any missing Parts.`);
          if (short) this.text(`Earn ${money(short)} more with ordinary flips. Your lead stays saved.`);
          this.button(c ? 'Deliver after my current flip' : 'Bring the Phoenix here', () => this.action({ type: 'Invite' }, 'world'), short > 0);
          this.button('Drive to Elias · save $300', () => this.action({ type: 'Visit' }, 'world'), !!c || !s.personal || M.leadBudget(s, true)[1] > 0, true);
        } else this.button('Invite the seller', () => this.action({ type: 'Invite' }, 'world'), !!c);
        this.button('Remind me in 5 minutes', () => this.remindCall(), false, true);
        this.text('Regular sellers keep arriving while this lead is saved.', 'tycoon-muted');
      },
      'deal': () => { if (!(c?.quote && d)) { this.close(); return; }

      const q = c.quote, b = q.mode === 'sell' ? M.buyer(s) : undefined;
      this.title(d.name, b ? `${b.name} · ${b.role}` : `${d.seller} · Seller`);
      this.quote(`“${q.line}”`); this.text(money(q.accepted), 'tycoon-price');
      if (b) { const margin = q.accepted - c.purchase - c.workSpent; this.text(`${money(Math.abs(margin))} ${margin < 0 ? 'loss' : 'profit'} · ${b.cue}`, margin < 0 ? 'loss' : 'profit'); }
      if (c.business) this.button(q.mode === 'buy' ? 'Haggle' : 'Ask more', () => this.offer('Counter', q.mode === 'buy' ? M.terms(s).floor : M.buyer(s).max), q.revision > 0, true);
      else if (this.counterAmount === undefined) this.button('Make a counter', () => { this.counterAmount = q.accepted; this.render(); }, false, true);
      else {
        const row = element('div', 'tycoon-counter'), minus = element('button', '', '−'), plus = element('button', '', '+'), value = element('output', '', money(this.counterAmount));
        minus.onclick = () => { this.counterAmount = Math.max(q.mode === 'sell' ? q.accepted : 50, this.counterAmount! - 50); value.textContent = money(this.counterAmount); };
        plus.onclick = () => { this.counterAmount = Math.min(q.mode === 'buy' ? M.terms(s).ask : 20000, this.counterAmount! + 50); value.textContent = money(this.counterAmount); };
        row.append(minus, value, plus); this.content.append(row);
        this.button('Send counter', () => { const amount = this.counterAmount; this.counterAmount = undefined; this.offer('Counter', amount); });
      }
      this.button(q.mode === 'buy' ? `Buy · ${money(q.accepted)}` : `Accept · ${money(q.accepted)}`, () => this.offer('Accept'));
      if (q.mode === 'sell') this.button('Pass · wait for another buyer', () => this.action({ type: 'Decline' }, 'world'), false, true);
      if (q.mode === 'buy' && c.business && !c.business.tutorial) this.button('Pass · wait for another seller', () => this.action({ type: 'Decline' }, 'world'), false, true);
      if (c.remote && !c.owned) this.button('Leave · drive home', () => this.action({ type: 'Leave' }, 'world'), false, true);
    
      },
      'build': () => { if (!(c && d)) { this.close(); return; }

      this.title('Choose your flip', d.name);
      for (const tier of catalog.tiers) {
        const supported = tier.id === 'Quick' || tier.id === 'Good', depth = supported ? tier.id as Depth : 'Good';
        const estimate = M.estimate(s, depth)!;
        this.text(tier.name, 'tycoon-subtitle'); this.text(tier.copy);
        const quote = M.workQuote(s, depth), inputs = repairCost(quote);
        if (supported) {
          this.text(`${money(inputs.cash)} + ${inputs.parts} Parts · est. ${money(estimate.profit)} profit`);
          const range = workOrderRange(quote, depth, c.condition, !!c.business?.tutorial);
          this.text(`${range.min === range.max ? range.min : range.min + '–' + range.max} repair tasks · order varies per car`);
        }
        this.button(supported ? `Choose ${tier.name}` : 'Signature · not available yet', () => this.action({ type: 'Plan', depth }, 'world'), !supported || depth === 'Good' && !M.has(s, 'finish'));
      }
    
      },
      'prepare': () => { if (!(c && d)) { this.close(); return; }

      this.title('Prepare for sale', d.name); this.quote('The work is done. Give your car a look, then find its buyer.');
      this.text(`Bought ${money(c.purchase)} · Work ${money(c.workSpent)}`);
      this.button('Take photo & list', () => this.action({ type: 'Photo' }, 'world'));
      this.button('Customize', () => this.open('custom'), !M.has(s, 'finish'), true);
      this.button('Car story', () => this.open('journal'), false, true);
    
      },
      'custom': () => { if (!(c && d && this.draft)) { this.close(); return; }

      this.title('Make it yours', d.name);
      const choice = this.draft;
      this.text('Paint', 'tycoon-subtitle');
      const swatches = element('div', 'tycoon-swatches');
      for (const paint of ['original', 'cream', 'blue', 'red', 'green'] as Look['paint'][]) {
        const button = element('button', paint === choice.paint ? 'selected' : '', paint); button.onclick = () => { choice.paint = paint; this.render(); }; swatches.append(button);
      }
      this.content.append(swatches);
      this.button(`Wheels: ${choice.wheels} · switch`, () => { choice.wheels = choice.wheels === 'original' ? 'sport' : 'original'; this.render(); }, false, true);
      this.button(`Stripe: ${choice.stripe ? 'on' : 'off'}`, () => { choice.stripe = !choice.stripe; this.render(); }, false, true);
      const fit = M.estimate(s, c.depth, choice)!; this.text(`${fit.role} · estimated offer ${money(fit.sale)}`);
      this.text(M.fit({ custom: choice }, fit.role)[1]);
      const cost = M.customizationCost(s, choice); this.button(cost ? `Apply · ${money(cost)}` : 'Keep this look', () => this.action({ type: 'Custom', choice }, 'prepare'));
    
      },
      'worker': () => {

      this.title('Jo', 'Your mechanic'); this.quote(s.worker.activity);
      this.text(`${s.worker.jobs} cars finished · ${s.worker.level > 1 ? 'Trained' : 'Rookie'}`);
      this.button(s.worker.level > 1 ? 'Trained · 20% less work time' : s.worker.jobs ? 'Train Jo · $350' : 'Finish one job to train', () => this.action({ type: 'Train' }), s.worker.level > 1 || !s.worker.jobs);
    
      },
      'phone': () => {

      this.title('Dealership phone', this.tab);
      const nav = element('nav', 'tycoon-tabs');
      for (const tab of ['Home', 'Deals', 'Team', 'Garage']) { const b = element('button', this.tab === tab ? 'selected' : '', tab); b.onclick = () => { this.tab = tab; this.render(); }; nav.append(b); } this.content.append(nav);
      const tabs: Record<string, () => void> = {
        'Home': () => {
        if (s.personal?.status === 'driving') { this.quote(guidance(s).text); this.button('Back to driving', () => this.close()); this.button('Go to your car', () => this.host.goToCar?.(), false, true); }
        else if (s.personal?.status === 'atLead' && !c?.owned) { this.quote('Elias is waiting by his garage.'); this.button('Meet seller', () => { this.close(); this.host.navigate(guidance(s)); }); this.button('Leave · drive home', () => this.action({ type: 'Leave' }, 'world'), false, true); }
        else if (s.lead) {
          this.quote(s.lead.text);
          if (s.lead.kind === 'rare') this.button('Drive there · save $300', () => this.action({ type: 'Visit' }, 'world'));
          this.button('Bring it here', () => this.action({ type: 'Invite' }, 'world'));
          if (s.lead.kind === 'rare') { const [, short] = M.leadBudget(s, true); if (short) this.text(`Need ${money(short)} more. Find a flip in Deals.`); }
        } else this.quote(c ? 'One car. Your attention.' : 'Your dealership, connected.');
        if (s.journey) {
          this.button('Build your dealership', () => this.open('journey'), false, true);
          if (partsUnlocked(s)) {
            this.button('Sell salvaged parts', () => this.host.navigate({ kind: 'parts', text: 'Parts sales laptop', label: 'Sell parts', point: PARTS_POSITION }), false, true);
            this.button('Parts laptop upgrades', () => this.open('parts'), false, true);
          }
          this.text(money(revenuePerMinute(s)) + ' earned in the last 60 seconds');
          this.text(offlineUnlocked(s) ? 'Offline business: ' + money(offlineRate(s) * 60) + '/min · up to 8 hours' : 'Offline earnings unlock after your first sale and mechanic hire.', 'tycoon-muted');
        }
        this.text(this.host.saveStatus(), 'tycoon-muted');
        this.text('WASD move / drive · Shift sprint · Space jump / handbrake · E interact / exit', 'tycoon-muted');
      },
        'Deals': () => {
        if (c && d) { this.quote(`${d.name} · ${M.grade(c.condition)}`); this.button(c.status === 'photo' ? 'Prepare for sale' : 'Car story', () => this.open(c.status === 'photo' ? 'prepare' : 'journal')); }
        else if (s.lead?.kind === 'rare' && M.leadBudget(s, false)[1] > 0) { this.quote('Build cash with an ordinary flip. Your rare lead stays saved.'); this.button('Find an ordinary flip', () => this.action({ type: 'Recovery' }, 'world')); }
        else this.quote('No active listing.');
        if (s.journey?.tutorialComplete) {
          this.button('Find an ordinary seller', () => this.action({ type: 'NextSeller' }, 'world'), !!c);
          this.button('Maya’s Desert Coupe', () => this.action({ type: 'SpecialDeal', index: 2 }, 'world'), !!c || !M.has(s, 'finish'), true);
          this.button('Nora’s City Hatch', () => this.action({ type: 'SpecialDeal', index: 3 }, 'world'), !!c || !M.has(s, 'finish'), true);
          this.button(s.journey.intakePaused ? 'Resume new arrivals' : 'Pause new arrivals', () => this.action({ type: 'ToggleIntake' }), false, true);
        }
        if (s.journey) this.button('Car index', () => this.open('index'), false, true);
      },
        'Team': () => {
        this.quote(s.worker.hired ? 'Jo has your workshop covered.' : 'It starts with you.'); if (s.worker.hired) this.button('View Jo', () => this.open('worker'));
        if (s.journey) {
          this.text('Manny · ' + (s.journey.step >= 6 ? 'Listing transport' : 'Unlocks at step 6'));
          this.text('Car buyer · ' + (s.journey.step >= 29 ? 'Automated intake' : 'Unlocks at step 29'));
          this.text('Sales advisor · ' + (s.journey.step >= 33 ? 'Automated sales' : 'Unlocks at step 33'));
          this.text('Mechanic · ' + (M.has(s, 'mechanic') ? 'Automated repairs' : 'Unlocks at step 40'));
          for (const d of departments) if (s.journey.step >= d.first) this.text(d.name + ' · ' + (s.journey.step >= d.staff ? 'Staffed' : 'Manual · specialist at step ' + d.staff));
          this.button(s.journey.automation ? 'Switch to manual deals' : 'Automate deals', () => this.action({ type: 'ToggleAutomation' }), !s.journey.tutorialComplete, true);
          this.text('Hired repair staff always handle repairs and order missing Parts from your cash.');
        }
      },
        'Garage': () => { this.quote(s.personal ? personalCarOption(personalModel(s.personal)!)!.name : 'Find a car of your own.'); this.button('Choose your car', () => this.open('personal')); this.button('Your car stories', () => this.open('complete'), false, true); }
      };
      tabs[this.tab]?.();
    
      },
      'personal': () => {
 this.renderGarage(); 
      },
      'collection': () => { this.renderCollection(); },
      'journal': () => { if (!(c && d)) { this.close(); return; }
 this.title(d.name, 'Car story'); this.text(`${c.arrivalGrade} on arrival`); for (const line of c.history) this.text(line); 
      },
      'wallet': () => {

      this.title('Your money'); this.text(money(s.cash), 'tycoon-price'); this.text(`${money(M.reserve(s))} reserved for work`);
      if (s.journey) this.text(money(revenuePerMinute(s)) + ' business revenue in the last 60 seconds');
      for (const e of s.ledger.slice(-100).reverse()) this.text(`${e.subject}  ${e.amount < 0 ? '−' : '+'}${money(Math.abs(e.amount))}`, 'tycoon-ledger');
      this.text(this.host.saveStatus(), 'tycoon-muted');
      this.text(RESET_AND_CLOSE_SHORTCUT + ' resets your save and closes the game.', 'tycoon-muted');
    
      },
      'result': () => { if (!(this.receipt)) { this.close(); return; }

      const r = this.receipt; this.title(r.buying ? 'It’s yours' : 'Deal done', `${r.car} · ${r.person}`);
      if (r.buying) { this.text(`${money(r.amount)} paid`, 'tycoon-price'); this.quote(r.line); }
      else { this.text(`${money(Math.abs(r.profit ?? 0))} ${(r.profit ?? 0) < 0 ? 'loss' : 'profit'}`, 'tycoon-price'); this.text(`Bought ${money(r.purchase)} · Work ${money(r.work)}`); this.text(`Sold for ${money(r.amount)}`); this.quote(r.line); }
      this.button('Continue', () => this.close());
    
      },
      'complete': () => {

      this.title('Your dealership', `${s.sales} cars sold`);
      for (const car of s.history) this.text(`${car.definition?.name ?? catalog.cars[car.index - 1].name}\n${car.keptAs ? 'Kept as ' + car.keptAs : money((car.sale ?? 0) - car.purchase - car.workSpent) + ' profit'}`, 'tycoon-ledger');
      if (!s.history.length) this.quote('Every car has a story. Your first one starts here.');
    
      },
      'journey': () => { if (!(s.journey)) { this.close(); return; }

      const step = s.journey.step, entry = nextEntry(step), pad = purchasePad(s), gate = purchaseGate(s);
      const construction = entries.filter(e => e.category !== 'Cosmetic');
      this.title('Your dealership', construction.filter(e => e.step <= step).length + ' / ' + construction.length + ' construction upgrades · ' + (entry?.chapter ?? 'INSTITUTION'));
      if (entry && pad) {
        this.text(entry.title, 'tycoon-subtitle'); this.category(entry.category); this.text(entry.benefit); this.text(money(entry.cost), 'tycoon-price');
        if (gate) this.quote(gate);
        else if (s.cash < entry.cost) this.text('Earn ' + money(entry.cost - s.cash) + ' more to build this upgrade.');
        this.button('Take me to this purchase', () => this.host.navigate({ kind: 'pad', id: pad.id, point: pad.pos, text: entry.title, label: 'Build' }), !!gate);
        const milestone = milestones.find(m => m.id === entry.milestone);
        if (milestone) { this.text(milestone.title, 'tycoon-subtitle'); this.text(milestone.payoff); }
        for (const upcoming of entries.filter(e => e.step > entry.step && e.category !== 'Cosmetic').slice(0, 4)) this.text(upcoming.step + '. ' + upcoming.title + ' · ' + money(upcoming.cost), 'tycoon-muted');
      } else this.quote('Your institutional campus is complete. The business keeps running.');
      if (cosmeticPads(s).length) this.button('Browse optional cosmetics', () => this.open('cosmetics'), false, true);
    
      },
      'cosmetics': () => {
        this.title('Optional cosmetics', 'Decorate whenever you like. These never block construction or earnings.');
        for (const pad of cosmeticPads(s)) {
          this.text(pad.name, 'tycoon-subtitle'); this.category('Cosmetic'); this.text(money(pad.cost));
          this.button('Go to blue pad', () => this.host.navigate({ kind: 'pad', id: pad.id, point: pad.pos, text: pad.description, label: pad.name }));
        }
      },
      'parts': () => { if (!(s.parts && partsUnlocked(s))) { this.close(); return; }

      const station = s.parts, running = station.remaining !== undefined, automated = partsAutomated(s);
      this.title('Parts laptop upgrades', 'Level ' + station.level + '/' + PARTS_MAX_LEVEL);
      this.text(partsPayout(station.level) + '$/sell', 'tycoon-price');
      this.text(automated ? 'Your mechanic handles sales automatically.' : 'Press E at the laptop to type a sale. Payment arrives after the animation.');
      this.button(running ? 'Continue at the laptop' : 'Go to the laptop', () => this.host.navigate({ kind: 'parts', point: PARTS_POSITION, label: 'Sell car part', text: 'Parts laptop' }), automated);
      this.button(station.level >= PARTS_MAX_LEVEL ? 'Fully upgraded' : '+$16 per batch · ' + money(partsUpgradeCost(station.level)),
        () => this.action({ type: 'UpgradeParts' }), station.level >= PARTS_MAX_LEVEL, true);
      this.text(station.completed + ' batches sold. No inventory purchase needed.', 'tycoon-muted');
    
      },
      'offline': () => { if (!(this.host.offline?.())) { this.close(); return; }

      const reward = this.host.offline()!;
      this.title('Welcome back', 'Your business kept working');
      this.text('+' + money(reward.amount), 'tycoon-price');
      this.text('Already added to your cash.');
      this.text(Math.floor(reward.seconds / 60) + ' minutes · ' + money(reward.rate * 60) + '/min');
      if (reward.capped) this.text('Earnings are capped at 8 hours.', 'tycoon-muted');
      this.button('Continue', () => this.close());
    
      },
      'index': () => { if (!(s.journey)) { this.close(); return; }

      this.title('Car index', 'Your dealership discoveries');
      for (const [id, name, step] of [['Rusty', 'Rusty', 2], ['HondoCivixEK', 'Hondo Civix EK', 2], ['Gblock', 'G-Block', 72], ['Bavora', 'Bavora', 90]] as [string, string, number][]) {
        this.text(name, 'tycoon-subtitle'); this.text(s.journey.step < step ? 'Unlocks at step ' + step : s.journey.seenCars.includes(id) ? 'Discovered · arriving in your seller pool' : 'Unlocked · waiting to meet');
      }
      this.text('Special leads', 'tycoon-subtitle');
      for (const car of catalog.cars.slice(1)) this.text(car.name + ' · ' + (s.history.some(c => !c.business && c.index === catalog.cars.indexOf(car) + 1) ? 'Sold' : car.id === catalog.cars[3].id ? 'Elias’s rare-car lead' : 'Available through Deals'));
    
      }
    };
    panels[this.page]?.();
  }
  private changeCar(direction: number) {
    const length = this.page === 'collection' ? garageVehicles(this.host.state).length : this.cars.length;
    this.carIndex = length ? (this.carIndex + direction + length) % length : 0; this.render();
  }
  private renderCollection() {
    const s = this.host.state, cars = garageVehicles(s), car = cars[this.carIndex];
    this.title('Personal garage', cars.length + ' vehicles owned');
    if (!car) {
      const empty = element('div', 'garage-details');
      empty.append(this.text('Keep a repaired car on its way to the selling area, or buy one below.'), this.button('Browse cars to buy', () => this.open('personal')));
      this.content.append(empty); return;
    }
    const selector = element('div', 'garage-selector');
    for (const [label, symbol, direction] of [['Previous car', '‹', -1], ['Next car', '›', 1]] as const) {
      const arrow = element('button', 'garage-arrow', symbol); arrow.setAttribute('aria-label', label);
      arrow.onclick = () => this.changeCar(direction); selector.append(arrow);
    }
    this.content.append(selector);
    const details = element('div', 'garage-details'); details.setAttribute('aria-live', 'polite');
    details.append(element('span', 'garage-eyebrow', `${this.carIndex + 1} / ${cars.length} · ${personalCarOption(car.modelId)!.name}`), element('h2', '', car.name));
    this.content.append(details);
    const canChange = (this.host.canChangeCar?.() ?? true) && (!s.personal || s.personal.status === 'parked');
    details.append(this.button(s.personal?.id === car.id ? 'Respawn at garage' : 'Spawn at garage', () => this.action({ type: 'SpawnPersonal', vehicleId: car.id }), !canChange));
    if (s.personal?.id === car.id) details.append(this.button('Go to car', () => this.host.goToCar?.(), !canChange, true));
    details.append(this.text('Paint color', 'tycoon-subtitle'));
    const palette = element('div', 'garage-paints');
    for (const [name, paint] of GARAGE_PAINTS) {
      const button = element('button', 'secondary', name); button.style.borderColor = paint;
      button.setAttribute('aria-pressed', String(car.paint === paint)); button.disabled = !canChange;
      button.onclick = () => this.action({ type: 'PaintPersonal', vehicleId: car.id, paint }); palette.append(button);
    }
    details.append(palette);
    details.append(this.text('Each car keeps its own name and paint. Spawning replaces your active personal car; the collection stays saved.', 'tycoon-muted'));
    details.append(this.button('Browse cars to buy', () => this.open('personal'), false, true));
  }
  private renderGarage() {
    const s = this.host.state, option = this.cars[this.carIndex], owned = [...new Set(garageVehicles(s).map(c => c.modelId))];
    const selected = personalModel(s.personal) === option.id, purchased = owned.includes(option.id);
    const available = Math.max(0, s.cash - M.reserve(s));
    const canChange = (this.host.canChangeCar?.() ?? true) && (!s.personal || s.personal.status === 'parked');
    this.title('Your garage', owned.length + ' / ' + this.cars.length + ' cars owned');
    const selector = element('div', 'garage-selector');
    for (const [label, symbol, direction] of [['Previous car', '‹', -1], ['Next car', '›', 1]] as const) {
      const arrow = element('button', 'garage-arrow', symbol); arrow.setAttribute('aria-label', label);
      arrow.onclick = () => this.changeCar(direction); selector.append(arrow);
    }
    const details = element('div', 'garage-details'); details.setAttribute('aria-live', 'polite');
    const heading = element('div', 'garage-heading');
    const title = element('div');
    title.append(element('span', 'garage-eyebrow', 'CAR ' + option.id + ' · ' + (this.carIndex + 1) + ' / ' + this.cars.length + (purchased ? selected ? ' · SELECTED' : ' · OWNED' : '')), element('h2', '', option.name));
    heading.append(title, element('strong', 'garage-price', money(option.price)));
    details.append(heading, element('p', 'garage-description', option.description));
    const stats = element('div', 'garage-stats');
    for (const [label, value] of [['Power', option.tuning.horsepower + ' hp'], ['Speed', option.tuning.maxSpeedKmh + ' km/h'], ['Weight', option.tuning.mass.toLocaleString() + ' kg'], ['Drive', 'Rear wheels']]) {
      const stat = element('div'); stat.append(element('small', '', label), element('strong', '', value)); stats.append(stat);
      if (label === 'Speed') stat.setAttribute('title', 'Target speed; terrain and traction affect performance.');
    }
    details.append(stats);
    const footer = element('div', 'garage-actions');
    const buy = element('button', '', selected ? 'Bring to garage' : purchased ? 'Use this car' : 'Buy & use · ' + money(option.price));
    buy.disabled = !canChange || !garageUnlocked(s) || !purchased && available < option.price;
    buy.onclick = () => this.action({ type: purchased ? 'SelectPersonal' : 'BuyPersonal', modelId: option.id });
    footer.append(buy);
    if (selected) {
      const drive = element('button', 'secondary', 'Go to car'); drive.disabled = !!s.personal?.route;
      drive.onclick = () => this.host.goToCar?.(); footer.append(drive);
    }
    const balance = element('span', 'garage-balance', money(available) + ' available'); footer.append(balance);
    details.append(footer);
    const message = !garageUnlocked(s) ? 'Finish your first sale to buy a personal car.'
      : !canChange ? 'Park and step out at home before changing cars.'
      : !purchased && available < option.price ? money(option.price - available) + ' more needed. Work money stays reserved.'
      : purchased ? 'Owned cars are yours to keep. Switch between them for free.' : 'Buy once. Keep it in your garage.';
    details.append(element('p', 'garage-note', message));
    this.content.append(selector, details);
    details.append(this.button('View owned collection', () => this.open('collection'), false, true));
  }
  dispose() {
    window.removeEventListener('keydown', this.keyDown); window.removeEventListener('blur', this.release);
    this.gains.dispose(); this.sellingProgress.remove();
    this.host.previewCar?.(); this.root.remove(); document.body.classList.remove('has-tycoon', 'has-garage');
  }
}
