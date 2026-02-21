import React, { useState } from 'react';
import {
  ArrowLeft, User, Weight, ShieldCheck,
  ChevronRight, Pill, Plus, ScanLine, AlertCircle,
  Sparkles, LogIn, Mail, Lock, Eye, EyeOff,
  LogOut, Save, Loader2, CheckCircle2, UserCircle,
  UserPlus
} from 'lucide-react';
import { PatientProfile } from '../types';
import { MOCK_PATIENT } from '../constants';
import { useAuth } from '../context/AuthContext';

interface UserProfileProps {
  onBack: () => void;
}

export const UserProfileScreen: React.FC<UserProfileProps> = ({ onBack }) => {
  const { isLoggedIn, login, logout } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);

  const [step, setStep] = useState(0);
  const [profile, setProfile] = useState<PatientProfile>(MOCK_PATIENT);
  const [editNombre, setEditNombre] = useState('María');
  const [editApellido, setEditApellido] = useState('García');

  const [isSaving, setIsSaving] = useState(false);
  const [savedOk, setSavedOk] = useState(false);

  const handleSaveBasics = async () => {
    setIsSaving(true);
    // Mock save delay
    await new Promise(resolve => setTimeout(resolve, 800));
    setIsSaving(false);
    setSavedOk(true);
    setTimeout(() => setSavedOk(false), 2000);
  };

  const renderGuestState = () => (
    <div className="h-full flex flex-col bg-black text-gray-300 select-none overflow-hidden relative">
      {/* Header */}
      <div className="px-5 pt-12 pb-3 flex items-center justify-between border-b border-gray-900 bg-black backdrop-blur-md">
        <button onClick={onBack} className="p-2 -ml-2 text-white"><ArrowLeft size={22} /></button>
        <div className="flex items-center gap-2">
          <span className="text-med-blue font-black text-sm tracking-widest italic">ICTAL</span>
        </div>
        <div className="w-8" />
      </div>

      {/* Guest Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center p-8 text-center space-y-6">
        <div className="w-24 h-24 rounded-full bg-gray-900 flex items-center justify-center mb-2">
          <UserPlus size={48} className="text-med-blue" strokeWidth={1.5} />
        </div>
        <h1 className="text-white font-bold text-2xl tracking-tight">Tu Perfil Médico</h1>
        <p className="text-gray-400 text-sm leading-relaxed mb-6">
          Inicia sesión o crea una cuenta para guardar tu expediente clínico, sincronizar sensores y configurar tu red de apoyo.
        </p>
        <button
          onClick={() => setShowAuthModal(true)}
          className="w-full py-4 bg-med-blue text-black font-bold text-[15px] rounded-xl active:scale-[0.98] transition-all"
        >
          Iniciar Sesión / Registrarse
        </button>
      </div>

      {/* Auth Modal Bottom Sheet */}
      {showAuthModal && (
        <div className="absolute inset-0 z-50 flex flex-col justify-end bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="absolute inset-0" onClick={() => setShowAuthModal(false)} />
          <div className="bg-[#1C1C1E] rounded-t-3xl p-6 pb-10 shadow-2xl animate-in slide-in-from-bottom-full duration-300 relative z-10 w-full">
            <div className="w-12 h-1.5 bg-gray-700 rounded-full mx-auto mb-6" />
            <h2 className="text-white font-bold text-xl mb-6 tracking-tight">Iniciar Sesión</h2>
            <div className="space-y-4">
              <input
                type="email"
                placeholder="Email"
                className="w-full bg-[#2C2C2E] text-white px-4 py-3.5 rounded-xl outline-none focus:ring-2 focus:ring-med-blue transition-all"
              />
              <input
                type="password"
                placeholder="Contraseña"
                className="w-full bg-[#2C2C2E] text-white px-4 py-3.5 rounded-xl outline-none focus:ring-2 focus:ring-med-blue transition-all"
              />
              <button
                onClick={() => {
                  login();
                  setShowAuthModal(false);
                }}
                className="w-full py-3.5 mt-2 bg-med-blue text-black font-bold text-[15px] rounded-xl active:scale-[0.98] transition-all"
              >
                Continuar
              </button>

              <div className="relative py-4 flex items-center justify-center">
                <div className="absolute border-t border-gray-700 w-full" />
                <span className="relative bg-[#1C1C1E] px-4 text-xs text-gray-500 font-medium">o</span>
              </div>

              <button
                onClick={() => {
                  login();
                  setShowAuthModal(false);
                }}
                className="w-full py-3.5 bg-white text-black font-bold text-[15px] rounded-xl flex items-center justify-center gap-2 active:scale-[0.98] transition-all"
              >
                 Sign in with Apple
              </button>

              <button
                onClick={() => setShowAuthModal(false)}
                className="w-full py-4 text-gray-500 text-sm font-bold"
              >
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  const renderAuthenticatedUserCard = () => (
    <div className="w-full bg-[#111] border border-gray-800 rounded-2xl p-4 flex items-center gap-4 text-left">
      <div className="w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 border-2 bg-med-blue/20 border-med-blue/40">
        <span className="text-med-blue font-bold text-lg">{editNombre[0]}{editApellido[0]}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-white font-bold text-base truncate">{editNombre} {editApellido}</p>
        <p className="text-gray-500 text-xs truncate">{editNombre.toLowerCase()}.{editApellido.toLowerCase()}@example.com</p>
        <div className="flex items-center gap-1.5 mt-1">
          <div className="w-1.5 h-1.5 rounded-full bg-med-green animate-pulse" />
          <span className="text-med-green text-[10px] font-bold">CUENTA ACTIVA</span>
        </div>
      </div>
    </div>
  );

  if (!isLoggedIn) {
    return renderGuestState();
  }

  // Dashboard / Authenticated State
  return (
    <div className="h-full flex flex-col bg-med-black text-gray-300 select-none overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-12 pb-3 flex items-center justify-between border-b border-gray-900 bg-med-black/95 backdrop-blur-md">
        <button onClick={onBack} className="p-2 -ml-2 text-white"><ArrowLeft size={22} /></button>
        <div className="flex items-center gap-2">
          <span className="text-med-blue font-black text-sm tracking-widest italic">ICTAL</span>
          <span className="text-gray-600 font-bold text-[10px]">VERSIÓN 1.0</span>
        </div>
        <div className="w-8" />
      </div>

      {/* Tabs */}
      <div className="flex border-b border-gray-900 px-5 bg-med-black">
        {['PERFIL', 'FÁRMACOS', 'ALERTAS'].map((label, i) => (
          <button
            key={i}
            onClick={() => setStep(i)}
            className={`flex-1 py-3 text-[10px] font-black border-b-2 transition-all ${step === i ? 'border-med-blue text-med-blue' : 'border-transparent text-gray-600'
              }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-5 py-4 pb-20 space-y-4">
        {renderAuthenticatedUserCard()}

        {/* Step 0: Basics */}
        {step === 0 && (
          <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
            {/* Perfil Fisiológico Card */}
            <div className="bg-[#111] p-4 rounded-xl border border-gray-800 space-y-4">
              <h3 className="text-white font-bold text-sm tracking-tight mb-2">Perfil Fisiológico</h3>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-gray-600 mb-1 block">NOMBRE</label>
                  <input
                    value={editNombre} onChange={e => setEditNombre(e.target.value)}
                    className="w-full bg-black border border-gray-800 rounded-lg px-3 py-2 text-sm text-white focus:border-med-blue outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-gray-600 mb-1 block">APELLIDO</label>
                  <input
                    value={editApellido} onChange={e => setEditApellido(e.target.value)}
                    className="w-full bg-black border border-gray-800 rounded-lg px-3 py-2 text-sm text-white focus:border-med-blue outline-none"
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="text-[10px] font-bold text-gray-600 mb-1 block">PESO (KG)</label>
                  <input
                    type="number" value={profile.demographics.weightKg}
                    onChange={e => setProfile({ ...profile, demographics: { ...profile.demographics, weightKg: parseFloat(e.target.value) } })}
                    className="w-full bg-black border border-gray-800 rounded-lg px-3 py-2 text-sm text-white focus:border-med-blue outline-none"
                  />
                </div>
                <div className="col-span-2">
                  <label className="text-[10px] font-bold text-gray-600 mb-1 block">SEXO BIOLÓGICO</label>
                  <div className="flex gap-1">
                    {['Male', 'Female'].map(s => (
                      <button
                        key={s} onClick={() => setProfile({ ...profile, demographics: { ...profile.demographics, biologicalSex: s as any } })}
                        className={`flex-1 py-1.5 rounded-lg text-xs font-bold border transition-all ${profile.demographics.biologicalSex === s ? 'bg-med-blue text-black border-med-blue' : 'border-gray-800 text-gray-600'
                          }`}
                      >
                        {s === 'Male' ? 'MASC' : 'FEM'}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
              <button
                onClick={handleSaveBasics} disabled={isSaving}
                className="w-full py-3 bg-med-blue/10 border border-med-blue/30 text-med-blue text-xs font-bold rounded-xl flex items-center justify-center gap-2"
              >
                {isSaving ? <Loader2 size={14} className="animate-spin" /> : savedOk ? <CheckCircle2 size={14} /> : <Save size={14} />}
                {isSaving ? 'GUARDANDO...' : savedOk ? '¡GUARDADO!' : 'GUARDAR CAMBIOS'}
              </button>
            </div>

            {/* Red de Apoyo / Support Network Card */}
            <div className="bg-[#111] p-4 rounded-xl border border-gray-800 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-white font-bold text-sm tracking-tight">Red de Apoyo</h3>
                <button className="text-med-blue text-xs font-bold p-1"><Plus size={16} /></button>
              </div>
              {profile.contacts.map((contact, i) => (
                <div key={i} className="flex flex-col gap-1 p-3 bg-black rounded-lg border border-gray-800">
                  <div className="flex items-center justify-between">
                    <span className="text-white font-semibold text-sm">{contact.name}</span>
                    <span className="text-xs text-gray-500">{contact.phone}</span>
                  </div>
                  <span className="text-[10px] text-med-blue font-bold uppercase">{contact.relationship}</span>
                </div>
              ))}
            </div>

            {/* Mis Tipos de Crisis Card */}
            <div className="bg-[#111] p-4 rounded-xl border border-gray-800 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-white font-bold text-sm tracking-tight">Mis Tipos de Crisis</h3>
              </div>
              {profile.medicalHistory.seizureTypes.map((type, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-black rounded-lg border border-gray-800">
                  <span className="text-white font-semibold text-sm">{type}</span>
                  <ChevronRight size={16} className="text-gray-600" />
                </div>
              ))}
            </div>

            {/* Logout Action */}
            <div className="pt-6">
              <button
                onClick={() => {
                  // "Clear any mock user data. Instantly revert the Profile screen back to the "Guest State""
                  setProfile(MOCK_PATIENT);
                  setEditNombre('María');
                  setEditApellido('García');
                  setStep(0);
                  logout();
                }}
                className="w-full py-4 bg-red-500/10 border border-red-500/30 text-red-500 font-bold text-[13px] rounded-xl flex items-center justify-center gap-2 active:scale-[0.98] transition-all"
              >
                <LogOut size={16} /> Cerrar Sesión
              </button>
            </div>

          </div>
        )}

        {/* Other Tabs Content */}
        {step > 0 && (
          <div className="p-8 text-center bg-[#111] border border-gray-800 rounded-2xl opacity-50 italic animate-in fade-in duration-300">
            <AlertCircle size={32} className="mx-auto mb-3 text-gray-700" />
            <p className="text-xs text-gray-600">Configuración avanzada disponible en esta sección.</p>
          </div>
        )}
      </div>
    </div>
  );
};