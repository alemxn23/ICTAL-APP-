import React, { useState, useEffect } from 'react';
import {
  ArrowLeft, User, Weight, ShieldCheck,
  ChevronRight, Pill, Plus, ScanLine, AlertCircle,
  Sparkles, LogIn, Mail, Lock, Eye, EyeOff,
  LogOut, Save, Loader2, CheckCircle2, UserCircle
} from 'lucide-react';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import { PatientProfile, Medication } from '../types';
import { MOCK_PATIENT } from '../constants';
import { authService } from '../services/authService';
import { onboardingService } from '../services/onboardingService';
import { supabase } from '../services/supabase';

interface UserProfileProps {
  onBack: () => void;
}

const COMMON_TRIGGERS = [
  'Estrés', 'Privación de Sueño', 'Luces Intermitentes',
  'Alcohol', 'Calor Extremo', 'Menstruación',
  'Omisión de Medicación', 'Cafeína',
];

// ============================================================
// Login Overlay / Form
// ============================================================

const LoginForm: React.FC<{ onSuccess: (user: SupabaseUser) => void; onCancel: () => void }> = ({ onSuccess, onCancel }) => {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!email.trim() || password.length < 6) {
      setError('Correo válido y contraseña de mín. 6 caracteres.');
      return;
    }
    setLoading(true);
    setError(null);
    const result = mode === 'signin'
      ? await authService.signInWithEmail(email.trim(), password)
      : await authService.signUpWithEmail(email.trim(), password);
    setLoading(false);
    if (result.error) {
      setError(result.error.message.includes('Invalid login') ? 'Credenciales incorrectas' : 'Error al conectar');
    } else if (result.user) {
      onSuccess(result.user);
    }
  };

  return (
    <div className="bg-[#111] border border-gray-800 rounded-2xl p-5 mt-4 space-y-4 animate-in fade-in zoom-in duration-200">
      <div className="flex bg-med-gray rounded-xl p-1">
        {(['signin', 'signup'] as const).map(m => (
          <button
            key={m}
            onClick={() => setMode(m)}
            className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold transition-all ${mode === m ? 'bg-med-blue text-black' : 'text-gray-500'
              }`}
          >
            {m === 'signin' ? 'ENTRAR' : 'REGISTRARME'}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        <div className="relative">
          <Mail size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            className="w-full bg-med-gray border border-gray-700 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm focus:outline-none focus:border-med-blue"
          />
        </div>
        <div className="relative">
          <Lock size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
          <input
            type={showPass ? 'text' : 'password'}
            placeholder="Contraseña"
            value={password}
            onChange={e => setPassword(e.target.value)}
            className="w-full bg-med-gray border border-gray-700 rounded-xl pl-9 pr-10 py-2.5 text-white text-sm focus:outline-none focus:border-med-blue"
          />
          <button onClick={() => setShowPass(!showPass)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500">
            {showPass ? <EyeOff size={14} /> : <Eye size={14} />}
          </button>
        </div>
      </div>

      {error && <p className="text-red-500 text-[10px] text-center">{error}</p>}

      <div className="flex gap-2">
        <button onClick={onCancel} className="px-4 py-2.5 border border-gray-700 rounded-xl text-xs text-gray-400 font-bold">CANCELAR</button>
        <button
          onClick={handleSubmit}
          disabled={loading}
          className="flex-1 py-2.5 bg-med-blue text-black font-bold text-xs rounded-xl flex items-center justify-center gap-2"
        >
          {loading ? <Loader2 size={14} className="animate-spin" /> : 'CONECTAR'}
        </button>
      </div>
    </div>
  );
};

// ============================================================
// Main Profile Screen
// ============================================================

export const UserProfileScreen: React.FC<UserProfileProps> = ({ onBack }) => {
  const [currentUser, setCurrentUser] = useState<SupabaseUser | null>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const [showLoginForm, setShowLoginForm] = useState(false);

  const [step, setStep] = useState(0);
  const [profile, setProfile] = useState<PatientProfile>(MOCK_PATIENT);
  const [dbProfile, setDbProfile] = useState<{ nombre?: string; apellido?: string; peso_kg?: number; sexo_biologico?: string } | null>(null);

  const [isSaving, setIsSaving] = useState(false);
  const [savedOk, setSavedOk] = useState(false);
  const [editNombre, setEditNombre] = useState('');
  const [editApellido, setEditApellido] = useState('');

  useEffect(() => {
    const init = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        setCurrentUser(session.user);
        await loadProfileFromDB(session.user.id);
      }
      setAuthLoading(false);
    };
    init();

    const sub = authService.onAuthStateChange(async (user) => {
      setCurrentUser(user);
      if (user) await loadProfileFromDB(user.id);
      else {
        setDbProfile(null);
        setEditNombre('');
        setEditApellido('');
      }
    });
    return () => sub.unsubscribe();
  }, []);

  const loadProfileFromDB = async (userId: string) => {
    const { data } = await supabase
      .from('perfil_clinico')
      .select('nombre, apellido, peso_kg, sexo_biologico')
      .eq('user_id', userId)
      .single();
    if (data) {
      setDbProfile(data);
      setEditNombre(data.nombre ?? '');
      setEditApellido(data.apellido ?? '');
      if (data.peso_kg) {
        setProfile(prev => ({ ...prev, demographics: { ...prev.demographics, weightKg: data.peso_kg } }));
      }
    }
  };

  const handleSaveBasics = async () => {
    if (!currentUser) return;
    setIsSaving(true);
    await onboardingService.upsertPerfilClinico(currentUser.id, {
      nombre: editNombre.trim(),
      apellido: editApellido.trim(),
      peso_kg: profile.demographics.weightKg,
      sexo_biologico: profile.demographics.biologicalSex === 'Male' ? 'Masculino' : 'Femenino',
    });
    setIsSaving(false);
    setSavedOk(true);
    setTimeout(() => setSavedOk(false), 2000);
  };

  const calculateProgress = () => {
    let score = 0;
    if (profile.demographics.weightKg > 0) score += 25;
    if (profile.contacts?.length > 0) score += 25;
    if (profile.medications.length > 0) score += 25;
    if (profile.medicalHistory.triggers.length > 0) score += 25;
    return score;
  };

  // Header Card (Responsive to Auth State)
  const renderUserCard = () => {
    if (authLoading) return <div className="h-24 bg-[#111] animate-pulse rounded-2xl" />;

    const initials = currentUser
      ? (dbProfile?.nombre ? `${dbProfile.nombre[0]}${dbProfile.apellido?.[0] ?? ''}` : (currentUser.email?.[0] ?? 'U')).toUpperCase()
      : 'U';

    const name = currentUser
      ? (dbProfile?.nombre ? `${dbProfile.nombre} ${dbProfile.apellido ?? ''}` : currentUser.email)
      : 'Iniciar Sesión';

    const subtitle = currentUser ? currentUser.email : 'Presiona para sincronizar tus datos';

    return (
      <button
        onClick={() => !currentUser && setShowLoginForm(true)}
        className="w-full bg-[#111] border border-gray-800 rounded-2xl p-4 flex items-center gap-4 text-left active:scale-[0.98] transition-transform"
      >
        <div className={`w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 border-2 ${currentUser ? 'bg-med-blue/20 border-med-blue/40' : 'bg-gray-800 border-gray-700'
          }`}>
          {currentUser ? <span className="text-med-blue font-bold text-lg">{initials}</span> : <UserCircle size={24} className="text-gray-500" />}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-white font-bold text-base truncate">{name}</p>
          <p className="text-gray-500 text-xs truncate">{subtitle}</p>
          {currentUser && (
            <div className="flex items-center gap-1.5 mt-1">
              <div className="w-1.5 h-1.5 rounded-full bg-med-green animate-pulse" />
              <span className="text-med-green text-[10px] font-bold">CUENTA ACTIVA</span>
            </div>
          )}
        </div>
        {currentUser ? (
          <button onClick={(e) => { e.stopPropagation(); authService.signOut().then(() => setCurrentUser(null)); }} className="p-2 text-gray-600 hover:text-med-red transition-colors">
            <LogOut size={16} />
          </button>
        ) : <ChevronRight size={18} className="text-gray-700" />}
      </button>
    );
  };

  return (
    <div className="h-full flex flex-col bg-med-black text-gray-300 select-none overflow-hidden">
      {/* Header */}
      <div className="px-5 pt-12 pb-3 flex items-center justify-between border-b border-gray-900 bg-med-black/95 backdrop-blur-md">
        <button onClick={onBack} className="p-2 -ml-2 text-white"><ArrowLeft size={22} /></button>
        <div className="flex items-center gap-2">
          <span className="text-med-blue font-black text-sm tracking-widest italic">ICTAL</span>
          <span className="text-gray-600 font-bold text-[10px]">VERSIÓN 1.0</span>
        </div>
        <div className="w-8" /> {/* Spacer */}
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
        {renderUserCard()}

        {showLoginForm && !currentUser && (
          <LoginForm
            onSuccess={() => { setShowLoginForm(false); }}
            onCancel={() => setShowLoginForm(false)}
          />
        )}

        {/* Step 0: Basics */}
        {step === 0 && (
          <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
            {currentUser ? (
              <div className="bg-[#111] p-4 rounded-xl border border-gray-800 space-y-4">
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
            ) : (
              <div className="p-8 text-center bg-[#111] border border-gray-800 rounded-2xl opacity-50 italic">
                <ShieldCheck size={32} className="mx-auto mb-3 text-gray-700" />
                <p className="text-xs text-gray-600">Inicia sesión para editar tu perfil clínico y sincronizar tus datos.</p>
              </div>
            )}
          </div>
        )}

        {/* Other steps could go here (meds, triggers) - using placeholders for brevity in this integrated flow */}
        {step > 0 && (
          <div className="p-8 text-center bg-[#111] border border-gray-800 rounded-2xl opacity-50 italic animate-in fade-in duration-300">
            <AlertCircle size={32} className="mx-auto mb-3 text-gray-700" />
            <p className="text-xs text-gray-600">Configuración avanzada disponible tras el registro biométrico.</p>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="p-5 border-t border-gray-900 bg-med-black">
        <button onClick={onBack} className="w-full py-4 bg-white text-black font-black text-xs rounded-xl flex items-center justify-center gap-2">
          LISTO <CheckCircle2 size={16} />
        </button>
      </div>
    </div>
  );
};