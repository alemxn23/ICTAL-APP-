import React, { useEffect, useState } from 'react';
import { Volume2, Activity, ShieldAlert, Watch } from 'lucide-react';
import { BYSTANDER_SCRIPT_ES, BYSTANDER_SCRIPT_EN } from '../constants';
import { VitalGraph } from './VitalGraph';
import { SensorDataPoint } from '../types';
import { SafeStopButton } from './SafeStopButton';

interface Phase2Props {
  elapsedTime: number;
  mockSensorData: SensorDataPoint[];
  onEndSeizure: () => void;
}

export const Phase2Ictal: React.FC<Phase2Props> = ({ elapsedTime, mockSensorData, onEndSeizure }) => {
  const [audioEnabled, setAudioEnabled] = useState(true);

  // VUI Logic (Voice User Interface)
  // Repeating the instructions for bystanders.
  useEffect(() => {
    let utterance: SpeechSynthesisUtterance | null = null;
    const loopInterval = setInterval(() => {
      if (audioEnabled && !window.speechSynthesis.speaking) {
        utterance = new SpeechSynthesisUtterance(BYSTANDER_SCRIPT_ES);
        utterance.rate = 0.9; // Slower for clarity
        utterance.pitch = 1.0; // Authoritative but calm
        utterance.lang = 'es-ES';
        window.speechSynthesis.speak(utterance);
      }
    }, 8000);

    return () => {
      clearInterval(loopInterval);
      window.speechSynthesis.cancel();
    };
  }, [audioEnabled]);

  const toggleAudio = () => {
    window.speechSynthesis.cancel();
    setAudioEnabled(!audioEnabled);
  };

  const formatTime = (ms: number) => {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  return (
    <div className="h-full flex flex-col bg-med-black text-white relative overflow-hidden">
      {/* Background Pulse Animation for urgency */}
      <div className="absolute inset-0 bg-med-blue/5 animate-pulse z-0"></div>

      {/* Header: Timer */}
      <div className="z-10 flex justify-between items-center px-6 py-4 bg-med-dark border-b border-med-gray">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded-full bg-med-red animate-pulse"></div>
          <div>
            <span className="text-med-red font-bold tracking-widest block leading-none">CRISIS ACTIVA</span>
            <span className="text-[10px] text-med-red/70 font-mono">FASE 2 • GENERALIZADA</span>
          </div>
        </div>
        <div className="text-4xl font-mono font-bold text-white">
          {formatTime(elapsedTime)}
        </div>
      </div>

      {/* Main Bystander Instructions - High Contrast */}
      <div className="z-10 flex-1 flex flex-col px-6 py-4 space-y-4 overflow-y-auto">
        <div className="space-y-3">
          <div className="bg-white text-black p-4 rounded-lg shadow-lg shadow-med-blue/20">
            <h1 className="text-3xl font-black uppercase leading-tight">
              NO ME SUJETE
            </h1>
          </div>
          <div className="bg-med-gray border-l-8 border-med-blue p-4 rounded-r-lg">
            <h1 className="text-2xl font-bold uppercase leading-tight text-med-blue">
              GIRE DE LADO
            </h1>
          </div>
          <div className="bg-med-gray border-l-8 border-med-blue p-4 rounded-r-lg">
            <h1 className="text-2xl font-bold uppercase leading-tight text-med-blue">
              PROTEJA CABEZA
            </h1>
          </div>
        </div>
        
        {/* Sensor Feedback Visualization */}
        <div className="h-24 min-h-[6rem] bg-med-dark rounded-xl border border-med-gray relative overflow-hidden shrink-0">
          <div className="absolute top-2 left-2 flex items-center gap-2 z-10">
            <Watch className="w-4 h-4 text-med-green" />
            <span className="text-xs font-mono text-med-green">FUENTE: APPLE WATCH S9</span>
          </div>
          <div className="absolute bottom-2 right-2 z-10">
             <span className="text-[10px] font-mono text-gray-400">SYNC: 50ms</span>
          </div>
          <VitalGraph data={mockSensorData} color="#39FF14" />
        </div>

        {/* Audio Toggle - Smaller */}
        <button 
          onClick={toggleAudio}
          className={`w-full flex items-center justify-center gap-2 py-3 rounded-lg font-bold text-sm ${audioEnabled ? 'bg-med-dark border border-med-blue text-med-blue' : 'bg-med-gray text-gray-400'}`}
        >
          <Volume2 className="w-4 h-4" />
          {audioEnabled ? 'SILENCIAR INSTRUCCIONES DE VOZ' : 'ACTIVAR INSTRUCCIONES DE VOZ'}
        </button>
      </div>

      {/* Footer Controls - Safety Stop */}
      <div className="z-20 p-6 bg-med-black border-t border-med-gray/50 shadow-[0_-10px_40px_rgba(0,0,0,0.8)]">
        <SafeStopButton onComplete={onEndSeizure} />
      </div>
    </div>
  );
};