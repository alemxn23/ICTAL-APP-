import SwiftUI

struct IctalView: View {
    @Binding var event: SeizureEvent
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Módulo Ictal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Estado de Alerta
                Toggle("¿Hubo pérdida de consciencia/desconexión?", isOn: $event.lossOfAwareness)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                if event.lossOfAwareness {
                    // Flujo de Desconexión
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("¿Hubo movimientos automáticos (chupeteo, frotar manos)?", isOn: $event.automatisms)
                        Divider()
                        Toggle("¿Terminó en convulsión generalizada?", isOn: $event.generalizedConvulsion)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity)
                } else {
                    // Flujo Consciente
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Síntomas Focales")
                            .font(.headline)
                        
                        Text("Selecciona lo que sentiste")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                            ForEach(FocalSymptom.allCases) { symptom in
                                SelectionChip(
                                    title: symptom.rawValue,
                                    isSelected: event.focalSymptoms?.contains(symptom) ?? false,
                                    action: {
                                        if event.focalSymptoms == nil { event.focalSymptoms = [] }
                                        if event.focalSymptoms!.contains(symptom) {
                                            event.focalSymptoms!.remove(symptom)
                                        } else {
                                            event.focalSymptoms!.insert(symptom)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .transition(.opacity)
                }
                
                // Duración
                VStack(alignment: .leading) {
                    Text("Duración del Evento")
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(event.duration / 60)) min")
                        Slider(value: $event.duration, in: 0...600, step: 10)
                        Text("\(Int(event.duration.truncatingRemainder(dividingBy: 60))) sec")
                    }
                    
                    if event.duration > 300 { // > 5 minutes
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            Text("ALERTA: Estatus Epiléptico. Llame a Urgencias.")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                        .transition(.scale)
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
