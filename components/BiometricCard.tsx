import React from 'react';
import { LucideIcon, AlertTriangle } from 'lucide-react';

interface BiometricCardProps {
  title: string;
  value: string | number;
  unit: string;
  isSupported: boolean;
  icon: LucideIcon;
  deviceName: string;
  colorClass: string;
  onClick?: () => void;
}

export const BiometricCard: React.FC<BiometricCardProps> = ({
  title,
  value,
  unit,
  isSupported,
  icon: Icon,
  deviceName,
  colorClass,
  onClick
}) => {
  return (
    <div
      onClick={onClick}
      className={`relative p-2 rounded-xl border transition-all overflow-hidden group cursor-pointer ${isSupported
          ? 'bg-med-dark border-med-gray hover:border-gray-600 active:scale-[0.98]'
          : 'bg-[#151515] border-[#252525] opacity-80 hover:border-gray-700 active:scale-[0.98]'
        }`}
    >
      {/* Icon & Title Header */}
      <div className="flex justify-between items-start mb-1">
        <div className="flex items-center gap-2">
          <Icon className={`w-4 h-4 ${isSupported ? colorClass : 'text-gray-600'}`} />
          <span className={`text-[10px] font-bold uppercase tracking-wider ${isSupported ? 'text-gray-400' : 'text-gray-600'}`}>
            {title}
          </span>
        </div>
      </div>

      {/* Main Value Display */}
      <div className="flex items-baseline gap-1 min-h-[1.75rem]">
        {isSupported ? (
          <>
            <span className="text-2xl font-mono font-bold text-white tracking-tight">{value}</span>
            <span className="text-xs font-bold text-gray-500">{unit}</span>
          </>
        ) : (
          <span className="text-xs font-mono font-bold text-gray-500 self-center">NO DISPONIBLE</span>
        )}
      </div>

      {/* Footer / Status */}
      {isSupported ? (
        <div className="mt-2 w-full bg-gray-800 rounded-full h-1 overflow-hidden">
          <div className={`h-full ${colorClass.replace('text-', 'bg-')} w-[60%] opacity-80 group-hover:w-[70%] transition-all duration-500`}></div>
        </div>
      ) : (
        <div className="mt-2 flex items-center gap-1.5">
          <AlertTriangle className="w-3 h-3 text-med-amber/60" />
          <p className="text-[8px] font-bold text-med-amber/60 leading-tight uppercase tracking-tight">
            ⚠️ No soportado por {deviceName}
          </p>
        </div>
      )}
    </div>
  );
};