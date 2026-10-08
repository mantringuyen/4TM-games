import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Play, RotateCcw, Trophy, KeyRound, Check, HelpCircle } from 'lucide-react';
import confetti from 'canvas-confetti';
import { sound } from '../utils/audio';

interface CipherBreakerProps {
  onBack: () => void;
  onUpdateHighScore?: (gameId: string, score: number) => void;
  highScore?: number;
}

interface CipherWord {
  word: string;
  hint: string;
  category: string;
}

const WORDS: CipherWord[] = [
  { word: 'PIXEL', hint: 'Smallest addressable element in a raster image', category: 'Graphics' },
  { word: 'ARCADE', hint: 'Classic coin-operated amusement machine venue', category: 'Retro' },
  { word: 'JOYSTICK', hint: 'Omnidirectional handheld game controller', category: 'Hardware' },
  { word: 'GLITCH', hint: 'Sudden, transient fault in a digital system', category: 'Computing' },
  { word: 'MATRIX', hint: 'A rectangular array of numbers or neural network grid', category: 'Cyber' },
  { word: 'AVATAR', hint: 'Graphical representation of a user or alter ego', category: 'Gaming' },
  { word: 'CYBER', hint: 'Relating to computers, digital tech, and cyberspace', category: 'Cyber' },
  { word: 'PORTAL', hint: 'A gateway into alternate dimensional space', category: 'Sci-Fi' },
  { word: 'SPRITE', hint: 'Two-dimensional bitmap integrated into a larger scene', category: 'Graphics' },
  { word: 'COMBO', hint: 'Sequential series of successfully executed actions', category: 'Arcade' },
  { word: 'QUANTUM', hint: 'Minimum amount of any physical entity involved in an interaction', category: 'Tech' },
  { word: 'CONSOLE', hint: 'Dedicated electronic device for video games', category: 'Gaming' },
];

const scramble = (str: string): string => {
  const arr = str.split('');
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  const res = arr.join('');
  return res === str ? scramble(str) : res;
};

