// Audio utility using Web Audio API for arcade sound effects
class SoundEngine {
  private ctx: AudioContext | null = null;
  private isMuted: boolean = false;

  constructor() {
    // Lazy initialize to comply with browser autoplay policies
  }

  private getContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
    return this.ctx;
  }

  public toggleMute(): boolean {
    this.isMuted = !this.isMuted;
    return this.isMuted;
  }

  public getMuted(): boolean {
    return this.isMuted;
  }

  public playTone(freq: number, type: OscillatorType, duration: number, startDelay = 0, volume = 0.15): void {
    if (this.isMuted) return;
    try {
      const ctx = this.getContext();
      if (!ctx) return;

      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = type;
      osc.frequency.setValueAtTime(freq, ctx.currentTime + startDelay);

      gain.gain.setValueAtTime(volume, ctx.currentTime + startDelay);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + startDelay + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(ctx.currentTime + startDelay);
      osc.stop(ctx.currentTime + startDelay + duration);
    } catch {
      // Ignore audio context errors silently
    }
  }

  public playClick(): void {
    this.playTone(600, 'sine', 0.05, 0, 0.1);
  }

  public playHit(): void {
    this.playTone(320, 'triangle', 0.08, 0, 0.15);
  }

  public playSuccess(): void {
    this.playTone(523.25, 'triangle', 0.1, 0, 0.12);
    this.playTone(659.25, 'triangle', 0.12, 0.08, 0.12);
    this.playTone(783.99, 'triangle', 0.25, 0.16, 0.15);
  }

  public playScore(): void {
    this.playTone(880, 'sine', 0.1, 0, 0.12);
    this.playTone(1174.66, 'sine', 0.15, 0.06, 0.14);
  }

  public playError(): void {
    this.playTone(220, 'sawtooth', 0.15, 0, 0.12);
    this.playTone(180, 'sawtooth', 0.2, 0.1, 0.12);
  }

  public playGameOver(): void {
    this.playTone(392.00, 'sawtooth', 0.2, 0, 0.15);
    this.playTone(349.23, 'sawtooth', 0.2, 0.15, 0.15);
    this.playTone(329.63, 'sawtooth', 0.3, 0.3, 0.15);
    this.playTone(261.63, 'sawtooth', 0.5, 0.45, 0.18);
  }
}

export const sound = new SoundEngine();
