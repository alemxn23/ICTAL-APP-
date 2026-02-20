// Medical Software Architect Note:
// Using HL7 FHIR R4 standard structures for interoperability.
// Onboarding types follow Supabase schema conventions.

export enum SeizurePhase {
  IDLE = 'IDLE',
  PREDICTION = 'PREDICTION', // New Phase 0: AI Forecasting
  AURA = 'AURA',             // 0 - 30s
  ICTAL = 'ICTAL',           // 30s - 5min
  STATUS = 'STATUS',         // > 5min (Emergency)
  RECOVERY = 'RECOVERY'
}

// Detailed Medication Interface for Pharmacology RWE
export interface Medication {
  id: string;
  drugName: string; // Generic name (e.g., Levetiracetam)
  brandName?: string; // Brand loyalty (e.g., Keppra)
  dosageMg: number;
  frequency: string; // e.g., "BID" (Twice a day)
  isRescue: boolean;
}

export interface EmergencyContact {
  id: string;
  name: string;
  phone: string; // E.164 format prefered
  relation: string;
}

// FHIR R4 Patient Resource Subset
export interface PatientProfile {
  resourceType: 'Patient';
  id: string;
  name: {
    given: string[];
    family: string;
  };
  demographics: {
    dateOfBirth: string;
    biologicalSex: 'Male' | 'Female' | 'Intersex' | 'Other';
    weightKg: number;
    heightCm: number;
  };
  medicalHistory: {
    diagnosis: string;
    diagnosisDate: string;
    epilepsyType: 'Focal' | 'Generalized' | 'Unknown' | 'Combined';
    isRefractory: boolean; // Drug-resistant epilepsy
    reflexEpilepsy: boolean; // CRITICAL SAFETY PARAMETER
    baselineHeartRate: number;
    comorbidities: string[];
    triggers: string[]; // e.g., ["Stress", "Photosensitivity"]
  };
  medications: Medication[];
  contacts: EmergencyContact[]; // Safety Circle
  rescueMedication: {
    drugName: string;
    dosage: string;
    route: 'Buccal' | 'Intranasal' | 'Rectal' | 'Intramuscular';
    instructions: string;
  };
}

// FHIR R4 MedicationAdministration Resource Subset
export interface MedicationAdministration {
  resourceType: 'MedicationAdministration';
  status: 'completed' | 'not-done' | 'in-progress';
  medicationCodeableConcept: {
    text: string;
  };
  subject: {
    reference: string;
  };
  effectiveDateTime: string;
  dosage: {
    text: string;
    route: {
      text: string;
    };
    dose: {
      value: number;
      unit: string;
    };
  };
}

// FHIR R4 Observation Resource (Seizure Event)
export interface SeizureObservation {
  resourceType: 'Observation';
  status: 'final';
  code: {
    coding: Array<{
      system: string;
      code: string;
      display: string;
    }>;
  };
  subject: {
    reference: string;
  };
  effectivePeriod: {
    start: string;
    end: string;
  };
  valueQuantity: {
    value: number;
    unit: 's';
    system: 'http://unitsofmeasure.org';
    code: 's';
  };
  // Extensions for clinical checklist
  component?: Array<{
    code: { text: string };
    valueBoolean: boolean;
  }>;
}

export interface SensorDataPoint {
  timestamp: number;
  value: number; // Normalized acceleration or HRV
  type: 'ACCEL' | 'HRV';
}

// Watch Bridge Types
export interface WatchTelemetry {
  heartRate: number;
  hrv: number;
  activity_type: 'RESTING' | 'WALKING' | 'EXERCISING' | 'SLEEPING';
  sleep_score: number;
  fallDetected: boolean;
  connectionState: 'CONNECTED' | 'DISCONNECTED';
}

export interface PredictionResult {
  status_color: 'GREEN' | 'AMBER' | 'RED' | 'CYAN';
  risk_score: number;
  title: string;
  message: string;
  action_required: string;
}

// ============================================================
// ONBOARDING TYPES
// ============================================================

/** Steps in the onboarding wizard flow */
export enum OnboardingStep {
  WELCOME = 'WELCOME',
  AUTH = 'AUTH',
  LEGAL = 'LEGAL',
  PROFILE_NAME = 'PROFILE_NAME',
  PROFILE_SEX = 'PROFILE_SEX',
  PROFILE_WEIGHT = 'PROFILE_WEIGHT',
  PERMISSIONS = 'PERMISSIONS',
  COMPLETE = 'COMPLETE',
}

/** Maps to public.perfil_clinico Supabase table */
export interface PerfilClinico {
  id?: string;
  user_id: string;
  nombre?: string | null;
  apellido?: string | null;
  fecha_nacimiento?: string | null;  // ISO date string 'YYYY-MM-DD'
  sexo_biologico?: 'Masculino' | 'Femenino' | 'Intersex' | 'Otro' | null;
  peso_kg?: number | null;
  onboarding_completado: boolean;
  permiso_notificaciones?: boolean;
  permiso_healthkit?: boolean;
  created_at?: string;
  updated_at?: string;
}

/** Maps to public.legal_consents INSERT payload */
export interface LegalConsentInsert {
  user_id: string;
  version_tos: string;
  version_privacidad: string;
  accepted_at: string;   // ISO 8601 timestamp
  ip_address: string;
}

/** Accumulated profile data across onboarding steps */
export interface OnboardingProfileData {
  nombre?: string;
  apellido?: string;
  fecha_nacimiento?: string;
  sexo_biologico?: 'Masculino' | 'Femenino' | 'Intersex' | 'Otro';
  peso_kg?: number;
}