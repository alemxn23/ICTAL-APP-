import { createClient } from '@supabase/supabase-js';

/**
 * Supabase Client Singleton
 * 
 * Add the following to your .env.local:
 *   VITE_SUPABASE_URL=https://<project-ref>.supabase.co
 *   VITE_SUPABASE_ANON_KEY=<your-anon-key>
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const env = (import.meta as any).env ?? {};
const supabaseUrl = (env.VITE_SUPABASE_URL ?? '') as string;
const supabaseAnonKey = (env.VITE_SUPABASE_ANON_KEY ?? '') as string;

if (!supabaseUrl || !supabaseAnonKey) {
    console.warn(
        '[EpilepsyCare] Missing Supabase env vars. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to .env.local'
    );
}

export const supabase = createClient(
    supabaseUrl || 'https://placeholder.supabase.co',
    supabaseAnonKey || 'placeholder-key',
    {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
            detectSessionInUrl: true,
        },
    }
);
