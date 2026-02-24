import SwiftUI

struct SeizureDiaryView: View {
    // Mock Data for Demo
    @State private var events: [SeizureEvent] = [
        SeizureEvent(
            id: UUID(),
            date: Date(),
            isQuickLog: true,
            quickLogType: "Aura / Aviso",
            missedMedication: false,
            triggers: [],
            aura: nil,
            lossOfAwareness: false,
            focalSymptoms: [],
            automatisms: false,
            generalizedConvulsion: false,
            duration: 0,
            recoveryTime: .immediate,
            deficits: []
        ),
        SeizureEvent(
            id: UUID(),
            date: Date().addingTimeInterval(-86400),
            isQuickLog: false,
            quickLogType: nil,
            missedMedication: true,
            triggers: [.sleepDeprivation],
            aura: "Luces parpadeantes",
            lossOfAwareness: true,
            focalSymptoms: [],
            automatisms: true,
            generalizedConvulsion: true,
            duration: 180,
            recoveryTime: .between15And60,
            deficits: [.confusion]
        )
    ]
    
    @State private var selectedFilter: TimeFilter = .all
    @State private var showExportSheet = false
    @State private var generatedReport = ""
    
    var filteredEvents: [SeizureEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .day:
            return events.filter { calendar.isDateInToday($0.date) }
        case .week:
            return events.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .month:
            return events.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .all:
            return events
        }
    }
    
    func exportReport() {
        var report = "Reporte de Crisis Epilépticas - Filtro: \(selectedFilter.rawValue)\n\n"
        
        for event in filteredEvents {
            report += "Fecha: \(event.date.formatted(date: .numeric, time: .shortened))\n"
            report += "Tipo: \(event.quickLogType ?? (event.lossOfAwareness ? "Desconexión" : "Focal"))\n"
            report += "Duración: \(Int(event.duration)) seg\n"
            if event.missedMedication { report += "⚠️ Medicación Omitida\n" }
            report += "--------------------------------\n"
        }
        
        generatedReport = report
        showExportSheet = true
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtros Temporales
                Picker("Filtro", selection: $selectedFilter) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Lista de Eventos Filtrada
                List {
                    ForEach(filteredEvents.indices, id: \.self) { index in
                        // Binding Proxies for Mutable Elements in a filtered list are tricky.
                        // For simplicity in this mockup, we find the index in main array.
                        // In production, use SwiftData @Query with dynamic predicates.
                        let event = filteredEvents[index]
                        if let mainIndex = events.firstIndex(where: { $0.id == event.id }) {
                            NavigationLink(destination: SeizureEventDetailView(event: $events[mainIndex])) {
                                EventRow(event: event)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Historial")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportReport) {
                        Label("Exportar", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(activityItems: [generatedReport])
            }
        }
    }
}

// Subcomponents
struct EventRow: View {
    let event: SeizureEvent
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Indicator
            VStack(spacing: 4) {
                Text(event.date, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
                Text(event.date, format: .dateTime.month(.abbreviated))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 50)
            
            Divider()
                .frame(height: 40)
            
            // Event Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.quickLogType ?? (event.lossOfAwareness ? "Crisis con Desconexión" : "Crisis Focal"))
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if event.isQuickLog {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    }
                }
                
                if event.isQuickLog {
                    Text("Toca para añadir detalles")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Duración: \(Int(event.duration / 60)) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum TimeFilter: String, CaseIterable {
    case day = "Día"
    case week = "Semana"
    case month = "Mes"
    case all = "Todo"
}

