import { supabase } from './supabase';
import type { User, AuthError } from '@supabase/supabase-js';

export interface AuthResult {
    user: User | null;
    error: AuthError | null;
}

/**
 * EpilepsyCare Auth Service
 * Handles Email/Password, Google OAuth, and Apple OAuth via Supabase Auth.
 */
export const authService = {

    /** Register with email and password */
    async signUpWithEmail(email: string, password: string): Promise<AuthResult> {
        const { data, error } = await supabase.auth.signUp({ email, password });
        return { user: data.user, error };
    },

    /** Sign in with email and password */
    async signInWithEmail(email: string, password: string): Promise<AuthResult> {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        return { user: data.user, error };
    },

    /**
     * Sign in with Google via OAuth.
     * Requires Google provider enabled in Supabase Auth dashboard.
     */
    async signInWithGoogle(): Promise<{ error: AuthError | null }> {
        const { error } = await supabase.auth.signInWithOAuth({
            provider: 'google',
            options: {
                redirectTo: window.location.origin,
            },
        });
        return { error };
    },

    /**
     * Sign in with Apple via OAuth.
     * Requires Apple provider enabled in Supabase Auth dashboard.
     * Mandatory for App Store distribution.
     */
    async signInWithApple(): Promise<{ error: AuthError | null }> {
        const { error } = await supabase.auth.signInWithOAuth({
            provider: 'apple',
            options: {
                redirectTo: window.location.origin,
            },
        });
        return { error };
    },

    /** Get current authenticated session user */
    async getCurrentUser(): Promise<User | null> {
        const { data: { user } } = await supabase.auth.getUser();
        return user;
    },

    /** Sign out current session */
    async signOut(): Promise<void> {
        await supabase.auth.signOut();
    },

    /** Subscribe to auth state changes */
    onAuthStateChange(callback: (user: User | null) => void) {
        const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
            callback(session?.user ?? null);
        });
        return subscription;
    },
};
