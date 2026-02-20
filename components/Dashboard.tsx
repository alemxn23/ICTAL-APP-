import React, { useState } from 'react';
import { Activity, Battery, Wifi, ShieldCheck, Brain, Watch, Zap, History, ChevronRight, UserCircle, Moon, Move, AlertTriangle } from 'lucide-react';
import { ResponsiveContainer, AreaChart, Area, PieChart, Pie, Cell } from 'recharts';
import { MetricDetailModal, MetricType } from './MetricDetailModal';
import { BiometricCard } from './BiometricCard';

interface DashboardProps {
  onSimulateAura: () => void;
  onSimulateFall: () => void;
  onOpenHistory: () => void;
  onOpenProfile: () => void;
}

const mockForecastData = [
  { time: '10:00', prob: 0.1 },
  { time: '11:00', prob: 0.12 },
  { time: '12:00', prob: 0.15 },
  { time: '13:00', prob: 0.2 },
  { time: '14:00', prob: 0.85 },
  { time: '15:00', prob: 0.6 },
];

// MOCK DEVICE STATE
const CONNECTED_DEVICE = {
  name: 'Xiaomi Mi Band 7',
  type: 'GENERIC_BAND',
  battery: 88,
  connectionState: 'CONNECTED'
};

const GAUGE_DATA = [
  { name: 'Stable', value: 88, color: '#34C759' }, // Green
  { name: 'Risk', value: 12, color: '#333333' }   // Dark Gray (Background)
];

