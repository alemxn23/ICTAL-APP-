import SwiftUI

// MARK: - Risk Detail Sheet
struct RiskDetailSheet: View {
    @ObservedObject private var healthKit = HealthKitManager.shared
    @AppStorage("dailyMedicationTaken") private var medicationTaken: Bool = true
    @AppStorage("dailySleepQuality") private var sleepQuality: Bool = true
    
    var body: some View {
        ZStack {
            Color.Medical.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Grabber removed, using native .presentationDragIndicator
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Análisis de Riesgo Dinámico")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Fake History Chart (Visual only for now)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TENDENCIA (7 DÍAS)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Medical.neutral)
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(0..<7) { i in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(i == 6 ? Color.Medical.danger : Color.Medical.neutral.opacity(0.3))
                                        .frame(height: CGFloat([40, 35, 50, 30, 45, 20, Double(healthKit.riesgoCalculado) * 0.8].randomElement() ?? 40))
                                }
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.Medical.card)
                        .cornerRadius(12)
                        
                        // Calculation Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DESGLOSE EN VIVO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Medical.neutral)
                            
                            VStack(spacing: 12) {
                                RowItem(label: "Riesgo Basal (ICTAL)", value: "10%", color: .white)
                                
                                // Medicación
                                RowItem(
                                    label: "Adherencia a Medicación",
                                    value: medicationTaken ? "0%" : "+40%",
                                    color: medicationTaken ? Color.Medical.safe : Color.Medical.danger
                                )
                                
                                // Sueño (Real vs Manual)
                                let sleepPenalty = (healthKit.horasSuenoHoy > 0.1 && healthKit.horasSuenoHoy < 6.0) ? 
                                    Int((6.0 - healthKit.horasSuenoHoy) * 10) : 
                                    (!sleepQuality ? 20 : 0)
                                
                                RowItem(
                                    label: (healthKit.horasSuenoHoy > 0.1) ? "Déficit de Sueño (HK)" : "Calidad de Sueño",
                                    value: sleepPenalty == 0 ? "0%" : "+\(sleepPenalty)%",
                                    color: sleepPenalty == 0 ? Color.Medical.safe : Color.Medical.caution
                                )
                                
                                // Biometría (HRV)
                                if let hrv = healthKit.hrv, hrv < 30 {
                                    RowItem(label: "Inestabilidad Log (VFC)", value: "+15%", color: Color.Medical.caution)
                                }
                                
                                // Biometría (FC)
                                if let fc = healthKit.frecuenciaCardiaca, fc > 100 {
                                    RowItem(label: "Taquicardia en Reposo", value: "+10%", color: Color.Medical.caution)
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                HStack {
                                    Text("Riesgo Total Estimado")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(healthKit.riesgoCalculado)%")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(
                                            healthKit.riesgoCalculado > 50 ? Color.Medical.danger : (healthKit.riesgoCalculado > 30 ? Color.Medical.caution : Color.Medical.safe)
                                        )
                                }
                            }
                        }
                        .padding()
                        .background(Color.Medical.card)
                        .cornerRadius(12)
                        
                        // Explanation
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color.Medical.accent)
                                Text("¿QUÉ SIGNIFICA ESTO?")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.Medical.neutral)
                            }
                            
                            Text("Este modelo predictivo suma factores pro-convulsivos conocidos para estimar tu probabilidad de un evento a corto plazo. No es un diagnóstico infalible, sino una guía para tomar precauciones (ej. evitar conducir si el riesgo es alto).")
                                .font(.subheadline)
                                .foregroundColor(Color.Medical.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.Medical.card)
                        .cornerRadius(12)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    struct RowItem: View {
        let label: String
        let value: String
        let color: Color
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(Color.Medical.textSecondary)
                Spacer()
                Text(value)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
        }
    }
}

// MARK: - Metric Detail Sheet
enum MetricType: Identifiable {
    case heartRate
    case hrv
    case sleep
    case status
    
    var id: String {
        switch self {
        case .heartRate: return "heartRate"
        case .hrv: return "hrv"
        case .sleep: return "sleep"
        case .status: return "status"
        }
    }
    
    var title: String {
        switch self {
        case .heartRate: return "Frecuencia Cardíaca"
        case .hrv: return "VFC (HRV)"
        case .sleep: return "Registro de Sueño"
        case .status: return "Estado de Actividad"
        }
    }
    
    var definition: String {
        switch self {
        case .heartRate: return "El número de veces que tu corazón late por minuto."
        case .hrv: return "La variación de tiempo (en milisegundos) entre cada latido."
        case .sleep: return "La cantidad total de horas de descanso registradas en tu última noche."
        case .status: return "Clasifica si tu cuerpo está en estado basal o bajo esfuerzo físico."
        }
    }
    
    var importance: String {
        switch self {
        case .heartRate: return "Algunas crisis están precedidas o acompañadas por taquicardia (aumento brusco de latidos). Monitorear tu línea base ayuda a identificar anomalías sistémicas."
        case .hrv: return "Es un indicador clave de tu sistema nervioso autónomo. Caídas significativas en la VFC pueden indicar estrés fisiológico agudo y, en algunos casos, se estudian como biomarcadores pre-ictales (antes de una crisis)."
        case .sleep: return "La privación del sueño es el principal desencadenante no farmacológico de crisis epilépticas. Mantener ciclos regulares reduce drásticamente el riesgo de descompensación."
        case .status: return "Permite al algoritmo contextualizar tu frecuencia cardíaca. Una taquicardia en reposo es una alerta clínica; una taquicardia durante el ejercicio es normal."
        }
    }
    
    var source: String {
        switch self {
        case .heartRate, .hrv, .sleep: return "Datos sincronizados de forma segura desde Apple Health mediante tu dispositivo conectado."
        case .status: return "Calculado mediante acelerómetro y giroscopio del dispositivo."
        }
    }
}

struct MetricDetailSheet: View {
    let type: MetricType
    
    var body: some View {
        ZStack {
            Color.Medical.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Grabber removed, using native .presentationDragIndicator
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text(type.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Definition
                        InfoSection(title: "¿QUÉ ES?", content: type.definition)
                        
                        // Importance
                        InfoSection(title: "IMPORTANCIA EN EPILEPSIA", content: type.importance)
                        
                        // Source
                        HStack {
                            Image(systemName: "applewatch")
                            Text("FUENTE DE DATOS")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(Color.Medical.neutral)
                        
                        Text(type.source)
                            .font(.caption)
                            .foregroundColor(Color.Medical.neutral)
                            .padding(.top, -4)
                    }
                    .padding(20)
                }
            }
        }
    }
    
    struct InfoSection: View {
        let title: String
        let content: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Medical.accent)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Medical.card)
            .cornerRadius(12)
        }
    }
}
