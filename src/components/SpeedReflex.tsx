import React, { useState, useEffect, useRef, useCallback } from 'react';
import { ArrowLeft, Play, RotateCcw, Trophy, Zap } from 'lucide-react';
import confetti from 'canvas-confetti';
import { sound } from '../utils/audio';

interface SpeedReflexProps {
  onBack: () => void;
  onUpdateHighScore: (gameId: string, score: number) => void;
  highScore: number;
}

interface Target {
  id: number;
  x: number;
  y: number;
  type: 'standard' | 'golden' | 'hazard';
  size: number;
  createdAt: number;
  lifetime: number;
}

export const SpeedReflex: React.FC<SpeedReflexProps> = ({ onBack, onUpdateHighScore, highScore }) => {
  const [gameState, setGameState] = useState<'idle' | 'playing' | 'gameover'>('idle');
  const [score, setScore] = useState(0);
  const [combo, setCombo] = useState(0);
  const [timeLeft, setTimeLeft] = useState(30);
  const [targets, setTargets] = useState<Target[]>([]);

  const targetCounter = useRef(0);
  const playAreaRef = useRef<HTMLDivElement | null>(null);

  const startGame = () => {
    setScore(0);
    setCombo(0);
    setTimeLeft(30);
    setTargets([]);
    setGameState('playing');
    sound.playClick();
  };

  const spawnTarget = useCallback(() => {
    if (!playAreaRef.current) return;
    const rect = playAreaRef.current.getBoundingClientRect();
    const margin = 35;
    const maxX = Math.max(margin, rect.width - margin * 2);
    const maxY = Math.max(margin, rect.height - margin * 2);

    const rand = Math.random();
    let type: 'standard' | 'golden' | 'hazard' = 'standard';
    let lifetime = 1400;
    let size = 44;

    if (rand < 0.2) {
      type = 'golden';
      lifetime = 1000;
      size = 36;
    } else if (rand < 0.35) {
      type = 'hazard';
      lifetime = 2000;
      size = 40;
    }

    const newTarget: Target = {
      id: ++targetCounter.current,
      x: margin + Math.random() * maxX,
      y: margin + Math.random() * maxY,
      type,
      size,
      createdAt: Date.now(),
      lifetime,
    };

    setTargets((prev) => [...prev.slice(-6), newTarget]);
  }, []);

  // Timer loop
  useEffect(() => {
    if (gameState !== 'playing') return;

    const timer = setInterval(() => {
      setTimeLeft((t) => {
        if (t <= 1) {
          clearInterval(timer);
          setGameState('gameover');
          sound.playGameOver();
          return 0;
        }
        return t - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [gameState]);

  // Target spawn loop
  useEffect(() => {
    if (gameState !== 'playing') return;

    const spawnInterval = setInterval(() => {
      spawnTarget();
    }, 650);

    // Clean expired targets
    const cleanerInterval = setInterval(() => {
      const now = Date.now();
      setTargets((prev) => prev.filter((t) => now - t.createdAt < t.lifetime));
    }, 200);

    return () => {
      clearInterval(spawnInterval);
      clearInterval(cleanerInterval);
    };
  }, [gameState, spawnTarget]);

  // Handle gameover callback
  useEffect(() => {
    if (gameState === 'gameover') {
      onUpdateHighScore('speedreflex', score);
      if (score > highScore && score > 0) {
        confetti({ particleCount: 80, spread: 70, origin: { y: 0.6 } });
      }
    }
  }, [gameState, score, highScore, onUpdateHighScore]);

  const handleTargetClick = (target: Target, e: React.MouseEvent) => {
    e.stopPropagation();

    if (target.type === 'hazard') {
      sound.playError();
      setCombo(0);
      setScore((s) => Math.max(0, s - 300));
    } else if (target.type === 'golden') {
      sound.playSuccess();
      const currentCombo = combo + 1;
      setCombo(currentCombo);
      const points = 350 + currentCombo * 50;
      setScore((s) => s + points);
    } else {
      sound.playScore();
      const currentCombo = combo + 1;
      setCombo(currentCombo);
      const points = 100 + currentCombo * 20;
      setScore((s) => s + points);
    }

    setTargets((prev) => prev.filter((t) => t.id !== target.id));
  };

  const handleAreaMiss = () => {
    if (gameState !== 'playing') return;
    setCombo(0);
    sound.playTone(160, 'sine', 0.05, 0, 0.05);
  };

  return (
    <div id="speedreflex-container" className="flex flex-col items-center w-full max-w-3xl mx-auto px-4 py-4">
      {/* Top Bar Controls */}
      <div className="flex items-center justify-between w-full mb-3">
        <button
          id="speedreflex-back-btn"
          onClick={onBack}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-900 border border-slate-700 text-slate-300 hover:text-white hover:border-slate-500 transition-colors text-sm font-medium"
        >
          <ArrowLeft className="w-4 h-4" />
          Menu
        </button>

        <div className="flex items-center gap-6">
          <div className="flex items-center gap-1.5 text-xs text-slate-400">
            <Trophy className="w-4 h-4 text-amber-400" />
            <span>High:</span>
            <span className="font-semibold text-amber-300 font-mono">{Math.max(highScore, score)}</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Time:</span>
            <span className={`font-bold font-mono text-base ${timeLeft <= 5 ? 'text-rose-400 animate-ping' : 'text-emerald-400'}`}>
              {timeLeft}s
            </span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <Zap className="w-4 h-4 text-amber-400" />
            <span className="text-slate-400">Combo:</span>
            <span className="font-bold text-amber-300 font-mono text-base">{combo}x</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Score:</span>
            <span className="font-bold text-sky-400 font-mono text-base">{score}</span>
          </div>
        </div>
      </div>

      {/* Target Arena */}
      <div
        id="target-arena"
        ref={playAreaRef}
        onClick={handleAreaMiss}
        className="relative w-full h-[420px] bg-slate-950 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl select-none cursor-crosshair"
      >
        {/* Radar concentric background rings */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-20">
          <div className="w-96 h-96 rounded-full border border-sky-500/30"></div>
          <div className="w-64 h-64 rounded-full border border-sky-500/40 absolute"></div>
          <div className="w-32 h-32 rounded-full border border-sky-500/50 absolute"></div>
        </div>

        {/* Active Targets */}
        {gameState === 'playing' &&
          targets.map((target) => {
            const isGold = target.type === 'golden';
            const isHazard = target.type === 'hazard';

            return (
              <button
                key={target.id}
                id={`target-${target.id}`}
                onClick={(e) => handleTargetClick(target, e)}
                style={{
                  left: `${target.x}px`,
                  top: `${target.y}px`,
                  width: `${target.size}px`,
                  height: `${target.size}px`,
                  transform: 'translate(-50%, -50%)',
                }}
                className={`absolute rounded-full border-2 flex items-center justify-center transition-transform hover:scale-110 active:scale-90 animate-fade-in ${
                  isGold
                    ? 'bg-amber-400/90 border-amber-200 shadow-lg shadow-amber-400/80 animate-pulse'
                    : isHazard
                    ? 'bg-rose-600/90 border-rose-300 shadow-lg shadow-rose-600/80'
                    : 'bg-cyan-500/90 border-cyan-200 shadow-lg shadow-cyan-500/70'
                }`}
              >
                <div
                  className={`rounded-full ${
                    isGold ? 'w-2 h-2 bg-white' : isHazard ? 'w-2.5 h-0.5 bg-white rotate-45' : 'w-2 h-2 bg-white'
                  }`}
                />
              </button>
            );
          })}

        {/* Ready Overlay */}
        {gameState === 'idle' && (
          <div className="absolute inset-0 bg-slate-950/85 backdrop-blur-xs flex flex-col items-center justify-center p-6 text-center">
            <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 mb-1">High-Speed Reaction Protocol</span>
            <h2 className="text-3xl font-bold font-arcade text-white mb-2">TARGET BLITZ</h2>
            <p className="text-slate-400 text-sm max-w-sm mb-6 leading-relaxed">
              Click glowing targets as quickly as they appear! Click <span className="text-amber-400 font-semibold">Gold</span> for bonus points, avoid <span className="text-rose-400 font-semibold">Red Glitches</span>. Build your combo!
            </p>
            <button
              id="start-speedreflex-btn"
              onClick={startGame}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-cyan-500/20"
            >
              <Play className="w-5 h-5 fill-current" />
              START BLITZ (30s)
            </button>
          </div>
        )}

        {/* Game Over Overlay */}
        {gameState === 'gameover' && (
          <div className="absolute inset-0 bg-slate-950/90 backdrop-blur-xs flex flex-col items-center justify-center p-6 text-center animate-fade-in">
            <span className="text-xs font-mono uppercase tracking-widest text-emerald-400 mb-1">Time Expired!</span>
            <h2 className="text-4xl font-extrabold text-white font-arcade mb-2">SESSION OVER</h2>
            <p className="text-slate-400 text-xs mb-1">Final Blitz Score</p>
            <p className="text-4xl font-bold font-mono text-cyan-400 mb-6">{score}</p>
            <div className="flex gap-3">
              <button
                id="retry-speedreflex-btn"
                onClick={startGame}
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105"
              >
                <RotateCcw className="w-4 h-4" />
                PLAY AGAIN
              </button>
              <button
                onClick={onBack}
                className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-medium text-sm transition-colors"
              >
                Exit to Menu
              </button>
            </div>
          </div>
        )}
      </div>

      <div className="flex items-center gap-6 mt-3 text-xs text-slate-400">
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded-full bg-cyan-500"></div>
          <span>Standard (+100)</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded-full bg-amber-400"></div>
          <span>Gold Bonus (+350)</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-3 h-3 rounded-full bg-rose-600"></div>
          <span>Glitch Penalty (-300)</span>
        </div>
      </div>
    </div>
  );
};