export const CipherBreaker: React.FC<CipherBreakerProps> = ({ onBack, onUpdateHighScore, highScore = 0 }) => {
  const [gameState, setGameState] = useState<'idle' | 'playing' | 'gameover'>('idle');
  const [score, setScore] = useState(0);
  const [solvedCount, setSolvedCount] = useState(0);
  const [currentWordIndex, setCurrentWordIndex] = useState(0);
  const [scrambled, setScrambled] = useState('');
  const [inputVal, setInputVal] = useState('');
  const [timeLeft, setTimeLeft] = useState(45);
  const [showHint, setShowHint] = useState(false);
  const [usedWords, setUsedWords] = useState<number[]>([]);

  const inputRef = useRef<HTMLInputElement | null>(null);

  const loadNextWord = (used: number[]) => {
    const available = WORDS.map((_, i) => i).filter((i) => !used.includes(i));
    if (available.length === 0) {
      // Reset used list if all completed
      const idx = Math.floor(Math.random() * WORDS.length);
      setCurrentWordIndex(idx);
      setScrambled(scramble(WORDS[idx].word));
      setUsedWords([idx]);
    } else {
      const idx = available[Math.floor(Math.random() * available.length)];
      setCurrentWordIndex(idx);
      setScrambled(scramble(WORDS[idx].word));
      setUsedWords([...used, idx]);
    }
    setInputVal('');
    setShowHint(false);
  };

  const startGame = () => {
    setScore(0);
    setSolvedCount(0);
    setTimeLeft(45);
    const initialUsed: number[] = [];
    loadNextWord(initialUsed);
    setGameState('playing');
    sound.playClick();
    setTimeout(() => inputRef.current?.focus(), 100);
  };

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

  useEffect(() => {
    if (gameState === 'gameover') {
      onUpdateHighScore?.('cipherbreaker', score);
      if (score > highScore && score > 0) {
        confetti({ particleCount: 80, spread: 70, origin: { y: 0.6 } });
      }
    }
  }, [gameState, score, highScore, onUpdateHighScore]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (gameState !== 'playing') return;

    const current = WORDS[currentWordIndex];
    if (inputVal.trim().toUpperCase() === current.word) {
      sound.playSuccess();
      const points = 200 + (showHint ? 0 : 100) + Math.min(timeLeft, 20) * 10;
      setScore((s) => s + points);
      setSolvedCount((c) => c + 1);
      // Give time bonus
      setTimeLeft((t) => Math.min(60, t + 5));
      loadNextWord(usedWords);
    } else {
      sound.playError();
      setInputVal('');
    }
  };

  const currentWord = WORDS[currentWordIndex] || WORDS[0];

  return (
    <div id="cipher-breaker-container" className="flex flex-col items-center w-full max-w-2xl mx-auto px-4 py-4">
      {/* Top Bar Controls */}
      <div className="flex items-center justify-between w-full mb-4">
        <button
          id="cipher-back-btn"
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
            <span className={`font-bold font-mono text-base ${timeLeft <= 8 ? 'text-rose-400 animate-pulse' : 'text-emerald-400'}`}>
              {timeLeft}s
            </span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Decoded:</span>
            <span className="font-bold text-violet-400 font-mono text-base">{solvedCount}</span>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Score:</span>
            <span className="font-bold text-amber-300 font-mono text-base">{score}</span>
          </div>
        </div>
      </div>

      {/* Main Container */}
      <div className="w-full bg-slate-900/70 border border-slate-800 rounded-2xl p-6 sm:p-8 backdrop-blur-xs flex flex-col items-center shadow-xl">
        {gameState === 'idle' && (
          <div className="flex flex-col items-center text-center py-6">
            <div className="w-14 h-14 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400 mb-4 shadow-lg shadow-amber-500/10">
              <KeyRound className="w-7 h-7" />
            </div>
            <span className="text-xs font-mono uppercase tracking-widest text-amber-400 mb-1">Encrypted Payload Challenge</span>
            <h2 className="text-3xl font-bold font-arcade text-white mb-2">CIPHER BREAKER</h2>
            <p className="text-slate-400 text-sm max-w-sm mb-6 leading-relaxed">
              Unscramble encrypted keywords before time runs out! Each solved cipher awards bonus time and score multiplier.
            </p>
            <button
              id="start-cipher-btn"
              onClick={startGame}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-amber-500/20"
            >
              <Play className="w-5 h-5 fill-current" />
              COMMENCE DECRYPTION
            </button>
          </div>
        )}

        {gameState === 'playing' && (
          <div className="w-full max-w-md flex flex-col items-center">
            <div className="flex items-center gap-2 mb-3">
              <span className="text-[11px] font-mono px-2.5 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
                CATEGORY: {currentWord.category.toUpperCase()}
              </span>
              <span className="text-[11px] font-mono text-slate-500">
                {currentWord.word.length} LETTERS
              </span>
            </div>

            {/* Scrambled Word Letter Blocks */}
            <div className="flex flex-wrap justify-center gap-2 mb-6">
              {scrambled.split('').map((char, index) => (
                <div
                  key={index}
                  className="w-12 h-14 sm:w-14 sm:h-16 rounded-xl bg-slate-950 border-2 border-amber-500/60 shadow-lg shadow-amber-500/20 flex items-center justify-center text-2xl sm:text-3xl font-bold font-mono text-amber-400 select-none animate-bounce"
                  style={{ animationDelay: `${index * 80}ms`, animationDuration: '1.2s' }}
                >
                  {char}
                </div>
              ))}
            </div>

            {/* Hint toggler */}
            <div className="w-full flex justify-end mb-2">
              <button
                type="button"
                onClick={() => setShowHint(!showHint)}
                className="flex items-center gap-1 text-xs text-slate-400 hover:text-amber-400 transition-colors"
              >
                <HelpCircle className="w-3.5 h-3.5" />
                {showHint ? 'Hide Hint' : 'Reveal Hint (-100pts)'}
              </button>
            </div>

            {showHint && (
              <div className="w-full mb-4 p-3 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs text-center animate-fade-in">
                💡 <span className="italic">{currentWord.hint}</span>
              </div>
            )}

            {/* Decryption input form */}
            <form onSubmit={handleSubmit} className="w-full flex gap-2">
              <input
                ref={inputRef}
                type="text"
                value={inputVal}
                onChange={(e) => setInputVal(e.target.value.toUpperCase())}
                placeholder="ENTER DECRYPTED WORD..."
                maxLength={currentWord.word.length + 2}
                autoComplete="off"
                className="flex-1 bg-slate-950 border border-slate-700 focus:border-amber-500 rounded-xl px-4 py-3 font-mono text-lg text-white tracking-widest text-center focus:outline-none transition-colors"
              />
              <button
                type="submit"
                className="px-5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold flex items-center justify-center transition-transform active:scale-95 shadow-md shadow-amber-500/20"
              >
                <Check className="w-5 h-5 stroke-[2.5]" />
              </button>
            </form>
          </div>
        )}

        {gameState === 'gameover' && (
          <div className="flex flex-col items-center text-center py-6 animate-fade-in">
            <span className="text-xs font-mono uppercase tracking-widest text-rose-400 mb-1">Time Elapsed</span>
            <h2 className="text-4xl font-extrabold text-white font-arcade mb-2">SYSTEM LOCKED</h2>
            <p className="text-slate-400 text-xs mb-1">Ciphers Solved: {solvedCount}</p>
            <p className="text-4xl font-bold font-mono text-amber-400 mb-6">Score: {score}</p>
            <div className="flex gap-3">
              <button
                id="retry-cipher-btn"
                onClick={startGame}
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105"
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
    </div>
  );
};
