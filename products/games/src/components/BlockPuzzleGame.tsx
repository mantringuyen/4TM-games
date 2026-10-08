import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { Maximize2, Minimize2 } from 'lucide-react';

interface BlockPuzzleGameProps {
  gameUrl?: string;
  onStateChange?: (state: unknown) => void;
}

export const BlockPuzzleGame: React.FC<BlockPuzzleGameProps> = ({
  gameUrl = 'https://games-data.4tm.io.vn/games/block-puzzle/index.html',
}) => {
  // 1. Initial state is false by default
  const [isPseudoFs, setIsPseudoFs] = useState<boolean>(false);
  const [isTouchDevice, setIsTouchDevice] = useState<boolean>(false);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  // 2. Mobile/touch detection for UI gestures ONLY (NEVER calls setIsPseudoFs(true))
  useEffect(() => {
    const checkTouch = () => {
      setIsTouchDevice('ontouchstart' in window || navigator.maxTouchPoints > 0);
    };
    checkTouch();
    window.addEventListener('resize', checkTouch);
    return () => window.removeEventListener('resize', checkTouch);
  }, []);

  // 3. handleToggleFullscreen is the ONLY normal path that changes isPseudoFs
  const handleToggleFullscreen = () => {
    setIsPseudoFs((prev) => !prev);
  };

  const gameFrame = (
    <div
      className={
        isPseudoFs
          ? 'fixed inset-0 z-[99999] bg-black flex flex-col w-screen h-screen overflow-hidden'
          : 'relative w-full h-full min-h-[500px] flex flex-col bg-slate-950 rounded-2xl overflow-hidden border border-slate-800'
      }
    >
      {/* Fullscreen Toggle Header Control */}
      <div className="absolute top-3 right-3 z-10">
        <button
          onClick={handleToggleFullscreen}
          className="p-2.5 rounded-xl bg-slate-900/80 text-white hover:bg-slate-800 border border-slate-700/80 backdrop-blur-md shadow-lg transition-all active:scale-95 cursor-pointer"
          title={isPseudoFs ? 'Exit Fullscreen' : 'Enter Fullscreen'}
          aria-label={isPseudoFs ? 'Exit Fullscreen' : 'Enter Fullscreen'}
        >
          {isPseudoFs ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
        </button>
      </div>

      {/* Godot Game Iframe */}
      <iframe
        ref={iframeRef}
        src={gameUrl}
        className="w-full h-full border-0 flex-1"
        title="Block Puzzle Game"
        allow="autoplay; fullscreen; gamepad; focus-without-user-activation"
        data-touch={isTouchDevice ? 'true' : 'false'}
      />
    </div>
  );

  // 4. Default mobile/PWA rendering stays inline inside PlayView; portal mounts ONLY on user action
  if (isPseudoFs && typeof document !== 'undefined') {
    return createPortal(gameFrame, document.body);
  }

  return gameFrame;
};

export default BlockPuzzleGame;
