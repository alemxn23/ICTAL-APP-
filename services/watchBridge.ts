import { WatchTelemetry } from '../types';

/**
 * ARCHITECTURAL NOTE:
 * In the production React Native app, this service wraps the `NativeModules` 
 * to communicate with the `WatchSessionManager.swift`.
 * 
 * For this Web/PWA environment, we simulate the WCSession behavior.
 */

type WatchCallback = (data: WatchTelemetry) => void;

class WatchBridgeService {
  private listeners: WatchCallback[] = [];
  private intervalId: number | null = null;
  private currentTelemetry: WatchTelemetry = {
    heartRate: 72,
    hrv: 45,
    activity_type: 'RESTING',
    sleep_score: 85,
    fallDetected: false,
    connectionState: 'CONNECTED'
  };


  constructor() {
    this.startSimulation();
  }

  public subscribe(callback: WatchCallback): () => void {
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback);
    };
  }

  // Simulates incoming data from Apple Watch via WCSession
  private startSimulation() {
    this.intervalId = window.setInterval(() => {
      // Simulate slight HR fluctuation
      const fluctuation = Math.floor(Math.random() * 5) - 2;
      this.currentTelemetry = {
        ...this.currentTelemetry,
        heartRate: Math.max(50, Math.min(180, this.currentTelemetry.heartRate + fluctuation)),
        hrv: Math.max(20, Math.min(100, this.currentTelemetry.hrv + (Math.random() * 2 - 1))),
      };
      this.notifyListeners();
    }, 2000); // Update every 2 seconds
  }

  // Trigger a simulated fall event (Simulating CMMotionManager > 3G Impact)
  public simulateFall() {
    this.currentTelemetry.fallDetected = true;
    this.notifyListeners();

    // Reset fall flag after 1s (event is transient)
    setTimeout(() => {
      this.currentTelemetry.fallDetected = false;
      this.notifyListeners();
    }, 1000);
  }

  // Trigger Haptics on Watch (Simulated)
  public triggerHaptic(type: 'WARNING' | 'CRITICAL' | 'RHYTHM') {
    console.log(`[WATCH BRIDGE] Triggering Haptic: ${type}`);
    // In React Native: NativeModules.WatchModule.triggerHaptic(type);
  }

  private notifyListeners() {
    this.listeners.forEach(listener => listener(this.currentTelemetry));
  }
}

export const watchBridge = new WatchBridgeService();