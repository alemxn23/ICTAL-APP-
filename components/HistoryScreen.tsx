import React, { useEffect, useState } from 'react';
import { ArrowLeft, Calendar, Clock, Activity, FileText, Share2, Syringe } from 'lucide-react';
import { SeizureObservation } from '../types';
import { SeizureStorage } from '../services/seizureStorage';
import { MOCK_PATIENT } from '../constants';

interface HistoryScreenProps {
  onBack: () => void;
}

export const HistoryScreen: React.FC<HistoryScreenProps> = ({ onBack }) => {
  const [history, setHistory] = useState<SeizureObservation[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    const data = await SeizureStorage.getHistory();
    setHistory(data);
    setLoading(false);
  };

  const formatDate = (isoString: string) => {
    const date = new Date(isoString);
    return date.toLocaleDateString('es-ES', { 
      day: '2-digit', month: 'short', year: 'numeric' 
    });
  };

  const formatTime = (isoString: string) => {
    const date = new Date(isoString);
    return date.toLocaleTimeString('es-ES', { 
      hour: '2-digit', minute: '2-digit' 
    });
  };

  // Helper to find specific components in FHIR observation
  const getComponentValue = (obs: SeizureObservation, textCode: string) => {
    const comp = obs.component?.find(c => c.code.text === textCode);
    return comp ? comp.valueBoolean : null;
  };

  // --- MEDICAL REPORT GENERATION ENGINE ---
  const handleShare = async () => {
    if (history.length === 0) {
      alert("No hay datos para reportar aún.");
      return;
    }

    // 1. Clinical Logic: Filter Last 30 Days
    const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
    const recentEvents = history.filter(event => 
      new Date(event.effectivePeriod.start).getTime() > thirtyDaysAgo
    );

    if (recentEvents.length === 0) {
      alert("No hay crisis registradas en los últimos 30 días para generar un reporte.");
      return;
    }

    // 2. Calculate Aggregates (Statistics)
    const totalSeizures = recentEvents.length;
    const totalDurationSeconds = recentEvents.reduce((acc, curr) => acc + curr.valueQuantity.value, 0);
    const avgSeconds = Math.round(totalDurationSeconds / totalSeizures);
    const lastEventDate = formatDate(recentEvents[0].effectivePeriod.start);

    const fmtDur = (s: number) => {
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return `${m} min ${sec > 0 ? sec + ' s' : ''}`;
    };

    // 3. Build Report String (WhatsApp Friendly Format)
    let report = `📋 REPORTE EPILEPSYCARE AI\n`;
    report += `Paciente: ${MOCK_PATIENT.name.given[0]} ${MOCK_PATIENT.name.family}\n`;
    report += `Periodo: Últimos 30 días\n\n`;
    
    report += `RESUMEN:\n`;
    report += `🔴 Total Crisis: ${totalSeizures}\n`;
    report += `⏱️ Duración Promedio: ${fmtDur(avgSeconds)}\n`;
    report += `📅 Último evento: ${lastEventDate}\n\n`;
    
    report += `DETALLE DE EVENTOS:\n`;

    recentEvents.forEach((event, index) => {
      const date = formatDate(event.effectivePeriod.start);
      // Including time is standard for determining circadian patterns
      const time = formatTime(event.effectivePeriod.start);
      const durationVal = event.valueQuantity.value;
      const durationStr = fmtDur(durationVal);
      const type = durationVal > 300 ? "ESTATUS EPILÉPTICO (Urgencia)" : "Crisis Tónico-Clónica";
      const medsGiven = getComponentValue(event, 'Medication Given');
      const medsStr = medsGiven ? "SÍ" : "No";

      report += `${index + 1}. ${date} ${time} - ${type} (${durationStr})\n`;
      report += `   Medicación rescate: ${medsStr}\n`;
    });

    report += `\nGenerado por EpilepsyCare AI (SaMD Class IIa)`;

    // 4. Trigger Native Share Sheet (PWA/Mobile Integration)
    if (navigator.share) {
      try {
        await navigator.share({
          title: `Reporte Epilepsia - ${MOCK_PATIENT.name.family}`,
          text: report,
        });
      } catch (error) {
        console.log('User cancelled share or error:', error);
      }
    } else {
      // Fallback for Desktop/Non-Supported Browsers
      navigator.clipboard.writeText(report);
      alert("Reporte copiado al portapapeles. Puede pegarlo en WhatsApp Web o Email.");
    }
  };

  return (
    <div className="h-full flex flex-col bg-med-black text-gray-300 relative overflow-hidden">
      
      {/* Header */}
      <div className="flex items-center justify-between p-6 border-b border-med-gray bg-med-dark/80 backdrop-blur-md sticky top-0 z-10">
        <button 
          onClick={onBack}
          className="p-2 -ml-2 rounded-full hover:bg-med-gray text-white transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div>
          <h1 className="text-xl font-bold text-white tracking-wide text-right">BITÁCORA CLÍNICA</h1>
          <p className="text-[10px] text-med-blue font-mono text-right uppercase">HISTORIAL FHIR R4</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 pb-24">
        {loading ? (
          <div className="flex justify-center py-10">
            <Activity className="w-8 h-8 text-med-blue animate-spin" />
          </div>
        ) : history.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-gray-600 space-y-4">
            <FileText className="w-16 h-16 opacity-20" />
            <p>No hay eventos registrados.</p>
          </div>
        ) : (
          history.map((event, index) => {
            const isLongSeizure = event.valueQuantity.value > 300; // > 5 mins
            const medsGiven = getComponentValue(event, 'Medication Given'); 
            const injuries = getComponentValue(event, 'Injuries Present');

            return (
              <div 
                key={index} 
                className={`bg-med-dark rounded-xl border-l-4 p-4 shadow-lg relative overflow-hidden group transition-all hover:bg-gray-900 ${isLongSeizure ? 'border-med-red' : 'border-med-green'}`}
              >
                {/* Background Decor */}
                <div className="absolute right-0 top-0 p-3 opacity-5">
                   <Activity className="w-24 h-24" />
                </div>

                <div className="flex justify-between items-start mb-3 relative z-10">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-gray-500" />
                    <span className="font-bold text-white">{formatDate(event.effectivePeriod.start)}</span>
                    <span className="text-xs text-gray-500">• {formatTime(event.effectivePeriod.start)}</span>
                  </div>
                  <div className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider ${isLongSeizure ? 'bg-med-red/20 text-med-red' : 'bg-med-green/20 text-med-green'}`}>
                    {isLongSeizure ? 'ESTATUS' : 'CRISIS'}
                  </div>
                </div>

                <div className="flex items-end gap-1 mb-4 relative z-10">
                  <Clock className="w-5 h-5 text-med-blue mb-1" />
                  <span className="text-3xl font-mono font-bold text-white">
                    {Math.floor(event.valueQuantity.value / 60)}:{(event.valueQuantity.value % 60).toString().padStart(2, '0')}
                  </span>
                  <span className="text-xs text-gray-500 mb-1 ml-1">DURACIÓN</span>
                </div>

                {/* Clinical context chips */}
                <div className="flex flex-wrap gap-2 relative z-10">
                  {medsGiven !== null && (
                    <span className={`text-[10px] px-2 py-1 rounded border flex items-center gap-1 ${medsGiven ? 'border-med-blue text-med-blue' : 'border-gray-700 text-gray-500'}`}>
                      <Syringe className="w-3 h-3" />
                      {medsGiven ? 'RESCATE ADMINIST.' : 'SIN MEDICACIÓN'}
                    </span>
                  )}
                  {injuries === true && (
                    <span className="text-[10px] px-2 py-1 rounded border border-med-amber text-med-amber">
                      ⚠️ LESIONES
                    </span>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Floating Action Button (Share) */}
      <div className="absolute bottom-6 right-6">
        <button 
          onClick={handleShare}
          className="w-14 h-14 rounded-full bg-med-blue text-black shadow-[0_0_20px_rgba(0,240,255,0.4)] flex items-center justify-center hover:scale-105 active:scale-95 transition-all z-20"
          title="Compartir Reporte (WhatsApp)"
        >
          <Share2 className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
};