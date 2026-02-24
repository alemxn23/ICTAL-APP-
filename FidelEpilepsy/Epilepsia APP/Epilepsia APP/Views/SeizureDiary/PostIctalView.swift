import SwiftUI

struct PostIctalView: View {
    @Binding var event: SeizureEvent
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Módulo Post-Ictal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Recuperación
                VStack(alignment: .leading) {
                    Text("Tiempo de recuperación")
                        .font(.headline)
                    
                    Picker("Recuperación", selection: $event.recoveryTime) {
                        ForEach(RecoveryDuration.allCases) { duration in
                            Text(duration.rawValue).tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Déficits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Déficits Temporales")
                        .font(.headline)
                    
                    Text("Selecciona si aplica (Chips)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        ForEach(PostIctalDeficit.allCases) { deficit in
                            SelectionChip(
                                title: deficit.rawValue,
                                isSelected: event.deficits.contains(deficit),
                                action: {
                                    if event.deficits.contains(deficit) {
                                        event.deficits.remove(deficit)
                                    } else {
                                        event.deficits.insert(deficit)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}
