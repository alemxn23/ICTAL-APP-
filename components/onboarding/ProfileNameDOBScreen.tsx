import React, { useState } from 'react';
import { User, Calendar, ChevronRight } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';
import { onboardingService } from '../../services/onboardingService';

/**
 * Phase 4A — Profile: Name + Date of Birth
 */
export const ProfileNameDOBScreen: React.FC = () => {
    const { currentUser, updateProfileData, setStep } = useOnboarding();
    const [nombre, setNombre] = useState('');
    const [apellido, setApellido] = useState('');
    const [fechaNacimiento, setFechaNacimiento] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const canProceed = nombre.trim().length > 0 && fechaNacimiento.length === 10;

    const handleNext = async () => {
        if (!canProceed || !currentUser) return;
        setIsLoading(true);
        updateProfileData({ nombre: nombre.trim(), apellido: apellido.trim(), fecha_nacimiento: fechaNacimiento });

        // Partial save to Supabase
        await onboardingService.upsertPerfilClinico(currentUser.id, {
            nombre: nombre.trim(),
            apellido: apellido.trim(),
            fecha_nacimiento: fechaNacimiento,
        });

        setIsLoading(false);
        setStep(OnboardingStep.PROFILE_SEX);
    };

    // Calculate age hint
    const getAgeHint = (): string => {
        if (fechaNacimiento.length !== 10) return '';
        const dob = new Date(fechaNacimiento);
        const now = new Date();
        const age = now.getFullYear() - dob.getFullYear();
        if (isNaN(age) || age < 0 || age > 130) return 'Fecha inválida';
        return `${age} años`;
    };

    return (
        <div className="w-full h-full bg-med-black flex flex-col">
            {/* Progress */}
            <div className="px-6 pt-12 pb-8">
                <div className="flex gap-1.5 mb-6">
                    {[0, 1, 2].map(i => (
                        <div key={i} className={`h-1 flex-1 rounded-full ${i === 0 ? 'bg-med-blue' : 'bg-gray-800'}`} />
                    ))}
                </div>
                <p className="text-gray-500 text-xs mb-2 uppercase tracking-widest">Paso 1 de 3</p>
                <div className="flex items-center gap-3 mb-3">
                    <div className="w-10 h-10 rounded-xl bg-med-blue/10 border border-med-blue/30 flex items-center justify-center">
                        <User size={18} className="text-med-blue" />
                    </div>
                    <h2 className="text-2xl font-bold text-white leading-tight">¿Cómo te llamas<br />y cuándo naciste?</h2>
                </div>
                <p className="text-gray-500 text-sm">Tu nombre personaliza las alertas para tus contactos de emergencia.</p>
            </div>

            {/* Form */}
            <div className="px-6 flex flex-col gap-4 flex-1">
                <div className="flex gap-3">
                    <div className="flex-1">
                        <label className="block text-gray-500 text-xs mb-1.5 uppercase tracking-wide">Nombre</label>
                        <input
                            id="profile-nombre"
                            type="text"
                            autoComplete="given-name"
                            placeholder="Alejandro"
                            value={nombre}
                            onChange={e => setNombre(e.target.value)}
                            className="w-full bg-med-gray border border-gray-700 rounded-xl px-4 py-4 text-white text-base focus:outline-none focus:border-med-blue transition-colors"
                        />
                    </div>
                    <div className="flex-1">
                        <label className="block text-gray-500 text-xs mb-1.5 uppercase tracking-wide">Apellido</label>
                        <input
                            id="profile-apellido"
                            type="text"
                            autoComplete="family-name"
                            placeholder="García"
                            value={apellido}
                            onChange={e => setApellido(e.target.value)}
                            className="w-full bg-med-gray border border-gray-700 rounded-xl px-4 py-4 text-white text-base focus:outline-none focus:border-med-blue transition-colors"
                        />
                    </div>
                </div>

                <div>
                    <label className="block text-gray-500 text-xs mb-1.5 uppercase tracking-wide">Fecha de nacimiento</label>
                    <div className="relative">
                        <Calendar size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" />
                        <input
                            id="profile-dob"
                            type="date"
                            value={fechaNacimiento}
                            onChange={e => setFechaNacimiento(e.target.value)}
                            max={new Date().toISOString().split('T')[0]}
                            min="1900-01-01"
                            className="w-full bg-med-gray border border-gray-700 rounded-xl pl-10 pr-4 py-4 text-white text-base focus:outline-none focus:border-med-blue transition-colors appearance-none"
                            style={{ colorScheme: 'dark' }}
                        />
                        {getAgeHint() && (
                            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xs text-med-blue font-semibold">
                                {getAgeHint()}
                            </span>
                        )}
                    </div>
                </div>

                {/* Why we need this */}
                <div className="bg-med-gray rounded-xl px-4 py-3 flex items-start gap-2">
                    <span className="text-med-blue text-sm">ℹ</span>
                    <p className="text-[11px] text-gray-500 leading-relaxed">
                        Tu fecha de nacimiento permite calcular las dosis farmacológicas apropiadas para tu edad y ajustar los umbrales de alerta del algoritmo predictivo.
                    </p>
                </div>

                <div className="flex-1" />

                <button
                    id="profile-name-next"
                    onClick={handleNext}
                    disabled={!canProceed || isLoading}
                    className={`w-full py-4 mb-8 font-bold text-base rounded-2xl flex items-center justify-center gap-2 transition-all active:scale-95 ${canProceed ? 'bg-med-blue text-black shadow-lg shadow-med-blue/30' : 'bg-gray-800 text-gray-600 cursor-not-allowed'
                        }`}
                >
                    {isLoading ? 'Guardando...' : 'Siguiente'}
                    {!isLoading && <ChevronRight size={18} />}
                </button>
            </div>
        </div>
    );
};
