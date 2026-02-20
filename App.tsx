import React, { useState, useEffect, useRef } from 'react';
import { SeizurePhase, SensorDataPoint, SeizureObservation, EmergencyContact, WatchTelemetry } from './types';
import { TIME_THRESHOLDS, MOCK_PATIENT } from './constants';
import { determinePhase, generateSimulatedSensorData } from './services/seizureLogic';
import { watchBridge } from './services/watchBridge';
import { SeizureStorage } from './services/seizureStorage';
import { EmergencyService } from './services/EmergencyService';

// Components
import { Dashboard } from './components/Dashboard';
import { HistoryScreen } from './components/HistoryScreen';
import { UserProfileScreen } from './components/UserProfileScreen';
import { EmergencyContactsScreen } from './components/EmergencyContactsScreen';
import { Phase0Prediction } from './components/Phase0Prediction';
import { Phase1Aura } from './components/Phase1Aura';
import { Phase2Ictal } from './components/Phase2Ictal';
import { Phase3Status } from './components/Phase3Status';
import { Phase4Recovery } from './components/Phase4Recovery';

// Auth context (only for profile tab integration — no app gate)
import { OnboardingProvider } from './context/OnboardingContext';

const App: React.FC = () => {
  // --- Global State ---
  const [patient, setPatient] = useState(MOCK_PATIENT);
  const [phase, setPhase] = useState<SeizurePhase>(SeizurePhase.IDLE);

  // Navigation State
  const [showHistory, setShowHistory] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const [showContacts, setShowContacts] = useState(false);

  const [startTime, setStartTime] = useState<number | null>(null);
  const [endTime, setEndTime] = useState<number | null>(null);
  const [elapsedTime, setElapsedTime] = useState(0);
  const [finalDuration, setFinalDuration] = useState(0);
  const [sensorData, setSensorData] = useState<SensorDataPoint[]>([]);
  const [watchData, setWatchData] = useState<WatchTelemetry | null>(null);

  // SOS State
  const [sosTriggered, setSosTriggered] = useState(false);
  const [sosStatus, setSosStatus] = useState<string>('');
  const [currentPrediction, setCurrentPrediction] = useState<any>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const requestRef = useRef<number>();

  // --- Watch Bridge Subscription ---
  useEffect(() => {
    const unsubscribe = watchBridge.subscribe((data) => {
      setWatchData(data);
      if (data.fallDetected && phase === SeizurePhase.IDLE) handleWatchFallDetection();
      const isStressed = (data.hrv < 30 || (data.heartRate > 100 && data.activity_type === 'RESTING'));
      if (isStressed && phase === SeizurePhase.IDLE && !isAnalyzing) handlePrediction(data);
    });
    return () => unsubscribe();
  }, [phase]);

  // --- Timer Logic & State Machine ---
  useEffect(() => {
    let intervalId: ReturnType<typeof setInterval>;
    if (phase !== SeizurePhase.IDLE && phase !== SeizurePhase.RECOVERY && phase !== SeizurePhase.PREDICTION) {
      intervalId = setInterval(() => {
        if (startTime) {
          const now = Date.now();
          const elapsed = now - startTime;
          setElapsedTime(elapsed);
          const nextPhase = determinePhase(elapsed, phase);
          if (nextPhase === SeizurePhase.STATUS && phase !== SeizurePhase.STATUS) {
            setPhase(nextPhase);
            watchBridge.triggerHaptic('CRITICAL');
          } else if (nextPhase !== phase) {
            setPhase(nextPhase);
          }
          if (nextPhase === SeizurePhase.STATUS && !sosTriggered) {
            setSosTriggered(true);
            EmergencyService.triggerSOS(patient, (status) => setSosStatus(status));
          }
        }
      }, 1000);
    }
    return () => clearInterval(intervalId);
  }, [phase, startTime, sosTriggered, patient]);

  // --- Sensor Stream ---
  useEffect(() => {
    if (phase === SeizurePhase.ICTAL || phase === SeizurePhase.STATUS) {
      const animate = () => {
        setSensorData(prev => generateSimulatedSensorData(prev));
        requestRef.current = requestAnimationFrame(animate);
      };
      requestRef.current = requestAnimationFrame(animate);
    } else {
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    }
    return () => { if (requestRef.current) cancelAnimationFrame(requestRef.current); };
  }, [phase]);

  // --- Handlers ---
  const handlePrediction = async (data: WatchTelemetry) => {
    setIsAnalyzing(true);
    try {
      const response = await fetch('http://localhost:8000/predict', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ current_bpm: data.heartRate, hrv_ms: data.hrv, activity_type: data.activity_type, sleep_score: data.sleep_score })
      });
      const result = await response.json();
      setCurrentPrediction(result);
      if (result.status_color === 'RED' || result.status_color === 'AMBER') {
        setPhase(SeizurePhase.PREDICTION);
        watchBridge.triggerHaptic('WARNING');
      }
    } catch (error) {
      console.error('Prediction analysis failed:', error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleStartSeizure = () => {
    setPhase(SeizurePhase.AURA);
    setStartTime(Date.now());
    setEndTime(null);
    setElapsedTime(0);
    setSosTriggered(false);
    setSosStatus('');
    if (!patient.medicalHistory.reflexEpilepsy) watchBridge.triggerHaptic('RHYTHM');
  };

  const handleWatchFallDetection = () => {
    const now = Date.now();
    setStartTime(now - 31000);
    setElapsedTime(31000);
    setPhase(SeizurePhase.ICTAL);
    setSosTriggered(false);
    watchBridge.triggerHaptic('CRITICAL');
  };

  const handleCancelSeizure = () => {
    setPhase(SeizurePhase.IDLE);
    setStartTime(null);
    setElapsedTime(0);
    setSensorData([]);
    setSosTriggered(false);
  };

  const handleConfirmSeizure = () => setPhase(SeizurePhase.ICTAL);

  const handleEndSeizure = () => {
    const endTs = Date.now();
    setEndTime(endTs);
    setFinalDuration(elapsedTime);
    setPhase(SeizurePhase.RECOVERY);
    setStartTime(null);
  };

  const handleSubmitReport = async (reportData: { medicationGiven: boolean; breathingNormal: boolean; injuries: boolean }) => {
    const seizureObservation: SeizureObservation = {
      resourceType: 'Observation',
      status: 'final',
      code: { coding: [{ system: 'http://loinc.org', code: '77777-0', display: 'Seizure duration' }] },
      subject: { reference: `Patient/${patient.id}` },
      effectivePeriod: {
        start: new Date(Date.now() - finalDuration).toISOString(),
        end: new Date(endTime || Date.now()).toISOString()
      },
      valueQuantity: { value: finalDuration / 1000, unit: 's', system: 'http://unitsofmeasure.org', code: 's' },
      component: [
        { code: { text: 'Medication Given' }, valueBoolean: reportData.medicationGiven },
        { code: { text: 'Breathing Normal' }, valueBoolean: reportData.breathingNormal },
        { code: { text: 'Injuries Present' }, valueBoolean: reportData.injuries }
      ]
    };
    await SeizureStorage.saveSeizure(seizureObservation);
    setPhase(SeizurePhase.IDLE);
    setElapsedTime(0);
    setFinalDuration(0);
    setSensorData([]);
    setEndTime(null);
    setSosTriggered(false);
  };

  const updateContacts = (newContacts: EmergencyContact[]) => setPatient({ ...patient, contacts: newContacts });

  // --- Render Router ---
  const renderContent = () => {
    switch (phase) {
      case SeizurePhase.IDLE:
        if (showHistory) return <HistoryScreen onBack={() => setShowHistory(false)} />;
        if (showProfile) return <UserProfileScreen onBack={() => setShowProfile(false)} />;
        if (showContacts) return <EmergencyContactsScreen patient={patient} onUpdate={updateContacts} onBack={() => setShowContacts(false)} />;
        return (
          <Dashboard
            onSimulateAura={handleStartSeizure}
            onSimulateFall={() => watchBridge.simulateFall()}
            onOpenHistory={() => setShowHistory(true)}
            onOpenProfile={() => setShowProfile(true)}
          />
        );
      case SeizurePhase.PREDICTION:
        return (
          <Phase0Prediction
            prediction={currentPrediction || { status_color: 'AMBER', risk_score: 50, title: 'Analizando...', message: 'Estamos procesando tus señales biométricas.', action_required: 'RESPIRAR' }}
            onDismiss={handleCancelSeizure}
            onConfirm={handleStartSeizure}
          />
        );
      case SeizurePhase.AURA:
        return <Phase1Aura patient={patient} elapsedTime={elapsedTime} onCancel={handleCancelSeizure} onConfirm={handleConfirmSeizure} />;
      case SeizurePhase.ICTAL:
        return <Phase2Ictal elapsedTime={elapsedTime} mockSensorData={sensorData} onEndSeizure={handleEndSeizure} />;
      case SeizurePhase.STATUS:
        return <Phase3Status patient={patient} elapsedTime={elapsedTime} notificationStatus={sosStatus} onEndSeizure={handleEndSeizure} />;
      case SeizurePhase.RECOVERY:
        return <Phase4Recovery finalDuration={finalDuration} onSubmitReport={handleSubmitReport} />;
      default:
        return (
          <Dashboard
            onSimulateAura={handleStartSeizure}
            onSimulateFall={() => watchBridge.simulateFall()}
            onOpenHistory={() => setShowHistory(true)}
            onOpenProfile={() => setShowProfile(true)}
          />
        );
    }
  };

  return (
    // OnboardingProvider wraps for auth state — does NOT gate the app
    <OnboardingProvider>
      <div className="w-full h-screen bg-black overflow-hidden font-sans select-none">
        <div className="w-full h-full max-w-md mx-auto relative bg-med-black shadow-2xl overflow-hidden">
          {renderContent()}

          {/* Floating SOS Setup Button */}
          {phase === SeizurePhase.IDLE && !showContacts && !showHistory && !showProfile && (
            <div className="absolute top-16 right-4 z-20">
              <button
                onClick={() => setShowContacts(true)}
                className="text-[10px] font-bold text-med-red bg-med-red/10 border border-med-red/30 px-2 py-1 rounded-full animate-pulse"
              >
                SOS SETUP
              </button>
            </div>
          )}
        </div>
      </div>
    </OnboardingProvider>
  );
};

export default App;