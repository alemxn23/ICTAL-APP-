import React, { useEffect, useState } from 'react';
import { Phone, MapPin, Syringe, Send } from 'lucide-react';
import { PatientProfile } from '../types';
import { SafeStopButton } from './SafeStopButton';

interface Phase3Props {
  patient: PatientProfile;
  elapsedTime: number;
  notificationStatus: string; // New prop for status feedback
  onEndSeizure: () => void;
}

export const Phase3Status: React.FC<Phase3Props> = ({ patient, elapsedTime, notificationStatus, onEndSeizure }) => {
  // SAFETY CONSTRAINT: NO CALCULATORS.
  // Static Pre-calculated display.
  const { rescueMedication } = patient;

  return (
    <div className="h-full flex flex-col bg-red-950 text-white animate-flash-red relative">
      <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')] opacity-20"></div>

      {/* Extreme Alert Header */}
      <div className="z-10 bg-med-red text-black p-4 text-center shadow-2xl shrink-0">
        <h1 className="text-3xl font-black tracking-tighter">ESTATUS EPILÉPTICO</h1>
        <p className="font-mono text-lg font-bold mt-1">&gt; 5 MINUTOS DE DURACIÓN</p>
      </div>

      <div className="z-10 flex-1 flex flex-col p-4 space-y-4 overflow-y-auto">

        {/* The Drug Card - The most important UI element */}
        <div className="bg-white text-black rounded-xl p-5 shadow-2xl border-4 border-black">
          <div className="flex items-center gap-2 mb-3 border-b-2 border-black pb-2">
            <Syringe className="w-8 h-8 text-med-red" />
            <h2 className="text-xl font-bold">MEDICACIÓN DE RESCATE</h2>
          </div>

          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <p className="text-xs font-bold text-gray-500 uppercase">FÁRMACO</p>
              <p className="text-2xl font-black">{rescueMedication.drugName}</p>
            </div>
            <div>
              <p className="text-xs font-bold text-gray-500 uppercase">DOSIS</p>
              <p className="text-2xl font-black text-med-red">{rescueMedication.dosage}</p>
            </div>
          </div>

          <div className="bg-gray-100 p-3 rounded-lg">
            <p className="text-xs font-bold text-gray-500 uppercase mb-1">VÍA DE ADM.</p>
            <p className="text-xl font-bold">{rescueMedication.route}</p>
            <p className="text-sm mt-1 font-medium leading-tight">{rescueMedication.instructions}</p>
          </div>
        </div>

        {/* SOS Automation Status */}
        <div className="bg-black/80 backdrop-blur-md rounded-xl p-4 border border-med-red">
          <div className="flex items-center gap-3 mb-3">
            <div className="relative">
              <Phone className="w-8 h-8 text-white z-10 relative" />
              <div className="absolute inset-0 bg-med-red/50 blur-lg animate-pulse"></div>
            </div>
            <div>
              <h3 className="text-lg font-bold text-med-red">PROTOCOLO SOS AUTOMÁTICO</h3>
              <div className="flex items-center gap-2 mt-1">
                {notificationStatus.includes("todos") || notificationStatus.includes("Completed") ? (
                  <span className="w-2 h-2 rounded-full bg-med-green"></span>
                ) : (
                  <span className="w-2 h-2 rounded-full bg-med-amber animate-pulse"></span>
                )}
                <p className="text-xs text-white font-mono uppercase truncate max-w-[200px]">
                  {notificationStatus || 'Iniciando...'}
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-2 mt-2 border-t border-gray-800 pt-2">
            {patient.contacts.map((contact, i) => (
              <div key={i} className="flex justify-between items-center text-xs text-gray-400">
                <span>{contact.name} ({contact.relation})</span>
                <span className="flex items-center gap-1 text-med-green">
                  <Send className="w-3 h-3" /> ENVIADO
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Footer Controls - Safety Stop */}
      <div className="z-20 p-6 bg-black border-t border-med-gray/50 shadow-[0_-10px_40px_rgba(0,0,0,0.8)] shrink-0">
        <SafeStopButton onComplete={onEndSeizure} label="TERMINAR ESTATUS" />
      </div>
    </div>
  );
};