import React, { useState } from 'react';
import { ClipboardCheck, ThumbsUp, AlertTriangle, Pill, Clock, CheckCircle2 } from 'lucide-react';

interface Phase4Props {
  finalDuration: number;
  onSubmitReport: (report: any) => void;
}

export const Phase4Recovery: React.FC<Phase4Props> = ({ finalDuration, onSubmitReport }) => {
  const [medicationGiven, setMedicationGiven] = useState<boolean | null>(null);
  const [breathingNormal, setBreathingNormal] = useState<boolean | null>(null);
  const [injuries, setInjuries] = useState<boolean | null>(null);

  const formatTime = (ms: number) => {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes} min ${seconds} seg`;
  };

  const isFormComplete = medicationGiven !== null && breathingNormal !== null && injuries !== null;

  const handleSubmit = () => {
    if (isFormComplete) {
      onSubmitReport({
        medicationGiven,
        breathingNormal,
        injuries
      });
    }
  };

  return (
    <div className="h-full flex flex-col bg-med-dark text-white overflow-hidden">
      
      {/* Recovery Header - Calming Blue Theme */}
      <div className="bg-med-calm-blue/10 border-b border-med-calm-blue/30 p-6 text-center">
        <div className="inline-flex items-center justify-center p-3 bg-med-calm-blue/20 rounded-full mb-3">
          <CheckCircle2 className="w-8 h-8 text-med-calm-blue" />
        </div>
        <h1 className="text-2xl font-bold text-med-calm-blue tracking-wide">CRISIS FINALIZADA</h1>
        <p className="text-gray-400 text-sm mt-1">FASE 4 • RECUPERACIÓN / POST-ICTAL</p>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-8">
        
        {/* Duration Card */}
        <div className="bg-gray-900 rounded-xl p-4 border border-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Clock className="w-6 h-6 text-med-calm-blue" />
            <div>
              <p className="text-xs text-gray-500 uppercase font-bold">DURACIÓN TOTAL</p>
              <p className="text-xl font-mono font-bold text-white">{formatTime(finalDuration)}</p>
            </div>
          </div>
        </div>

        {/* Clinical Form */}
        <div className="space-y-6">
          <h2 className="text-sm font-bold text-gray-500 uppercase tracking-widest border-b border-gray-800 pb-2">
            REGISTRO CLÍNICO RÁPIDO
          </h2>

          {/* Question 1: Medication */}
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <Pill className="w-5 h-5 text-gray-400" />
              <p className="text-lg font-medium">¿Se administró medicación?</p>
            </div>
            <div className="flex gap-3">
              <button 
                onClick={() => setMedicationGiven(true)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${medicationGiven === true ? 'bg-med-calm-blue text-black border-med-calm-blue' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                SÍ
              </button>
              <button 
                onClick={() => setMedicationGiven(false)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${medicationGiven === false ? 'bg-gray-700 text-white border-gray-600' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                NO
              </button>
            </div>
          </div>

          {/* Question 2: Breathing */}
          <div className="space-y-3">
            <div className="flex items-center gap-2">
              <ThumbsUp className="w-5 h-5 text-gray-400" />
              <p className="text-lg font-medium">¿Respiración normal?</p>
            </div>
            <div className="flex gap-3">
              <button 
                onClick={() => setBreathingNormal(true)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${breathingNormal === true ? 'bg-med-green text-black border-med-green' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                SÍ
              </button>
              <button 
                onClick={() => setBreathingNormal(false)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${breathingNormal === false ? 'bg-med-red text-black border-med-red' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                NO
              </button>
            </div>
          </div>

           {/* Question 3: Injuries */}
           <div className="space-y-3">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-gray-400" />
              <p className="text-lg font-medium">¿Hubo lesiones?</p>
            </div>
            <div className="flex gap-3">
              <button 
                onClick={() => setInjuries(true)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${injuries === true ? 'bg-med-amber text-black border-med-amber' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                SÍ
              </button>
              <button 
                onClick={() => setInjuries(false)}
                className={`flex-1 py-3 rounded-lg border font-bold transition-all ${injuries === false ? 'bg-gray-700 text-white border-gray-600' : 'bg-transparent border-gray-700 text-gray-400 hover:border-gray-500'}`}
              >
                NO
              </button>
            </div>
          </div>

        </div>
      </div>

      {/* Footer Submit */}
      <div className="p-6 border-t border-gray-800 bg-black/50">
        <button 
          onClick={handleSubmit}
          disabled={!isFormComplete}
          className={`w-full py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all ${isFormComplete ? 'bg-med-calm-blue text-black hover:bg-med-calm-blue/90' : 'bg-gray-800 text-gray-500 cursor-not-allowed'}`}
        >
          <ClipboardCheck className="w-5 h-5" />
          GUARDAR EN HISTORIA CLÍNICA (FHIR)
        </button>
      </div>

    </div>
  );
};