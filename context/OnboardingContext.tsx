import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import type { User } from '@supabase/supabase-js';
import { OnboardingStep, OnboardingProfileData } from '../types';
import { authService } from '../services/authService';
import { onboardingService } from '../services/onboardingService';
import { supabase } from '../services/supabase';

// ============================================================
// Context Shape
// ============================================================

interface OnboardingContextValue {
    // Auth
    currentUser: User | null;
    isAuthLoading: boolean;

    // Onboarding step
    currentStep: OnboardingStep;
    isOnboardingDone: boolean;
    isCheckingOnboarding: boolean;

    // Accumulated profile data
    profileData: OnboardingProfileData;

    // Actions
    setStep: (step: OnboardingStep) => void;
    updateProfileData: (partial: Partial<OnboardingProfileData>) => void;
    completeOnboarding: () => Promise<void>;
    handleSignOut: () => Promise<void>;
}

// ============================================================
// Context & Provider
// ============================================================

const OnboardingContext = createContext<OnboardingContextValue | null>(null);

interface OnboardingProviderProps {
    children: ReactNode;
}

export const OnboardingProvider: React.FC<OnboardingProviderProps> = ({ children }) => {
    const [currentUser, setCurrentUser] = useState<User | null>(null);
    const [isAuthLoading, setIsAuthLoading] = useState(true);
    const [currentStep, setCurrentStep] = useState<OnboardingStep>(OnboardingStep.WELCOME);
    const [isOnboardingDone, setIsOnboardingDone] = useState(false);
    const [isCheckingOnboarding, setIsCheckingOnboarding] = useState(false);
    const [profileData, setProfileData] = useState<OnboardingProfileData>({});

    // Subscribe to Supabase auth state changes
    useEffect(() => {
        const subscription = authService.onAuthStateChange(async (user) => {
            setCurrentUser(user);
            setIsAuthLoading(false);

            if (user) {
                // User just authenticated — check if onboarding is already complete
                await checkOnboardingStatus(user.id);
            } else {
                // Logged out — reset to welcome
                setCurrentStep(OnboardingStep.WELCOME);
                setIsOnboardingDone(false);
            }
        });

        return () => subscription.unsubscribe();
    }, []);

    // Check onboarding status against Supabase
    const checkOnboardingStatus = async (userId: string) => {
        setIsCheckingOnboarding(true);
        try {
            const status = await onboardingService.getOnboardingStatus(userId);
            if (status === true) {
                setIsOnboardingDone(true);
            } else {
                // Profile exists but onboarding incomplete, or no profile yet
                setCurrentStep(OnboardingStep.LEGAL);
                setIsOnboardingDone(false);
            }
        } catch {
            setIsOnboardingDone(false);
        } finally {
            setIsCheckingOnboarding(false);
        }
    };

    // Also check on Supabase initial session load (page refresh)
    useEffect(() => {
        const initSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            if (session?.user) {
                setCurrentUser(session.user);
                await checkOnboardingStatus(session.user.id);
            }
            setIsAuthLoading(false);
        };
        initSession();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const setStep = (step: OnboardingStep) => setCurrentStep(step);

    const updateProfileData = (partial: Partial<OnboardingProfileData>) => {
        setProfileData(prev => ({ ...prev, ...partial }));
    };

    const completeOnboarding = async () => {
        if (!currentUser) return;

        // Final upsert of all accumulated profile data
        await onboardingService.upsertPerfilClinico(currentUser.id, {
            ...profileData,
            onboarding_completado: true,
        });

        setIsOnboardingDone(true);
    };

    const handleSignOut = async () => {
        await authService.signOut();
        setCurrentUser(null);
        setIsOnboardingDone(false);
        setCurrentStep(OnboardingStep.WELCOME);
        setProfileData({});
    };

    const value: OnboardingContextValue = {
        currentUser,
        isAuthLoading,
        currentStep,
        isOnboardingDone,
        isCheckingOnboarding,
        profileData,
        setStep,
        updateProfileData,
        completeOnboarding,
        handleSignOut,
    };

    return (
        <OnboardingContext.Provider value={value}>
            {children}
        </OnboardingContext.Provider>
    );
};

// ============================================================
// Hook
// ============================================================

export const useOnboarding = (): OnboardingContextValue => {
    const ctx = useContext(OnboardingContext);
    if (!ctx) {
        throw new Error('useOnboarding must be used inside <OnboardingProvider>');
    }
    return ctx;
};
