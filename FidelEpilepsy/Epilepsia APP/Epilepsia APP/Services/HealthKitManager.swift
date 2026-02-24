import HealthKit
import Foundation
import Combine

// MARK: - EstadoDispositivo
enum EstadoDispositivo: Equatable {
    case sinConectar
    case solicitandoPermiso
    case autorizado(fecha: Date)
    case denegado
    case noDisponible   // dispositivos sin HealthKit (iPad sin sensores, simulador)
}

// MARK: - HealthKitManager (ObservableObject, Reactivo)
// Todos los estados se publican para que la UI los consuma sin polling.
// La vía de datos es: HealthKit → @Published → PerfilViewModel → PerfilView

class HealthKitManager: ObservableObject {

    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    // Estado publicado para la UI
    @Published var estadoAppleHealth: EstadoDispositivo = .sinConectar
    @Published var frecuenciaCardiaca: Double? = nil
    @Published var hrv: Double? = nil
    @Published var horasSuenoHoy: Double = 0.0
    @Published var riesgoCalculado: Int = 10
    @Published var estadoActividad: String = "REPOSO"

    // Tipos de datos que se solicitarán
    private var typesToRead: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let hr  = HKObjectType.quantityType(forIdentifier: .heartRate)               { types.insert(hr)  }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let sl  = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)            { types.insert(sl)  }
        return types
    }

    private init() {
        // Si el dispositivo no soporta HealthKit, marcarlo desde el inicio
        if !HKHealthStore.isHealthDataAvailable() {
            estadoAppleHealth = .noDisponible
        }
    }

    // MARK: - Solicitar y Observar Permisos

    /// Punto de entrada para el toggle de Apple Health en el perfil.
    /// - Si ya existe autorización previa → verificar y actualizar estado.
    /// - Si no → solicitar permisos al sistema (muestra el sheet nativo de iOS).
    @MainActor
    func requestAndObservePermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            estadoAppleHealth = .noDisponible
            return
        }
        estadoAppleHealth = .solicitandoPermiso

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            // Para lectura, HealthKit no devuelve un estado de 'autorizado' por privacidad.
            // Si la llamada no da error, marcamos como conectado localmente.
            UserDefaults.standard.set(true, forKey: "healthkit.enabled")
            estadoAppleHealth = .autorizado(fecha: Date())
            UserDefaults.standard.set(Date(), forKey: "healthkit.lastSync")
            activarBackgroundDelivery()
            await fetchUltimaLectura()
        } catch {
            estadoAppleHealth = .denegado
            print("[HealthKit] Error solicitando permisos: \(error.localizedDescription)")
        }
    }

    // MARK: - Restaurar Estado al Lanzar

    /// Llamar en onAppear de la vista para restaurar el estado sin mostrar diálogos.
    @MainActor
    func restaurarEstadoGuardado() {
        guard HKHealthStore.isHealthDataAvailable() else {
            estadoAppleHealth = .noDisponible
            return
        }
        let isEnabled = UserDefaults.standard.bool(forKey: "healthkit.enabled")
        if isEnabled {
            let fecha = UserDefaults.standard.object(forKey: "healthkit.lastSync") as? Date ?? Date()
            estadoAppleHealth = .autorizado(fecha: fecha)
            // Cargar datos reales inmediatamente en segundo plano
            Task {
                await fetchUltimaLectura()
            }
            // Iniciar observadores para actualizaciones en vivo y enableBackgroundDelivery
            activarBackgroundDelivery()
        } else {
            estadoAppleHealth = .sinConectar
        }
    }

    // MARK: - Fetch Última Lectura (FC y HRV)

    @MainActor
    func fetchUltimaLectura() async {
        // Frecuencia Cardíaca
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            let sample = await fetchUltimoValorQuantity(type: hrType)
            frecuenciaCardiaca = sample?.quantity.doubleValue(
                for: HKUnit.count().unitDivided(by: .minute()))
        }
        // HRV (SDNN en ms)
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            let sample = await fetchUltimoValorQuantity(type: hrvType)
            hrv = sample?.quantity.doubleValue(for: .secondUnit(with: .milli))
        }
        // Sueño
        let sleepSamples = await fetchSleepData()
        let totalSeconds = sleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        horasSuenoHoy = totalSeconds / 3600.0
        
        actualizarRiesgoYEstado()
    }
    
    @MainActor
    private func actualizarRiesgoYEstado() {
        // 1. Cálculo de Riesgo (Lógica Clínica ILAE)
        var riesgo = 10 // Base basal
        
        let medTomada = UserDefaults.standard.bool(forKey: "dailyMedicationTaken")
        let suenoBuenoManual = UserDefaults.standard.bool(forKey: "dailySleepQuality")
        
        // Penalización por Sueño
        // Si no hay data (0.0) pero el usuario marcó "Sueño Bueno" manualmente, no penalizamos.
        // Si hay data y es < 6h, penalizamos.
        // Si no hay data y el usuario marcó "Sueño Malo", penalizamos base 20.
        if horasSuenoHoy > 0.1 {
            if horasSuenoHoy < 6.0 {
                let deficit = 6.0 - horasSuenoHoy
                riesgo += Int(deficit * 10) 
            }
        } else if !suenoBuenoManual {
            riesgo += 20 // Penalización por reporte manual de mal sueño
        }
        
        // Penalización por HRV (SDNN < 30ms)
        if let hrvActual = hrv, hrvActual < 30 {
            riesgo += 15
        }
        
        // Taquicardia en reposo
        if let fc = frecuenciaCardiaca, fc > 100 {
            riesgo += 10
        }
        
        // Adherencia a Medicación (Crítico)
        if !medTomada {
            riesgo += 40
        }
        
        self.riesgoCalculado = min(riesgo, 100)
        
        // 2. Estado (Umbral de reposo vs actividad)
        if let fc = frecuenciaCardiaca {
            self.estadoActividad = fc > 105 ? "ACTIVIDAD" : "REPOSO"
        }
    }

    private func fetchUltimoValorQuantity(type: HKQuantityType) async -> HKQuantitySample? {
        await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil,
                                      limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                continuation.resume(returning: samples?.first as? HKQuantitySample)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Fetch Sueño (últimas 24 h)

    func fetchSleepData() async -> [HKCategorySample] {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sort]) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery & Observation

    private func activarBackgroundDelivery() {
        for type in typesToRead {
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { _, error in
                if let error = error {
                    print("[HealthKit] Background delivery error: \(error.localizedDescription)")
                }
            }
        }
        startObservingHealthKit()
    }
    
    private func startObservingHealthKit() {
        for type in typesToRead {
            guard let sampleType = type as? HKSampleType else { continue }
            // Observador para cambios en la base de datos de salud
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
                guard error == nil else {
                    print("[HealthKit] Error observing \(type.identifier): \(error!.localizedDescription)")
                    return
                }
                
                // Disparar actualización en el Main Thread cada vez que hay datos nuevos
                Task { @MainActor in
                    await self?.fetchUltimaLectura()
                    // Informar a HealthKit que hemos procesado la actualización
                    completionHandler()
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Estado helpers para la UI

extension EstadoDispositivo {
    var textoEstado: String {
        switch self {
        case .sinConectar:           return "Sin conectar"
        case .solicitandoPermiso:    return "Solicitando permiso…"
        case .autorizado(let fecha): return "Sincronizado \(fecha.formatted(.relative(presentation: .numeric)))"
        case .denegado:              return "Acceso denegado"
        case .noDisponible:          return "No disponible en este dispositivo"
        }
    }

    var estaConectado: Bool {
        if case .autorizado = self { return true }
        return false
    }

    var colorEstado: String {
        switch self {
        case .autorizado: return "34C759"   // Verde
        case .denegado:   return "FF3B30"   // Rojo
        default:          return "8E8E93"   // Gris
        }
    }
}
