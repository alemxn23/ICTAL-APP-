import SwiftUI

struct ActionButtonView: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    // Theme Colors
    let neuroRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(neuroRed)
            .foregroundColor(.white)
            // Use corner radius instead of standard button style backgrounds for absolute control
            .cornerRadius(22)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionButtonView(title: "REPORTAR", icon: "bolt.fill", action: {})
        .padding()
}
