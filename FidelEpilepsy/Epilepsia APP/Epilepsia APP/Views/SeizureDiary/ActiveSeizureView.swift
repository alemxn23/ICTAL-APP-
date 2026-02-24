import SwiftUI

/// Entry point for an active seizure event.
/// Immediately launches Phase 1 (Aura) full-screen.
/// The crisis start time is set here and passed through all phases for cumulative timing.
struct ActiveSeizureView: View {
    @Environment(\.dismiss) var dismiss
    
    private let crisisStartTime: Date = Date()
    
    var body: some View {
        SeizurePhase1View(crisisStartTime: crisisStartTime)
    }
}
