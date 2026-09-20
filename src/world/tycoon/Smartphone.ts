import type { TycoonState } from './types.js';
/** Persistent phone shell: callers slide into view, Enter answers into the call dialog. */
export class Smartphone {
  readonly root = document.createElement('aside');
  private readonly status = document.createElement('small');
  private readonly name = document.createElement('h3');
  private readonly avatar = document.createElement('div');
  private readonly message = document.createElement('p');
  private readonly answer = document.createElement('button');
  private readonly remind = document.createElement('button');
  private readonly apps = document.createElement('button');
  private readonly dismiss = document.createElement('button');
  private manual = false;
  private dismissed?: object;
  constructor(parent: HTMLElement, onAnswer: () => void, onRemind: () => void, onApps: () => void) {
    this.root.className = 'tycoon-smartphone'; this.root.setAttribute('aria-label', 'Smartphone');
    const screen = document.createElement('div'); screen.className = 'smartphone-screen';
    const top = document.createElement('div'); top.className = 'smartphone-status'; top.textContent = 'MAPLE  ▮▮▮  ▰';
    this.avatar.className = 'smartphone-avatar'; this.message.className = 'smartphone-message';
    this.answer.className = 'smartphone-answer'; this.answer.onclick = onAnswer;
    this.remind.textContent = 'Remind me in 5 minutes'; this.remind.className = 'smartphone-remind'; this.remind.onclick = onRemind;
    this.apps.textContent = 'Dealership apps'; this.apps.onclick = onApps;
    this.dismiss.textContent = 'Put away'; this.dismiss.className = 'smartphone-dismiss';
    this.dismiss.onclick = () => { this.manual = false; this.root.classList.remove('visible'); this.dismissed = this.currentLead; };
    screen.append(top, this.status, this.avatar, this.name, this.message, this.answer, this.remind, this.apps, this.dismiss);
    this.root.append(screen); parent.append(this.root);
  }
  private currentLead?: object;
  toggle(force?: boolean) { this.manual = force ?? !this.manual; this.dismissed = undefined; }
  hide() { this.manual = false; this.dismissed = this.currentLead; this.root.classList.remove('visible'); }
  update(s: TycoonState, modal: boolean) {
    const lead = s.lead, ringing = !!lead && ['ringing', 'missed'].includes(lead.status);
    if (this.lastStatus !== lead?.status) { if (ringing) this.dismissed = undefined; this.lastStatus = lead?.status; }
    this.currentLead = lead;
    const visible = !modal && (this.manual || ringing && this.dismissed !== lead);
    this.root.classList.toggle('visible', visible); this.root.setAttribute('aria-hidden', String(!visible));
    this.status.textContent = ringing ? 'INCOMING CALL' : lead?.status === 'snoozed' ? 'REMINDER SAVED' : lead ? 'SAVED CONVERSATION' : 'MESSAGES';
    this.name.textContent = lead?.caller ?? 'Dealership'; this.avatar.textContent = lead?.caller.slice(0, 1) ?? 'M';
    this.message.textContent = lead?.text ?? s.notice ?? 'Your business, in your pocket.';
    this.answer.textContent = ringing ? 'Enter · Answer call' : 'Open conversation';
    this.answer.hidden = !lead || ['snoozed', 'visiting', 'queued'].includes(lead.status);
    this.remind.hidden = !lead || ['snoozed', 'visiting', 'queued'].includes(lead.status);
  }
  private lastStatus?: string;
}
