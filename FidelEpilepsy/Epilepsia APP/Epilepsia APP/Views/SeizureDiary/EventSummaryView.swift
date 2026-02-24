import SwiftUI

struct EventSummaryView: View {
    let event: SeizureEvent
    @Environment(\.dismiss) private var dismiss
    
    // Generate a structured summary text for exporting/sharing
    var summaryText: String {
        var text = "Reporte de Crisis - \(event.date.formatted(date: .numeric, time: .shortened))\n\n"
        
        // Type
        let type = event.quickLogType ?? (event.lossOfAwareness ? "Crisis con Desconexión" : "Crisis Focal Consciente")
        text += "• Tipo: \(type)\n"
        
        // Duration
        text += "• Duración: \(Int(event.duration / 60)) min \(Int(event.duration.truncatingRemainder(dividingBy: 60))) seg\n"
        
        // Medication
        text += "• Medicación: \(event.missedMedication ? "Omitida (Riesgo)" : "Tomada correctamente")\n"
        
        // Triggers
        if !event.triggers.isEmpty {
            let triggersList = event.triggers.map { $0.rawValue }.joined(separator: ", ")
            text += "• Desencadenantes: \(triggersList)\n"
        } else {
            text += "• Desencadenantes: Ninguno reportado\n"
        }
        
        // Aura
        if let aura = event.aura, !aura.isEmpty {
            text += "• Aura: \(aura)\n"
        }
        
        // Ictal Details
        if event.lossOfAwareness {
            var details: [String] = []
            if event.automatisms { details.append("Automatismos") }
            if event.generalizedConvulsion { details.append("Convulsión Generalizada") }
            if !details.isEmpty {
                text += "• Detalles Ictales: \(details.joined(separator: ", "))\n"
            }
        } else if let focal = event.focalSymptoms, !focal.isEmpty {
            let symptoms = focal.map { $0.rawValue }.joined(separator: ", ")
            text += "• Síntomas: \(symptoms)\n"
        }
        
        // Post-Ictal
        text += "• Recuperación: \(event.recoveryTime.rawValue)\n"
        
        if !event.deficits.isEmpty {
            let deficitsList = event.deficits.map { $0.rawValue }.joined(separator: ", ")
            text += "• Déficits Post-Ictales: \(deficitsList)\n"
        }
        
        return text
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(Color.Medical.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.Medical.accent)
                }
                .padding(.top, 20)
                
                Text("Evento Registrado")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("RESUMEN CLÍNICO")
                        .font(Font.Medical.dataLabel)
                        .foregroundColor(Color.Medical.neutral)
                    
                    Group {
                        DetailRow(label: "Fecha", value: event.date.formatted(date: .abbreviated, time: .shortened))
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        DetailRow(label: "Tipo", value: event.quickLogType ?? (event.lossOfAwareness ? "Desconexión" : "Focal"))
                        
                        DetailRow(label: "Duración", value: "\(Int(event.duration / 60))m \(Int(event.duration.truncatingRemainder(dividingBy: 60)))s")
                        
                        if event.missedMedication {
                            DetailRow(label: "Medicación", value: "OMITIDA", valueColor: .red)
                        }
                        
                        if !event.triggers.isEmpty {
                            DetailRow(label: "Triggers", value: event.triggers.map { $0.rawValue }.joined(separator: ", "))
                        }
                        
                        DetailRow(label: "Recuperación", value: event.recoveryTime.rawValue)
                    }
                }
                .padding(20)
                .background(Color.Medical.card)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    ShareLink(item: summaryText) {
                        Label("Compartir Reporte", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Medical.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cerrar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color.Medical.background.ignoresSafeArea())
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.Medical.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
            
            Spacer()
        }
    }
}
