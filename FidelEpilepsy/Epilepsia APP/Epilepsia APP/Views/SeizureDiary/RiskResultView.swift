import SwiftUI

struct RiskResultView: View {
    let event: SeizureEvent
    
    var riskColor: Color {
        switch event.recurrenceRisk {
        case 0..<30: return .green
        case 30..<60: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Análisis de Riesgo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(riskColor)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(event.recurrenceRisk / 100, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(riskColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: event.recurrenceRisk)
                    
                    VStack {
                        Text("\(Int(event.recurrenceRisk))%")
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                        Text("Probabilidad")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 200, height: 200)
                .padding()
                
                VStack(alignment: .leading, spacing: 15) {
                    if event.recurrenceRisk >= 50 {
                        HStack {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(.red)
                            Text("Riesgo Alto")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Text("Retoma tu dosis inmediatamente según las indicaciones de tu médico y evita conducir.")
                            .font(.body)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            
                    } else if event.recurrenceRisk >= 30 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Riesgo Moderado")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        Text("Mantén vigilancia y asegura un buen descanso hoy.")
                            .font(.body)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Riesgo Bajo")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Text("Continúa con tu rutina habitual y medicación.")
                            .font(.body)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}
