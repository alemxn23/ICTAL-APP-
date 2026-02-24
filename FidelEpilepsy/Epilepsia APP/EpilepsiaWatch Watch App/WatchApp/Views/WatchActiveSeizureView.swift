import SwiftUI
import WatchKit
import Combine

struct WatchActiveSeizureView: View {
    @Environment(\.dismiss) var dismiss
    
    // Global start time
    let crisisStartTime: Date = Date()
    @State private var timeElapsed: TimeInterval = 0
    
    // Phase Trackers
    @State private var phase: CrisisPhase = .aura
    
    // Voice Checkpoints
    @State private var voice15sDone = false
    @State private var voice30sDone = false
    @State private var voice1minDone = false
    @State private var voice2minDone = false
    @State private var voice3minDone = false
    @State private var voice5minDone = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum CrisisPhase {
        case aura       // < 30s
        case motor      // > 30s or manual confirm
        case emergency  // > 5m
    }
    
    var timeFormatted: String {
        let t = Int(timeElapsed)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    var body: some View {
        ZStack {
            // Background overrides
            if phase == .emergency {
                Color.orange.opacity(0.1).ignoresSafeArea()
            }
            
            VStack(spacing: 8) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(phase == .aura ? Theme.Colors.neuroCyan : Theme.Colors.neuroRed)
                        .font(.system(size: 14))
                    Text(phase == .aura ? "FASE 1: AURA" : "CRISIS MOTORA")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(phase == .aura ? Theme.Colors.neuroCyan : Theme.Colors.neuroRed)
                }
                .padding(.top, 4)
                
                // Timer Component
                if phase == .aura {
                    ZStack {
                        // Ring
                        let progress = min(timeElapsed / 30.0, 1.0)
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 8)
                        Circle().trim(from: 0, to: progress)
                            .stroke(Theme.Colors.neuroCyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text(timeFormatted)
                            .font(.system(size: 32, weight: .light, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                } else {
                    Text(timeFormatted)
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundColor(phase == .emergency ? .red : .white)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Actions (Dynamic based on phase)
                if phase == .aura {
                    VStack(spacing: 4) {
                        Button(action: escalateToMotor) {
                            Text("FASE MOTORA")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(Theme.Colors.neuroRed)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: falseAlarm) {
                            Text("FALSA ALARMA")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.Colors.neuroGreen, lineWidth: 1)
                                )
                                .foregroundColor(Theme.Colors.neuroGreen)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                } else {
                    Button(action: finishEvent) {
                        Text("FINALIZAR EVENTO")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Theme.Colors.neuroGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            WatchSeizureNarrator.shared.speak("Crisis detectada. Se inicia el aura. Mantén la calma y mide el tiempo.")
        }
        .onReceive(timer) { _ in
            timeElapsed = Date().timeIntervalSince(crisisStartTime)
            
            // Auto escalate Aura to Phase 2 at 30s
            if phase == .aura && timeElapsed >= 30 {
                escalateToMotor()
            }
            
            // Escalation to emergency at 5 mins
            if phase == .motor && timeElapsed >= 300 {
                phase = .emergency
            }
            
            triggerVoiceCheckpoints()
        }
    }
    
    // MARK: - Logic
    func escalateToMotor() {
        if phase == .aura {
            phase = .motor
            WatchSeizureNarrator.shared.speak("Fase motora confirmada. Protege la cabeza. No lo sujetes.")
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    func falseAlarm() {
        WatchSeizureNarrator.shared.speak("Falsa alarma confirmada. No se registrará ningún evento.")
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            WatchSeizureNarrator.shared.stop()
            dismiss()
        }
    }
    
    func finishEvent() {
        WatchSeizureNarrator.shared.stop()
        WKInterfaceDevice.current().play(.success)
        dismiss()
    }
    
    func triggerVoiceCheckpoints() {
        let t = Int(timeElapsed)
        
        // Aura
        if t == 15 && !voice15sDone {
            voice15sDone = true
            if phase == .aura {
                WatchSeizureNarrator.shared.speak("Han pasado quince segundos. Observa los síntomas cuidadosamente.")
            }
        }
        if t == 28 && !voice30sDone {
            voice30sDone = true
            if phase == .aura {
                WatchSeizureNarrator.shared.speak("Treinta segundos. Si hay convulsiones, confirma la fase motora.")
            }
        }
        
        // Motor Phase
        if t == 60 && !voice1minDone {
            voice1minDone = true
            WatchSeizureNarrator.shared.speak("Un minuto. Pon a la persona de lado. No la sujetes.")
        }
        if t == 120 && !voice2minDone {
            voice2minDone = true
            WatchSeizureNarrator.shared.speak("Dos minutos. Mantén la calma. Continúa midiendo el tiempo.")
        }
        if t == 180 && !voice3minDone {
            voice3minDone = true
            WatchSeizureNarrator.shared.speak("Tres minutos. Si no para en dos minutos más, llama a emergencias.")
            WKInterfaceDevice.current().play(.failure)
        }
        if t == 290 && !voice5minDone {
            voice5minDone = true
            WatchSeizureNarrator.shared.speak("Cinco minutos. Estatus epiléptico. Activa el protocolo de emergencia médica ahora.")
            WKInterfaceDevice.current().play(.failure)
        }
    }
}

#Preview {
    WatchActiveSeizureView()
}
