import React, { useState, useRef, useEffect } from 'react';
import { ChevronRight, Unlock } from 'lucide-react';

interface SafeStopButtonProps {
  onComplete: () => void;
  label?: string;
}

export const SafeStopButton: React.FC<SafeStopButtonProps> = ({ onComplete, label = "DESLIZA PARA TERMINAR" }) => {
  const [dragX, setDragX] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const maxDrag = useRef(0);

  // Constants
  const HANDLE_WIDTH = 64; // px
  const SNAP_THRESHOLD = 0.9; // 90% to trigger

  useEffect(() => {
    if (containerRef.current) {
      maxDrag.current = containerRef.current.clientWidth - HANDLE_WIDTH;
    }
  }, []);

  const handleStart = (e: React.MouseEvent | React.TouchEvent) => {
    setIsDragging(true);
  };

  const handleMove = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDragging || !containerRef.current) return;

    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const rect = containerRef.current.getBoundingClientRect();
    
    // Calculate drag position relative to container
    let newX = clientX - rect.left - (HANDLE_WIDTH / 2);
    
    // Clamp
    newX = Math.max(0, Math.min(newX, maxDrag.current));
    setDragX(newX);
  };

  const handleEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);

    const progress = dragX / maxDrag.current;
    
    if (progress > SNAP_THRESHOLD) {
      setDragX(maxDrag.current);
      onComplete(); // TRIGGER ACTION
    } else {
      // Snap back
      setDragX(0);
    }
  };

  return (
    <div className="w-full select-none py-2">
      <div 
        ref={containerRef}
        className="relative w-full h-16 rounded-full bg-med-gray border border-gray-700 overflow-hidden shadow-inner"
        onMouseMove={handleMove}
        onTouchMove={handleMove}
        onMouseUp={handleEnd}
        onMouseLeave={handleEnd}
        onTouchEnd={handleEnd}
      >
        {/* Background Track Text */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-0">
           <span className="text-gray-500 font-bold tracking-widest text-sm opacity-50 animate-pulse">
             {label} &gt;&gt;&gt;
           </span>
        </div>

        {/* Progress Fill */}
        <div 
          className="absolute inset-y-0 left-0 bg-med-calm-blue/30 z-0 transition-none"
          style={{ width: `${dragX + HANDLE_WIDTH}px` }}
        />

        {/* Draggable Handle */}
        <div
          onMouseDown={handleStart}
          onTouchStart={handleStart}
          className="absolute top-1 bottom-1 w-14 rounded-full bg-white shadow-[0_0_15px_rgba(255,255,255,0.5)] flex items-center justify-center cursor-grab active:cursor-grabbing z-10 transition-transform duration-75"
          style={{ transform: `translateX(${dragX}px)` }}
        >
          {dragX > maxDrag.current * SNAP_THRESHOLD ? (
            <Unlock className="w-6 h-6 text-med-calm-blue" />
          ) : (
            <ChevronRight className="w-6 h-6 text-med-black" />
          )}
        </div>
      </div>
      <p className="text-center text-[10px] text-gray-500 mt-2 font-mono uppercase">
        Seguridad: Deslizamiento Continuo Requerido
      </p>
    </div>
  );
};