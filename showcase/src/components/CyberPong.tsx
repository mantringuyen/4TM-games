import React, { useEffect, useRef, useState, useCallback } from 'react';
import { Play, RotateCcw, ArrowLeft, Trophy } from 'lucide-react';
import confetti from 'canvas-confetti';
import { sound } from '../utils/audio';

interface CyberPongProps {
  onBack: () => void;
  onUpdateHighScore?: (gameId: string, score: number) => void;
  highScore?: number;
}

interface Ball {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  color: string;
}

interface Block {
  x: number;
  y: number;
  w: number;
  h: number;
  hp: number;
  maxHp: number;
  color: string;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  alpha: number;
  color: string;
  size: number;
}

export const CyberPong: React.FC<CyberPongProps> = ({ onBack, onUpdateHighScore, highScore = 0 }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [gameState, setGameState] = useState<'ready' | 'playing' | 'gameover' | 'victory'>('ready');
  const [score, setScore] = useState(0);
  const [lives, setLives] = useState(3);
  const [_combo, setCombo] = useState(0);

  const gameStateRef = useRef({
    score: 0,
    lives: 3,
    state: 'ready' as 'ready' | 'playing' | 'gameover' | 'victory',
    paddleX: 200,
    paddleW: 90,
    paddleH: 14,
    balls: [] as Ball[],
    blocks: [] as Block[],
    particles: [] as Particle[],
    isLeftPressed: false,
    isRightPressed: false,
    canvasW: 600,
    canvasH: 500,
  });

  const initGame = useCallback(() => {
    const w = 600;
    const h = 500;
    const paddleW = 96;
    gameStateRef.current.canvasW = w;
    gameStateRef.current.canvasH = h;
    gameStateRef.current.paddleW = paddleW;
    gameStateRef.current.paddleX = (w - paddleW) / 2;
    gameStateRef.current.score = 0;
    gameStateRef.current.lives = 3;
    gameStateRef.current.state = 'playing';
    gameStateRef.current.particles = [];

    // Initialize ball
    gameStateRef.current.balls = [
      {
        x: w / 2,
        y: h - 60,
        vx: 4 * (Math.random() > 0.5 ? 1 : -1),
        vy: -4.5,
        radius: 7,
        color: '#38bdf8',
      },
    ];

    // Initialize blocks (grid of neon blocks)
    const blocks: Block[] = [];
    const rows = 4;
    const cols = 7;
    const padding = 8;
    const blockH = 20;
    const totalPadding = (cols + 1) * padding;
    const blockW = (w - totalPadding) / cols;

    const rowColors = ['#f43f5e', '#fb923c', '#eab308', '#06b6d4'];

    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        blocks.push({
          x: padding + c * (blockW + padding),
          y: 45 + r * (blockH + padding),
          w: blockW,
          h: blockH,
          hp: r === 0 ? 2 : 1,
          maxHp: r === 0 ? 2 : 1,
          color: rowColors[r],
        });
      }
    }
    gameStateRef.current.blocks = blocks;

    setScore(0);
    setLives(3);
    setCombo(0);
    setGameState('playing');
    sound.playClick();
  }, []);

  // Controls handler
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
        gameStateRef.current.isLeftPressed = true;
      }
      if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
        gameStateRef.current.isRightPressed = true;
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft' || e.key === 'a' || e.key === 'A') {
        gameStateRef.current.isLeftPressed = false;
      }
      if (e.key === 'ArrowRight' || e.key === 'd' || e.key === 'D') {
        gameStateRef.current.isRightPressed = false;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, []);

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const clientX = (e.clientX - rect.left) * scaleX;
    gameStateRef.current.paddleX = Math.max(
      0,
      Math.min(canvas.width - gameStateRef.current.paddleW, clientX - gameStateRef.current.paddleW / 2)
    );
  };

  // Main game loop
  useEffect(() => {
    let animId: number;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const render = () => {
      const g = gameStateRef.current;
      const { canvasW, canvasH } = g;

      // Update paddle by keyboard
      if (g.isLeftPressed) {
        g.paddleX = Math.max(0, g.paddleX - 8);
      }
      if (g.isRightPressed) {
        g.paddleX = Math.min(canvasW - g.paddleW, g.paddleX + 8);
      }

      // Clear canvas
      ctx.fillStyle = '#090d16';
      ctx.fillRect(0, 0, canvasW, canvasH);

      // Draw subtle grid lines
      ctx.strokeStyle = '#1e293b22';
      ctx.lineWidth = 1;
      for (let x = 0; x < canvasW; x += 30) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvasH);
        ctx.stroke();
      }
      for (let y = 0; y < canvasH; y += 30) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(canvasW, y);
        ctx.stroke();
      }

      // Draw blocks
      g.blocks.forEach((b) => {
        if (b.hp <= 0) return;
        ctx.fillStyle = b.color;
        ctx.shadowColor = b.color;
        ctx.shadowBlur = b.hp === b.maxHp ? 8 : 2;
        ctx.fillRect(b.x, b.y, b.w, b.h);
        ctx.shadowBlur = 0;

        // Inner highlight
        ctx.fillStyle = '#ffffff22';
        ctx.fillRect(b.x + 2, b.y + 2, b.w - 4, 3);
      });

      // Draw Paddle
      const paddleY = canvasH - 24;
      ctx.fillStyle = '#38bdf8';
      ctx.shadowColor = '#0284c7';
      ctx.shadowBlur = 10;
      ctx.beginPath();
      ctx.roundRect(g.paddleX, paddleY, g.paddleW, g.paddleH, [6, 6, 4, 4]);
      ctx.fill();
      ctx.shadowBlur = 0;

      // Paddle neon center stripe
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(g.paddleX + g.paddleW / 2 - 10, paddleY + 4, 20, 3);

      if (g.state === 'playing') {
        // Update & draw balls
        for (let i = g.balls.length - 1; i >= 0; i--) {
          const ball = g.balls[i];
          ball.x += ball.vx;
          ball.y += ball.vy;

          // Wall bounces
          if (ball.x - ball.radius <= 0) {
            ball.x = ball.radius;
            ball.vx = Math.abs(ball.vx);
            sound.playHit();
          } else if (ball.x + ball.radius >= canvasW) {
            ball.x = canvasW - ball.radius;
            ball.vx = -Math.abs(ball.vx);
            sound.playHit();
          }

          if (ball.y - ball.radius <= 0) {
            ball.y = ball.radius;
            ball.vy = Math.abs(ball.vy);
            sound.playHit();
          }

          // Paddle collision
          if (
            ball.y + ball.radius >= paddleY &&
            ball.y - ball.radius <= paddleY + g.paddleH &&
            ball.x + ball.radius >= g.paddleX &&
            ball.x - ball.radius <= g.paddleX + g.paddleW &&
            ball.vy > 0
          ) {
            ball.y = paddleY - ball.radius;
            // Angle based on where ball hits paddle
            const hitOffset = (ball.x - (g.paddleX + g.paddleW / 2)) / (g.paddleW / 2);
            const speed = Math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
            const maxAngle = Math.PI / 3; // 60 deg max
            const angle = hitOffset * maxAngle;
            ball.vx = speed * Math.sin(angle);
            ball.vy = -Math.abs(speed * Math.cos(angle));

            sound.playHit();

            // Particle spark
            for (let p = 0; p < 6; p++) {
              g.particles.push({
                x: ball.x,
                y: paddleY,
                vx: (Math.random() - 0.5) * 4,
                vy: -Math.random() * 3 - 1,
                alpha: 1,
                color: '#38bdf8',
                size: Math.random() * 3 + 2,
              });
            }
          }

          // Block collisions
          for (const b of g.blocks) {
            if (b.hp <= 0) continue;
            if (
              ball.x + ball.radius >= b.x &&
              ball.x - ball.radius <= b.x + b.w &&
              ball.y + ball.radius >= b.y &&
              ball.y - ball.radius <= b.y + b.h
            ) {
              b.hp -= 1;
              ball.vy = -ball.vy;
              const points = 100 * (b.maxHp);
              g.score += points;
              setScore(g.score);
              setCombo((c) => c + 1);

              sound.playScore();

              // Explosion particles
              for (let p = 0; p < 8; p++) {
                g.particles.push({
                  x: b.x + b.w / 2,
                  y: b.y + b.h / 2,
                  vx: (Math.random() - 0.5) * 6,
                  vy: (Math.random() - 0.5) * 6,
                  alpha: 1,
                  color: b.color,
                  size: Math.random() * 3 + 2,
                });
              }
              break;
            }
          }

          // Check if ball fell below screen
          if (ball.y - ball.radius > canvasH) {
            g.balls.splice(i, 1);
          }
        }

        // Check if all balls lost
        if (g.balls.length === 0) {
          g.lives -= 1;
          setLives(g.lives);
          setCombo(0);
          sound.playError();

          if (g.lives <= 0) {
            g.state = 'gameover';
            setGameState('gameover');
            sound.playGameOver();
            onUpdateHighScore?.('cyberpong', g.score);
          } else {
            // Respawn ball
            g.balls.push({
              x: canvasW / 2,
              y: canvasH - 60,
              vx: 4 * (Math.random() > 0.5 ? 1 : -1),
              vy: -4.5,
              radius: 7,
              color: '#38bdf8',
            });
          }
        }

        // Check victory
        const remainingBlocks = g.blocks.filter((b) => b.hp > 0).length;
        if (remainingBlocks === 0 && g.blocks.length > 0) {
          g.state = 'victory';
          setGameState('victory');
          sound.playSuccess();
          confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
          onUpdateHighScore?.('cyberpong', g.score + 1000);
          setScore(g.score + 1000);
        }
      }

      // Draw balls
      g.balls.forEach((ball) => {
        ctx.fillStyle = ball.color;
        ctx.shadowColor = ball.color;
        ctx.shadowBlur = 12;
        ctx.beginPath();
        ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;
      });

      // Update & draw particles
      for (let i = g.particles.length - 1; i >= 0; i--) {
        const p = g.particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.alpha -= 0.03;
        if (p.alpha <= 0) {
          g.particles.splice(i, 1);
          continue;
        }
        ctx.save();
        ctx.globalAlpha = p.alpha;
        ctx.fillStyle = p.color;
        ctx.fillRect(p.x, p.y, p.size, p.size);
        ctx.restore();
      }

      animId = requestAnimationFrame(render);
    };

    animId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animId);
  }, [onUpdateHighScore]);

  return (
    <div id="cyberpong-container" className="flex flex-col items-center w-full max-w-4xl mx-auto px-4 py-4">
      {/* Top Bar Controls */}
      <div className="flex items-center justify-between w-full max-w-[600px] mb-3">
        <button
          id="cyberpong-back-btn"
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

          <div className="flex items-center gap-2 text-xs">
            <span className="text-slate-400">Lives:</span>
            <div className="flex gap-1">
              {[...Array(3)].map((_, i) => (
                <div
                  key={i}
                  className={`w-2.5 h-2.5 rounded-full ${i < lives ? 'bg-rose-500 shadow-sm shadow-rose-500' : 'bg-slate-800'}`}
                />
              ))}
            </div>
          </div>

          <div className="flex items-center gap-1.5 text-xs">
            <span className="text-slate-400">Score:</span>
            <span className="font-bold text-sky-400 font-mono text-base">{score}</span>
          </div>
        </div>
      </div>

      {/* Game Stage Canvas */}
      <div className="relative border border-slate-800 rounded-xl overflow-hidden shadow-2xl bg-slate-950">
        <canvas
          id="cyberpong-canvas"
          ref={canvasRef}
          width={600}
          height={500}
          onPointerMove={handlePointerMove}
          className="touch-none block w-full max-w-[600px] cursor-none"
          style={{ aspectRatio: '600 / 500' }}
        />

        {/* Overlay screens */}
        {gameState === 'ready' && (
          <div className="absolute inset-0 bg-slate-950/85 backdrop-blur-xs flex flex-col items-center justify-center p-6 text-center">
            <h2 className="text-3xl font-bold text-sky-400 font-arcade mb-2 tracking-wide">CYBER PONG</h2>
            <p className="text-slate-400 text-sm max-w-sm mb-6 leading-relaxed">
              Use mouse, touch, or Left/Right arrow keys to move the paddle. Clear all cyber blocks without letting the orb drop!
            </p>
            <button
              id="cyberpong-start-btn"
              onClick={initGame}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-sky-500 hover:bg-sky-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105 active:scale-95 shadow-lg shadow-sky-500/30"
            >
              <Play className="w-5 h-5 fill-current" />
              START GAME
            </button>
          </div>
        )}

        {gameState === 'gameover' && (
          <div className="absolute inset-0 bg-slate-950/90 backdrop-blur-xs flex flex-col items-center justify-center p-6 text-center animate-fade-in">
            <span className="text-xs font-mono font-semibold uppercase tracking-widest text-rose-400 mb-1">System Overload</span>
            <h2 className="text-4xl font-extrabold text-rose-500 font-arcade mb-2">GAME OVER</h2>
            <p className="text-slate-300 text-sm mb-1 font-medium">Final Score</p>
            <p className="text-3xl font-bold text-white font-mono mb-6">{score}</p>
            <div className="flex gap-3">
              <button
                id="cyberpong-retry-btn"
                onClick={initGame}
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-sky-500 hover:bg-sky-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105"
              >
                <RotateCcw className="w-4 h-4" />
                PLAY AGAIN
              </button>
              <button
                id="cyberpong-menu-btn"
                onClick={onBack}
                className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-medium text-sm transition-colors"
              >
                Exit to Menu
              </button>
            </div>
          </div>
        )}

        {gameState === 'victory' && (
          <div className="absolute inset-0 bg-slate-950/90 backdrop-blur-xs flex flex-col items-center justify-center p-6 text-center">
            <span className="text-xs font-mono font-semibold uppercase tracking-widest text-emerald-400 mb-1">Stage Cleared!</span>
            <h2 className="text-4xl font-extrabold text-emerald-400 font-arcade mb-2">VICTORY</h2>
            <p className="text-slate-300 text-sm mb-1">All grids breached! +1000 Bonus</p>
            <p className="text-3xl font-bold text-emerald-300 font-mono mb-6">{score}</p>
            <div className="flex gap-3">
              <button
                id="cyberpong-victory-retry-btn"
                onClick={initGame}
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold font-arcade tracking-wider transition-all transform hover:scale-105"
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

      <div className="mt-3 text-xs text-slate-500 text-center">
        Controls: Mouse/Touch drag or <kbd className="px-1 py-0.5 bg-slate-800 rounded text-slate-400">A</kbd> / <kbd className="px-1 py-0.5 bg-slate-800 rounded text-slate-400">D</kbd> or <kbd className="px-1 py-0.5 bg-slate-800 rounded text-slate-400">&larr;</kbd> / <kbd className="px-1 py-0.5 bg-slate-800 rounded text-slate-400">&rarr;</kbd>
      </div>
    </div>
  );
};
