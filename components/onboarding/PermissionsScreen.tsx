import React, { useState } from 'react';
import { Bell, Heart, ChevronRight, CheckCircle2, Info } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';
import { onboardingService } from '../../services/onboardingService';

type PermStage = 'notifications' | 'health' | 'done';

/**
 * Phase 5 — Device Permissions
 * Shows WHY before requesting each permission.
 * Strategy: explain → request → confirm → next permission.
 */
export const PermissionsScreen: React.FC = () => {
    const { currentUser, setStep } = useOnboarding();
    const [stage, setStage] = useState<PermStage>('notifications');
    const [notifGranted, setNotifGranted] = useState<boolean | null>(null);
    const [healthGranted, setHealthGranted] = useState<boolean | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    const handleRequestNotifications = async () => {
        try {
            // Web Notifications API — simulates OS permission dialog
            if ('Notification' in window) {
                const result = await Notification.requestPermission();
                const granted = result === 'granted';
                setNotifGranted(granted);
                if (currentUser) {
                    await onboardingService.upsertPerfilClinico(currentUser.id, { permiso_notificaciones: granted });
                }
            } else {
                setNotifGranted(true); // Mobile native — assume granted for web demo
            }
        } catch {
            setNotifGranted(false);
        }
        setStage('health');
    };

    const handleRequestHealth = async () => {
        setIsLoading(true);
        // Simulated HealthKit / Google Fit permission request
        // In React Native / Swift — this would call NativeModules.HealthKit.requestAuthorization()
        await new Promise(resolve => setTimeout(resolve, 1200));
        setHealthGranted(true);
        if (currentUser) {
            await onboardingService.upsertPerfilClinico(currentUser.id, { permiso_healthkit: true });
        }
        setIsLoading(false);
        setStage('done');
    };

    const handleFinish = () => setStep(OnboardingStep.COMPLETE);

    return (
        <div className="w-full h-full bg-med-black flex flex-col overflow-y-auto">
            {/* Header */}
            <div className="px-6 pt-12 pb-6">
                <h2 className="text-2xl font-bold text-white mb-2">Permisos del dispositivo</h2>
                <p className="text-gray-500 text-sm">
                    Explicamos el <em className="text-gray-300 not-italic">por qué</em> de cada permiso antes de solicitarlo.
                </p>
            </div>

            <div className="px-6 flex flex-col gap-5 flex-1">

                {/* Notification Permission Card */}
                <div className={`rounded-2xl border p-5 transition-all ${notifGranted !== null ? 'border-med-green/30 bg-med-green/5' : stage === 'notifications' ? 'border-med-blue/40 bg-med-blue/5' : 'border-gray-800 bg-med-gray opacity-50'
                    }`}>
                    {/* Icon + title row */}
                    <div className="flex items-center gap-3 mb-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${notifGranted === true ? 'bg-med-green/20' : 'bg-med-blue/20'
                            }`}>
                            {notifGranted === true
                                ? <CheckCircle2 size={20} className="text-med-green" />
                                : <Bell size={20} className="text-med-blue" />
                            }
                        </div>
                        <div>
                            <p className="text-white font-semibold text-sm">Notificaciones</p>
                            <p className="text-gray-500 text-xs">
                                {notifGranted === true ? 'Activadas ✓' : notifGranted === false ? 'Denegadas — puedes activarlas en Ajustes' : 'Por activar'}
                            </p>
                        </div>
                    </div>

                    {/* Why card */}
                    <div className="flex items-start gap-2 bg-black/30 rounded-xl px-3 py-3 mb-4">
                        <Info size={12} className="text-med-blue mt-0.5 flex-shrink-0" />
                        <p className="text-[11px] text-gray-400 leading-relaxed">
                            <strong className="text-gray-300">¿Para qué?</strong> Para recordarte tomar tu medicación, alertarte de patrones de riesgo detectados y notificar a tus contactos de emergencia durante una crisis.
                        </p>
                    </div>

                    {notifGranted === null && stage === 'notifications' && (
                        <button
                            id="perm-notifications"
                            onClick={handleRequestNotifications}
                            className="w-full py-3 bg-med-blue text-black font-bold text-sm rounded-xl active:scale-95 transition-transform"
                        >
                            Activar notificaciones →
                        </button>
                    )}
                </div>

                {/* Health Data Permission Card */}
                <div className={`rounded-2xl border p-5 transition-all ${healthGranted !== null ? 'border-med-green/30 bg-med-green/5' : stage === 'health' ? 'border-med-blue/40 bg-med-blue/5' : 'border-gray-800 bg-med-gray opacity-50'
                    }`}>
                    <div className="flex items-center gap-3 mb-3">
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${healthGranted === true ? 'bg-med-green/20' : 'bg-med-red/20'
                            }`}>
                            {healthGranted === true
                                ? <CheckCircle2 size={20} className="text-med-green" />
                                : <Heart size={20} className="text-med-red" />
                            }
                        </div>
                        <div>
                            <p className="text-white font-semibold text-sm">Apple Health / Google Fit</p>
                            <p className="text-gray-500 text-xs">
                                {healthGranted === true ? 'Conectado ✓' : stage === 'health' ? 'Por conectar' : 'Primero activa notificaciones'}
                            </p>
                        </div>
                    </div>

                    {/* Why card + data promise */}
                    <div className="flex items-start gap-2 bg-black/30 rounded-xl px-3 py-3 mb-3">
                        <Info size={12} className="text-med-blue mt-0.5 flex-shrink-0" />
                        <p className="text-[11px] text-gray-400 leading-relaxed">
                            <strong className="text-gray-300">¿Para qué?</strong> Para nutrir el algoritmo predictivo con tu frecuencia cardíaca (HeartRate) y calidad de sueño (SleepAnalysis), los dos biomarcadores más fiables de riesgo ictal.
                        </p>
                    </div>

                    {/* Privacy promise */}
                    <div className="flex items-center gap-2 mb-4">
                        <div className="w-2 h-2 rounded-full bg-med-green" />
                        <p className="text-[11px] text-gray-400">
                            <strong className="text-med-green">Tus datos de salud NO se venden.</strong> Solo lectura. Procesado localmente.
                        </p>
                    </div>

                    {/* Data we access */}
                    <div className="flex gap-2 mb-4 flex-wrap">
                        {['❤️ HeartRate', '📊 HRV', '😴 SleepAnalysis'].map(tag => (
                            <span key={tag} className="text-[10px] bg-gray-800 text-gray-400 px-2 py-1 rounded-full border border-gray-700">
                                {tag}
                            </span>
                        ))}
                    </div>

                    {healthGranted === null && stage === 'health' && (
                        <button
                            id="perm-health"
                            onClick={handleRequestHealth}
                            disabled={isLoading}
                            className="w-full py-3 bg-med-red text-white font-bold text-sm rounded-xl active:scale-95 transition-transform disabled:opacity-70"
                        >
                            {isLoading ? 'Conectando...' : 'Conectar con Apple Health →'}
                        </button>
                    )}
                </div>

                {stage === 'done' && (
                    <div className="bg-med-green/10 border border-med-green/30 rounded-2xl px-5 py-4">
                        <div className="flex items-center gap-2 mb-1">
                            <CheckCircle2 size={16} className="text-med-green" />
                            <p className="text-med-green font-semibold text-sm">¡Todo listo!</p>
                        </div>
                        <p className="text-gray-400 text-xs">El sistema de monitoreo predictivo está activo. Puedes ajustar los permisos en Ajustes del dispositivo en cualquier momento.</p>
                    </div>
                )}

                <div className="flex-1" />

                <button
                    id="perm-continue"
                    onClick={handleFinish}
                    className={`w-full py-4 mb-8 font-bold text-base rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 ${stage === 'done' ? 'bg-med-blue text-black shadow-lg shadow-med-blue/30' : 'bg-gray-800 text-gray-500 cursor-not-allowed'
                        }`}
                    disabled={stage !== 'done'}
                >
                    {stage === 'done' ? 'Continuar al Dashboard' : 'Completa los permisos para continuar'}
                    {stage === 'done' && <ChevronRight size={18} />}
                </button>
            </div>
        </div>
    );
};
