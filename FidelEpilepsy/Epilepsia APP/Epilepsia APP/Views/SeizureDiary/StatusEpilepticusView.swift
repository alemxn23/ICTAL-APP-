import SwiftUI
import MessageUI
import CoreLocation

// MARK: - SMS Compose Helper

struct SMSComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    @Environment(\.dismiss) var dismiss
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: SMSComposeView
        init(_ parent: SMSComposeView) { self.parent = parent }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Status Epilepticus View

struct StatusEpilepticusView: View {
    let crisisStartTime: Date
    
    @StateObject private var contactsManager = EmergencyContactsManager.shared
    @State private var timeElapsed: TimeInterval = 0
    @State private var pulseRed: Bool = false
    @State private var showSMSCompose = false
    @State private var smsBody: String = ""
    @State private var slideOffset: CGFloat = 0
    @Environment(\.dismiss) var dismiss
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let slideWidth: CGFloat = 280
    private let buttonWidth: CGFloat = 60
    
    var timeFormatted: String {
        let t = Int(timeElapsed)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
    
    var body: some View {
        ZStack {
            // Pulsing Red Background
            Color.black.ignoresSafeArea()
            Color.red.opacity(pulseRed ? 0.22 : 0.08).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulseRed)
            
            VStack(spacing: 0) {
                // ─── HEADER ───────────────────────────────────────────
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                        Text("⚠️ ESTATUS EPILÉPTICO")
                            .font(.system(size: 18, weight: .black))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .blinkEffect()
                    
                    Text(timeFormatted)
                        .font(.system(size: 90, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .red, radius: 20)
                }
                .padding(.top, 50)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // ─── SEM PROTOCOL CARD ─────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            Label("ACTIVAR PROTOCOLO SEM", systemImage: "cross.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.Medical.danger)
                            
                            Text("La crisis supera los 5 minutos. Esto es una emergencia médica que requiere atención inmediata.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            VStack(spacing: 12) {
                                EmergencyCallButton(
                                    title: "🚑 LLAMAR AL 911",
                                    number: "tel://911"
                                )
                                EmergencyCallButton(
                                    title: "🔴 CRUZ ROJA (065)",
                                    number: "tel://065"
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.25), Color.black.opacity(0.9)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                        
                        // ─── LOCATION SHARING ──────────────────────
                        Button(action: prepareAndSendLocation) {
                            VStack(spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                    Text("ENVIAR UBICACIÓN A CONTACTOS")
                                        .font(.system(size: 16, weight: .black))
                                }
                                Text("\(contactsManager.contacts.count) contacto(s) de emergencia · \(contactsManager.locationStatus)")
                                    .font(.caption)
                                    .opacity(0.75)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(14)
                        }
                        
                        // ─── MIDAZOLAM TREATMENT CARD ──────────────
                        MidazolamCard()
                        
                        // ─── SAFETY REMINDERS ──────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MIENTRAS LLEGA LA AYUDA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Medical.neutral)
                            
                            SafetyReminderRow(icon: "hand.raised.fill", text: "NO sujetar al paciente ni restringir movimientos")
                            SafetyReminderRow(icon: "mouth", text: "NO meter nada en la boca")
                            SafetyReminderRow(icon: "bed.double.fill", text: "Posición lateral de seguridad")
                            SafetyReminderRow(icon: "lungs.fill", text: "Vigilar que respira tras la crisis")
                        }
                        .padding(16)
                        .background(Color.Medical.card)
                        .cornerRadius(16)
                        
                        Spacer().frame(height: 20)
                        
                        // ─── SLIDE TO FINISH ───────────────────────
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.Medical.neutral.opacity(0.5))
                                .frame(width: slideWidth, height: 60)
                            
                            Text("DESLIZA PARA FINALIZAR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: slideWidth, height: 60, alignment: .center)
                            
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                        .shadow(radius: 5)
                                    Image(systemName: "stop.fill")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .offset(x: slideOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.translation.width > 0 && value.translation.width < (slideWidth - buttonWidth) {
                                                slideOffset = value.translation.width
                                            }
                                        }
                                        .onEnded { value in
                                            if value.translation.width > (slideWidth - buttonWidth - 20) {
                                                finishEvent()
                                            } else {
                                                withAnimation { slideOffset = 0 }
                                            }
                                        }
                                )
                                Spacer()
                            }
                            .padding(.leading, 2)
                        }
                        .frame(width: slideWidth, height: 60)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
        }
        .onAppear {
            pulseRed = true
            timeElapsed = Date().timeIntervalSince(crisisStartTime)
            contactsManager.requestLocationForEmergency()
            SeizureNarrator.shared.speak("Alerta. Estatus epiléptico. Han pasado más de cinco minutos. Llame a emergencias al nueve uno uno ahora mismo.")
        }
        .onReceive(timer) { _ in
            timeElapsed = Date().timeIntervalSince(crisisStartTime)
        }
        .sheet(isPresented: $showSMSCompose) {
            SMSComposeView(
                recipients: contactsManager.getPhoneNumbers(),
                body: smsBody
            )
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Actions
    
    func prepareAndSendLocation() {
        SeizureNarrator.shared.speak("Enviando ubicación a tus contactos de emergencia.")
        smsBody = contactsManager.buildEmergencyMessage(coordinate: contactsManager.currentLocation)
        showSMSCompose = true
    }
    
    func finishEvent() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        SeizureNarrator.shared.stop()
        dismiss()
    }
}

// MARK: - Subcomponents

struct EmergencyCallButton: View {
    let title: String
    let number: String
    
    var body: some View {
        Button(action: {
            guard let url = URL(string: number) else { return }
            UIApplication.shared.open(url)
        }) {
            Text(title)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
    }
}

struct SafetyReminderRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color.Medical.danger)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MidazolamCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "pills.fill")
                    .foregroundColor(Color.Medical.caution)
                Text("TRATAMIENTO DE PRIMERA LÍNEA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Medical.caution)
            }
            
            Text("Midazolam — Benzodiacepina de acción rápida")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                MidazolamRow(
                    brand: "Buccolam®",
                    presentation: "5–10 mg, solución oromucosal (nasal/bucal)",
                    dose: "Adultos: 10 mg. Niños: según peso prescrito",
                    note: "Disponible en farmacias especializadas (México)"
                )
                Divider().background(Color.white.opacity(0.1))
                MidazolamRow(
                    brand: "Dormicum® (off-label intranasal)",
                    presentation: "Ampolleta 15 mg/3 mL IV — vía intranasal",
                    dose: "0.2 mg/kg intranasal con atomizador MAD",
                    note: "Uso solo por personal médico entrenado"
                )
            }
            
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle")
                Text("Solo administrar si hay prescripción médica previa. No es de venta libre.")
                    .font(.caption2)
            }
            .foregroundColor(Color.Medical.neutral)
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "1A1200"), Color.Medical.card],
                startPoint: .top, endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Medical.caution.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MidazolamRow: View {
    let brand: String
    let presentation: String
    let dose: String
    let note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(brand)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.Medical.caution)
            Text(presentation)
                .font(.caption)
                .foregroundColor(Color.Medical.textSecondary)
            Text(dose)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Text(note)
                .font(.caption2)
                .foregroundColor(Color.Medical.neutral)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
