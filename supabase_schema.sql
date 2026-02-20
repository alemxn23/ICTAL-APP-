-- ============================================================
--  EpilepsyCare AI — Supabase Database Schema
--  Version: 1.0 | 2026-02-19
--  Author: Senior Database Architect
--
--  INSTRUCTIONS:
--  Paste this entire file into the Supabase SQL Editor
--  and click "Run". Run ONCE on a fresh project.
-- ============================================================

-- ============================================================
-- TABLE 1: perfil_clinico
-- Stores the patient's baseline clinical profile.
-- Linked 1:1 to auth.users via user_id (UUID).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.perfil_clinico (
  id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Personal Data
  nombre                TEXT,
  apellido              TEXT,
  fecha_nacimiento      DATE,

  -- Clinical Data
  sexo_biologico        TEXT CHECK (sexo_biologico IN ('Masculino', 'Femenino', 'Intersex', 'Otro')),
  peso_kg               NUMERIC(5, 2) CHECK (peso_kg > 0 AND peso_kg < 500),

  -- Onboarding Gate
  onboarding_completado BOOLEAN NOT NULL DEFAULT FALSE,

  -- Permissions Flags
  permiso_notificaciones  BOOLEAN DEFAULT FALSE,
  permiso_healthkit       BOOLEAN DEFAULT FALSE,

  -- Audit
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Enforce one profile per user
  CONSTRAINT perfil_clinico_user_id_unique UNIQUE (user_id)
);

-- Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_perfil_clinico_updated_at ON public.perfil_clinico;
CREATE TRIGGER set_perfil_clinico_updated_at
  BEFORE UPDATE ON public.perfil_clinico
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- TABLE 2: legal_consents
-- Immutable audit log of legal consent acceptance.
-- Each acceptance creates a NEW row (append-only).
-- Users cannot DELETE rows — protection against retraction.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.legal_consents (
  id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Legal Versioning
  version_tos          TEXT NOT NULL,          -- e.g. '1.0'
  version_privacidad   TEXT NOT NULL,          -- e.g. '1.0'

  -- Compliance Data
  accepted_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ip_address           TEXT,                   -- Best-effort; capture server-side in prod

  -- Index for quick lookups
  CONSTRAINT legal_consents_user_version_unique UNIQUE (user_id, version_tos, version_privacidad)
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) — MEDICAL SECURITY DIRECTIVE
-- Zero cross-user data exposure.
-- A user can ONLY access rows where auth.uid() = user_id.
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.perfil_clinico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_consents ENABLE ROW LEVEL SECURITY;

-- -------------------------------------------------------
-- RLS Policies: perfil_clinico
-- -------------------------------------------------------

-- A user can only SELECT their own profile
CREATE POLICY "perfil_clinico: select own"
  ON public.perfil_clinico
  FOR SELECT
  USING (auth.uid() = user_id);

-- A user can INSERT their own profile (first-time onboarding)
CREATE POLICY "perfil_clinico: insert own"
  ON public.perfil_clinico
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- A user can UPDATE their own profile
CREATE POLICY "perfil_clinico: update own"
  ON public.perfil_clinico
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- A user can DELETE their own profile (account deletion flow)
CREATE POLICY "perfil_clinico: delete own"
  ON public.perfil_clinico
  FOR DELETE
  USING (auth.uid() = user_id);

-- -------------------------------------------------------
-- RLS Policies: legal_consents
-- -------------------------------------------------------

-- A user can view their own consent records
CREATE POLICY "legal_consents: select own"
  ON public.legal_consents
  FOR SELECT
  USING (auth.uid() = user_id);

-- A user can INSERT their own consent (accept T&C)
CREATE POLICY "legal_consents: insert own"
  ON public.legal_consents
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- NO UPDATE allowed — consent records are immutable
-- NO DELETE allowed — consent records must be retained for legal compliance

-- ============================================================
-- INDEXES for performance
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_perfil_clinico_user_id
  ON public.perfil_clinico(user_id);

CREATE INDEX IF NOT EXISTS idx_legal_consents_user_id
  ON public.legal_consents(user_id);

CREATE INDEX IF NOT EXISTS idx_legal_consents_accepted_at
  ON public.legal_consents(accepted_at DESC);

-- ============================================================
-- VERIFICATION QUERIES (run these after setup to confirm RLS)
-- ============================================================
--
-- 1. As anonymous (expected: 0 rows, RLS blocks access):
--    SELECT * FROM public.perfil_clinico;
--
-- 2. As authenticated user (expected: only their row):
--    SELECT * FROM public.perfil_clinico;
--
-- 3. Confirm RLS is enabled:
--    SELECT tablename, rowsecurity
--    FROM pg_tables
--    WHERE schemaname = 'public'
--    AND tablename IN ('perfil_clinico', 'legal_consents');
-- ============================================================
