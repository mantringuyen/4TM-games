import { useState } from 'react';
import { GAME_CATALOG } from './data/games';
import { GameMetadata } from './types/game';
import { GameCard } from './components/GameCard';
import { GameDetailModal } from './components/GameDetailModal';

// Playable showcase demo components
import { CyberPong } from './components/CyberPong';
import { MemoryMatrix } from './components/MemoryMatrix';
import { SpeedReflex } from './components/SpeedReflex';
import { CipherBreaker } from './components/CipherBreaker';

import {
  Gamepad2,
  Sparkles,
  ExternalLink,
  Volume2,
  VolumeX,
  ArrowLeft,
  LayoutGrid,
  Code2,
  Globe,
  Layers,
  ChevronRight,
} from 'lucide-react';
import { sound } from './utils/audio';

export default function App() {
  const [selectedCategory, setSelectedCategory] = useState<'all' | 'flagship' | 'playable' | 'dev'>('all');
  const [activeGameModal, setActiveGameModal] = useState<GameMetadata | null>(null);
  const [activePlayableGame, setActivePlayableGame] = useState<GameMetadata | null>(null);
  const [isMuted, setIsMuted] = useState<boolean>(sound.getMuted());

  const toggleAudio = () => {
    const muted = sound.toggleMute();
    setIsMuted(muted);
  };

  const filteredGames = GAME_CATALOG.filter((game) => {
    if (selectedCategory === 'flagship') return game.id === 'block-puzzle';
    if (selectedCategory === 'playable') return game.isPlayableWeb;
    if (selectedCategory === 'dev') return game.status === 'in_development';
    return true;
  });

  const flagshipGame = GAME_CATALOG.find((g) => g.id === 'block-puzzle') || GAME_CATALOG[0];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans selection:bg-cyan-500 selection:text-slate-950">
      {/* Ecosystem Header */}
      <header className="sticky top-0 z-40 border-b border-slate-800/80 bg-slate-950/90 backdrop-blur-md">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6">
          {/* Logo & Brand */}
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600 p-2 shadow-lg shadow-cyan-500/20">
              <Gamepad2 className="h-6 w-6 text-slate-950" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-black text-lg tracking-tight text-white font-mono">4TM GAMES</span>
                <span className="rounded bg-cyan-500/10 px-2 py-0.5 text-[10px] font-bold text-cyan-400 border border-cyan-500/20 font-mono">
                  SHOWCASE
                </span>
              </div>
              <p className="text-xs text-slate-400 font-mono">games.4tm.io.vn</p>
            </div>
          </div>

          {/* Header Controls & Ecosystem Link */}
          <div className="flex items-center gap-3">
            <button
              onClick={toggleAudio}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-800 bg-slate-900 px-3 py-1.5 text-xs font-semibold text-slate-300 hover:border-slate-700 hover:text-white transition-colors cursor-pointer"
              title="Toggle Audio"
            >
              {isMuted ? <VolumeX className="h-4 w-4 text-rose-400" /> : <Volume2 className="h-4 w-4 text-cyan-400" />}
              <span className="hidden sm:inline">{isMuted ? 'Muted' : 'Audio ON'}</span>
            </button>

            <a
              href="https://4tm.io.vn"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-1.5 rounded-lg border border-cyan-500/30 bg-cyan-500/10 px-3 py-1.5 text-xs font-semibold text-cyan-300 hover:bg-cyan-500/20 transition-colors"
            >
              <Globe className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">Ecosystem Hub</span>
              <ExternalLink className="h-3 w-3" />
            </a>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      {activePlayableGame ? (
        /* Active Playable Game View */
        <main className="flex-1 bg-slate-950 px-4 py-6 sm:px-6">
          <div className="mx-auto max-w-6xl">
            {/* Game Top Navigation */}
            <div className="mb-6 flex flex-wrap items-center justify-between gap-4 border-b border-slate-800 pb-4">
              <button
                onClick={() => setActivePlayableGame(null)}
                className="inline-flex items-center gap-2 rounded-xl border border-slate-800 bg-slate-900 px-4 py-2 text-sm font-bold text-slate-200 hover:border-slate-700 hover:bg-slate-800 hover:text-white transition-all cursor-pointer"
              >
                <ArrowLeft className="h-4 w-4" /> Back to Showcase Catalog
              </button>

              <div className="flex items-center gap-3">
                <span className="text-sm font-bold text-white font-mono">{activePlayableGame.title}</span>
                <span className="rounded-full bg-emerald-500/10 px-2.5 py-0.5 text-xs font-semibold text-emerald-400 border border-emerald-500/20">
                  Demo Game
                </span>
              </div>
            </div>

            {/* Render Selected Playable Game Component */}
            <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-2 sm:p-6 shadow-2xl">
              {activePlayableGame.id === 'cyberpong' && <CyberPong onBack={() => setActivePlayableGame(null)} />}
              {activePlayableGame.id === 'memorymatrix' && <MemoryMatrix onBack={() => setActivePlayableGame(null)} />}
              {activePlayableGame.id === 'speedreflex' && <SpeedReflex onBack={() => setActivePlayableGame(null)} />}
              {activePlayableGame.id === 'cipherbreaker' && <CipherBreaker onBack={() => setActivePlayableGame(null)} />}
            </div>
          </div>
        </main>
      ) : (
        /* Showcase Hub View */
        <main className="flex-1">
          {/* Showcase Hero Header */}
          <section className="relative overflow-hidden border-b border-slate-800/80 bg-gradient-to-b from-slate-900/80 to-slate-950 py-12 px-4 sm:px-6">
            <div className="mx-auto max-w-7xl">
              <div className="max-w-3xl">
                <div className="inline-flex items-center gap-2 rounded-full border border-cyan-500/30 bg-cyan-500/10 px-3.5 py-1 text-xs font-bold text-cyan-300 mb-4 font-mono">
                  <Sparkles className="h-3.5 w-3.5" /> 4TM ECOSYSTEM GAMES HUB
                </div>
                <h1 className="text-3xl font-black tracking-tight text-white sm:text-5xl">
                  4TM Showcase & Game Catalog
                </h1>
                <p className="mt-4 text-base text-slate-300 leading-relaxed sm:text-lg">
                  Official game discovery portal for 2D cross-platform games and playable arcade demos, powered by the
                  4TM Ecosystem.
                </p>
              </div>

              {/* Spotlight Banner: Xếp Gạch — 4TM Flagship */}
              <div className="mt-8 rounded-2xl border border-amber-500/30 bg-gradient-to-r from-amber-950/40 via-slate-900 to-slate-900 p-6 sm:p-8 shadow-xl">
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
                  <div className="space-y-3 max-w-2xl">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/20 px-3 py-1 text-xs font-bold text-amber-300 border border-amber-500/40">
                        <Code2 className="h-3.5 w-3.5" /> Flagship Project
                      </span>
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-800 px-3 py-1 text-xs font-mono font-medium text-slate-300 border border-slate-700">
                        <Layers className="h-3.5 w-3.5 text-cyan-400" /> Godot 4.x (2D)
                      </span>
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/10 px-3 py-1 text-xs font-mono font-semibold text-amber-400 border border-amber-500/30">
                        Status: In Development
                      </span>
                    </div>

                    <h2 className="text-2xl font-extrabold text-white sm:text-3xl flex items-center gap-3">
                      <LayoutGrid className="h-7 w-7 text-amber-400" />
                      Xếp Gạch — 4TM
                    </h2>

                    <p className="text-sm text-slate-300 leading-relaxed">
                      {flagshipGame.shortDescription}
                    </p>

                    <div className="flex flex-wrap items-center gap-4 text-xs font-mono text-slate-400 pt-2">
                      <span>Targets: Web, Android, iOS, PC</span>
                      <span>•</span>
                      <span>Route: games.4tm.io.vn/games/block-puzzle</span>
                    </div>
                  </div>

                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 shrink-0">
                    <button
                      onClick={() => setActiveGameModal(flagshipGame)}
                      className="inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500 px-5 py-3 text-sm font-bold text-slate-950 hover:bg-amber-400 transition-all cursor-pointer shadow-lg shadow-amber-500/20 active:scale-95"
                    >
                      View Specs & Development Roadmap
                      <ChevronRight className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Catalog Section */}
          <section className="mx-auto max-w-7xl px-4 py-10 sm:px-6">
            {/* Category Filter Tabs */}
            <div className="flex flex-wrap items-center justify-between gap-4 mb-8 pb-4 border-b border-slate-800">
              <div className="flex flex-wrap items-center gap-2">
                <button
                  onClick={() => setSelectedCategory('all')}
                  className={`rounded-xl px-4 py-2 text-xs font-bold transition-all cursor-pointer ${
                    selectedCategory === 'all'
                      ? 'bg-cyan-500 text-slate-950 shadow-md shadow-cyan-500/20'
                      : 'bg-slate-900 text-slate-300 hover:bg-slate-800 hover:text-white border border-slate-800'
                  }`}
                >
                  All Catalog ({GAME_CATALOG.length})
                </button>
                <button
                  onClick={() => setSelectedCategory('flagship')}
                  className={`rounded-xl px-4 py-2 text-xs font-bold transition-all cursor-pointer ${
                    selectedCategory === 'flagship'
                      ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-500/20'
                      : 'bg-slate-900 text-slate-300 hover:bg-slate-800 hover:text-white border border-slate-800'
                  }`}
                >
                  Flagship (1)
                </button>
                <button
                  onClick={() => setSelectedCategory('playable')}
                  className={`rounded-xl px-4 py-2 text-xs font-bold transition-all cursor-pointer ${
                    selectedCategory === 'playable'
                      ? 'bg-cyan-500 text-slate-950 shadow-md shadow-cyan-500/20'
                      : 'bg-slate-900 text-slate-300 hover:bg-slate-800 hover:text-white border border-slate-800'
                  }`}
                >
                  Playable Demos (4)
                </button>
                <button
                  onClick={() => setSelectedCategory('dev')}
                  className={`rounded-xl px-4 py-2 text-xs font-bold transition-all cursor-pointer ${
                    selectedCategory === 'dev'
                      ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-500/20'
                      : 'bg-slate-900 text-slate-300 hover:bg-slate-800 hover:text-white border border-slate-800'
                  }`}
                >
                  In Development (1)
                </button>
              </div>

              <div className="text-xs font-mono text-slate-400">
                Showcase Domain: <span className="text-cyan-400">games.4tm.io.vn</span>
              </div>
            </div>

            {/* Grid of Games */}
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {filteredGames.map((game) => (
                <GameCard
                  key={game.id}
                  game={game}
                  onSelect={(g) => setActiveGameModal(g)}
                  onPlayDirect={(g) => setActivePlayableGame(g)}
                />
              ))}
            </div>
          </section>
        </main>
      )}

      {/* Game Specification Modal */}
      <GameDetailModal
        game={activeGameModal}
        onClose={() => setActiveGameModal(null)}
        onPlay={(g) => setActivePlayableGame(g)}
      />

      {/* Showcase Footer */}
      <footer className="border-t border-slate-800/80 bg-slate-950 py-8 px-4 sm:px-6">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 text-center sm:flex-row sm:text-left">
          <div>
            <p className="text-xs font-mono font-bold text-slate-300">4TM GAMES SHOWCASE • 4TM ECOSYSTEM</p>
            <p className="mt-1 text-xs text-slate-500 font-mono">
              Public Showcase Domain:{' '}
              <a href="https://games.4tm.io.vn" target="_blank" rel="noreferrer" className="text-cyan-400 hover:underline">
                https://games.4tm.io.vn
              </a>
            </p>
          </div>

          <div className="flex items-center gap-6 text-xs text-slate-400 font-mono">
            <a href="https://4tm.io.vn" target="_blank" rel="noreferrer" className="hover:text-cyan-300 transition-colors">
              Ecosystem Hub
            </a>
            <span>•</span>
            <span className="text-amber-400/90">Godot 4.x Architecture</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
