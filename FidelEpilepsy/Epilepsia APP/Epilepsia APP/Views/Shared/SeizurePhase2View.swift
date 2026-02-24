import SwiftUI
import Combine

struct SeizurePhase2View: View {
    @Environment(\.dismiss) var dismiss
    
    let crisisStartTime: Date
    
    @State private var timeElapsed: TimeInterval = 0
    @State private var showStatusEpilepticus = false
    
    // Voice checkpoints
    @State private var voice1minDone = false
    @State private var voice2minDone = false
    @State private var voice3minDone = false
    @State private var voice5minDone = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let semThreshold: TimeInterval = 300 // 5 minutes
    
    init(crisisStartTime: Date = Date()) {
        self.crisisStartTime = crisisStartTime
    }
    
    var timeFormatted: String {
        let t = Int(timeElapsed)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    var isApproachingCritical: Bool { timeElapsed >= 180 } // 3 min
    
    var timerColor: Color {
        if timeElapsed >= 300 { return .red }
        if timeElapsed >= 180 { return .orange }
        if timeElapsed >= 60  { return .orange }
        return .white
    }
    
    // Safety Instructions
    let instructions: [(String, String)] = [
        ("hand.raised.fill",    "NO sujetar ni restringir movimientos"),
        ("pills",               "NO dar medicamentos por la boca"),
        ("bed.double.fill",     "Proteger la cabeza del suelo"),
        ("eye.fill",            "Vigilar la respiración"),
        ("clock.fill",          "Medir el tiempo exacto de la crisis"),
    ]
    
    var body: some View {
        if showStatusEpilepticus {
            StatusEpilepticusView(crisisStartTime: crisisStartTime)
        } else {
            content
        }
    }
    
    var content: some View {
        ZStack {
            Color.Medical.background.ignoresSafeArea()
            
            // Subtle orange tint after 3 min
            if isApproachingCritical {
                Color.orange.opacity(0.07).ignoresSafeArea()
                    .animation(.easeIn(duration: 1.5), value: isApproachingCritical)
            }
            
            VStack(spacing: 0) {
                
                // ─── HEADER ──────────────────────────────────────
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.headline)
                        Text("CRISIS GENERALIZADA")
                            .font(.system(size: 17, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.Medical.danger)
                    .cornerRadius(8)
                    
                    // Cumulative timer (from absolute start of crisis)
                    Text(timeFormatted)
                        .font(.system(size: 80, weight: .black, design: .monospaced))
                        .foregroundColor(timerColor)
                        .shadow(color: timerColor.opacity(0.5), radius: 12)
                        .animation(.easeInOut(duration: 0.5), value: timerColor)
                    
                    // Warning banner at 3 min
                    if isApproachingCritical {
                        Text("⚠️ Prepárate para llamar a emergencias")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                            .blinkEffect()
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // ─── VITALS CARD ─────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "applewatch")
                                    .foregroundColor(Color.Medical.neutral)
                                Text("BIOMÉTRICOS EN VIVO")
                                    .font(Font.Medical.dataLabel)
                                    .foregroundColor(Color.Medical.neutral)
                            }
                            TelemetryWaveView()
                                .frame(height: 90)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .padding(20)
                        .background(Color.Medical.card)
                        .cornerRadius(16)
                        
                        // ─── SAFETY CHECKLIST ─────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PROTOCOLO DE ASISTENCIA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Medical.neutral)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(instructions, id: \.1) { icon, text in
                                HStack(spacing: 14) {
                                    Image(systemName: icon)
                                        .font(.body)
                                        .foregroundColor(Color.Medical.danger)
                                        .frame(width: 26)
                                    Text(text)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.Medical.card)
                                .cornerRadius(12)
                            }
                        }
                        
                        Spacer().frame(height: 10)
                        
                        // ─── FINISH BUTTON ─────────────────────────
                        Button(action: finishEvent) {
                            Text("FINALIZAR EVENTO")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.Medical.safe)
                                .cornerRadius(14)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            SeizureNarrator.shared.speak("Fase motora activa. Mantén la calma. Protege la cabeza. Mide el tiempo.")
        }
        .onReceive(timer) { _ in
            timeElapsed = Date().timeIntervalSince(crisisStartTime)
            triggerVoiceCheckpoints()
            
            // Auto-escalate to Status Epilepticus at 5 min
            if timeElapsed >= semThreshold && !showStatusEpilepticus {
                showStatusEpilepticus = true
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Actions
    
    func finishEvent() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        SeizureNarrator.shared.stop()
        dismiss()
    }
    
    func triggerVoiceCheckpoints() {
        let mins = Int(timeElapsed)
        
        if mins >= 60 && !voice1minDone {
            voice1minDone = true
            SeizureNarrator.shared.speak("Un minuto. Pon a la persona de lado. No la sujetes.")
        }
        if mins >= 120 && !voice2minDone {
            voice2minDone = true
            SeizureNarrator.shared.speak("Dos minutos. Mantén la calma. Continúa midiendo el tiempo.")
        }
        if mins >= 180 && !voice3minDone {
            voice3minDone = true
            SeizureNarrator.shared.speak("Tres minutos. Si no para en dos minutos más, llama a emergencias al noventa y uno uno.")
        }
        if mins >= 290 && !voice5minDone {
            voice5minDone = true
            SeizureNarrator.shared.speak("Cinco minutos. Estatus epiléptico. Activa el protocolo de emergencia médica ahora.")
        }
    }
}
