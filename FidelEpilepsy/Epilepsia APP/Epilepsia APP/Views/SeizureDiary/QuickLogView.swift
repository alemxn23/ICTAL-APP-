import SwiftUI

struct QuickLogView: View {
    @Binding var isPresented: Bool
    @State private var logDate = Date()
    @State private var selectedType: String?
    
    // Colloquial tags as requested
    let seizureTypes = [
        "Aura / " + "Aviso", // Using + to avoid string literal inside string literal issues if any
        "Desconexión",
        "Sacudidas",
        "Convulsión",
        "No lo sé"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("Registro Rápido")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        // Saving action (Mock)
                        isPresented = false
                    }) {
                        Text("Guardar")
                            .bold()
                            .foregroundColor(selectedType == nil ? .gray : .blue)
                    }
                    .disabled(selectedType == nil)
                }
                .padding()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("¿Cuándo ocurrió?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            DatePicker("Hora", selection: $logDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 120) // Compact
                                .clipped()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        // 2. Type (Chips)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tipo de Crisis")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                ForEach(seizureTypes, id: \.self) { type in
                                    Button(action: {
                                        selectedType = type
                                    }) {
                                        Text(type)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedType == type ? Color.orange : Color(UIColor.tertiarySystemBackground))
                                            .foregroundColor(selectedType == type ? .white : .primary)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedType == type ? Color.orange : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemBackground))
        }
    }
}
