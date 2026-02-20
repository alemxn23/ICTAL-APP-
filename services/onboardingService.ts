import { supabase } from './supabase';
import type { PerfilClinico, LegalConsentInsert } from '../types';

/**
 * EpilepsyCare Onboarding Service
 * All writes are protected by RLS — each user can only write to their own rows.
 */
export const onboardingService = {

    /**
     * Fetch the user's client IP via a best-effort public API.
     * In production, capture IP server-side via Supabase Edge Functions.
     */
    async fetchClientIP(): Promise<string> {
        try {
            const res = await fetch('https://api.ipify.org?format=json');
            const data = await res.json();
            return data.ip as string;
        } catch {
            return 'unknown';
        }
    },

    /**
     * Insert legal consent record.
     * LEGAL REQUIREMENT: Must record version, timestamp and IP for compliance.
     */
    async insertLegalConsent(userId: string): Promise<{ error: Error | null }> {
        const ip = await onboardingService.fetchClientIP();

        const payload: LegalConsentInsert = {
            user_id: userId,
            version_tos: '1.0',
            version_privacidad: '1.0',
            accepted_at: new Date().toISOString(),
            ip_address: ip,
        };

        const { error } = await supabase.from('legal_consents').insert(payload);
        return { error: error as Error | null };
    },

    /**
     * Upsert clinical profile data.
     * Uses upsert so each onboarding step can save partial data safely.
     */
    async upsertPerfilClinico(
        userId: string,
        data: Partial<Omit<PerfilClinico, 'user_id' | 'created_at' | 'updated_at'>>
    ): Promise<{ error: Error | null }> {
        const { error } = await supabase
            .from('perfil_clinico')
            .upsert({ user_id: userId, ...data }, { onConflict: 'user_id' });

        return { error: error as Error | null };
    },

    /**
     * Mark onboarding as complete.
     * This flag gates the user into the main Dashboard.
     */
    async markOnboardingComplete(userId: string): Promise<{ error: Error | null }> {
        const { error } = await supabase
            .from('perfil_clinico')
            .update({ onboarding_completado: true, updated_at: new Date().toISOString() })
            .eq('user_id', userId);

        return { error: error as Error | null };
    },

    /**
     * Get the onboarding completion status for the current user.
     * Returns null if no profile row exists yet (first-time user).
     */
    async getOnboardingStatus(userId: string): Promise<boolean | null> {
        const { data, error } = await supabase
            .from('perfil_clinico')
            .select('onboarding_completado')
            .eq('user_id', userId)
            .single();

        if (error || !data) return null;
        return data.onboarding_completado as boolean;
    },
};
