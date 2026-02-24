import SwiftUI
import Combine

struct SeizurePhase1View: View {
    @Environment(\.dismiss) var dismiss

    // Global start time — passed to Phase 2 for cumulative timing
    let crisisStartTime: Date
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var navigateToPhase2 = false
    @State private var auraProgress: Double = 0.0   // 0.0 → 1.0 over 30s
    @State private var voiceTriggered15s = false
    @State private var voiceTriggered30s = false
    
    private let auraThreshold: TimeInterval = 30
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(crisisStartTime: Date = Date()) {
        self.crisisStartTime = crisisStartTime
    }
    
    var timeString: String {
        let t = Int(elapsedTime)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    var ringColor: Color {
        if elapsedTime < 15 { return Color.Medical.safe }
        if elapsedTime < 25 { return Color.Medical.caution }
        return Color.Medical.danger
    }
    
    var body: some View {
        if navigateToPhase2 {
            SeizurePhase2View(crisisStartTime: crisisStartTime)
        } else {
            content
        }
    }
    
    var content: some View {
        ZStack {
            Color.Medical.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                // ─── HEADER ────────────────────────────────────────
                VStack(spacing: 6) {
                    Text("CRISIS DETECTADA")
                        .font(Font.Medical.dataLabel)
                        .foregroundColor(Color.Medical.caution)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Color.Medical.caution.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("Fase 1: Aura")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // ─── COUNTDOWN RING ────────────────────────────────
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 14)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0, to: auraProgress)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: auraProgress)
                    
                    // Center: Timer
                    VStack(spacing: 2) {
                        Text(timeString)
                            .font(.system(size: 52, weight: .light, design: .monospaced))
                            .foregroundColor(.white)
                        Text("AURA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.Medical.neutral)
                            .tracking(2)
                    }
                }
                .frame(width: 180, height: 180)
                
                // ─── STATUS BOX ────────────────────────────────────
                HStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.headline)
                        .foregroundColor(Color.Medical.safe)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monitorización Activa")
                            .font(Font.Medical.headline)
                            .foregroundColor(.white)
                        Text("Los biométricos se están registrando localmente.")
                            .font(Font.Medical.subheadline)
                            .foregroundColor(Color.Medical.textSecondary)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Medical.card)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // ─── ACTIONS ───────────────────────────────────────
                VStack(spacing: 14) {
                    // Confirm Motor Phase
                    Button(action: confirmMotorPhase) {
                        Label("CONFIRMAR FASE MOTORA", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Medical.caution)
                            .cornerRadius(14)
                    }
                    
                    // False Alarm
                    Button(action: falseAlarm) {
                        Text("FALSA ALARMA — ESTOY BIEN")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.Medical.safe)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Medical.card)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.Medical.safe.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Initial voice
            SeizureNarrator.shared.speak("Crisis detectada. Se inicia el aura. Mantén la calma y mide el tiempo.")
        }
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(crisisStartTime)
            auraProgress = min(elapsedTime / auraThreshold, 1.0)
            triggerVoiceCheckpoints()
            
            // Auto-advance at 30s
            if elapsedTime >= auraThreshold && !navigateToPhase2 {
                confirmMotorPhase()
            }
        }
    }
    
    // MARK: - Logic
    
    func confirmMotorPhase() {
        SeizureNarrator.shared.speak("Fase motora confirmada. Protege la cabeza. No lo sujetes.")
        withAnimation { navigateToPhase2 = true }
    }
    
    func falseAlarm() {
        SeizureNarrator.shared.speak("Falsa alarma confirmada. No se registrará ningún evento.")
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            SeizureNarrator.shared.stop()
            dismiss()
        }
    }
    
    func triggerVoiceCheckpoints() {
        if Int(elapsedTime) == 15 && !voiceTriggered15s {
            voiceTriggered15s = true
            SeizureNarrator.shared.speak("Han pasado quince segundos. Observa los síntomas cuidadosamente.")
        }
        if Int(elapsedTime) >= 28 && !voiceTriggered30s {
            voiceTriggered30s = true
            SeizureNarrator.shared.speak("Treinta segundos. Si hay convulsiones, confirma la fase motora.")
        }
    }
}
