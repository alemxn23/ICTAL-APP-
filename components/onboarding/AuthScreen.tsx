import React, { useState } from 'react';
import { Eye, EyeOff, Mail, Lock, AlertCircle } from 'lucide-react';
import { useOnboarding } from '../../context/OnboardingContext';
import { OnboardingStep } from '../../types';
import { authService } from '../../services/authService';

type AuthMode = 'signup' | 'signin';

/**
 * Phase 2 — Authentication Screen
 * Email/Password + Apple + Google sign-in via Supabase Auth.
 */
export const AuthScreen: React.FC = () => {
    const { setStep } = useOnboarding();
    const [mode, setMode] = useState<AuthMode>('signup');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPass, setShowPass] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleEmailAuth = async () => {
        if (!email.trim() || !password.trim()) {
            setError('Por favor ingresa tu correo y contraseña.');
            return;
        }
        if (password.length < 8) {
            setError('La contraseña debe tener al menos 8 caracteres.');
            return;
        }

        setError(null);
        setIsLoading(true);

        try {
            const result = mode === 'signup'
                ? await authService.signUpWithEmail(email.trim(), password)
                : await authService.signInWithEmail(email.trim(), password);

            if (result.error) {
                setError(translateAuthError(result.error.message));
            } else if (result.user) {
                // OnboardingContext will detect auth state change and route to LEGAL
                setStep(OnboardingStep.LEGAL);
            }
        } finally {
            setIsLoading(false);
        }
    };

    const handleGoogleSignIn = async () => {
        setError(null);
        const { error } = await authService.signInWithGoogle();
        if (error) setError(translateAuthError(error.message));
    };

    const handleAppleSignIn = async () => {
        setError(null);
        const { error } = await authService.signInWithApple();
        if (error) setError(translateAuthError(error.message));
    };

    const translateAuthError = (msg: string): string => {
        if (msg.includes('already registered')) return 'Este correo ya está registrado. Inicia sesión.';
        if (msg.includes('Invalid login credentials')) return 'Correo o contraseña incorrectos.';
        if (msg.includes('Email not confirmed')) return 'Revisa tu correo y confirma tu cuenta.';
        return 'Error de autenticación. Intenta de nuevo.';
    };

    return (
        <div className="w-full h-full bg-med-black flex flex-col overflow-y-auto">
            {/* Header */}
            <div className="px-6 pt-12 pb-8">
                <button onClick={() => setStep(OnboardingStep.WELCOME)} className="text-gray-500 text-sm mb-6 flex items-center gap-1">
                    ← Volver
                </button>
                <h2 className="text-2xl font-bold text-white mb-1">
                    {mode === 'signup' ? 'Crear cuenta' : 'Bienvenido de vuelta'}
                </h2>
                <p className="text-gray-500 text-sm">
                    {mode === 'signup'
                        ? 'Tu información médica encriptada y protegida.'
                        : 'Accede a tu perfil neurológico seguro.'}
                </p>
            </div>

            {/* Form */}
            <div className="px-6 flex flex-col gap-4 flex-1">
                {/* Mode Toggle */}
                <div className="flex bg-med-gray rounded-xl p-1">
                    {(['signup', 'signin'] as AuthMode[]).map(m => (
                        <button
                            key={m}
                            onClick={() => { setMode(m); setError(null); }}
                            className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${mode === m
                                    ? 'bg-med-blue text-black shadow'
                                    : 'text-gray-400 hover:text-gray-200'
                                }`}
                        >
                            {m === 'signup' ? 'Registrarme' : 'Iniciar Sesión'}
                        </button>
                    ))}
                </div>

                {/* Email field */}
                <div className="relative">
                    <Mail size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" />
                    <input
                        id="auth-email"
                        type="email"
                        inputMode="email"
                        autoComplete="email"
                        placeholder="correo@ejemplo.com"
                        value={email}
                        onChange={e => setEmail(e.target.value)}
                        className="w-full bg-med-gray border border-gray-700 rounded-xl pl-10 pr-4 py-4 text-white text-sm placeholder-gray-600 focus:outline-none focus:border-med-blue transition-colors"
                    />
                </div>

                {/* Password field */}
                <div className="relative">
                    <Lock size={16} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" />
                    <input
                        id="auth-password"
                        type={showPass ? 'text' : 'password'}
                        autoComplete={mode === 'signup' ? 'new-password' : 'current-password'}
                        placeholder="Contraseña (mín. 8 caracteres)"
                        value={password}
                        onChange={e => setPassword(e.target.value)}
                        onKeyDown={e => e.key === 'Enter' && handleEmailAuth()}
                        className="w-full bg-med-gray border border-gray-700 rounded-xl pl-10 pr-12 py-4 text-white text-sm placeholder-gray-600 focus:outline-none focus:border-med-blue transition-colors"
                    />
                    <button
                        onClick={() => setShowPass(!showPass)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500"
                    >
                        {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                </div>

                {/* Error */}
                {error && (
                    <div className="flex items-start gap-2 bg-red-900/30 border border-red-700/50 rounded-xl px-4 py-3">
                        <AlertCircle size={14} className="text-med-red mt-0.5 flex-shrink-0" />
                        <p className="text-red-400 text-xs leading-relaxed">{error}</p>
                    </div>
                )}

                {/* Submit button */}
                <button
                    id="auth-submit"
                    onClick={handleEmailAuth}
                    disabled={isLoading}
                    className="w-full py-4 bg-med-blue text-black font-bold rounded-2xl shadow-lg shadow-med-blue/30 disabled:opacity-50 active:scale-95 transition-transform"
                >
                    {isLoading ? 'Procesando...' : mode === 'signup' ? 'Crear mi cuenta' : 'Entrar'}
                </button>

                {/* Divider */}
                <div className="flex items-center gap-3 my-1">
                    <div className="flex-1 h-px bg-gray-800" />
                    <span className="text-gray-600 text-xs">o continúa con</span>
                    <div className="flex-1 h-px bg-gray-800" />
                </div>

                {/* Google Button */}
                <button
                    id="google-signin"
                    onClick={handleGoogleSignIn}
                    className="w-full py-4 bg-med-gray border border-gray-700 rounded-xl flex items-center justify-center gap-3 text-white font-medium text-sm active:scale-95 transition-transform hover:border-gray-500"
                >
                    {/* Google colors G */}
                    <svg width="18" height="18" viewBox="0 0 18 18">
                        <path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.875 2.684-6.615z" fill="#4285F4" />
                        <path d="M9 18c2.43 0 4.467-.806 5.956-2.184l-2.908-2.258c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z" fill="#34A853" />
                        <path d="M3.964 10.707c-.18-.54-.282-1.117-.282-1.707s.102-1.167.282-1.707V4.961H.957C.347 6.175 0 7.55 0 9s.348 2.825.957 4.039l3.007-2.332z" fill="#FBBC05" />
                        <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.961L3.964 6.293C4.672 4.165 6.656 3.58 9 3.58z" fill="#EA4335" />
                    </svg>
                    Continuar con Google
                </button>

                {/* Apple Button — required for App Store */}
                <button
                    id="apple-signin"
                    onClick={handleAppleSignIn}
                    className="w-full py-4 bg-white text-black font-semibold text-sm rounded-xl flex items-center justify-center gap-3 active:scale-95 transition-transform"
                >
                    {/* Apple logo */}
                    <svg width="16" height="18" viewBox="0 0 16 18" fill="black">
                        <path d="M13.173 9.618c-.02-2.086 1.703-3.094 1.78-3.143-0.976-1.424-2.49-1.618-3.022-1.635-1.291-.131-2.52.762-3.172.762-.657 0-1.672-.744-2.745-.724-1.41.021-2.714.82-3.438 2.085C.986 9.46 2.022 13.624 3.55 15.851c.742 1.089 1.626 2.305 2.784 2.261 1.12-.044 1.54-.728 2.892-.728 1.345 0 1.725.728 2.905.706 1.208-.021 1.97-1.103 2.709-2.196.855-1.258 1.204-2.479 1.222-2.542-.026-.01-2.343-.897-2.363-3.364-.017-2.08 1.694-3.07 1.77-3.12l-.296-.25z" />
                        <path d="M10.917 2.136C11.508 1.41 11.914.432 11.797 0c-.861.036-1.918.577-2.527 1.302-.551.636-1.037 1.65-.905 2.627.963.074 1.942-.487 2.552-1.793z" />
                    </svg>
                    Continuar con Apple
                </button>

                <p className="text-center text-[10px] text-gray-600 pb-6 leading-relaxed">
                    Tus datos clínicos se cifran en reposo (AES-256) y nunca se comparten con terceros.
                </p>
            </div>
        </div>
    );
};
