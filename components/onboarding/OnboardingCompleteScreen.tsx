import React, { useEffect, useState } from 'react';
import { CheckCircle2, Brain, Bell, Heart, Zap } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';

/**
 * Phase 6 — Onboarding Complete
 * Summary of what was set up, then redirect to Dashboard.
 * Calls completeOnboarding() to set onboarding_completado = true in Supabase.
 */
export const OnboardingCompleteScreen: React.FC = () => {
    const { profileData, completeOnboarding } = useOnboarding();
    const [isCompleting, setIsCompleting] = useState(false);
    const [showContent, setShowContent] = useState(false);

    useEffect(() => {
        // Stagger entry animation
        setTimeout(() => setShowContent(true), 300);
    }, []);

    const handleGoToDashboard = async () => {
        setIsCompleting(true);
        await completeOnboarding();
        // OnboardingContext will detect isOnboardingDone = true and render the Dashboard
    };

    const firstName = profileData.nombre ?? 'Paciente';

    const achievements = [
        {
            icon: <CheckCircle2 size={16} className="text-med-green" />,
            text: 'Consentimiento clínico registrado',
            color: 'text-med-green',
        },
        {
            icon: <Brain size={16} className="text-med-blue" />,
            text: `Perfil basal creado para ${firstName}`,
            color: 'text-med-blue',
        },
        {
            icon: <Bell size={16} className="text-med-amber" />,
            text: 'Alertas de medicación activadas',
            color: 'text-med-amber',
        },
        {
            icon: <Heart size={16} className="text-med-red" />,
            text: 'Monitor biométrico conectado',
            color: 'text-med-red',
        },
        {
            icon: <Zap size={16} className="text-med-blue" />,
            text: 'Algoritmo predictivo en espera de datos',
            color: 'text-med-blue',
        },
    ];

    return (
        <div className="w-full h-full bg-med-black flex flex-col items-center justify-center px-6 overflow-hidden">
            {/* Central success icon */}
            <div className={`transition-all duration-700 ${showContent ? 'opacity-100 scale-100' : 'opacity-0 scale-50'}`}>
                <div className="relative mb-8">
                    {/* Outer rings */}
                    <div className="absolute inset-0 rounded-full border border-med-green/20 animate-ping" style={{ animationDuration: '2s' }} />
                    <div className="absolute inset-2 rounded-full border border-med-green/30 animate-ping" style={{ animationDuration: '2.5s', animationDelay: '0.3s' }} />

                    <div className="w-28 h-28 rounded-full bg-med-green/10 border-2 border-med-green/50 flex items-center justify-center">
                        <CheckCircle2 size={52} className="text-med-green" strokeWidth={1.5} />
                    </div>
                </div>
            </div>

            {/* Title */}
            <div className={`text-center mb-8 transition-all duration-700 delay-200 ${showContent ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
                <h2 className="text-3xl font-bold text-white mb-2">
                    ¡Todo listo, <span className="text-med-blue">{firstName}</span>!
                </h2>
                <p className="text-gray-400 text-sm leading-relaxed max-w-xs mx-auto">
                    Tu diario neurológico seguro está configurado y listo para monitorear tu salud cerebral en tiempo real.
                </p>
            </div>

            {/* Achievement list */}
            <div className={`w-full bg-med-gray rounded-2xl px-5 py-4 mb-8 transition-all duration-700 delay-300 ${showContent ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
                <p className="text-gray-500 text-xs uppercase tracking-widest mb-3">Configurado con éxito</p>
                <div className="flex flex-col gap-3">
                    {achievements.map((item, i) => (
                        <div key={i} className="flex items-center gap-3">
                            {item.icon}
                            <p className="text-gray-300 text-sm">{item.text}</p>
                        </div>
                    ))}
                </div>
            </div>

            {/* Dashboard CTA */}
            <div className={`w-full flex flex-col gap-3 transition-all duration-700 delay-500 ${showContent ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
                <button
                    id="go-to-dashboard"
                    onClick={handleGoToDashboard}
                    disabled={isCompleting}
                    className="w-full py-4 bg-med-blue text-black font-bold text-base rounded-2xl shadow-lg shadow-med-blue/30 active:scale-95 transition-transform disabled:opacity-70"
                >
                    {isCompleting ? 'Activando sistema...' : 'Ir al Dashboard →'}
                </button>

                <p className="text-center text-[10px] text-gray-600">
                    El análisis de riesgo comenzará una vez que el monitor biométrico recopile datos durante 24h.
                </p>
            </div>
        </div>
    );
};
