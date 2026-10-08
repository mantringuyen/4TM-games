import React, { useState, useRef } from 'react';
import { ArrowLeft, Play, RotateCcw, Trophy, Sparkles } from 'lucide-react';
import confetti from 'canvas-confetti';
import { sound } from '../utils/audio';

interface MemoryMatrixProps {
  onBack: () => void;
  onUpdateHighScore?: (gameId: string, score: number) => void;
  highScore?: number;
}

const PAD_CONFIG = [
  { id: 0, label: 'ALPHA', color: 'bg-emerald-500', glow: 'shadow-emerald-500/70', border: 'border-emerald-400', freq: 330 },
  { id: 1, label: 'BETA', color: 'bg-cyan-500', glow: 'shadow-cyan-500/70', border: 'border-cyan-400', freq: 440 },
  { id: 2, label: 'GAMMA', color: 'bg-violet-500', glow: 'shadow-violet-500/70', border: 'border-violet-400', freq: 554 },
  { id: 3, label: 'DELTA', color: 'bg-amber-500', glow: 'shadow-amber-500/70', border: 'border-amber-400', freq: 659 },
  { id: 4, label: 'EPSILON', color: 'bg-rose-500', glow: 'shadow-rose-500/70', border: 'border-rose-400', freq: 784 },
  { id: 5, label: 'ZETA', color: 'bg-fuchsia-500', glow: 'shadow-fuchsia-500/70', border: 'border-fuchsia-400', freq: 880 },
];

