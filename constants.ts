import { PatientProfile } from './types';

// Clinical Constants based on ILAE guidelines
export const TIME_THRESHOLDS = {
  AURA_LIMIT_MS: 30000,      // 30 Seconds
  STATUS_LIMIT_MS: 300000,   // 5 Minutes (300 seconds)
};

// Mock Patient Data (simulating secure enclave storage)
export const MOCK_PATIENT: PatientProfile = {
  resourceType: 'Patient',
  id: 'uuid-1234-5678',
  name: {
    given: ['Alejandro'],
    family: 'Doe',
  },
  demographics: {
    dateOfBirth: '1990-05-15',
    biologicalSex: 'Male',
    weightKg: 75,
    heightCm: 180
  },
  medicalHistory: {
    diagnosis: 'Epilepsia del Lóbulo Temporal',
    diagnosisDate: '2015-06-20',
    epilepsyType: 'Focal',
    isRefractory: false,
    reflexEpilepsy: false, // CHANGE TO TRUE TO TEST SAFETY LOCK
    baselineHeartRate: 72,
    comorbidities: ['Ansiedad'],
    triggers: ['Estrés', 'Privación de Sueño']
  },
  medications: [
    { id: '1', drugName: 'Levetiracetam', brandName: 'Keppra', dosageMg: 1000, frequency: 'BID', isRescue: false },
    { id: '2', drugName: 'Lamotrigina', dosageMg: 200, frequency: 'QD', isRescue: false }
  ],
  contacts: [
    { id: 'c1', name: 'Sarah Doe', phone: '+15550123', relation: 'Pareja' },
    { id: 'c2', name: 'Dr. House', phone: '+15559999', relation: 'Neurólogo' }
  ],
  rescueMedication: {
    drugName: 'Midazolam',
    dosage: '10mg',
    route: 'Intranasal',
    instructions: 'Administrar un spray (5mg) en cada fosa nasal.',
  },
};

export const BYSTANDER_SCRIPT_ES = 
  "Soy epiléptico. No me sujete. Gire mi cuerpo de lado. Ponga algo suave bajo mi cabeza. Cronometre la crisis.";

export const BYSTANDER_SCRIPT_EN = 
  "I have epilepsy. Do not hold me down. Turn me on my side. Place something soft under my head. Time the seizure.";