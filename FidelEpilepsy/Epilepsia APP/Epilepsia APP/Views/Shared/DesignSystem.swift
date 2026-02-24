import SwiftUI

// MARK: - Font System
extension Font {
    struct Medical {
        static let hero = Font.system(size: 40, weight: .bold, design: .default)
        static let title = Font.system(size: 28, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .medium, design: .default)
        static let data = Font.system(size: 34, weight: .bold, design: .default)
        static let dataLabel = Font.system(size: 12, weight: .bold, design: .default)
    }
}

// MARK: - Color System
extension Color {
    struct Medical {
        // Apple Native Semantic Colors (iOS 17/18)
        static let safe = Color(hex: "34C759") // Apple Green
        static let caution = Color(hex: "FF9500") // Apple Amber/Orange
        static let danger = Color(hex: "FF3B30") // Apple Red
        static let accent = Color(hex: "007AFF") // Apple Blue
        
        static let background = Color.black // Pure OLED Black
        static let card = Color(hex: "101010") // Darker, near black for elegance
        static let neutral = Color(hex: "8E8E93") // System Gray
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)
    }
}

// MARK: - Component Styles

struct AppleButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers (Shared)

extension View {
    /// Animates the view between fully opaque and fully transparent on repeat.
    /// Used during emergency states to draw attention to critical UI elements.
    func blinkEffect() -> some View {
        self.modifier(BlinkModifier())
    }
}

struct BlinkModifier: ViewModifier {
    @State private var isBlinking = false
    func body(content: Content) -> some View {
        content
            .opacity(isBlinking ? 0 : 1)
            .animation(.easeInOut(duration: 0.6).repeatForever(), value: isBlinking)
            .onAppear { isBlinking = true }
    }
}

