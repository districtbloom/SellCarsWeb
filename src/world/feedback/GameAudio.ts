import { Vector3 } from 'three';
import type { PerspectiveCamera } from 'three';
import { assetUrl } from '../../runtimeAssets.js';

// Stable replacement IDs; public/audio/sound-map.json is the artist-facing manifest.
export const SOUND_CUES = {
  'npc.greeting': [.75, .8], 'npc.chatter': [.45, 3], 'npc.agreement': [.7, .8],
  'npc.decline': [.65, .8], 'phone.ring': [.55, 6], 'ui.click': [.3, .1],
  'ui.denied': [.35, .5], 'purchase.build': [.65, .3], 'cash.receive': [.55, .6],
  'repair.tool': [.45, .15], 'repair.spray': [.35, .3], 'repair.pour': [.3, .35],
  'repair.complete': [.65, .6], 'camera.shutter': [.5, .3],
  'car.impact.light': [.65, .15], 'car.impact.heavy': [.85, .25],
  'car.door': [.5, .2], 'car.start': [.45, .8], 'car.rev': [.6, .5],
  'garage.store': [.7, .35],
  'player.footstep': [.18, .2], 'player.jump': [.25, .25], 'player.land': [.3, .3],
} as const;
export type SoundId = keyof typeof SOUND_CUES;
interface Replacement { file: string | null; volume?: number }

