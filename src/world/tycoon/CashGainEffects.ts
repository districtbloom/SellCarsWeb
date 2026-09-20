interface Flight { node: HTMLElement; age: number; x: number; y: number }
/** Cosmetic feedback only: the transaction is already committed before it is queued. */
export class CashGainEffects {
  readonly root = document.createElement('div');
  private pending: number[] = [];
  private flights: Flight[] = [];
  private spacing = 0;
  private origin?: { x: number; y: number };
  constructor(private wallet: HTMLElement) {
    this.root.className = 'tycoon-ui tycoon-cash-effects'; this.root.setAttribute('aria-hidden', 'true');
    document.body.append(this.root);
  }
  credit(amount: number) { if (Number.isFinite(amount) && amount > 0) this.pending.push(amount); }
  setOrigin(point: { x: number; y: number } | undefined) { this.origin = point; }
  tick(dt: number, visible: boolean) {
    this.root.hidden = !visible;
    if (!visible) return;
    dt = Math.max(0, Math.min(.1, dt)); this.spacing -= dt;
    if (this.pending.length && this.spacing <= 0) {
      const amount = this.pending.shift()!, node = this.wallet.cloneNode(true) as HTMLElement;
      node.classList.add('tycoon-cash-gain'); node.removeAttribute('id'); node.setAttribute('aria-hidden', 'true');
      node.setAttribute('tabindex', '-1'); node.setAttribute('disabled', '');
      node.textContent = '+$' + Math.floor(amount).toLocaleString('en-US');
      const x = this.origin?.x ?? window.innerWidth * .5, y = this.origin?.y ?? window.innerHeight * .6;
      this.root.append(node); this.flights.push({ node, age: 0, x, y }); this.spacing = .16;
    }
    const bounds = this.wallet.getBoundingClientRect(), targetX = bounds.left + bounds.width / 2, targetY = bounds.top + bounds.height / 2;
    this.flights = this.flights.filter(flight => {
      flight.age += dt;
      const progress = Math.min(1, flight.age / 1.05), travel = Math.max(0, (progress - .12) / .88);
      const eased = travel * travel * (3 - 2 * travel);
      flight.node.style.left = flight.x + (targetX - flight.x) * eased + 'px';
      flight.node.style.top = flight.y + (targetY - flight.y) * eased - Math.sin(travel * Math.PI) * 55 + 'px';
      flight.node.style.transform = `translate(-50%, -50%) scale(${1.15 - .15 * eased})`;
      flight.node.style.opacity = String(Math.min(1, (1 - progress) / .16));
      if (progress < 1) return true;
      flight.node.remove(); return false;
    });
  }
  dispose() { this.pending = []; this.flights = []; this.root.remove(); }
}
