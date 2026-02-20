import React, { useEffect, useState } from 'react';
import { AlertCircle, BrainCircuit, Watch } from 'lucide-react';
import { PatientProfile } from '../types';

interface Phase1Props {
  patient: PatientProfile;
  elapsedTime: number;
  onCancel: () => void;
  onConfirm: () => void;
}

export const Phase1Aura: React.FC<Phase1Props> = ({ patient, elapsedTime, onCancel, onConfirm }) => {
  const [safetyLockActive, setSafetyLockActive] = useState(false);

  // CLINICAL SAFETY LOGIC:
  // IEC 62304 Requirement: Prevent harm.
  // If patient has reflex epilepsy (photosensitive), disable 1Hz visual stimulation.
  useEffect(() => {
    if (patient.medicalHistory.reflexEpilepsy) {
      setSafetyLockActive(true);
    }
  }, [patient]);

  return (
    <div className="flex flex-col items-center justify-between h-full py-6">
      
      {/* Top Status - CLINICAL UPDATE: Focal Aware Seizure IS Ictal */}
      <div className="w-full px-6 border-l-4 border-med-amber bg-med-amber/10 py-3">
        <div className="flex items-center gap-3">
          <AlertCircle className="text-med-amber w-8 h-8 animate-pulse" />
          <div>
            <h2 className="text-xl font-bold text-med-amber tracking-wider">CRISIS EN CURSO</h2>
            <p className="text-xs text-gray-400 font-mono">FASE 1 • INICIO FOCAL (AURA)</p>
          </div>
        </div>
      </div>

      {/* Neuromodulation Visuals */}
      <div className="relative flex items-center justify-center w-64 h-64">
        {safetyLockActive ? (
          <div className="text-center p-4 border border-med-gray rounded-lg bg-med-dark/50">
            <BrainCircuit className="w-12 h-12 text-gray-500 mx-auto mb-2" />
            <p className="text-sm text-gray-400">Estimulación Rítmica Desactivada</p>
            <p className="text-xs text-med-red mt-1 font-bold">BLOQUEO SEGURIDAD: EPILEPSIA REFLEJA</p>
          </div>
        ) : (
          <>
            {/* 1Hz Rhythmic Stimulation Sphere */}
            <div className="absolute w-full h-full rounded-full bg-med-amber/20 animate-ping" style={{ animationDuration: '1s' }}></div>
            <div className="absolute w-48 h-48 rounded-full bg-med-amber/40 blur-xl"></div>
            <div className="z-10 text-center flex flex-col items-center">
              <span className="text-4xl font-bold text-white">{Math.max(0, 30 - Math.floor(elapsedTime / 1000))}s</span>
              <p className="text-xs text-med-amber tracking-widest mt-1">TRANSICIÓN AUTO</p>
            </div>
          </>
        )}
      </div>

      {/* Haptic Feedback Indicator */}
      <div className="flex items-center gap-2 bg-med-gray/50 px-4 py-2 rounded-full border border-med-gray">
        <Watch className="w-4 h-4 text-med-blue animate-pulse" />
        <span className="text-xs font-mono text-med-blue">ESTIMULACIÓN HÁPTICA EN MUÑECA ACTIVA</span>
      </div>

      {/* Action Area */}
      <div className="w-full px-6 space-y-4">
        <button 
          onClick={onCancel}
          className="w-full py-6 rounded-xl bg-med-gray border border-gray-600 active:bg-gray-700 active:scale-95 transition-all"
        >
          <span className="text-xl font-bold text-white">ESTOY BIEN</span>
          <p className="text-xs text-gray-400">Cancelar Alarma (Falso Positivo)</p>
        </button>

        <button 
          onClick={onConfirm}
          className="w-full py-4 rounded-xl border-2 border-med-amber text-med-amber font-mono font-bold tracking-widest active:bg-med-amber/10 transition-all hover:bg-med-amber hover:text-black"
        >
          CONFIRMAR FASE MOTORA
        </button>
      </div>
    </div>
  );
};