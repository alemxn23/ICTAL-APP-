import React, { useState } from 'react';
import { CheckSquare, Square, Shield, ScrollText, ChevronRight, AlertCircle } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';
import { onboardingService } from '../../services/onboardingService';

const TOS_VERSION = '1.0';
const PRIVACY_VERSION = '1.0';

/**
 * Phase 3 — Legal Consent Screen
 * Both checkboxes must be accepted before proceeding.
 * On accept: INSERT into legal_consents (user_id, version, timestamp, IP).
 */
export const LegalConsentScreen: React.FC = () => {
    const { currentUser, setStep } = useOnboarding();
    const [acceptedTos, setAcceptedTos] = useState(false);
    const [acceptedPrivacy, setAcceptedPrivacy] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [expandedSection, setExpandedSection] = useState<string | null>(null);

    const canProceed = acceptedTos && acceptedPrivacy;

    const handleContinue = async () => {
        if (!canProceed || !currentUser) return;
        setIsLoading(true);
        setError(null);

        try {
            const { error: insertError } = await onboardingService.insertLegalConsent(currentUser.id);
            if (insertError) throw insertError;
            setStep(OnboardingStep.PROFILE_NAME);
        } catch {
            setError('No se pudo registrar tu consentimiento. Por favor intenta de nuevo.');
        } finally {
            setIsLoading(false);
        }
    };

    const CheckboxRow: React.FC<{
        id: string;
        checked: boolean;
        onChange: (v: boolean) => void;
        label: string;
        version: string;
        sectionKey: string;
        preview: string;
    }> = ({ id, checked, onChange, label, version, sectionKey, preview }) => (
        <div className={`rounded-2xl border p-4 transition-all ${checked ? 'border-med-blue/50 bg-med-blue/5' : 'border-gray-800 bg-med-gray'}`}>
            <div className="flex items-start gap-3">
                {/* Checkbox */}
                <button id={id} onClick={() => onChange(!checked)} className="mt-0.5 flex-shrink-0">
                    {checked
                        ? <CheckSquare size={22} className="text-med-blue" />
                        : <Square size={22} className="text-gray-600" />
                    }
                </button>

                <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                        <p className="text-white text-sm font-semibold">{label}</p>
                        <span className="text-[10px] text-gray-500 flex-shrink-0">v{version}</span>
                    </div>
                    <p className="text-gray-500 text-xs mt-1 leading-relaxed line-clamp-2">{preview}</p>

                    {/* Expand/collapse */}
                    <button
                        onClick={() => setExpandedSection(expandedSection === sectionKey ? null : sectionKey)}
                        className="flex items-center gap-1 text-med-blue text-xs mt-2"
                    >
                        {expandedSection === sectionKey ? 'Ocultar' : 'Leer completo'}
                        <ChevronRight size={12} className={`transition-transform ${expandedSection === sectionKey ? 'rotate-90' : ''}`} />
                    </button>

                    {expandedSection === sectionKey && (
                        <div className="mt-3 text-[11px] text-gray-400 leading-relaxed space-y-2 max-h-40 overflow-y-auto pr-1">
                            {sectionKey === 'tos' ? (
                                <>
                                    <p><strong className="text-gray-300">1. Uso de la App:</strong> EpilepsyCare AI es un dispositivo de apoyo médico, no un sustituto del diagnóstico o tratamiento profesional.</p>
                                    <p><strong className="text-gray-300">2. Responsabilidad:</strong> El usuario es responsable de compartir cualquier alerta con su médico tratante.</p>
                                    <p><strong className="text-gray-300">3. Algoritmo Predictivo:</strong> La puntuación de riesgo es probabilística y no garantiza la predicción de crisis epilépticas.</p>
                                    <p><strong className="text-gray-300">4. Emergencias:</strong> En caso de crisis, llamar a los servicios de emergencia (911 en México).</p>
                                    <p><strong className="text-gray-300">5. Actualizaciones:</strong> Los términos pueden actualizarse. Se notificará al usuario ante cambios materiales.</p>
                                </>
                            ) : (
                                <>
                                    <p><strong className="text-gray-300">Datos recopilados:</strong> Datos biométricos (FC, VFC, sueño), perfil clínico (peso, sexo, medicación), y eventos de crisis.</p>
                                    <p><strong className="text-gray-300">Almacenamiento:</strong> Supabase (cifrado AES-256 en reposo, TLS en tránsito). Región: us-east-1.</p>
                                    <p><strong className="text-gray-300">No se venden datos:</strong> Tus datos no se comparten con terceros con fines comerciales ni publicitarios.</p>
                                    <p><strong className="text-gray-300">Apple Health / Google Fit:</strong> Los datos de salud solo se leen para el algoritmo predictivo local. No se suben al servidor sin tu consentimiento explícito.</p>
                                    <p><strong className="text-gray-300">Derecho de supresión:</strong> Puedes solicitar la eliminación total de tus datos desde Perfil → Eliminar cuenta.</p>
                                </>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );

    return (
        <div className="w-full h-full bg-med-black flex flex-col overflow-y-auto">
            {/* Header */}
            <div className="px-6 pt-12 pb-6">
                <div className="w-12 h-12 rounded-2xl bg-med-amber/10 border border-med-amber/30 flex items-center justify-center mb-5">
                    <Shield size={22} className="text-med-amber" />
                </div>
                <h2 className="text-2xl font-bold text-white mb-2">Consentimiento clínico</h2>
                <p className="text-gray-500 text-sm leading-relaxed">
                    Al ser una aplicación médica, necesitamos tu consentimiento explícito. Lee y acepta ambos documentos para continuar.
                </p>
            </div>

            {/* Legal Consents */}
            <div className="px-6 flex flex-col gap-3 flex-1">
                <CheckboxRow
                    id="tos-checkbox"
                    checked={acceptedTos}
                    onChange={setAcceptedTos}
                    label="Términos y Condiciones"
                    version={TOS_VERSION}
                    sectionKey="tos"
                    preview="EpilepsyCare AI es un dispositivo de apoyo médico. El algoritmo predictivo es probabilístico y no reemplaza el criterio médico."
                />

                <CheckboxRow
                    id="privacy-checkbox"
                    checked={acceptedPrivacy}
                    onChange={setAcceptedPrivacy}
                    label="Aviso de Privacidad"
                    version={PRIVACY_VERSION}
                    sectionKey="privacy"
                    preview="Tus datos biométricos y clínicos se almacenan cifrados (AES-256). No se venden ni comparten con terceros."
                />

                {/* Legal protection notice */}
                <div className="flex items-start gap-2 bg-med-gray rounded-xl px-4 py-3 mt-1">
                    <ScrollText size={13} className="text-gray-500 mt-0.5 flex-shrink-0" />
                    <p className="text-[11px] text-gray-500 leading-relaxed">
                        Tu consentimiento se registra con <strong className="text-gray-400">fecha, hora y dirección IP</strong> para protección legal de ambas partes (NOM-024-SSA3 / HIPAA).
                    </p>
                </div>

                {error && (
                    <div className="flex items-start gap-2 bg-red-900/30 border border-red-700/50 rounded-xl px-4 py-3">
                        <AlertCircle size={14} className="text-med-red mt-0.5 flex-shrink-0" />
                        <p className="text-red-400 text-xs">{error}</p>
                    </div>
                )}

                <div className="pb-6 pt-2">
                    <button
                        id="legal-continue"
                        onClick={handleContinue}
                        disabled={!canProceed || isLoading}
                        className={`w-full py-4 font-bold text-base rounded-2xl transition-all active:scale-95 ${canProceed
                                ? 'bg-med-blue text-black shadow-lg shadow-med-blue/30'
                                : 'bg-gray-800 text-gray-600 cursor-not-allowed'
                            }`}
                    >
                        {isLoading ? 'Registrando consentimiento...' : canProceed ? 'Acepto y continúo' : 'Acepta ambos documentos para continuar'}
                    </button>
                </div>
            </div>
        </div>
    );
};
