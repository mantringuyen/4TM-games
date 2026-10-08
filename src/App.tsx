import React, { useState, useEffect } from 'react';
import { Gamepad2, Brain, Zap, KeyRound, Trophy, Volume2, VolumeX, Flame, Sparkles } from 'lucide-react';
import { CyberPong } from './components/CyberPong';
import { MemoryMatrix } from './components/MemoryMatrix';
import { SpeedReflex } from './components/SpeedReflex';
import { CipherBreaker } from './components/CipherBreaker';
import { sound } from './utils/audio';

type ActiveGame = 'hub' | 'cyberpong' | 'memorymatrix' | 'speedreflex' | 'cipherbreaker';

interface HighScores {
  cyberpong: number;
  memorymatrix: number;
  speedreflex: number;
  cipherbreaker: number;
}

const DEFAULT_SCORES: HighScores = {
  cyberpong: 0,
  memorymatrix: 0,
  speedreflex: 0,
  cipherbreaker: 0,
};

export default function App() {
  const [activeGame, setActiveGame] = useState<ActiveGame>('hub');
  const [highScores, setHighScores] = useState<HighScores>(() => {
    try {
      const saved = localStorage.getItem('4tm_high_scores');
      return saved ? { ...DEFAULT_SCORES, ...JSON.parse(saved) } : DEFAULT_SCORES;
    } catch {
      return DEFAULT_SCORES;
    }
  });

  const [isMuted, setIsMuted] = useState(false);

  useEffect(() => {
    try {
      localStorage.setItem('4tm_high_scores', JSON.stringify(highScores));
    } catch {
      // Ignore local storage write errors
    }
  }, [highScores]);

  useEffect(() => {
    const themeMeta = document.querySelector('meta[name="theme-color"]');
    if (activeGame !== 'hub') {
      const origHtmlBg = document.documentElement.style.backgroundColor;
      const origHtmlColorScheme = document.documentElement.style.colorScheme;
      const origBodyBg = document.body.style.backgroundColor;
      const origThemeColor = themeMeta ? themeMeta.getAttribute('content') : null;

      document.documentElement.style.backgroundColor = '#000000';
      document.documentElement.style.colorScheme = 'dark';
      document.body.style.backgroundColor = '#000000';
      if (themeMeta) {
        themeMeta.setAttribute('content', '#000000');
      }

      return () => {
        document.documentElement.style.backgroundColor = origHtmlBg;
        document.documentElement.style.colorScheme = origHtmlColorScheme;
        document.body.style.backgroundColor = origBodyBg;
        if (themeMeta) {
          if (origThemeColor) {
            themeMeta.setAttribute('content', origThemeColor);
          } else {
            themeMeta.removeAttribute('content');
          }
        }
      };
    }
  }, [activeGame]);

  const updateHighScore = (gameId: string, score: number) => {
    setHighScores((prev) => {
      const current = prev[gameId as keyof HighScores] || 0;
      if (score > current) {
        return { ...prev, [gameId]: score };
      }
      return prev;
    });
  };

  const toggleSound = () => {
    const muted = sound.toggleMute();
    setIsMuted(muted);
    if (!muted) sound.playClick();
  };

  const totalScore = Object.values(highScores).reduce((a, b) => a + b, 0);

  return (
    <div id="app-root" className="min-h-screen bg-slate-950 text-slate-100 flex flex-col selection:bg-cyan-500 selection:text-slate-950">
      {/* Navigation Header */}
      <header id="main-header" className="w-full border-b border-slate-800/80 bg-slate-950/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div
            id="brand-logo"
            onClick={() => {
              setActiveGame('hub');
              sound.playClick();
            }}
            className="flex items-center gap-3 cursor-pointer group"
          >
            <div className="w-10 h-10 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400 group-hover:border-cyan-400 transition-colors">
              <Gamepad2 className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-arcade font-bold text-xl tracking-wider text-white">4TM</span>
                <span className="text-xs px-2 py-0.5 rounded font-mono font-semibold bg-cyan-500/20 text-cyan-300 border border-cyan-500/30">
                  ARCADE
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-mono hidden sm:block">Interactive Mini-Game Suite</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {/* High Score Badge */}
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-900 border border-slate-800 text-xs font-mono">
              <Trophy className="w-4 h-4 text-amber-400" />
              <span className="text-slate-400">Total Arcade Score:</span>
              <span className="font-bold text-amber-300">{totalScore.toLocaleString()}</span>
            </div>

            {/* Audio Toggle */}
            <button
              id="audio-toggle-btn"
              onClick={toggleSound}
              aria-label={isMuted ? 'Unmute Audio' : 'Mute Audio'}
              className="p-2 rounded-lg bg-slate-900 border border-slate-800 text-slate-400 hover:text-white hover:border-slate-700 transition-colors"
            >
              {isMuted ? <VolumeX className="w-4 h-4 text-rose-400" /> : <Volume2 className="w-4 h-4 text-cyan-400" />}
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main id="main-content" className="flex-1 max-w-6xl w-full mx-auto px-4 sm:px-6 py-8">
        {activeGame === 'hub' && (
          <div id="hub-view" className="flex flex-col gap-8">
            {/* Hero Section */}
            <div className="text-center max-w-2xl mx-auto pt-2 pb-4">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-cyan-950/60 border border-cyan-800/40 text-cyan-400 text-xs font-mono mb-4">
                <Sparkles className="w-3.5 h-3.5" />
                <span>4TM Games Virtual Arcade</span>
              </div>
              <h1 className="text-3xl sm:text-5xl font-extrabold font-arcade text-white tracking-tight leading-tight mb-4">
                CHALLENGE YOUR <span className="text-cyan-400">REFLEXES</span> &amp; <span className="text-violet-400">MIND</span>
              </h1>
              <p className="text-slate-400 text-sm sm:text-base leading-relaxed">
                Choose a mini-game below to test your reflexes, pattern recognition, precision timing, and code breaking skills.
              </p>
            </div>

            {/* Games Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {/* Card 1: Cyber Pong */}
              <div
                id="card-cyberpong"
                onClick={() => {
                  setActiveGame('cyberpong');
                  sound.playClick();
                }}
                className="group relative bg-slate-900/60 border border-slate-800 hover:border-sky-500/60 rounded-2xl p-6 transition-all duration-200 hover:-translate-y-1 cursor-pointer flex flex-col justify-between overflow-hidden shadow-lg hover:shadow-sky-500/10"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-12 h-12 rounded-xl bg-sky-500/10 border border-sky-500/30 flex items-center justify-center text-sky-400 group-hover:bg-sky-500 group-hover:text-slate-950 transition-colors">
                      <Gamepad2 className="w-6 h-6" />
                    </div>
                    <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                      ARCADE / PHYSICS
                    </span>
                  </div>
                  <h3 className="text-xl font-bold font-arcade text-white group-hover:text-sky-400 transition-colors mb-2">
                    CYBER PONG
                  </h3>
                  <p className="text-slate-400 text-sm leading-relaxed mb-4">
                    High-energy retro paddle &amp; block breaker with reactive energy orbs, neon block explosions, and physics angles.
                  </p>
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-slate-800/80 text-xs font-mono">
                  <span className="text-slate-500">Best Score:</span>
                  <span className="font-semibold text-amber-300">{highScores.cyberpong} pts</span>
                </div>
              </div>

              {/* Card 2: Memory Matrix */}
              <div
                id="card-memorymatrix"
                onClick={() => {
                  setActiveGame('memorymatrix');
                  sound.playClick();
                }}
                className="group relative bg-slate-900/60 border border-slate-800 hover:border-violet-500/60 rounded-2xl p-6 transition-all duration-200 hover:-translate-y-1 cursor-pointer flex flex-col justify-between overflow-hidden shadow-lg hover:shadow-violet-500/10"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-12 h-12 rounded-xl bg-violet-500/10 border border-violet-500/30 flex items-center justify-center text-violet-400 group-hover:bg-violet-500 group-hover:text-slate-950 transition-colors">
                      <Brain className="w-6 h-6" />
                    </div>
                    <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                      MEMORY / PATTERN
                    </span>
                  </div>
                  <h3 className="text-xl font-bold font-arcade text-white group-hover:text-violet-400 transition-colors mb-2">
                    MEMORY MATRIX
                  </h3>
                  <p className="text-slate-400 text-sm leading-relaxed mb-4">
                    Synchronize your senses with an escalating multi-tone audiovisual sequence across hexagonal frequency pads.
                  </p>
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-slate-800/80 text-xs font-mono">
                  <span className="text-slate-500">Best Score:</span>
                  <span className="font-semibold text-amber-300">{highScores.memorymatrix} pts</span>
                </div>
              </div>

              {/* Card 3: Target Blitz */}
              <div
                id="card-speedreflex"
                onClick={() => {
                  setActiveGame('speedreflex');
                  sound.playClick();
                }}
                className="group relative bg-slate-900/60 border border-slate-800 hover:border-cyan-500/60 rounded-2xl p-6 transition-all duration-200 hover:-translate-y-1 cursor-pointer flex flex-col justify-between overflow-hidden shadow-lg hover:shadow-cyan-500/10"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-12 h-12 rounded-xl bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center text-cyan-400 group-hover:bg-cyan-500 group-hover:text-slate-950 transition-colors">
                      <Zap className="w-6 h-6" />
                    </div>
                    <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                      REFLEX / SPEED
                    </span>
                  </div>
                  <h3 className="text-xl font-bold font-arcade text-white group-hover:text-cyan-400 transition-colors mb-2">
                    TARGET BLITZ
                  </h3>
                  <p className="text-slate-400 text-sm leading-relaxed mb-4">
                    30-second rapid-fire reaction arena. Click luminous nodes, snatch golden multipliers, and dodge corrupt hazard glitches.
                  </p>
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-slate-800/80 text-xs font-mono">
                  <span className="text-slate-500">Best Score:</span>
                  <span className="font-semibold text-amber-300">{highScores.speedreflex} pts</span>
                </div>
              </div>

              {/* Card 4: Cipher Breaker */}
              <div
                id="card-cipherbreaker"
                onClick={() => {
                  setActiveGame('cipherbreaker');
                  sound.playClick();
                }}
                className="group relative bg-slate-900/60 border border-slate-800 hover:border-amber-500/60 rounded-2xl p-6 transition-all duration-200 hover:-translate-y-1 cursor-pointer flex flex-col justify-between overflow-hidden shadow-lg hover:shadow-amber-500/10"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400 group-hover:bg-amber-500 group-hover:text-slate-950 transition-colors">
                      <KeyRound className="w-6 h-6" />
                    </div>
                    <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                      PUZZLE / WORD
                    </span>
                  </div>
                  <h3 className="text-xl font-bold font-arcade text-white group-hover:text-amber-400 transition-colors mb-2">
                    CIPHER BREAKER
                  </h3>
                  <p className="text-slate-400 text-sm leading-relaxed mb-4">
                    Decipher scrambled code keywords under clock pressure with contextual clue hints and consecutive streak bonuses.
                  </p>
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-slate-800/80 text-xs font-mono">
                  <span className="text-slate-500">Best Score:</span>
                  <span className="font-semibold text-amber-300">{highScores.cipherbreaker} pts</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Active Game Views */}
        {activeGame === 'cyberpong' && (
          <CyberPong
            onBack={() => setActiveGame('hub')}
            onUpdateHighScore={updateHighScore}
            highScore={highScores.cyberpong}
          />
        )}

        {activeGame === 'memorymatrix' && (
          <MemoryMatrix
            onBack={() => setActiveGame('hub')}
            onUpdateHighScore={updateHighScore}
            highScore={highScores.memorymatrix}
          />
        )}

        {activeGame === 'speedreflex' && (
          <SpeedReflex
            onBack={() => setActiveGame('hub')}
            onUpdateHighScore={updateHighScore}
            highScore={highScores.speedreflex}
          />
        )}

        {activeGame === 'cipherbreaker' && (
          <CipherBreaker
            onBack={() => setActiveGame('hub')}
            onUpdateHighScore={updateHighScore}
            highScore={highScores.cipherbreaker}
          />
        )}
      </main>

      {/* Footer */}
      <footer id="main-footer" className="w-full border-t border-slate-800/60 py-4 px-4 text-center text-xs text-slate-500 font-mono">
        4TM Games &copy; {new Date().getFullYear()} &bull; Fast-loading responsive web arcade
      </footer>
    </div>
  );
}
