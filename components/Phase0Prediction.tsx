import React from 'react';
import { Brain, X, Zap } from 'lucide-react';

interface Phase0Props {
  prediction: {
    status_color: 'GREEN' | 'AMBER' | 'RED' | 'CYAN';
    risk_score: number;
    title: string;
    message: string;
    action_required: string;
  };
  onDismiss: () => void;
  onConfirm: () => void;
}

export const Phase0Prediction: React.FC<Phase0Props> = ({ prediction, onDismiss, onConfirm }) => {
  const getColor = (color: string) => {
    switch (color) {
      case 'RED': return 'text-med-red border-med-red';
      case 'AMBER': return 'text-med-amber border-med-amber';
      case 'CYAN': return 'text-med-blue border-med-blue';
      default: return 'text-med-green border-med-green';
    }
  };

  const getBgColor = (color: string) => {
    switch (color) {
      case 'RED': return 'bg-med-red/10 border-med-red';
      case 'AMBER': return 'bg-med-amber/10 border-med-amber';
      case 'CYAN': return 'bg-med-blue/10 border-med-blue';
      default: return 'bg-med-green/10 border-med-green';
    }
  };

  return (
    <div className="flex flex-col items-center justify-between h-full py-6 bg-gradient-to-b from-purple-900/20 to-med-black">

      {/* Top Status */}
      <div className={`w-full px-6 border-l-4 ${getColor(prediction.status_color)} bg-opacity-10 py-3`}>
        <div className="flex items-center gap-3">
          <Brain className={`w-8 h-8 animate-pulse ${getColor(prediction.status_color).split(' ')[0]}`} />
          <div>
            <h2 className={`text-xl font-bold tracking-wider ${getColor(prediction.status_color).split(' ')[0]}`}>{prediction.title}</h2>
            <p className="text-xs text-gray-400 font-mono text-uppercase">{prediction.action_required} DETECTADO • FASE 0</p>
          </div>
        </div>
      </div>

      {/* Probability Visual */}
      <div className="flex flex-col items-center justify-center">
        <div className={`w-48 h-48 rounded-full border-4 ${getColor(prediction.status_color).split(' ')[1]} flex items-center justify-center relative`}>
          <div className={`absolute inset-0 rounded-full bg-opacity-10 animate-ping-slow ${getBgColor(prediction.status_color).split(' ')[0]}`}></div>
          <div className="text-center">
            <span className="text-5xl font-black text-white">{prediction.risk_score}%</span>
            <p className={`text-xs font-bold mt-1 uppercase ${getColor(prediction.status_color).split(' ')[0]}`}>Índice de Riesgo</p>
          </div>
        </div>
        <div className="mt-6 px-8 text-center">
          <p className="text-sm text-gray-300 leading-relaxed font-semibold">
            {prediction.message}
          </p>
        </div>
      </div>

      {/* Action Area */}
      <div className="w-full px-6 space-y-4">
        <button
          onClick={onDismiss}
          className="w-full py-4 rounded-xl bg-transparent border border-gray-600 text-gray-400 hover:bg-gray-800 transition-all flex items-center justify-center gap-2"
        >
          <X className="w-5 h-5" />
          Descartar (Falso Positivo)
        </button>

        <button
          onClick={onConfirm}
          className="w-full py-5 rounded-xl bg-purple-600 hover:bg-purple-500 border border-purple-400 text-white font-bold tracking-widest shadow-[0_0_20px_rgba(168,85,247,0.4)] flex items-center justify-center gap-2 transition-all"
        >
          <Zap className="w-5 h-5 fill-current" />
          ACCIONAR PROTOCOLO
        </button>
      </div>

    </div>
  );
};