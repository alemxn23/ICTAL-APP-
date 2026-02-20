import React, { useState, useRef } from 'react';
import { ChevronRight, Minus, Plus } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';
import { onboardingService } from '../../services/onboardingService';

const MIN_KG = 20;
const MAX_KG = 300;

/**
 * Phase 4C — Profile: Weight (in kg)
 * Native numeric keyboard. Required for drug dosage calculations.
 */
export const ProfileWeightScreen: React.FC = () => {
    const { currentUser, updateProfileData, setStep } = useOnboarding();
    const [pesoStr, setPesoStr] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const inputRef = useRef<HTMLInputElement>(null);

    const pesoNum = parseFloat(pesoStr);
    const isValid = !isNaN(pesoNum) && pesoNum >= MIN_KG && pesoNum <= MAX_KG;

    const getBMIHint = (): string => {
        if (!isValid) return '';
        // Without height we can't compute real BMI, just a weight hint
        if (pesoNum < 45) return 'Bajo peso registrado';
        if (pesoNum > 120) return 'Dosaje farmacológico ajustado';
        return 'Rango típico adulto';
    };

    const adjustPeso = (delta: number) => {
        const current = isNaN(pesoNum) ? 70 : pesoNum;
        const next = Math.max(MIN_KG, Math.min(MAX_KG, current + delta));
        setPesoStr(next.toString());
    };

    const handleNext = async () => {
        if (!isValid || !currentUser) return;
        setIsLoading(true);
        updateProfileData({ peso_kg: pesoNum });

        await onboardingService.upsertPerfilClinico(currentUser.id, {
            peso_kg: pesoNum,
        });

        setIsLoading(false);
        setStep(OnboardingStep.PERMISSIONS);
    };

    return (
        <div className="w-full h-full bg-med-black flex flex-col">
            {/* Progress */}
            <div className="px-6 pt-12 pb-8">
                <div className="flex gap-1.5 mb-6">
                    {[0, 1, 2].map(i => (
                        <div key={i} className="h-1 flex-1 rounded-full bg-med-blue" />
                    ))}
                </div>
                <p className="text-gray-500 text-xs mb-2 uppercase tracking-widest">Paso 3 de 3</p>
                <h2 className="text-2xl font-bold text-white mb-2 leading-tight">¿Cuál es tu peso actual?</h2>
                <p className="text-gray-500 text-sm leading-relaxed">
                    El peso corporal determina la dosificación exacta de antiepilépticos como Levetiracetam y Valproato.
                </p>
            </div>

            {/* Weight Input */}
            <div className="px-6 flex flex-col items-center flex-1">
                {/* Large display */}
                <div className="flex items-end gap-3 mb-8">
                    <button
                        onClick={() => adjustPeso(-1)}
                        className="w-12 h-12 rounded-full bg-med-gray border border-gray-700 flex items-center justify-center text-gray-300 active:scale-90 transition-transform"
                    >
                        <Minus size={18} />
                    </button>

                    <div className="flex flex-col items-center">
                        <div
                            className="flex items-baseline gap-2 cursor-text"
                            onClick={() => inputRef.current?.focus()}
                        >
                            <input
                                ref={inputRef}
                                id="profile-weight"
                                type="number"
                                inputMode="decimal"
                                min={MIN_KG}
                                max={MAX_KG}
                                step="0.5"
                                placeholder="70"
                                value={pesoStr}
                                onChange={e => setPesoStr(e.target.value)}
                                className="bg-transparent text-center text-6xl font-bold text-white w-40 focus:outline-none"
                                style={{ caretColor: '#00F0FF' }}
                            />
                            <span className="text-2xl text-gray-500 font-medium">kg</span>
                        </div>

                        {/* BMI/weight hint */}
                        <p className={`text-xs mt-1 font-medium ${isValid ? 'text-med-blue' : 'text-gray-600'}`}>
                            {isValid ? getBMIHint() : `Ingresa un valor entre ${MIN_KG} y ${MAX_KG} kg`}
                        </p>
                    </div>

                    <button
                        onClick={() => adjustPeso(1)}
                        className="w-12 h-12 rounded-full bg-med-gray border border-gray-700 flex items-center justify-center text-gray-300 active:scale-90 transition-transform"
                    >
                        <Plus size={18} />
                    </button>
                </div>

                {/* Quick-pick common weights */}
                <div className="flex gap-2 flex-wrap justify-center mb-8">
                    {[55, 65, 70, 75, 80, 90].map(w => (
                        <button
                            key={w}
                            onClick={() => setPesoStr(w.toString())}
                            className={`px-4 py-2 rounded-full text-sm font-medium border transition-all ${pesoNum === w
                                    ? 'bg-med-blue text-black border-med-blue'
                                    : 'bg-med-gray text-gray-400 border-gray-700 hover:border-gray-500'
                                }`}
                        >
                            {w} kg
                        </button>
                    ))}
                </div>

                {/* Clinical note */}
                <div className="w-full bg-med-gray rounded-xl px-4 py-3 flex items-start gap-2">
                    <span className="text-med-amber text-sm mt-0.5">⚕</span>
                    <p className="text-[11px] text-gray-500 leading-relaxed">
                        Tu peso se usa <strong className="text-gray-400">exclusivamente</strong> para calcular dosis farmacológicas y nunca con fines comerciales. Puedes actualizarlo en cualquier momento desde tu perfil.
                    </p>
                </div>

                <div className="flex-1" />

                <button
                    id="profile-weight-next"
                    onClick={handleNext}
                    disabled={!isValid || isLoading}
                    className={`w-full py-4 mb-8 font-bold text-base rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 ${isValid ? 'bg-med-blue text-black shadow-lg shadow-med-blue/30' : 'bg-gray-800 text-gray-600 cursor-not-allowed'
                        }`}
                >
                    {isLoading ? 'Guardando...' : 'Siguiente'}
                    {!isLoading && <ChevronRight size={18} />}
                </button>
            </div>
        </div>
    );
};
