import Foundation

// MARK: - Enums y Estructuras Auxiliares

enum SexoBiologico: String, CaseIterable, Codable, Identifiable {
    case femenino = "Femenino"
    case masculino = "Masculino"

    var id: String { self.rawValue }

    /// Nota backend: Crucial para alertar riesgos teratogénicos (ej. Ácido Valproico en femenino)
    var requiereAlertaTeratogenica: Bool { self == .femenino }
}

enum FrecuenciaMedicacion: String, CaseIterable, Codable, Identifiable {
    case cada24h = "Cada 24 horas"
    case cada12h = "Cada 12 horas"
    case cada8h  = "Cada 8 horas"
    case cada6h  = "Cada 6 horas"
    case segunNecesidad = "Según necesidad (SOS)"

    var id: String { self.rawValue }
}

enum TerminoILAE: String, CaseIterable, Codable, Identifiable {
    case focalConsciente              = "Focal Consciente"
    case focalAlteracionConsciencia   = "Focal con Alteración de Consciencia"
    case tonicoClonicaBilateral       = "Tónico-Clónica Bilateral"
    case ausencia                     = "Ausencia"
    case mioclonica                   = "Mioclónica"
    case atonica                      = "Atónica"
    case desconocida                  = "Desconocida / No Clasificada"

    var id: String { self.rawValue }
}

// MARK: - Contacto de Emergencia

struct ContactoEmergencia: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var telefono: String
    var relacion: String  // "Madre", "Hermano", "Cuidador", etc.

    /// Mostrado debajo: "Este es el contacto que se marcará al pulsar REGISTRAR CRISIS AHORA"
    var esContactoPrincipal: Bool = false
}

// MARK: - Dispositivo Conectado

struct DispositivoConectado: Identifiable, Codable {
    var id: UUID = UUID()
    var nombre: String           // "Apple Health" / "Google Fit"
    var icono: String            // SF Symbol name
    var sincronizado: Bool       = false
    var ultimaSincronizacion: Date?

    var estadoTexto: String {
        if sincronizado, let fecha = ultimaSincronizacion {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Sincronizado \(formatter.localizedString(for: fecha, relativeTo: Date()))"
        }
        return "Sin conectar"
    }
}

// MARK: - Modelos Principales

struct PerfilUsuario: Codable {
    var nombreCompleto: String = "Usuario"
    var correo: String         = "usuario@email.com"
    var fechaNacimiento: Date
    var sexo: SexoBiologico
    var pesoKg: Int            // Int para selector drum nativo (sin teclado libre)

    var edad: Int {
        Calendar.current.dateComponents([.year], from: fechaNacimiento, to: Date()).year ?? 0
    }

    static let vacio = PerfilUsuario(
        nombreCompleto: "Usuario Nuevo",
        correo: "",
        fechaNacimiento: Date(),
        sexo: .femenino,
        pesoKg: 0
    )
}

// MARK: - Medicamento

struct Medicamento: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var dosisMg: Double
    var frecuencia: FrecuenciaMedicacion
    var fechaInicio: Date
    var activo: Bool = true
    
    /// Nota backend: dosisMg / pesoKg = mg/kg — crítico para calcular nivel terapéutico
    var codigoATC: String?   // Campo oculto para clasificación farmacológica
}

// MARK: - Tipo de Crisis

struct TipoCrisisPersonalizado: Identifiable, Codable {
    var id: UUID = UUID()
    var etiquetaPaciente: String   // "La de temblor fuerte"
    var terminoClinico: TerminoILAE // Código ILAE — asignado por el médico tratante
    var descripcion: String?
    var icono: String = "waveform.path.ecg"
}

// MARK: - Mock Data

extension Medicamento {
    static let ejemplos: [Medicamento] = [
        Medicamento(nombre: "Levetiracetam", dosisMg: 1000, frecuencia: .cada12h,
                    fechaInicio: Date().addingTimeInterval(-86400 * 30), codigoATC: "N03AX14"),
        Medicamento(nombre: "Lamotrigina",   dosisMg: 200,  frecuencia: .cada24h,
                    fechaInicio: Date().addingTimeInterval(-86400 * 60), codigoATC: "N03AX09")
    ]
}

extension TipoCrisisPersonalizado {
    static let ejemplos: [TipoCrisisPersonalizado] = [
        TipoCrisisPersonalizado(etiquetaPaciente: "Desconexión rápida",
                                terminoClinico: .ausencia,
                                descripcion: "Me quedo mirando al vacío unos segundos",
                                icono: "eye.slash"),
        TipoCrisisPersonalizado(etiquetaPaciente: "Sacudida fuerte",
                                terminoClinico: .tonicoClonicaBilateral,
                                descripcion: "Pierdo el conocimiento y tiemblo",
                                icono: "bolt.fill")
    ]
}

extension ContactoEmergencia {
    static let ejemplos: [ContactoEmergencia] = [
        ContactoEmergencia(nombre: "Jorge García", telefono: "+52 55 1234 5678",
                           relacion: "Padre", esContactoPrincipal: true)
    ]
}

extension DispositivoConectado {
    static let ejemplos: [DispositivoConectado] = [
        DispositivoConectado(nombre: "Apple Health", icono: "heart.fill",
                             sincronizado: true,
                             ultimaSincronizacion: Date().addingTimeInterval(-600)),
        DispositivoConectado(nombre: "Google Fit", icono: "figure.run",
                             sincronizado: false, ultimaSincronizacion: nil)
    ]
}
