import SwiftUI

struct HeroStatusView: View {
    let instabilityIndex: Int
    let statusText: String
    let statusColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background track
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 8)
                
                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(instabilityIndex) / 100.0)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                // Value inside circle
                Text("\(instabilityIndex)%")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 80, height: 80)
            
            // Status Text
            Text(statusText.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HeroStatusView(instabilityIndex: 12, statusText: "Estable", statusColor: Color(red: 0.0, green: 1.0, blue: 0.4))
}