export const Dashboard: React.FC<DashboardProps> = ({ onSimulateAura, onSimulateFall, onOpenHistory, onOpenProfile }) => {
  const [selectedMetric, setSelectedMetric] = useState<MetricType | null>(null);

  // Instability Index (Simulated)
  const instabilityIndex = 12;

  return (
    <div className="h-full flex flex-col bg-med-black text-gray-300 relative overflow-hidden">

      {/* Detail Modal Overlay */}
      {selectedMetric && (
        <MetricDetailModal
          type={selectedMetric}
          onClose={() => setSelectedMetric(null)}
        />
      )}

      {/* Main Scrollable Content */}
      <div className="flex-1 overflow-y-auto p-4 pb-32 space-y-4">
        {/* pb-32 Ensures content is not hidden behind the fixed button */}

        {/* 1. COMPACT HEADER */}
        <div className="flex justify-between items-center border-b border-med-gray/50 pb-2">
          <div>
            <h1 className="text-lg font-bold text-white tracking-tight italic">ICTAL</h1>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="w-1.5 h-1.5 rounded-full bg-med-green shadow-[0_0_6px_#39FF14]"></span>
              <span className="text-[9px] font-mono text-med-green tracking-wide">SISTEMA NOMINAL</span>
            </div>
          </div>
          <div className="flex gap-3 text-med-gray items-center">
            <button onClick={onOpenHistory} className="hover:text-med-blue transition-colors p-1" title="Bitácora">
              <History className="w-5 h-5" />
            </button>
            <button onClick={onOpenProfile} className="hover:text-med-green transition-colors p-1" title="Perfil Paciente">
              <UserCircle className="w-5 h-5" />
            </button>
            <div className="w-px h-4 bg-med-gray/50 mx-1"></div>
            <Battery className="w-4 h-4 text-white" />
          </div>
        </div>

        {/* 2. CONSOLIDATED HERO CARD */}
        <div
          onClick={() => setSelectedMetric('FORECAST')}
          className="bg-med-dark rounded-2xl border border-med-gray p-0 overflow-hidden flex h-32 relative cursor-pointer active:scale-[0.99] transition-transform shadow-lg"
        >
          {/* Left Side: Telemetry (60%) */}
          <div className="w-[60%] p-4 flex flex-col justify-between relative z-10">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <Activity className="w-4 h-4 text-med-blue animate-pulse" />
                <span className="text-[10px] font-bold text-white uppercase tracking-wider">Monitoreo Activo</span>
              </div>
              <p className="text-xs text-gray-400 font-medium leading-tight">Análisis biométrico<br />en tiempo real</p>
            </div>

            {/* Mini Wave Chart */}
            <div className="h-10 w-full opacity-60 absolute bottom-0 left-0 right-0">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={mockForecastData}>
                  <defs>
                    <linearGradient id="colorWave" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#007AFF" stopOpacity={0.5} />
                      <stop offset="95%" stopColor="#007AFF" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <Area type="monotone" dataKey="prob" stroke="#007AFF" strokeWidth={2} fill="url(#colorWave)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Right Side: Index Gauge (40%) */}
          <div className="w-[40%] bg-med-gray/10 flex flex-col items-center justify-center border-l border-med-gray/30 relative">
            <div className="relative w-20 h-20">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={GAUGE_DATA}
                    cx="50%"
                    cy="50%"
                    innerRadius={28}
                    outerRadius={35}
                    startAngle={90}
                    endAngle={-270}
                    dataKey="value"
                    stroke="none"
                  >
                    <Cell key="stable" fill="#34C759" />
                    <Cell key="bg" fill="#333333" />
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              {/* Centered Text */}
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-xl font-bold text-white tracking-tighter">{instabilityIndex}%</span>
              </div>
            </div>
            <span className="text-[10px] font-bold text-med-green uppercase tracking-wide mt-1">Estable</span>
            <span className="text-[8px] text-gray-500 font-mono">ÍNDICE</span>
          </div>
        </div>

        {/* 3. COMPACT VITALS GRID */}
        <div>
          <div className="flex justify-between items-center mb-2 px-1">
            <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Resumen de Salud</span>
            <span className="text-[9px] text-gray-600 bg-gray-900 px-1.5 py-0.5 rounded border border-gray-800">{CONNECTED_DEVICE.name}</span>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <BiometricCard
              title="CORAZÓN"
              value="72"
              unit="LPM"
              isSupported={true}
              icon={Activity}
              deviceName={CONNECTED_DEVICE.name}
              colorClass="text-med-red"
              onClick={() => setSelectedMetric('HEART_RATE')}
            />
            <BiometricCard
              title="ESTADO"
              value="ACTIVO"
              unit=""
              isSupported={true}
              icon={Move}
              deviceName={CONNECTED_DEVICE.name}
              colorClass="text-med-green"
              onClick={() => setSelectedMetric('FALLS')} // Re-using state for demo
            />
            <BiometricCard
              title="VFC (HRV)"
              value="45"
              unit="ms"
              isSupported={false} // Simulated generic band
              icon={Battery}
              deviceName={CONNECTED_DEVICE.name}
              colorClass="text-med-blue"
              onClick={() => setSelectedMetric('HRV')}
            />
            <BiometricCard
              title="SUEÑO"
              value="7h 20m"
              unit=""
              isSupported={true}
              icon={Moon}
              deviceName={CONNECTED_DEVICE.name}
              colorClass="text-med-amber"
              onClick={() => setSelectedMetric('SLEEP')}
            />
          </div>
        </div>

        {/* Dev Tools (Pushed to bottom, accessible via scroll) */}
        <div className="pt-4 opacity-40 hover:opacity-100 transition-opacity">
          <h3 className="text-[9px] font-bold text-gray-600 uppercase mb-2 text-center">Herramientas de Desarrollador</h3>
          <div className="grid grid-cols-2 gap-2">
            <button onClick={onSimulateAura} className="bg-gray-800 text-gray-400 py-2 rounded text-[10px] font-mono border border-gray-700">Simular Aura</button>
            <button onClick={onSimulateFall} className="bg-gray-800 text-gray-400 py-2 rounded text-[10px] font-mono border border-gray-700">Simular Caída</button>
          </div>
        </div>

        <div className="h-6"></div> {/* Extra spacer */}
      </div>

      {/* 4. FIXED FLOATING BUTTON (Reportar Evento) */}
      <div className="absolute bottom-0 left-0 right-0 p-4 pt-6 bg-gradient-to-t from-black via-black/90 to-transparent z-50">
        <button
          onClick={onSimulateAura} // Using Aura trigger as manual report for now
          className="w-full h-[50px] bg-med-red hover:bg-red-600 active:bg-red-700 rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-red-900/20 transition-all active:scale-[0.98] group"
        >
          <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center group-hover:bg-white/30 transition-colors">
            <Zap className="w-3.5 h-3.5 text-white fill-white" />
          </div>
          <span className="text-white font-bold text-base tracking-wide">REPORTAR EVENTO</span>
        </button>
      </div>

    </div>
  );
};