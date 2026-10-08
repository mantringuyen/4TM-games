import React from 'react';
import { GameMetadata } from '../types/game';
import { Gamepad2, Brain, Zap, KeyRound, LayoutGrid, Play, Info, Smartphone, Monitor } from 'lucide-react';

interface GameCardProps {
  game: GameMetadata;
  onSelect: (game: GameMetadata) => void;
  onPlayDirect?: (game: GameMetadata) => void;
}

const ICON_MAP: Record<string, React.ElementType> = {
  LayoutGrid,
  Gamepad2,
  Brain,
  Zap,
  KeyRound,
};

export const GameCard: React.FC<GameCardProps> = ({ game, onSelect, onPlayDirect }) => {
  const IconComponent = ICON_MAP[game.thumbnailIcon] || Gamepad2;

  const isDev = game.status === 'in_development';

  return (
    <div
      id={`game-card-${game.id}`}
      className={`group relative flex flex-col justify-between rounded-xl border p-5 transition-all duration-300 ${
        isDev
          ? 'border-amber-500/30 bg-slate-900/80 shadow-lg shadow-amber-950/20 hover:border-amber-500/60'
          : 'border-slate-800 bg-slate-900/90 hover:border-cyan-500/50 hover:shadow-xl hover:shadow-cyan-950/30'
      }`}
    >
      {/* Top Header & Status Badge */}
      <div>
        <div className="flex items-start justify-between gap-3 mb-4">
          <div
            className={`flex h-12 w-12 items-center justify-center rounded-xl p-2.5 transition-transform duration-300 group-hover:scale-105 ${
              isDev
                ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                : 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20'
            }`}
          >
            <IconComponent className="h-6 w-6" />
          </div>

          <div className="flex flex-col items-end gap-1">
            {isDev ? (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/10 px-2.5 py-1 text-xs font-semibold text-amber-400 border border-amber-500/30 animate-pulse">
                <span className="h-1.5 w-1.5 rounded-full bg-amber-400"></span>
                In Development
              </span>
            ) : (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold text-emerald-400 border border-emerald-500/30">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-400"></span>
                Playable Demo
              </span>
            )}
            <span className="text-[11px] font-mono text-slate-400">{game.engine}</span>
          </div>
        </div>

        {/* Title & Category */}
        <h3 className="text-xl font-bold tracking-tight text-white group-hover:text-cyan-300 transition-colors">
          {game.title}
        </h3>
        <p className="mt-1 text-xs font-medium text-cyan-400/90 font-mono">{game.genre}</p>

        {/* Description */}
        <p className="mt-3 text-sm text-slate-300 line-clamp-2 leading-relaxed">
          {game.shortDescription}
        </p>
      </div>

      {/* Footer & Actions */}
      <div className="mt-6 pt-4 border-t border-slate-800/80">
        {/* Platforms */}
        <div className="flex items-center justify-between mb-4 text-xs text-slate-400">
          <div className="flex items-center gap-2 font-mono">
            <span>Targets:</span>
            <div className="flex items-center gap-1">
              {game.platforms.includes('Android') || game.platforms.includes('iOS') ? (
                <span title="Mobile Supported"><Smartphone className="h-3.5 w-3.5 text-slate-300" /></span>
              ) : null}
              {game.platforms.includes('Web') ? (
                <span title="Web Supported"><Monitor className="h-3.5 w-3.5 text-slate-300" /></span>
              ) : null}
              <span className="text-slate-300 font-sans">{game.platforms.join(', ')}</span>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          {game.isPlayableWeb && onPlayDirect ? (
            <button
              id={`btn-play-${game.id}`}
              onClick={() => onPlayDirect(game)}
              className="flex-1 inline-flex items-center justify-center gap-2 rounded-lg bg-cyan-500 px-3.5 py-2 text-xs font-bold text-slate-950 transition-all duration-200 hover:bg-cyan-400 hover:shadow-lg hover:shadow-cyan-500/20 active:scale-95 cursor-pointer"
            >
              <Play className="h-3.5 w-3.5 fill-current" />
              Play Now
            </button>
          ) : (
            <button
              id={`btn-details-${game.id}`}
              onClick={() => onSelect(game)}
              className="flex-1 inline-flex items-center justify-center gap-2 rounded-lg bg-amber-500/20 border border-amber-500/40 px-3.5 py-2 text-xs font-bold text-amber-300 transition-all duration-200 hover:bg-amber-500/30 active:scale-95 cursor-pointer"
            >
              <Info className="h-3.5 w-3.5" />
              Development Roadmap
            </button>
          )}

          <button
            id={`btn-info-${game.id}`}
            onClick={() => onSelect(game)}
            className="inline-flex items-center justify-center rounded-lg border border-slate-700 bg-slate-800/80 p-2 text-slate-300 hover:border-slate-600 hover:bg-slate-700 hover:text-white transition-colors cursor-pointer"
            title="View Details"
          >
            <Info className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
