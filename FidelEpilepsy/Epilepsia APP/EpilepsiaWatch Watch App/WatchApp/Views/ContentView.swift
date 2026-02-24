import SwiftUI

struct Theme {
    struct Colors {
        static let background = Color.black
        static let neuroGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
        static let neuroPink = Color(red: 1.0, green: 0.0, blue: 0.5)
        static let neuroCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
        static let neuroRed = Color(red: 1.0, green: 0.2, blue: 0.2)
        static let cardBackground = Color(white: 0.1)
    }
}

struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager.shared
    @State private var isCrisisActive = false
    
    var body: some View {
        VStack(spacing: 2) {
            // 1. TOP: Ring + Medicacion/Sueno
            HStack(spacing: 8) {
                // Ring
                ZStack {
                    Circle().stroke(Theme.Colors.neuroGreen.opacity(0.3), lineWidth: 4)
                    Circle().trim(from: 0, to: 0.1)
                        .stroke(Theme.Colors.neuroGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("10%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 45, height: 45)
                
                // Toggles
                VStack(spacing: 4) {
                    CompactStatusRow(icon: "pills.fill", color: Theme.Colors.neuroGreen)
                    CompactStatusRow(icon: "moon.fill", color: .blue)
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)
            
            // 2. MIDDLE: 2x2 Grid
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    CompactGridCell(icon: "heart.fill", color: Theme.Colors.neuroRed, value: String(format: "%.0f", healthManager.currentHeartRate), unit: "LPM")
                    CompactGridCell(icon: "figure.walk", color: Theme.Colors.neuroGreen, value: "REPOSO", unit: "")
                }
                HStack(spacing: 2) {
                    CompactGridCell(icon: "waveform.path.ecg", color: Theme.Colors.neuroPink, value: String(format: "%.0f", healthManager.currentHRV), unit: "MS")
                    CompactGridCell(icon: "bed.double.fill", color: .blue, value: "7h 20m", unit: "")
                }
            }
            .padding(.horizontal, 2)
            
            Spacer(minLength: 0)
            
            // 3. BOTTOM: Action Button
            Button(action: {
                isCrisisActive = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold))
                    Text("CRISIS")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(Theme.Colors.neuroRed)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 2)
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            healthManager.startMonitoring()
        }
        .fullScreenCover(isPresented: $isCrisisActive) {
            WatchActiveSeizureView()
        }
    }
}

// Subcomponents for Compact View
struct CompactStatusRow: View {
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            Spacer()
            
            // Fake Toggle switch visual
            Capsule()
                .fill(color)
                .frame(width: 24, height: 12)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(1.5)
                    , alignment: .trailing
                )
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(white: 0.12))
        .cornerRadius(6)
    }
}

struct CompactGridCell: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.all, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.12))
        .cornerRadius(6)
    }
}

#Preview {
    ContentView()
}
