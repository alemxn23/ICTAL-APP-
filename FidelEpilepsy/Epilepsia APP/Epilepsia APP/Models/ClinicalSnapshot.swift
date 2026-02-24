import Foundation

struct ClinicalSnapshot: Codable {
    let user_id: String
    let clinical_snapshot: SnapshotData
}

struct SnapshotData: Codable {
    let timestamp: Date
    let sleep_metrics: SleepMetrics
    let autonomic_metrics: AutonomicMetrics
}

struct SleepMetrics: Codable {
    let total_duration_minutes: Int
    let was_fragmented: Bool
    let source: String
}

struct AutonomicMetrics: Codable {
    let avg_hrv_sdnn: Double
    let resting_hr: Double
    let hrv_status: HRVStatus
}

enum HRVStatus: String, Codable {
    case normal = "NORMAL"
    case depressed = "DEPRESSED"
}
