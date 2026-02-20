import { SeizureObservation } from '../types';

const STORAGE_KEY = 'EPILEPSY_CARE_HISTORY_V1';

/**
 * SeizureStorage Service
 * Responsibilities:
 * 1. Persist Seizure Events locally (Offline First).
 * 2. Sync to Apple HealthKit (simulated).
 * 3. Provide history for the UI.
 */
export const SeizureStorage = {
  
  /**
   * Saves a seizure event to local storage and attempts HealthKit sync.
   */
  saveSeizure: async (observation: SeizureObservation): Promise<void> => {
    try {
      // 1. Get existing history
      const historyJSON = localStorage.getItem(STORAGE_KEY);
      const history: SeizureObservation[] = historyJSON ? JSON.parse(historyJSON) : [];

      // 2. Add new observation to the TOP of the list
      const updatedHistory = [observation, ...history];

      // 3. Persist
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updatedHistory));
      
      console.log(`[STORAGE] Seizure saved. Total records: ${updatedHistory.length}`);

      // 4. Sync to HealthKit (Simulation)
      await SeizureStorage.syncToHealthKit(observation);

    } catch (error) {
      console.error('[STORAGE] Failed to save seizure:', error);
    }
  },

  /**
   * Retrieves the full clinical history.
   */
  getHistory: async (): Promise<SeizureObservation[]> => {
    try {
      const historyJSON = localStorage.getItem(STORAGE_KEY);
      return historyJSON ? JSON.parse(historyJSON) : [];
    } catch (error) {
      console.error('[STORAGE] Failed to load history:', error);
      return [];
    }
  },

  /**
   * Simulates writing to Apple HealthKit.
   * In React Native, this would use `rn-apple-healthkit`.
   */
  syncToHealthKit: async (observation: SeizureObservation): Promise<void> => {
    const duration = observation.valueQuantity.value;
    const startTime = observation.effectivePeriod.start;
    const endTime = observation.effectivePeriod.end;

    console.log(`[HEALTHKIT BRIDGE] Writing Sample...`);
    console.log(`   Type: HKCategoryTypeIdentifierSeizure`);
    console.log(`   Start: ${startTime}`);
    console.log(`   End: ${endTime}`);
    console.log(`   Metadata: { duration: ${duration}s }`);
    
    // Simulate async native bridge call
    return new Promise(resolve => setTimeout(resolve, 500));
  }
};