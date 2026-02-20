import React, { useState } from 'react';
import { X, Info, Activity, Battery, Brain, Moon, Move, ChevronLeft } from 'lucide-react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ReferenceLine } from 'recharts';

export type MetricType = 'HEART_RATE' | 'HRV' | 'FORECAST' | 'SLEEP' | 'FALLS';

interface MetricDetailModalProps {
  type: MetricType;
  onClose: () => void;
}

// --- CONSTANTS ---
const TIME_RANGES = ['Hoy', '7D', '30D', '6M'];

// --- MOCK DATA GENERATOR ---
const generateData = (type: MetricType, range: string) => {
  const data = [];
  const points = range === 'Hoy' ? 24 : range === '7D' ? 7 : 30;

  for (let i = 0; i < points; i++) {
    let value = 0;
    // Simulate organic curves
    const base = Math.sin(i * 0.5) * 10;

    if (type === 'HEART_RATE') value = 65 + base + Math.random() * 15;
    if (type === 'HRV') value = 40 + base + Math.random() * 20;
    if (type === 'FORECAST') value = Math.max(0, Math.min(100, 15 + base + Math.random() * 10)); // Intability Index
    if (type === 'SLEEP') value = 6 + Math.random() * 3;
    if (type === 'FALLS') value = Math.random() > 0.9 ? 1 : 0;

    data.push({
      label: i.toString(),
      value: Number(value.toFixed(1))
    });
  }
  return data;
};

// --- CONTENT MAP ---
const CONTENT_MAP = {
  FORECAST: {
    title: "ÍNDICE / MONITOREO ACTIVO",
    value: "12%",
    unit: "INESTABILIDAD",
    color: "#00F0FF", // Cyan (Futuristic/Active)
    gradient: ["#00F0FF", "rgba(0, 240, 255, 0)"],
    icon: Brain,
    eduTitle: "Contexto Clínico",
    eduText: "Tu Índice de Inestabilidad mide la desviación de tus signos vitales (como pulsaciones y estrés) respecto a tu nivel normal. Un índice alto de forma sostenida indica una mayor 'carga alostática' o estrés fisiológico, lo cual puede reducir tu umbral convulsivo. Usamos esto para anticipar momentos de vulnerabilidad."
  },
  HEART_RATE: {
    title: "CORAZÓN (LPM)",
    value: "72",
    unit: "LPM",
    color: "#FF003C", // Med Red
    gradient: ["#FF003C", "rgba(255, 0, 60, 0)"],
    icon: Activity,
    eduTitle: "Sobre este dato",
    eduText: "El ritmo cardíaco en reposo es un indicador vital. En la epilepsia, el estrés extremo o la actividad cerebral inusual antes de una crisis (fase pre-ictal) pueden causar taquicardia súbita sin esfuerzo físico. Monitorizar tus picos nos ayuda a detectar falsas alarmas y eventos reales."
  },
  HRV: {
    title: "VFC (HRV)",
    value: "45",
    unit: "ms",
    color: "#39FF14", // Med Green
    gradient: ["#39FF14", "rgba(57, 255, 20, 0)"],
    icon: Battery,
    eduTitle: "Contexto Clínico",
    eduText: "La Variabilidad de la Frecuencia Cardíaca mide el equilibrio de tu sistema nervioso. Una VFC alta es buena (estás relajado). Una VFC baja constante significa que tu cuerpo está bajo estrés o fatiga profunda, factores ampliamente conocidos por actuar como detonantes (triggers) de crisis epilépticas."
  },
  SLEEP: {
    title: "SUEÑO",
    value: "7h 20m",
    unit: "PROMEDIO",
    color: "#FFBF00", // Amber
    gradient: ["#FFBF00", "rgba(255, 191, 0, 0)"],
    icon: Moon,
    eduTitle: "Sobre este dato",
    eduText: "La falta de sueño o el sueño fragmentado es uno de los principales desencadenantes universales de las crisis epilépticas. Monitorizamos tus horas de descanso para advertirte si estás entrando en un déficit de sueño peligroso que requiera mayor precaución en tu día."
  },
  FALLS: {
    title: "MONITOR DE CAÍDAS",
    value: "ACTIVO",
    unit: "ESTADO",
    color: "#FFFFFF",
    gradient: ["#FFFFFF", "rgba(255, 255, 255, 0)"],
    icon: Move,
    eduTitle: "Monitor de Seguridad",
    eduText: "Este sensor analiza acelerometría en 3 ejes para detectar impactos súbitos superiores a 3G, característicos de crisis tónico-clónicas. El sistema está activo y calibrado para ignorar movimientos cotidianos."
  }
};

