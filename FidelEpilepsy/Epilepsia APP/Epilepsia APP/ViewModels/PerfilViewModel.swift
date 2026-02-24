import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class PerfilViewModel: ObservableObject {

    // MARK: - Propiedades Publicadas

    @Published var perfil: PerfilUsuario
    @Published var medicamentos: [Medicamento]
    @Published var tiposCrisis: [TipoCrisisPersonalizado]
    @Published var contactosEmergencia: [ContactoEmergencia]
    @Published var dispositivosConectados: [DispositivoConectado]

    // Auth State driven by Supabase
    @Published var isLoggedIn: Bool = false

    // Estados UI
    @Published var mostrandoAlertaExportacion: Bool = false
    @Published var mensajeExportacion: String = ""
    @Published var mostrandoAlertaCerrarSesion: Bool = false
    @Published var mostrandoAlertaEliminarCuenta: Bool = false
    @Published var mostrandoAlertaError: Bool = false
    @Published var mensajeError: String = ""

    // Loading states
    @Published var cargandoPDF: Bool = false
    @Published var cargandoEliminarCuenta: Bool = false

    // Apple Health — estado reactivo desde HealthKitManager
    @Published var estadoAppleHealth: EstadoDispositivo = .sinConectar

    // PDF share item
    @Published var pdfURL: URL?
    @Published var mostrandoShareSheet: Bool = false

    // HealthKit manager observado
    private let healthKit = HealthKitManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        self.perfil               = PerfilUsuario.vacio
        self.pdfURL               = nil
        // Data REAL vacía de inicio hasta no fetchear Supabase.
        self.medicamentos         = []
        self.tiposCrisis          = []
        self.contactosEmergencia  = []
        
        // El único dispositivo por defecto es Apple Health.
        self.dispositivosConectados = [
            DispositivoConectado(nombre: "Apple Health", icono: "heart.fill", sincronizado: false)
        ]

        // Suscribirse al estado reactivo de HealthKit
        healthKit.$estadoAppleHealth
            .receive(on: DispatchQueue.main)
            .assign(to: &$estadoAppleHealth)

        // Actualizar fila de Apple Health en dispositivosConectados cuando cambia el estado
        healthKit.$estadoAppleHealth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] estado in
                self?.actualizarDispositivoAppleHealth(estado: estado)
            }
            .store(in: &cancellables)

        // Escuchar estado de sesión de Supabase
        SupabaseManager.shared.$estadoSesion
            .receive(on: DispatchQueue.main)
            .sink { [weak self] estado in
                if case .autenticado = estado {
                    self?.isLoggedIn = true
                } else {
                    self?.isLoggedIn = false
                }
            }
            .store(in: &cancellables)

        // Restaurar estado HealthKit desde UserDefaults (sin mostrar dialogs)
        healthKit.restaurarEstadoGuardado()
    }

    // MARK: - Gestión de Medicamentos

    func agregarMedicamento(nombre: String, dosis: Double, frecuencia: FrecuenciaMedicacion) {
        medicamentos.append(Medicamento(nombre: nombre, dosisMg: dosis,
                                        frecuencia: frecuencia, fechaInicio: Date()))
    }

    func eliminarMedicamento(at offsets: IndexSet) { medicamentos.remove(atOffsets: offsets) }

    func actualizarMedicamento(_ med: Medicamento) {
        if let idx = medicamentos.firstIndex(where: { $0.id == med.id }) { medicamentos[idx] = med }
    }

    // MARK: - Gestión de Crisis

    func agregarTipoCrisis(etiqueta: String, termino: TerminoILAE, descripcion: String?) {
        tiposCrisis.append(TipoCrisisPersonalizado(etiquetaPaciente: etiqueta,
                                                    terminoClinico: termino,
                                                    descripcion: descripcion))
    }

    func eliminarTipoCrisis(at offsets: IndexSet) { tiposCrisis.remove(atOffsets: offsets) }

    func renombrarCrisis(id: UUID, nuevoNombre: String) {
        if let idx = tiposCrisis.firstIndex(where: { $0.id == id }) {
            tiposCrisis[idx].etiquetaPaciente = nuevoNombre
        }
    }

    // MARK: - Gestión de Contactos

    func agregarContacto(_ c: ContactoEmergencia) {
        var nuevo = c
        if contactosEmergencia.isEmpty { nuevo.esContactoPrincipal = true }
        contactosEmergencia.append(nuevo)
    }

    func eliminarContacto(at offsets: IndexSet) {
        contactosEmergencia.remove(atOffsets: offsets)
        if !contactosEmergencia.isEmpty,
           contactosEmergencia.allSatisfy({ !$0.esContactoPrincipal }) {
            contactosEmergencia[0].esContactoPrincipal = true
        }
    }

    func establecerContactoPrincipal(id: UUID) {
        for idx in contactosEmergencia.indices {
            contactosEmergencia[idx].esContactoPrincipal = (contactosEmergencia[idx].id == id)
        }
    }

    // MARK: - 📄 Exportar Expediente PDF (REAL)

    func generarReporteClinico() {
        Task {
            cargandoPDF = true
            defer { cargandoPDF = false }

            do {
                // 1. Fetch datos desde Supabase (en paralelo)
                async let perfilDB     = SupabaseManager.shared.fetchPerfilClinico()
                async let eventosDB    = SupabaseManager.shared.fetchEventosIctales(dias: 30)

                let (perfilResult, eventosResult) = try await (perfilDB, eventosDB)

                // 2. Generar PDF
                let url = try await ExpedientePDFGenerator.shared.generarExpediente(
                    perfil: perfilResult,
                    medicamentos: medicamentos,
                    eventos: eventosResult,
                    perfilLocal: perfil
                )

                // 3. Lanzar Share Sheet
                pdfURL = url
                mostrandoShareSheet = true

            } catch {
                mensajeError = "No se pudo generar el expediente: \(error.localizedDescription)"
                mostrandoAlertaError = true
            }
        }
    }

    // MARK: - ❤️ Apple Health Toggle

    func toggleAppleHealth() {
        Task {
            if estadoAppleHealth.estaConectado {
                // Desconectar — solo limpiamos estado local
                // (HealthKit no permite revocar permisos desde la app: el usuario debe hacerlo en Ajustes)
                estadoAppleHealth = .sinConectar
                actualizarDispositivoAppleHealth(estado: .sinConectar)
                UserDefaults.standard.removeObject(forKey: "healthkit.lastSync")
            } else {
                // Conectar → solicitar permisos
                await healthKit.requestAndObservePermissions()
            }
        }
    }

    private func actualizarDispositivoAppleHealth(estado: EstadoDispositivo) {
        if let idx = dispositivosConectados.firstIndex(where: { $0.nombre == "Apple Health" }) {
            dispositivosConectados[idx].sincronizado = estado.estaConectado
            if case .autorizado(let fecha) = estado {
                dispositivosConectados[idx].ultimaSincronizacion = fecha
            }
        }
    }

    // MARK: - 🔓 Cerrar Sesión

    func cerrarSesion() {
        Task {
            await SupabaseManager.shared.cerrarSesion()
            // Cleanup mock data locally just in case
            perfil = PerfilUsuario.vacio
            medicamentos = []
            tiposCrisis = []
            contactosEmergencia = []
        }
    }

    // MARK: - 🗑️ Eliminar Cuenta (Cascade Delete via Edge Function)

    func eliminarCuenta() {
        Task {
            cargandoEliminarCuenta = true
            defer { cargandoEliminarCuenta = false }
            do {
                try await SupabaseManager.shared.invocarEliminarCuenta()
                // El signOut ocurre dentro de invocarEliminarCuenta()
                // El router en Epilepsia_APPApp reacciona a estadoSesion → .sinSesion
            } catch {
                mensajeError = error.localizedDescription
                mostrandoAlertaError = true
            }
        }
    }

    // MARK: - Avatar Iniciales

    var inicialesAvatar: String {
        let partes = perfil.nombreCompleto.components(separatedBy: " ").prefix(2)
        return partes.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}