export const MemoryMatrix: React.FC<MemoryMatrixProps> = ({ onBack, onUpdateHighScore, highScore = 0 }) => {
  const [sequence, setSequence] = useState<number[]>([]);
  const [playerStep, setPlayerStep] = useState<number>(0);
  const [activePad, setActivePad] = useState<number | null>(null);
  const [status, setStatus] = useState<'idle' | 'showing' | 'player_turn' | 'gameover'>('idle');
  const [score, setScore] = useState<number>(0);
  const [round, setRound] = useState<number>(1);

  const isShowingSequence = useRef(false);

  const startNewGame = () => {
    setScore(0);
    setRound(1);
    const initialSeq = [Math.floor(Math.random() * 6)];
    setSequence(initialSeq);
    setPlayerStep(0);
    sound.playClick();
    playSequence(initialSeq);
  };

  const playSequence = async (seq: number[]) => {
    setStatus('showing');
    isShowingSequence.current = true;
    setPlayerStep(0);

    // Wait a brief initial moment
    await new Promise((r) => setTimeout(r, 600));

    for (let i = 0; i < seq.length; i++) {
      const padId = seq[i];
      setActivePad(padId);
      const pad = PAD_CONFIG[padId];
      sound.playTone(pad.freq, 'sine', 0.25, 0, 0.18);

      await new Promise((r) => setTimeout(r, 450));
      setActivePad(null);
      await new Promise((r) => setTimeout(r, 120));
    }

    isShowingSequence.current = false;
    setStatus('player_turn');
  };

  const handlePadClick = (padId: number) => {
    if (status !== 'player_turn' || isShowingSequence.current) return;

    // Flash clicked pad
    setActivePad(padId);
    const pad = PAD_CONFIG[padId];
    sound.playTone(pad.freq, 'sine', 0.2, 0, 0.2);
    setTimeout(() => setActivePad(null), 250);

    // Check correctness
    if (padId === sequence[playerStep]) {
      const nextStep = playerStep + 1;
      setPlayerStep(nextStep);

      // Completed full sequence for this round!
      if (nextStep === sequence.length) {
        const roundPoints = sequence.length * 150;
        const newScore = score + roundPoints;
        setScore(newScore);
        sound.playSuccess();

        if (round % 5 === 0) {
          confetti({ particleCount: 50, spread: 60, origin: { y: 0.7 } });
        }

        const nextRound = round + 1;
        setRound(nextRound);

        // Add new step
        const nextSeq = [...sequence, Math.floor(Math.random() * 6)];
        setSequence(nextSeq);
        setTimeout(() => playSequence(nextSeq), 700);
      }
    } else {
      // Wrong pad clicked
      sound.playError();
      setStatus('gameover');
      onUpdateHighScore?.('memorymatrix', score);
    }
  };

  return (
    <div id="memory-matrix-container" className="flex flex-col items-center w-full max-w-2xl mx-auto px-4 py-4">
      {/* Top Bar Controls */}
      <div className="flex items-center justify-between w-full mb-6">
        <button
          id="memory-back-btn"
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
            <span className="text-slate-400">Round:</span>
            <span className="font-bold text-violet-400 font-mono text-base">{round}</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Score:</span>
            <span className="font-bold text-cyan-400 font-mono text-base">{score}</span>
          </div>
        </div>
      </div>

      {/* Main Game Stage */}
      <div className="w-full bg-slate-900/60 border border-slate-800 rounded-2xl p-6 sm:p-8 backdrop-blur-xs flex flex-col items-center shadow-xl">
        <div className="text-center mb-6">
          <span className="text-xs font-mono uppercase tracking-widest text-cyan-400">Neural Sync Matrix</span>
          <h2 className="text-2xl font-bold font-arcade text-white tracking-wide mt-0.5">MEMORY SEQUENCE</h2>
          <p className="text-xs text-slate-400 mt-1">
            {status === 'idle' && 'Memorize and replay the escalating audiovisual sequence.'}
            {status === 'showing' && 'Observe pattern carefully...'}
            {status === 'player_turn' && `Your turn: step ${playerStep + 1} of ${sequence.length}`}
            {status === 'gameover' && 'Sequence desynchronized!'}
          </p>
        </div>

        {/* 6 Pads Matrix (2x3) */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3.5 sm:gap-4 w-full max-w-md">
          {PAD_CONFIG.map((pad) => {
            const isActive = activePad === pad.id;
            return (
              <button
                key={pad.id}
                id={`pad-${pad.id}`}
                disabled={status !== 'player_turn'}
                onClick={() => handlePadClick(pad.id)}
                className={`h-24 sm:h-28 rounded-xl border-2 transition-all duration-150 flex flex-col items-center justify-center p-3 relative overflow-hidden select-none active:scale-95 ${
                  isActive
                    ? `${pad.color} ${pad.border} ${pad.glow} shadow-xl scale-98 text-slate-950 font-bold brightness-125`
                    : 'bg-slate-950/80 border-slate-800 text-slate-400 hover:border-slate-600 hover:text-slate-200'
                } ${status !== 'player_turn' ? 'cursor-default' : 'cursor-pointer'}`}
              >
                <div
                  className={`w-3 h-3 rounded-full mb-2 transition-colors ${
                    isActive ? 'bg-white shadow-xs shadow-white' : 'bg-slate-700'
                  }`}
                />
                <span className="font-arcade text-xs tracking-wider uppercase font-semibold">{pad.label}</span>
                <span className="font-mono text-[10px] opacity-60 mt-0.5">{pad.freq}Hz</span>
              </button>
            );
          })}
        </div>

        {/* Action Button */}
        <div className="mt-8 flex justify-center">
          {status === 'idle' && (
            <button
              id="start-memory-btn"
              onClick={startNewGame}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-cyan-500/20"
            >
              <Play className="w-4 h-4 fill-current" />
              START SEQUENCE
            </button>
          )}

          {status === 'gameover' && (
            <div className="flex flex-col items-center animate-fade-in">
              <div className="text-center mb-4">
                <span className="text-xs text-rose-400 font-mono">DESYNC AT ROUND {round}</span>
                <p className="text-xl font-bold font-mono text-white">Score: {score}</p>
              </div>
              <button
                id="retry-memory-btn"
                onClick={startNewGame}
                className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105"
              >
                <RotateCcw className="w-4 h-4" />
                TRY AGAIN
              </button>
            </div>
          )}

          {status === 'player_turn' && (
            <div className="text-xs font-mono text-slate-400 bg-slate-950/80 px-4 py-1.5 rounded-full border border-slate-800">
              Input step {playerStep + 1} / {sequence.length}
            </div>
          )}

          {status === 'showing' && (
            <div className="flex items-center gap-2 text-xs font-mono text-cyan-400 bg-cyan-950/40 px-4 py-1.5 rounded-full border border-cyan-800/40 animate-pulse">
              <Sparkles className="w-3.5 h-3.5" />
              Transmitting neural pattern...
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
