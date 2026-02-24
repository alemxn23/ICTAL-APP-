import SwiftUI

struct DashboardView: View {
    @StateObject private var gestorSesion = GestorSesionTelefono.shared
    @ObservedObject private var healthKit = HealthKitManager.shared
    @State private var mostrarReporteAura = false
    
    init() {}

    // Virtual Data for Demo/Real Logic
    var instabilityPercentage: Int {
        healthKit.riesgoCalculado
    }
    
    @State private var showRiskDetail = false
    @State private var showQuickLog = false
    @State private var selectedMetric: MetricType?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.Medical.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. GREETING & HEADER (Compressed)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Date(), style: .date)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.Medical.neutral)
                            .textCase(.uppercase)
                        Text("Hola, Fidel")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 2. RISK ANALYSIS (New Centerpiece)
                    Button(action: { showRiskDetail = true }) {
                        RiskAnalysisCard()
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevent default button press effect on complex views if needed
                    .padding(.horizontal, 20)
                        
                    // 4. VITALS SECTION
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RESUMEN DE SALUD")
                            .font(Font.Medical.dataLabel)
                            .foregroundColor(Color.Medical.neutral)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            Button(action: { selectedMetric = .heartRate }) {
                                let labelValue: String = {
                                    if let hr = healthKit.frecuenciaCardiaca { return "\(Int(hr)) LPM" }
                                    if let hr = gestorSesion.ultimosDatosRecibidos?.frecuenciaCardiaca { return "\(Int(hr)) LPM" }
                                    return "-- LPM"
                                }()
                                MetricCard(
                                    title: "CORAZÓN",
                                    value: labelValue,
                                    icon: "heart.fill",
                                    color: Color.Medical.danger,
                                    trend: "Normal"
                                )
                            }
                            
                            Button(action: { selectedMetric = .status }) {
                                MetricCard(
                                    title: "ESTADO",
                                    value: healthKit.estadoActividad,
                                    icon: "figure.walk",
                                    color: Color.Medical.safe,
                                    trend: "Estable"
                                )
                            }
                            
                            Button(action: { selectedMetric = .hrv }) {
                                let labelValue: String = {
                                    if let hrv = healthKit.hrv { return "\(Int(hrv)) MS" }
                                    if let hrv = gestorSesion.ultimosDatosRecibidos?.variabilidadFrecuenciaCardiaca { return "\(Int(hrv)) MS" }
                                    return "-- MS"
                                }()
                                MetricCard(
                                    title: "VFC (HRV)",
                                    value: labelValue,
                                    icon: "waveform.path.ecg",
                                    color: Color.Medical.caution,
                                    trend: "Estable"
                                )
                            }
                            
                            Button(action: { selectedMetric = .sleep }) {
                                let hours = Int(healthKit.horasSuenoHoy)
                                let minutes = Int((healthKit.horasSuenoHoy - Double(hours)) * 60)
                                MetricCard(
                                    title: "SUEÑO",
                                    value: healthKit.horasSuenoHoy > 0 ? "\(hours)h \(minutes)m" : "--h --m",
                                    icon: "bed.double.fill",
                                    color: Color.Medical.accent,
                                    trend: "Bueno"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
            
            // FIXED BOTTOM ACTION BAR
            VStack {
                Spacer()
                Button(action: {
                    showQuickLog = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                        Text("REGISTRAR CRISIS AHORA")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .fullScreenCover(isPresented: $showQuickLog) {
            ActiveSeizureView()
        }
        // Sheets logic
        .sheet(isPresented: $showRiskDetail) {
            // Need to pass data to RiskDetailSheet. 
            // Since RiskAnalysisCard manages its own storage, we might need to read it here or duplicates it.
            // Ideally, RiskAnalysisCard should probably bind to a model, but for now we can read AppStorage or just show the static/calculated part.
            // Wait, RiskDetailSheet needs `dailyRisk`, `medicationTaken`, `sleepQuality`.
            // These are `@AppStorage` in `RiskAnalysisCard`. I need to access them here too or pass them.
            // Best way is to make `DashboardView` read them or separate the logic.
            // For simplicity and to match the prompt's speed, I'll access AppStorage here too.
            DashboardRiskSheetWrapper()
                .presentationDetents([.fraction(0.6), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedMetric) { metric in
            MetricDetailSheet(type: metric)
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            Task {
                await healthKit.fetchUltimaLectura()
            }
        }
    }
}

struct DashboardRiskSheetWrapper: View {
    @ObservedObject private var healthKit = HealthKitManager.shared
    @AppStorage("dailyMedicationTaken") private var medicationTaken: Bool = true
    @AppStorage("dailySleepQuality") private var sleepQuality: Bool = true
    
    var body: some View {
        RiskDetailSheet()
    }
}