/** One context, bounded voices, cached MP3s, and procedural placeholders when files are absent. */
export class GameAudio {
  private context?: AudioContext;
  private master?: GainNode;
  private replacements: Partial<Record<SoundId, Replacement>> = {};
  private buffers = new Map<SoundId, AudioBuffer | null>();
  private loading = new Set<SoundId>();
  private last = new Map<SoundId, number>();
  private voices = new Set<AudioScheduledSourceNode>();
  private disposed = false;
  private noise?: AudioBuffer;
  private clock = 0;
  private readonly listener = new Vector3();
  private readonly right = new Vector3();
  private readonly offset = new Vector3();
  constructor(private camera: PerspectiveCamera, private baseUrl = '/') {
    window.addEventListener('pointerdown', this.unlock, true);
    window.addEventListener('keydown', this.unlock, true);
    document.addEventListener?.('visibilitychange', this.visibility);
    void this.loadManifest();
  }
  private async loadManifest() {
    try {
      const response = await fetch(assetUrl(this.baseUrl + 'audio/sound-map.json'));
      if (!response.ok) return;
      const data = await response.json();
      if (!this.disposed && data?.sounds && typeof data.sounds === 'object') {
        for (const id of Object.keys(SOUND_CUES) as SoundId[]) {
          const entry = data.sounds[id];
          if (!entry || (entry.file !== null && typeof entry.file !== 'string')) continue;
          this.replacements[id] = { file: entry.file, volume: Number.isFinite(entry.volume) ? entry.volume : 1 };
        }
      }
    } catch { /* The built-in palette also works offline without a manifest. */ }
  }
  private unlock = () => {
    if (this.disposed || typeof AudioContext === 'undefined') return;
    try {
      if (!this.context) {
        this.context = new AudioContext(); this.master = this.context.createGain();
        this.master.gain.value = .55; this.master.connect(this.context.destination);
      }
      if (this.context.state === 'suspended') void this.context.resume().catch(() => {});
    } catch { /* Audio is optional if the browser/device cannot initialize it. */ }
  };
  private visibility = () => {
    if (document.hidden) {
      for (const voice of this.voices) { try { voice.stop(); } catch {} }
      if (this.context?.state === 'running') void this.context.suspend().catch(() => {});
    } else if (this.context) this.unlock();
  };
  tick(dt: number, listener: Vector3) { this.clock += dt; this.listener.copy(listener); }
  play(id: SoundId, position?: Vector3, intensity = 1) {
    const ctx = this.context;
    if (this.disposed || !ctx || ctx.state !== 'running' || document.hidden || this.voices.size >= 24) return;
    const [volume, cooldown] = SOUND_CUES[id];
    if (this.clock - (this.last.get(id) ?? -Infinity) < cooldown) return;
    const distance = position ? position.distanceTo(this.listener) : 0;
    if (distance > 120) return;
    this.last.set(id, this.clock);
    const gain = Math.min(1, Math.max(0, intensity)) * volume * Math.pow(Math.max(0, 1 - distance / 120), 2);
    let pan = 0;
    if (position) {
      this.right.set(1, 0, 0).applyQuaternion(this.camera.quaternion);
      pan = Math.max(-.85, Math.min(.85, this.offset.copy(position).sub(this.listener).normalize().dot(this.right)));
    }
    const replacement = this.replacements[id];
    if (replacement?.file) {
      const buffer = this.buffers.get(id);
      if (buffer) {
        const source = ctx.createBufferSource(); source.buffer = buffer;
        this.connect(source, gain * Math.max(0, Math.min(2, replacement.volume ?? 1)), pan);
        source.start(); source.stop(ctx.currentTime + Math.min(buffer.duration, 8)); return;
      }
      if (!this.buffers.has(id) && !this.loading.has(id)) void this.loadClip(id, replacement.file);
    }
    this.synthesize(id, gain, pan);
  }
  private async loadClip(id: SoundId, file: string) {
    this.loading.add(id);
    try {
      const response = await fetch(assetUrl(this.baseUrl + 'audio/' + file));
      if (!response.ok) throw new Error('Missing audio');
      const buffer = await this.context!.decodeAudioData(await response.arrayBuffer());
      if (!this.disposed) this.buffers.set(id, buffer);
    } catch { if (!this.disposed) this.buffers.set(id, null); }
    finally { this.loading.delete(id); }
    // Never replay an old event when a download finishes.
  }
  private connect(source: AudioScheduledSourceNode, volume: number, pan: number, duration?: number, delay = 0) {
    const ctx = this.context!, gain = ctx.createGain(), panner = ctx.createStereoPanner();
    const start = ctx.currentTime + delay;
    gain.gain.setValueAtTime(volume, start);
    if (duration) {
      gain.gain.setValueAtTime(.0001, start);
      gain.gain.exponentialRampToValueAtTime(Math.max(.0002, volume), start + .012);
      gain.gain.exponentialRampToValueAtTime(.0001, start + duration);
    }
    panner.pan.value = pan; source.connect(gain); gain.connect(panner); panner.connect(this.master!);
    this.voices.add(source);
    source.onended = () => { source.disconnect(); gain.disconnect(); panner.disconnect(); this.voices.delete(source); };
    return gain;
  }
  private rev(volume: number, pan: number) {
    const ctx = this.context!, start = ctx.currentTime;
    // A low engine note and its exhaust harmonic rise under throttle, then settle.
    for (const [harmonic, level] of [[1, .38], [2, .14]]) {
      if (this.voices.size >= 24) break;
      const source = ctx.createOscillator(); source.type = harmonic === 1 ? 'triangle' : 'sawtooth';
      source.frequency.setValueAtTime(55 * harmonic, start);
      source.frequency.exponentialRampToValueAtTime(175 * harmonic, start + .3);
      source.frequency.exponentialRampToValueAtTime(215 * harmonic, start + .46);
      source.frequency.exponentialRampToValueAtTime(60 * harmonic, start + .95);
      const envelope = this.connect(source, .0001, pan).gain;
      envelope.exponentialRampToValueAtTime(Math.max(.0002, volume * level), start + .12);
      envelope.setValueAtTime(Math.max(.0002, volume * level * .85), start + .46);
      envelope.exponentialRampToValueAtTime(.0001, start + 1.05);
      source.start(start); source.stop(start + 1.07);
    }
  }
  private tone(frequency: number, end: number, duration: number, volume: number, pan: number, delay = 0, type: OscillatorType = 'sine') {
    if (this.voices.size >= 24) return;
    const ctx = this.context!, source = ctx.createOscillator(), start = ctx.currentTime + delay;
    source.type = type; source.frequency.setValueAtTime(frequency, start);
    source.frequency.exponentialRampToValueAtTime(end, start + duration);
    this.connect(source, volume, pan, duration, delay); source.start(start); source.stop(start + duration + .02);
  }
  private hiss(duration: number, volume: number, pan: number, rate = 1) {
    const ctx = this.context!;
    if (!this.noise) {
      this.noise = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const data = this.noise.getChannelData(0);
      // Smoothed noise keeps placeholders gentle even on headphones.
      let sample = 0;
      for (let i = 0; i < data.length; i++) { sample = sample * .72 + (Math.random() * 2 - 1) * .28; data[i] = sample; }
    }
    const source = ctx.createBufferSource(); source.buffer = this.noise; source.playbackRate.value = rate;
    this.connect(source, volume, pan, duration); source.start(); source.stop(ctx.currentTime + duration + .02);
  }
  private synthesize(id: SoundId, gain: number, pan: number) {
    const tone = (hz: number, end: number, seconds: number, delay = 0, type: OscillatorType = 'sine', level = 1) => this.tone(hz, end, seconds, gain * level, pan, delay, type);
    if (id.startsWith('npc.')) {
      // Voiced, wordless syllables with a changing vowel overtone and speech pauses.
      const pitch = id === 'npc.agreement' ? 175 : id === 'npc.decline' ? 115 : 140;
      const melody = id === 'npc.decline' ? [1.2, 1, .85] : [1, 1.22, .93, 1.12, 1.3];
      melody.forEach((note, i) => {
        const start = i * .14 + (i > 2 ? .12 : 0), hz = pitch * note;
        tone(hz, hz * .92, .11, start, 'triangle', .32);
        tone(hz * (i % 2 ? 4 : 3), hz * 3.2, .09, start, 'sine', .11);
      });
    } else if (id === 'car.impact.heavy' || id === 'car.impact.light') {
      const heavy = id.endsWith('heavy'); this.hiss(heavy ? .45 : .2, gain, pan, .7);
      tone(heavy ? 95 : 160, 38, heavy ? .4 : .18); tone(620, 190, .12, .025, 'triangle', .18);
    } else if (id === 'car.door') { this.hiss(.09, gain, pan); tone(180, 55, .16); }
    else if (id === 'car.start') { tone(45, 110, .65, 0, 'sawtooth', .22); }
    else if (id === 'car.rev') { this.rev(gain, pan); }
    else if (id === 'garage.store') { this.hiss(.28, gain * .7, pan, .65); tone(420, 90, .24, 0, 'sine', .7); tone(660, 990, .22, .12, 'sine', .45); }
    else if (id === 'repair.spray') { this.hiss(.32, gain, pan, 1.3); }
    else if (id === 'repair.pour') { this.hiss(.28, gain, pan, .45); tone(380, 230, .12, .08, 'sine', .2); }
    else if (id === 'repair.tool') { this.hiss(.08, gain, pan); tone(850, 360, .09, 0, 'triangle', .45); }
    else if (id === 'camera.shutter') { this.hiss(.1, gain, pan, 1.8); tone(1300, 400, .04, .075, 'square', .1); }
    else if (id === 'player.footstep' || id === 'player.land') { this.hiss(id.endsWith('land') ? .2 : .08, gain, pan, .6); tone(100, 45, .09); }
    else if (id === 'player.jump') tone(160, 360, .15);
    else if (id === 'ui.denied') { tone(180, 130, .17); }
    else if (id === 'ui.click') tone(650, 420, .06);
    else if (id === 'phone.ring') { [0, .18, .7, .88].forEach(t => tone(880, 920, .12, t, 'sine', .5)); }
    else {
      const notes = id === 'cash.receive' ? [880, 1320] : id === 'purchase.build' ? [330, 440, 660] : [523, 659, 784];
      notes.forEach((hz, i) => tone(hz, hz, .22, i * .09, 'sine', .6));
    }
  }
  dispose() {
    this.disposed = true;
    window.removeEventListener('pointerdown', this.unlock, true); window.removeEventListener('keydown', this.unlock, true);
    document.removeEventListener?.('visibilitychange', this.visibility);
    for (const voice of this.voices) { try { voice.stop(); } catch {} }
    this.buffers.clear(); this.loading.clear(); this.last.clear(); this.voices.clear(); this.noise = undefined;
    this.master?.disconnect(); void this.context?.close().catch(() => {});
  }
}
