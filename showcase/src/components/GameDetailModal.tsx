import React from 'react';
import { GameMetadata } from '../types/game';
import { X, Play, Code2, Layers, Smartphone, Monitor, Globe, Tag, Sparkles, CheckCircle2, Clock } from 'lucide-react';

interface GameDetailModalProps {
  game: GameMetadata | null;
  onClose: () => void;
  onPlay?: (game: GameMetadata) => void;
}

export const GameDetailModal: React.FC<GameDetailModalProps> = ({ game, onClose, onPlay }) => {
  if (!game) return null;

  const isDev = game.status === 'in_development';

  return (
    <div
      id="game-detail-modal-overlay"
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 p-4 backdrop-blur-md animate-fade-in"
      onClick={onClose}
    >
      <div
        id="game-detail-modal"
        className="relative w-full max-w-2xl rounded-2xl border border-slate-800 bg-slate-900 p-6 shadow-2xl transition-all sm:p-8 max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          id="btn-close-modal"
          onClick={onClose}
          className="absolute right-4 top-4 rounded-xl border border-slate-800 bg-slate-800/60 p-2 text-slate-400 hover:border-slate-700 hover:bg-slate-700 hover:text-white transition-all cursor-pointer"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Header */}
        <div className="flex items-start gap-4">
          <div
            className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl p-3 ${
              isDev
                ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                : 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30'
            }`}
          >
            <Sparkles className="h-7 w-7" />
          </div>

          <div>
            <div className="flex items-center gap-2 mb-1">
              {isDev ? (
                <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/10 px-3 py-0.5 text-xs font-semibold text-amber-400 border border-amber-500/30">
                  <Clock className="h-3 w-3" /> In Development
                </span>
              ) : (
                <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-3 py-0.5 text-xs font-semibold text-emerald-400 border border-emerald-500/30">
                  <CheckCircle2 className="h-3 w-3" /> Playable Demo
                </span>
              )}
              <span className="text-xs font-mono text-slate-400">{game.genre}</span>
            </div>
            <h2 className="text-2xl font-black tracking-tight text-white sm:text-3xl">{game.title}</h2>
          </div>
        </div>

        {/* Main Body */}
        <div className="mt-6 space-y-6 text-slate-300">
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-mono">Overview</h4>
            <p className="mt-2 leading-relaxed text-sm text-slate-200">{game.fullDescription}</p>
          </div>

          {/* Development Status Callout */}
          {game.highlightNote && (
            <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 p-4 text-amber-200">
              <div className="flex items-center gap-2 font-bold text-amber-400 text-sm mb-1">
                <Code2 className="h-4 w-4" /> Architectural Status
              </div>
              <p className="text-xs leading-relaxed text-amber-200/90">{game.highlightNote}</p>
            </div>
          )}

          {/* Specifications Grid */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-4">
              <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400 font-mono mb-2">
                <Layers className="h-4 w-4 text-cyan-400" /> Game Engine
              </div>
              <p className="text-sm font-semibold text-white">{game.engine}</p>
              <p className="text-xs text-slate-400 mt-1">
                {isDev
                  ? 'Target engine for 2D physics, touch gestures & cross-platform exports.'
                  : 'Embedded web engine running natively in browser.'}
              </p>
            </div>

            <div className="rounded-xl border border-slate-800 bg-slate-950/60 p-4">
              <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400 font-mono mb-2">
                <Globe className="h-4 w-4 text-cyan-400" /> Target Route
              </div>
              <p className="text-sm font-mono font-semibold text-cyan-300">games.4tm.io.vn{game.route}</p>
              <p className="text-xs text-slate-400 mt-1">Official 4TM Ecosystem showcase route</p>
            </div>
          </div>

          {/* Target Platforms */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-mono mb-2">
              Target Platforms
            </h4>
            <div className="flex flex-wrap gap-2">
              {game.platforms.map((platform) => (
                <span
                  key={platform}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-slate-800 bg-slate-800/80 px-3 py-1.5 text-xs font-medium text-slate-200"
                >
                  {platform === 'Android' || platform === 'iOS' ? (
                    <Smartphone className="h-3.5 w-3.5 text-cyan-400" />
                  ) : (
                    <Monitor className="h-3.5 w-3.5 text-cyan-400" />
                  )}
                  {platform}
                </span>
              ))}
            </div>
          </div>

          {/* Tags */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-mono mb-2">Tags</h4>
            <div className="flex flex-wrap gap-2">
              {game.tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1 rounded-md bg-slate-800/50 px-2.5 py-1 text-xs text-slate-400 border border-slate-800"
                >
                  <Tag className="h-3 w-3 text-slate-500" />
                  {tag}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="mt-8 flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
          <button
            onClick={onClose}
            className="rounded-lg border border-slate-700 bg-slate-800 px-4 py-2 text-xs font-semibold text-slate-300 hover:bg-slate-700 hover:text-white transition-colors cursor-pointer"
          >
            Close
          </button>

          {game.isPlayableWeb && onPlay ? (
            <button
              onClick={() => {
                onClose();
                onPlay(game);
              }}
              className="inline-flex items-center gap-2 rounded-lg bg-cyan-500 px-5 py-2 text-xs font-bold text-slate-950 hover:bg-cyan-400 transition-colors cursor-pointer"
            >
              <Play className="h-4 w-4 fill-current" /> Play Game
            </button>
          ) : (
            <span className="text-xs font-mono text-amber-400/90 bg-amber-500/10 px-3 py-2 rounded-lg border border-amber-500/20">
              In Development with Godot 4.x
            </span>
          )}
        </div>
      </div>
    </div>
  );
};
