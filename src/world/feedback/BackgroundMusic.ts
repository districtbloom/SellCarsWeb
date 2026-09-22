import { assetUrl } from '../../runtimeAssets.js';

export type MusicLocation = 'city' | 'tycoon' | 'racing' | 'moneyearnminigame';
export const MUSIC_FADE_SECONDS = 1.25;
/** Streaming loops keep the four long tracks out of decoded WebAudio memory. */
export class BackgroundMusic {
  private tracks = new Map<MusicLocation, HTMLAudioElement>();
  private location: MusicLocation = 'tycoon';
  private unlocked = false;
  private muted = false;
  private button = document.createElement('button');
  constructor(private baseUrl: string) {
    this.button.className = 'music-toggle'; this.button.textContent = '♫ Music';
    this.button.setAttribute('aria-label', 'Mute background music');
    this.button.onclick = () => { this.muted = !this.muted; this.button.textContent = this.muted ? '♫ Muted' : '♫ Music'; this.button.setAttribute('aria-pressed', String(this.muted)); this.button.setAttribute('aria-label', this.muted ? 'Unmute background music' : 'Mute background music'); this.sync(); };
    document.body.append(this.button);
    window.addEventListener('pointerdown', this.unlock, true);
    window.addEventListener('keydown', this.unlock, true);
    document.addEventListener('visibilitychange', this.sync);
  }
  setLocation(location: MusicLocation) { if (this.location !== location) { this.location = location; this.sync(); } }
  private unlock = () => { this.unlocked = true; this.sync(); };
  private sync = () => {
    for (const track of this.tracks.values()) if (this.muted || document.hidden) { track.pause(); track.volume = 0; }
    if (!this.unlocked || this.muted || document.hidden) return;
    let track = this.tracks.get(this.location);
    if (!track) { track = new Audio(assetUrl(this.baseUrl + 'audio/music/' + this.location + '.mp3')); track.loop = true; track.volume = 0; this.tracks.set(this.location, track); }
    if (track.paused) void track.play().catch(() => { /* A later user gesture retries browser audio activation. */ });
  };
  tick(dt: number) {
    if (!this.unlocked || this.muted || document.hidden) return;
    const step = .32 * Math.max(0, Math.min(.1, dt)) / MUSIC_FADE_SECONDS;
    for (const [name, track] of this.tracks) {
      const target = name === this.location ? .32 : 0;
      track.volume = Math.max(0, Math.min(.32, track.volume + Math.max(-step, Math.min(step, target - track.volume))));
      if (!target && track.volume < .00001) { track.volume = 0; track.pause(); }
    }
  }
  dispose() {
    window.removeEventListener('pointerdown', this.unlock, true); window.removeEventListener('keydown', this.unlock, true);
    document.removeEventListener('visibilitychange', this.sync); this.button.remove();
    for (const track of this.tracks.values()) { track.pause(); track.removeAttribute('src'); track.load(); }
    this.tracks.clear();
  }
}
