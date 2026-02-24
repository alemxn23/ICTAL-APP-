import SwiftUI

struct RiskAnalysisCard: View {
    // 1. Estados Iniciales (Persistentes)
    // El usuario pide inicializar en TRUE (asumimos cumplimiento)
    @AppStorage("dailyMedicationTaken") private var medicationTaken: Bool = true
    @AppStorage("dailySleepQuality") private var sleepQuality: Bool = true
    @AppStorage("lastCheckInDate") private var lastCheckInDate: Double = Date().timeIntervalSince1970
    
    @ObservedObject private var healthKit = HealthKitManager.shared
    
    // 2. Fórmula de Cálculo Reactivo
    var dailyRisk: Int {
        healthKit.riesgoCalculado
    }
    
    // Color Dinámico del Gauge (<30 Verde, 31-69 Naranja, >70 Rojo)
    var riskColor: Color {
        if dailyRisk >= 70 { return Color.Medical.danger }
        if dailyRisk > 30 { return Color.Medical.caution }
        return Color.Medical.safe
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            // HEADER INTEGRADO
            HStack {
                Text("ANÁLISIS DE RIESGO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Medical.neutral)
                    .tracking(1.0)
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(Color.Medical.neutral)
            }
            .padding(.horizontal, 4)
            
            // HÉROE: GAUGE + TOGGLES
            // Layout: Gauge a la izquierda, Toggles a la derecha (Side-by-side)
            HStack(alignment: .center, spacing: 20) {
                
                // 1. MEDIDOR DE RIESGO (HERO)
                ZStack {
                    // Fondo del anillo (Sutil)
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 15)
                        .frame(width: 130, height: 130)
                    
                    // Anillo de Progreso
                    Circle()
                        .trim(from: 0.0, to: CGFloat(Double(dailyRisk) / 100.0))
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [riskColor.opacity(0.8), riskColor]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(-90 + 360 * (Double(dailyRisk) / 100.0))
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 130, height: 130)
                        .shadow(color: riskColor.opacity(0.5), radius: 10, x: 0, y: 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: dailyRisk)
                    
                    // Texto Central
                    VStack(spacing: 0) {
                        Text("\(dailyRisk)%")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: riskColor.opacity(0.3), radius: 10)
                        
                        Text("PROBABILIDAD")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(Color.Medical.neutral)
                            .tracking(1.0)
                            .offset(y: 4)
                    }
                }
                
                // 2. CHECK-INS DIARIOS (TOGGLES LIMPIOS)
                VStack(spacing: 16) {
                    
                    // Toggle Medicación
                    HStack {
                        ZStack {
                            Circle()
                                .fill(medicationTaken ? Color.Medical.safe.opacity(0.15) : Color.white.opacity(0.05))
                                .frame(width: 32, height: 32)
                            Image(systemName: "pills.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(medicationTaken ? Color.Medical.safe : Color.Medical.neutral)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Medicación")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text(medicationTaken ? "Al día" : "Olvidada")
                                .font(.caption2)
                                .foregroundColor(medicationTaken ? Color.Medical.safe : Color.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $medicationTaken)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color.Medical.safe))
                            .scaleEffect(0.7)
                            .onChange(of: medicationTaken) { _ in
                                Task { await healthKit.fetchUltimaLectura() }
                            }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    
                    // Toggle Sueño
                    HStack {
                        ZStack {
                            Circle()
                                .fill(sleepQuality ? Color.Medical.accent.opacity(0.15) : Color.white.opacity(0.05))
                                .frame(width: 32, height: 32)
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(sleepQuality ? Color.Medical.accent : Color.Medical.neutral)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sueño")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text(sleepQuality ? "Bueno" : "Malo")
                                .font(.caption2)
                                .foregroundColor(sleepQuality ? Color.Medical.accent : Color.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $sleepQuality)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color.Medical.accent))
                            .scaleEffect(0.7)
                            .onChange(of: sleepQuality) { _ in
                                Task { await healthKit.fetchUltimaLectura() }
                            }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        // Fondo Integrado: Degradado muy sutil de arriba a abajo, casi negro
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.black.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            // Reset lógica para nuevo día
            let lastDate = Date(timeIntervalSince1970: lastCheckInDate)
            if !Calendar.current.isDateInToday(lastDate) {
                // Mantener defaults diarios (TRUE/TRUE)
                medicationTaken = true 
                sleepQuality = true
                lastCheckInDate = Date().timeIntervalSince1970
            }
        }
    }
}

struct QuickLogButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                Text("REGISTRAR CRISIS AHORA")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            // Mantener degradado naranja solicitado
            .background(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
}
