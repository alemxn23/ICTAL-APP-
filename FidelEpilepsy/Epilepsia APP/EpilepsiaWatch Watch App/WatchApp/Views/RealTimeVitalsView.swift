import SwiftUI

struct RealTimeVitalsView: View {
    let heartRate: Double
    let hrv: Double
    let isOnWrist: Bool
    
    // Theme Colors
    let cardBackground = Color(white: 0.11)
    let neuroRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    let neuroCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 6) {
            // Card 1: Heart Rate
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(isOnWrist ? neuroRed : .gray)
                    .font(.system(size: 20))
                    .frame(width: 24)
                    .symbolEffect(.bounce, options: .repeating, value: isOnWrist && heartRate > 0)
                
                if isOnWrist {
                    Text(String(format: "%.0f", heartRate))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("LPM")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(neuroRed)
                } else {
                    Text("Sensor Inactivo")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(12)
            
            // Card 2: HRV / Sleep
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(isOnWrist ? neuroCyan : .gray)
                    .font(.system(size: 16))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("HRV: \(isOnWrist ? String(format: "%.0f ms", hrv) : "--")")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Sueño: 6h 30m")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(cardBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    RealTimeVitalsView(heartRate: 72.0, hrv: 45.0, isOnWrist: true)
}
