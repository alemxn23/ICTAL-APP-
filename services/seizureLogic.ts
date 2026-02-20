import { SeizurePhase, SensorDataPoint } from '../types';
import { TIME_THRESHOLDS } from '../constants';

export const determinePhase = (elapsedTimeMs: number, currentPhase: SeizurePhase): SeizurePhase => {
  // Static phases that rely on user interaction to exit
  if (currentPhase === SeizurePhase.IDLE) return SeizurePhase.IDLE;
  if (currentPhase === SeizurePhase.RECOVERY) return SeizurePhase.RECOVERY;
  if (currentPhase === SeizurePhase.PREDICTION) return SeizurePhase.PREDICTION;

  // PRIORITY 1: Status Epilepticus (Medical Emergency)
  // If duration exceeds 5 minutes, force transition to STATUS regardless of current phase.
  if (elapsedTimeMs > TIME_THRESHOLDS.STATUS_LIMIT_MS) {
    return SeizurePhase.STATUS;
  }
  
  // PRIORITY 2: State Locking
  // If we are already in ICTAL (Active Seizure), we MUST NOT revert to AURA,
  // even if the timer was reset (elapsedTimeMs < 30s).
  if (currentPhase === SeizurePhase.ICTAL) {
    return SeizurePhase.ICTAL;
  }

  // PRIORITY 3: Auto-Transition
  // If still in AURA and time exceeds limit, advance to ICTAL.
  if (elapsedTimeMs > TIME_THRESHOLDS.AURA_LIMIT_MS) {
    return SeizurePhase.ICTAL;
  }

  // Default State
  return SeizurePhase.AURA;
};

// Simulated Edge Computing for Sensor Data
// In a real app, this processes TensorFlow Lite outputs
export const generateSimulatedSensorData = (prevData: SensorDataPoint[]): SensorDataPoint[] => {
  const now = Date.now();
  // Keep only last 50 points
  const newData = [...prevData].slice(-49);
  
  // Create a chaotic wave to simulate clonic activity
  const randomFactor = Math.random() * 2 - 1; 
  const sineWave = Math.sin(now / 100);
  const value = sineWave + randomFactor;

  newData.push({
    timestamp: now,
    value: value,
    type: 'ACCEL'
  });

  return newData;
};