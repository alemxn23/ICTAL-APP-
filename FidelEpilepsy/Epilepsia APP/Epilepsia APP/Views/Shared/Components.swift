import SwiftUI

// MARK: - Telemetry Wave View
struct TelemetryWaveView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Layer 1
            WaveShape(phase: phase, frequency: 1.5, amplitude: 10)
                .fill(LinearGradient(colors: [Color.Medical.accent.opacity(0.3), Color.Medical.accent.opacity(0.1)], startPoint: .leading, endPoint: .trailing))
            
            // Layer 2
            WaveShape(phase: phase * 1.5, frequency: 1.2, amplitude: 15)
                .fill(LinearGradient(colors: [Color.Medical.accent.opacity(0.2), Color.Medical.accent.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
                .offset(y: 5)
        }
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var frequency: CGFloat
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency + phase)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Circular Progress Ring
struct CircularProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    var lineWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Instability Index Card
struct InstabilityIndexCard: View {
    let percentage: Int
    
    var statusColor: Color {
        percentage > 70 ? Color.Medical.caution : Color.Medical.safe
    }
    
    var statusText: String {
        percentage > 70 ? "Carga de Estrés Alta" : "Sistema Estable"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                CircularProgressRing(progress: Double(percentage) / 100.0, color: statusColor)
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 2) {
                    Text("\(percentage)%")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("ÍNDICE")
                        .font(Font.Medical.dataLabel)
                        .foregroundColor(Color.Medical.textSecondary)
                }
            }
            
            VStack(spacing: 4) {
                Text("Inestabilidad")
                    .font(Font.Medical.headline)
                    .foregroundColor(.white)
                Text(statusText)
                    .font(Font.Medical.subheadline)
                    .foregroundColor(statusColor)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.Medical.card)
        .cornerRadius(16)
    }
}

// MARK: - Metric Card (Apple Health Style)
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    init(title: String, value: String, icon: String, color: Color, trend: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(Font.Medical.dataLabel)
                    .foregroundColor(Color.Medical.textSecondary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                if let trend = trend {
                    Text(trend)
                        .font(Font.Medical.caption)
                        .foregroundColor(Color.Medical.neutral)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Medical.card)
        .cornerRadius(12)
    }
}

// MARK: - Telemetry Hero Card
struct ConsolidatedHeroCard: View {
    let percentage: Int
    
    var statusColor: Color {
        percentage > 70 ? Color.Medical.caution : Color.Medical.safe
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Side: Telemetry (approx 60%)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.Medical.accent)
                        .frame(width: 6, height: 6)
                    Text("Monitoreo Activo")
                        .font(Font.Medical.caption)
                        .foregroundColor(Color.Medical.accent)
                }
                
                Text("Análisis en tiempo real")
                    .font(Font.Medical.subheadline)
                    .bold()
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                TelemetryWaveView()
                    .frame(height: 40)
                    .opacity(0.6)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right Side: Index (approx 40%)
            VStack(spacing: 8) {
                ZStack {
                    CircularProgressRing(progress: Double(percentage) / 100.0, color: statusColor, lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Text("\(percentage)%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 2) {
                    Text(percentage > 70 ? "RIESGO" : "ESTABLE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(statusColor)
                    Text("ÍNDICE")
                        .font(.system(size: 8))
                        .foregroundColor(Color.Medical.textSecondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.Medical.background.opacity(0.3))
        }
        .frame(height: 120)
        .background(Color.Medical.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
