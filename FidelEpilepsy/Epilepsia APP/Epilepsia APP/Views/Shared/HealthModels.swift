import Foundation  // <--- SIN BARRAS
struct HealthData: Codable {
    let heartRate: Double
    let hrv: Double
    let timestamp: Date
}
