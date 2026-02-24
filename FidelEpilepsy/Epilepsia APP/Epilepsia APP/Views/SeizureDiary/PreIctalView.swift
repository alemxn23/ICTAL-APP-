import SwiftUI

struct PreIctalView: View {
    @Binding var event: SeizureEvent
    @State private var hasAura: Bool = false
    @State private var showingDatePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Módulo Pre-Ictal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                // Fecha y Hora Compacta (Chip Interactiva)
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        
                        Text(event.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .sheet(isPresented: $showingDatePicker) {
                    VStack {
                        DatePicker("Seleccionar Fecha", selection: $event.date)
                            .datePickerStyle(.graphical)
                            .padding()
                        
                        Button("Confirmar") {
                            showingDatePicker = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .presentationDetents([.medium])
                }
                
                // Adherencia
                Toggle("¿Olvidaste tomar tu medicamento en las últimas 48 horas?", isOn: $event.missedMedication)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                // Triggers
                VStack(alignment: .leading, spacing: 12) {
                    Text("Factores de Estrés (Triggers)")
                        .font(.headline)
                    
                    Text("Selecciona los que apliquen (Chips)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        ForEach(SeizureTrigger.allCases) { trigger in
                            SelectionChip(
                                title: trigger.rawValue,
                                isSelected: event.triggers.contains(trigger),
                                action: {
                                    if event.triggers.contains(trigger) {
                                        event.triggers.remove(trigger)
                                    } else {
                                        event.triggers.insert(trigger)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Aura
                VStack(alignment: .leading) {
                    Toggle("¿Sentiste un Aura?", isOn: $hasAura)
                    
                    if hasAura {
                        TextField("Describe la sensación (olores, déjà vu...)", text: Binding(
                            get: { event.aura ?? "" },
                            set: { event.aura = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .transition(.opacity)
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