export const MetricDetailModal: React.FC<MetricDetailModalProps> = ({ type, onClose }) => {
  const [range, setRange] = useState('Hoy');
  const content = CONTENT_MAP[type];
  const data = generateData(type, range);

  // Dynamic Text Rendering
  const renderEduText = (text: string) => {
    return (
      <p className="text-gray-400 text-sm leading-relaxed font-regular">
        {text}
      </p>
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black animate-in fade-in duration-300">

      {/* 1. HEADER (IOS STYLE) */}
      <div className="flex items-center justify-between px-4 py-4 shrink-0 bg-black/80 backdrop-blur-md sticky top-0 z-10">
        <button
          onClick={onClose}
          className="flex items-center text-med-blue hover:text-white transition-colors"
        >
          <ChevronLeft className="w-6 h-6" />
          <span className="text-lg font-medium">Atrás</span>
        </button>
        <div className="text-white font-semibold text-sm tracking-wide opacity-0">Title</div> {/* Spacer */}
        <div className="w-6"></div> {/* Spacer to balancer */}
      </div>

      {/* SCROLLABLE CONTENT */}
      <div className="flex-1 overflow-y-auto overflow-x-hidden pb-10">

        {/* 2. MAIN METRIC HEADER */}
        <div className="px-5 pt-2 pb-6">
          <h1 className="text-sm font-bold text-gray-500 uppercase tracking-wider mb-1">{content.title}</h1>
          <div className="flex items-baseline gap-2">
            <span className="text-5xl font-bold text-white tracking-tight font-display">{content.value}</span>
            <span className="text-xl font-medium text-gray-500">{content.unit}</span>
          </div>
        </div>

        {/* 3. SEGMENTED CONTROL */}
        <div className="px-5 mb-6">
          <div className="bg-[#1C1C1E] rounded-lg p-0.5 flex">
            {TIME_RANGES.map((r) => (
              <button
                key={r}
                onClick={() => setRange(r)}
                className={`flex-1 py-1.5 text-xs font-bold rounded-md transition-all ${range === r
                    ? 'bg-[#636366] text-white shadow-sm'
                    : 'text-gray-400 hover:text-white'
                  }`}
              >
                {r}
              </button>
            ))}
          </div>
        </div>

        {/* 4. CHART AREA */}
        <div className="h-64 w-full mb-8 relative">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data} margin={{ top: 10, right: 0, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id={`gradient-${type}`} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={content.color} stopOpacity={0.4} />
                  <stop offset="95%" stopColor={content.color} stopOpacity={0} />
                </linearGradient>
              </defs>
              {/* Hidden axes for clean look, minimal grid */}
              <CartesianGrid stroke="#333" strokeDasharray="3 3" vertical={false} horizontal={true} opacity={0.3} />
              <Tooltip
                cursor={{ stroke: '#666', strokeWidth: 1 }}
                contentStyle={{ backgroundColor: '#1C1C1E', border: 'none', borderRadius: '8px', color: '#fff' }}
                itemStyle={{ color: content.color }}
                formatter={(val: number) => [val, content.unit]}
              />
              <Area
                type="monotone"
                dataKey="value"
                stroke={content.color}
                strokeWidth={3}
                fill={`url(#gradient-${type})`}
                isAnimationActive={true}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* 5. EDUCATIONAL CARD */}
        <div className="px-4">
          <div className="bg-[#1C1C1E] rounded-xl p-5 border border-white/5">
            <div className="flex items-center gap-2 mb-3 border-b border-white/10 pb-3">
              <Info className="w-5 h-5 text-gray-400" />
              <h3 className="text-sm font-bold text-gray-200 uppercase">{content.eduTitle}</h3>
            </div>

            {renderEduText(content.eduText)}
          </div>
        </div>

      </div>
    </div>
  );
};