import React, { useState } from 'react';
import { ChevronRight } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep, OnboardingProfileData } from '../../types';
import { onboardingService } from '../../services/onboardingService';

type SexOption = NonNullable<OnboardingProfileData['sexo_biologico']>;

const SEX_OPTIONS: { value: SexOption; label: string; emoji: string; description: string }[] = [
    {
        value: 'Masculino',
        label: 'Masculino',
        emoji: '♂',
        description: 'Incluye hombres cisgénero y personas AMAB',
    },
    {
        value: 'Femenino',
        label: 'Femenino',
        emoji: '♀',
        description: 'Incluye mujeres cisgénero y personas AFAB',
    },
    {
        value: 'Intersex',
        label: 'Intersex',
        emoji: '⚥',
        description: 'Variaciones naturales en características sexuales',
    },
    {
        value: 'Otro',
        label: 'Prefiero no especificar',
        emoji: '◦',
        description: 'Se usarán valores farmacológicos promedio',
    },
];

/**
 * Phase 4B — Profile: Biological Sex
 * Required for drug metabolism alerts (pharmokinetics differ by sex).
 */
export const ProfileSexScreen: React.FC = () => {
    const { currentUser, updateProfileData, setStep } = useOnboarding();
    const [selected, setSelected] = useState<SexOption | null>(null);
    const [isLoading, setIsLoading] = useState(false);

    const handleNext = async () => {
        if (!selected || !currentUser) return;
        setIsLoading(true);
        updateProfileData({ sexo_biologico: selected });

        await onboardingService.upsertPerfilClinico(currentUser.id, {
            sexo_biologico: selected,
        });

        setIsLoading(false);
        setStep(OnboardingStep.PROFILE_WEIGHT);
    };

    return (
        <div className="w-full h-full bg-med-black flex flex-col">
            {/* Progress */}
            <div className="px-6 pt-12 pb-8">
                <div className="flex gap-1.5 mb-6">
                    {[0, 1, 2].map(i => (
                        <div key={i} className={`h-1 flex-1 rounded-full ${i <= 1 ? 'bg-med-blue' : 'bg-gray-800'}`} />
                    ))}
                </div>
                <p className="text-gray-500 text-xs mb-2 uppercase tracking-widest">Paso 2 de 3</p>
                <h2 className="text-2xl font-bold text-white mb-2 leading-tight">¿Cuál es tu sexo<br />biológico?</h2>
                <p className="text-gray-500 text-sm leading-relaxed">
                    <em className="text-gray-400 not-italic">Requerido para alertas de metabolismo de fármacos antiepilépticos.</em> El metabolismo de AEDs varía significativamente con el sexo biológico.
                </p>
            </div>

            {/* Options */}
            <div className="px-6 flex flex-col gap-3 flex-1">
                {SEX_OPTIONS.map(opt => {
                    const isSelected = selected === opt.value;
                    return (
                        <button
                            key={opt.value}
                            id={`sex-${opt.value.toLowerCase()}`}
                            onClick={() => setSelected(opt.value)}
                            className={`w-full flex items-center gap-4 rounded-2xl px-5 py-4 text-left border transition-all active:scale-98 ${isSelected
                                    ? 'bg-med-blue/10 border-med-blue/60 shadow-sm shadow-med-blue/20'
                                    : 'bg-med-gray border-gray-800 hover:border-gray-600'
                                }`}
                        >
                            <span className={`text-2xl w-8 text-center transition-all ${isSelected ? 'scale-125' : ''}`}>
                                {opt.emoji}
                            </span>
                            <div className="flex-1">
                                <p className={`font-semibold text-sm ${isSelected ? 'text-med-blue' : 'text-white'}`}>
                                    {opt.label}
                                </p>
                                <p className="text-gray-500 text-xs mt-0.5">{opt.description}</p>
                            </div>
                            {isSelected && (
                                <div className="w-5 h-5 rounded-full bg-med-blue flex items-center justify-center flex-shrink-0">
                                    <div className="w-2 h-2 rounded-full bg-black" />
                                </div>
                            )}
                        </button>
                    );
                })}

                <div className="flex-1" />

                <button
                    id="profile-sex-next"
                    onClick={handleNext}
                    disabled={!selected || isLoading}
                    className={`w-full py-4 mb-8 font-bold text-base rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 ${selected ? 'bg-med-blue text-black shadow-lg shadow-med-blue/30' : 'bg-gray-800 text-gray-600 cursor-not-allowed'
                        }`}
                >
                    {isLoading ? 'Guardando...' : 'Siguiente'}
                    {!isLoading && <ChevronRight size={18} />}
                </button>
            </div>
        </div>
    );
};
