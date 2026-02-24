import SwiftUI

struct SeizureEventDetailView: View {
    @Binding var event: SeizureEvent
    @State private var currentStep = 0
    
    var body: some View {
        VStack {
            // Progress Indicator
            ProgressView(value: Double(currentStep), total: 3)
                .padding()
            
            TabView(selection: $currentStep) {
                PreIctalView(event: $event)
                    .tag(0)
                
                IctalView(event: $event)
                    .tag(1)
                
                PostIctalView(event: $event)
                    .tag(2)
                
                EventSummaryView(event: event)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            // Navigation Buttons
            HStack {
                if currentStep > 0 {
                    Button("Atrás") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentStep < 3 {
                    Button(currentStep == 2 ? "Finalizar" : "Siguiente") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Detalle del Evento")
        .navigationBarTitleDisplayMode(.inline)
    }
}
