import SwiftUI
import ContactsUI

// MARK: - PerfilView (Tab Principal)

struct PerfilView: View {
    @StateObject private var vm = PerfilViewModel()

    @State private var mostrandoSheetMedicamento  = false
    @State private var mostrandoSheetCrisis       = false
    @State private var mostrandoContactPicker     = false
    @State private var mostrandoSheetFisiologico  = false
    @State private var mostrandoEditarCrisis: TipoCrisisPersonalizado? = nil
    @State private var nombreEditado = ""

    // Legal links
    @State private var mostrandoPrivacidad = false
    @State private var mostrandoTerminos   = false
    @State private var mostrandoRelevo     = false

    // HealthKit denegado → modal explicativo
    @State private var mostrandoAlertaHealthKitDenegado = false

    // Auth Modal para Lazy Login
    @State private var mostrandoAuthModal = false

    var body: some View {
        NavigationView {
            if !vm.isLoggedIn {
                // GUEST STATE
                GuestProfileView(vm: vm, mostrandoAuthModal: $mostrandoAuthModal)
                    .sheet(isPresented: $mostrandoAuthModal) {
                        AuthModalView(vm: vm)
                    }
            } else {
                // AUTHENTICATED DASHBOARD
            ZStack {
                Color.Medical.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        CabeceraUsuarioView(vm: vm)
                        TarjetaFisiologicaView(vm: vm, mostrandoSheet: $mostrandoSheetFisiologico)
                        TarjetaRedApoyoView(vm: vm, mostrandoContactPicker: $mostrandoContactPicker)
                        TarjetaDiagnosticoView(
                            vm: vm,
                            mostrandoSheetMed: $mostrandoSheetMedicamento,
                            mostrandoSheetCrisis: $mostrandoSheetCrisis,
                            mostrandoEditarCrisis: $mostrandoEditarCrisis,
                            nombreEditado: $nombreEditado
                        )
                        TarjetaGestionClinicaView(
                            vm: vm,
                            mostrandoPrivacidad: $mostrandoPrivacidad,
                            mostrandoTerminos: $mostrandoTerminos,
                            mostrandoRelevo: $mostrandoRelevo,
                            mostrandoAlertaHealthKit: $mostrandoAlertaHealthKitDenegado
                        )
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // PDF Loading Overlay
                if vm.cargandoPDF {
                    PDFLoadingOverlay()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            // MARK: Sheets
            .sheet(isPresented: $mostrandoSheetFisiologico) {
                EditarFisiologicoSheet(vm: vm)
            }
            .sheet(isPresented: $mostrandoContactPicker) {
                ContactPickerRepresentable { vm.agregarContacto($0) }.ignoresSafeArea()
            }
            .sheet(isPresented: $mostrandoSheetMedicamento) {
                AgregarMedicamentoView(vm: vm)
            }
            .sheet(isPresented: $mostrandoSheetCrisis) {
                AgregarTipoCrisisView(vm: vm)
            }
            // Legal links → SFSafariViewController
            .sheet(isPresented: $mostrandoPrivacidad) {
                SafariView(url: LegalURLs.shared.privacidad)
            }
            .sheet(isPresented: $mostrandoTerminos) {
                SafariView(url: LegalURLs.shared.terminos)
            }
            .sheet(isPresented: $mostrandoRelevo) {
                SafariView(url: LegalURLs.shared.relevo)
            }
            // Share Sheet (PDF)
            .sheet(isPresented: $vm.mostrandoShareSheet) {
                if let url = vm.pdfURL {
                    ShareSheetRepresentable(items: [url])
                        .ignoresSafeArea()
                }
            }
            // MARK: Alerts
            .alert("Editar Etiqueta", isPresented: Binding(
                get: { mostrandoEditarCrisis != nil },
                set: { if !$0 { mostrandoEditarCrisis = nil } }
            )) {
                TextField("Nombre", text: $nombreEditado)
                Button("Guardar") {
                    if let crisis = mostrandoEditarCrisis, !nombreEditado.isEmpty {
                        vm.renombrarCrisis(id: crisis.id, nuevoNombre: nombreEditado)
                    }
                    mostrandoEditarCrisis = nil
                }
                Button("Cancelar", role: .cancel) { mostrandoEditarCrisis = nil }
            } message: {
                Text("¿Cómo quieres llamar a esta crisis?")
            }
            .alert("Apple Health", isPresented: $mostrandoAlertaHealthKitDenegado) {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("El acceso a Apple Health fue denegado. Ve a Ajustes → Privacidad y Seguridad → Salud → ICTAL y activa los permisos.")
            }
            .alert("Cerrar Sesión", isPresented: $vm.mostrandoAlertaCerrarSesion) {
                Button("Cerrar Sesión", role: .destructive) { vm.cerrarSesion() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Estás seguro de que deseas cerrar sesión?")
            }
            .alert("Eliminar Cuenta", isPresented: $vm.mostrandoAlertaEliminarCuenta) {
                Button("Eliminar Cuenta", role: .destructive) { vm.eliminarCuenta() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("⚠️ Esta acción es irreversible y destruirá tu diario clínico por completo. No podrás recuperar ningún registro.")
            }
            .alert("Error", isPresented: $vm.mostrandoAlertaError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.mensajeError)
            }
            // Observar estado denegado de HealthKit para mostrar alerta
            .onChange(of: vm.estadoAppleHealth) { estado in
                if case .denegado = estado {
                    mostrandoAlertaHealthKitDenegado = true
                }
            }
            } // End of if vm.isLoggedIn block
        }
    }
}


// MARK: - PDF Loading Overlay

private struct PDFLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.Medical.accent))
                    .scaleEffect(1.4)
                Text("Generando expediente…")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text("Consultando datos clínicos")
                    .font(.system(size: 12))
                    .foregroundColor(Color.Medical.textSecondary)
            }
            .padding(32)
            .background(Color.Medical.card)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }
}

// MARK: - UIActivityViewController Bridge

struct ShareSheetRepresentable: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = [.assignToContact, .addToReadingList]
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 0. Cabecera de Usuario

private struct CabeceraUsuarioView: View {
    @ObservedObject var vm: PerfilViewModel

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.Medical.accent, Color(hex: "5856D6")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.Medical.accent.opacity(0.35), radius: 12, x: 0, y: 6)
                Text(vm.inicialesAvatar)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.perfil.nombreCompleto)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.Medical.textPrimary)
                Text(vm.perfil.correo)
                    .font(.system(size: 14))
                    .foregroundColor(Color.Medical.textSecondary)
                HStack(spacing: 5) {
                    Circle().fill(Color.Medical.safe).frame(width: 7, height: 7)
                    Text("Cuenta Activa")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.Medical.safe)
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.Medical.safe.opacity(0.12)).clipShape(Capsule())
            }
            Spacer()
        }
        .padding(20)
        .background(Color.Medical.card)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - 1. Tarjeta Fisiológica

private struct TarjetaFisiologicaView: View {
    @ObservedObject var vm: PerfilViewModel
    @Binding var mostrandoSheet: Bool

    var body: some View {
        CardContainer(titulo: "Perfil Fisiológico",
                      icono: "staroflife.fill",
                      iconoColor: Color(hex: "32D7A0"),
                      botonAccion: ("Editar", { mostrandoSheet = true })) {
            HStack(spacing: 12) {
                FisioDataCell(icono: "calendar",      iconoColor: Color.Medical.accent,
                              etiqueta: "Edad",  valor: "\(vm.perfil.edad) años")
                FisioDataCell(icono: "scalemass.fill", iconoColor: Color(hex: "FF9F0A"),
                              etiqueta: "Peso",  valor: "\(vm.perfil.pesoKg) kg")
                FisioDataCell(icono: "figure.stand",
                              iconoColor: vm.perfil.sexo == .femenino ? Color(hex: "FF375F") : Color.Medical.accent,
                              etiqueta: "Sexo",  valor: vm.perfil.sexo.rawValue)
            }
            if vm.perfil.sexo.requiereAlertaTeratogenica {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "FF9F0A")).font(.caption)
                    Text("Tu médico revisará compatibilidad de FAE con riesgo teratogénico.")
                        .font(.system(size: 12)).foregroundColor(Color.Medical.textSecondary)
                }
                .padding(10)
                .background(Color(hex: "FF9F0A").opacity(0.08)).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "FF9F0A").opacity(0.2), lineWidth: 1))
            }
        }
    }
}

private struct FisioDataCell: View {
    let icono: String; let iconoColor: Color; let etiqueta: String; let valor: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icono).font(.system(size: 18)).foregroundColor(iconoColor)
            Text(etiqueta).font(.system(size: 11, weight: .medium)).foregroundColor(Color.Medical.textSecondary)
            Text(valor).font(.system(size: 16, weight: .bold)).foregroundColor(Color.Medical.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color.white.opacity(0.04)).cornerRadius(12)
    }
}

// MARK: - 2. Tarjeta Red de Apoyo

private struct TarjetaRedApoyoView: View {
    @ObservedObject var vm: PerfilViewModel
    @Binding var mostrandoContactPicker: Bool

    var body: some View {
        CardContainer(titulo: "Red de Apoyo", icono: "person.2.fill",
                      iconoColor: Color(hex: "FF375F"),
                      botonAccion: ("Añadir", { mostrandoContactPicker = true })) {
            if vm.contactosEmergencia.isEmpty {
                EmptyStateRow(mensaje: "Sin contactos de emergencia", icono: "person.badge.plus")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.contactosEmergencia.enumerated()), id: \.element.id) { idx, c in
                        ContactoRow(contacto: c, onSetPrincipal: { vm.establecerContactoPrincipal(id: c.id) })
                        if idx < vm.contactosEmergencia.count - 1 {
                            Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)
                        }
                    }
                }
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundColor(Color.Medical.accent).font(.system(size: 13)).padding(.top, 1)
                Text("El contacto principal será marcado automáticamente al pulsar **REGISTRAR CRISIS AHORA** en la pantalla principal.")
                    .font(.system(size: 12)).foregroundColor(Color.Medical.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.Medical.accent.opacity(0.07)).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.Medical.accent.opacity(0.15), lineWidth: 1))
        }
    }
}

private struct ContactoRow: View {
    let contacto: ContactoEmergencia; let onSetPrincipal: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(contacto.esContactoPrincipal ? Color(hex: "FF375F").opacity(0.2) : Color.white.opacity(0.06)).frame(width: 40, height: 40)
                Image(systemName: contacto.esContactoPrincipal ? "star.fill" : "person.fill").font(.system(size: 16))
                    .foregroundColor(contacto.esContactoPrincipal ? Color(hex: "FF375F") : Color.Medical.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(contacto.nombre).font(.system(size: 15, weight: .semibold)).foregroundColor(Color.Medical.textPrimary)
                    if contacto.esContactoPrincipal {
                        Text("PRINCIPAL").font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "FF375F"))
                            .padding(.horizontal, 6).padding(.vertical, 2).background(Color(hex: "FF375F").opacity(0.15)).clipShape(Capsule())
                    }
                }
                Text("\(contacto.relacion) · \(contacto.telefono)").font(.system(size: 13)).foregroundColor(Color.Medical.textSecondary)
            }
            Spacer()
            if !contacto.esContactoPrincipal {
                Button(action: onSetPrincipal) {
                    Text("Principal").font(.system(size: 12, weight: .medium)).foregroundColor(Color.Medical.accent)
                        .padding(.horizontal, 10).padding(.vertical, 5).background(Color.Medical.accent.opacity(0.12)).clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 3. Tarjeta Diagnóstico

private struct TarjetaDiagnosticoView: View {
    @ObservedObject var vm: PerfilViewModel
    @Binding var mostrandoSheetMed: Bool
    @Binding var mostrandoSheetCrisis: Bool
    @Binding var mostrandoEditarCrisis: TipoCrisisPersonalizado?
    @Binding var nombreEditado: String

    var body: some View {
        VStack(spacing: 16) {
            CardContainer(titulo: "Mis Tipos de Crisis", icono: "waveform.path.ecg.rectangle.fill",
                          iconoColor: Color(hex: "FF9F0A"),
                          botonAccion: ("Añadir", { mostrandoSheetCrisis = true })) {
                if vm.tiposCrisis.isEmpty {
                    EmptyStateRow(mensaje: "Aún no has registrado tipos de crisis", icono: "plus.circle")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.tiposCrisis.enumerated()), id: \.element.id) { idx, crisis in
                            Button { nombreEditado = crisis.etiquetaPaciente; mostrandoEditarCrisis = crisis } label: {
                                CrisisRow(crisis: crisis)
                            }.buttonStyle(.plain)
                            if idx < vm.tiposCrisis.count - 1 {
                                Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)
                            }
                        }
                    }
                }
                Text("Toca una crisis para renombrarla. Tu médico asignará el código ILAE.")
                    .font(.system(size: 11)).foregroundColor(Color.Medical.neutral).padding(.top, 4)
            }
            CardContainer(titulo: "Mis Medicamentos", icono: "pills.fill",
                          iconoColor: Color(hex: "32ADE6"),
                          botonAccion: ("Añadir", { mostrandoSheetMed = true })) {
                if vm.medicamentos.isEmpty {
                    EmptyStateRow(mensaje: "Sin medicación registrada", icono: "cross.case")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(vm.medicamentos.enumerated()), id: \.element.id) { idx, med in
                            MedicamentoRow(med: med)
                            if idx < vm.medicamentos.count - 1 {
                                Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct CrisisRow: View {
    let crisis: TipoCrisisPersonalizado
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: "FF9F0A").opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: crisis.icono).font(.system(size: 16)).foregroundColor(Color(hex: "FF9F0A"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(crisis.etiquetaPaciente).font(.system(size: 15, weight: .semibold)).foregroundColor(Color.Medical.textPrimary)
                Text(crisis.terminoClinico.rawValue).font(.system(size: 12)).foregroundColor(Color.Medical.neutral)
            }
            Spacer()
            Image(systemName: "pencil").font(.system(size: 13)).foregroundColor(Color.Medical.neutral)
        }
        .padding(.vertical, 10).contentShape(Rectangle())
    }
}

private struct MedicamentoRow: View {
    let med: Medicamento
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: "32ADE6").opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "pills.fill").font(.system(size: 16)).foregroundColor(Color(hex: "32ADE6"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(med.nombre).font(.system(size: 15, weight: .semibold)).foregroundColor(Color.Medical.textPrimary)
                Text("\(Int(med.dosisMg)) mg · \(med.frecuencia.rawValue)").font(.system(size: 12)).foregroundColor(Color.Medical.neutral)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.Medical.neutral.opacity(0.6))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 4. Tarjeta Gestión Clínica y Legal (FUNCIONAL)

private struct TarjetaGestionClinicaView: View {
    @ObservedObject var vm: PerfilViewModel
    @Binding var mostrandoPrivacidad: Bool
    @Binding var mostrandoTerminos: Bool
    @Binding var mostrandoRelevo: Bool
    @Binding var mostrandoAlertaHealthKit: Bool

    var body: some View {
        CardContainer(titulo: "Gestión Clínica y Legal",
                      icono: "shield.lefthalf.filled",
                      iconoColor: Color(hex: "5856D6")) {

            // ── Exportar PDF ──────────────────────────────────────────────────
            Button {
                vm.generarReporteClinico()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(Color.Medical.safe.opacity(0.2)).frame(width: 36, height: 36)
                        if vm.cargandoPDF {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.Medical.safe)).scaleEffect(0.7)
                        } else {
                            Image(systemName: "square.and.arrow.up.fill").font(.system(size: 16)).foregroundColor(Color.Medical.safe)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exportar Expediente (PDF)").font(.system(size: 15, weight: .semibold)).foregroundColor(Color.Medical.textPrimary)
                        Text("Reporte de 30 días para tu médico").font(.system(size: 12)).foregroundColor(Color.Medical.neutral)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.Medical.neutral.opacity(0.5))
                }
                .padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(vm.cargandoPDF)

            Divider().background(Color.Medical.neutral.opacity(0.15))

            // ── Apple Health ──────────────────────────────────────────────────
            Button {
                vm.toggleAppleHealth()
                // Si después del toggle el estado sigue en denegado, la alerta se muestra
                // via .onChange(of: vm.estadoAppleHealth) en PerfilView
            } label: {
                DispositivoRowFuncional(
                    nombre: "Apple Health",
                    icono: "heart.fill",
                    estado: vm.estadoAppleHealth
                )
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)

            // ── Google Fit (placeholder — solo iOS en esta implementación) ────
            DispositivoRowFuncional(
                nombre: "Google Fit",
                icono: "figure.run",
                estado: .noDisponible
            )
            .padding(.vertical, 10)
            .opacity(0.5)

            Divider().background(Color.Medical.neutral.opacity(0.15))

            // ── Legales ────────────────────────────────────────────────────────
            GestionNavButton(icono: "doc.text.fill",       titulo: "Aviso de Privacidad")         { mostrandoPrivacidad = true }
            Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)
            GestionNavButton(icono: "checkmark.seal.fill", titulo: "Términos y Condiciones")      { mostrandoTerminos = true }
            Divider().background(Color.Medical.neutral.opacity(0.15)).padding(.leading, 52)
            GestionNavButton(icono: "cross.case.fill",     titulo: "Relevo de Responsabilidad Médica") { mostrandoRelevo = true }

            Divider().background(Color.Medical.neutral.opacity(0.15))

            // ── Cerrar Sesión ──────────────────────────────────────────────────
            Button { vm.mostrandoAlertaCerrarSesion = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 17))
                        .foregroundColor(Color.Medical.danger).frame(width: 40)
                    Text("Cerrar Sesión").font(.system(size: 16)).foregroundColor(Color.Medical.danger)
                    Spacer()
                }
                .padding(.vertical, 12).contentShape(Rectangle())
            }.buttonStyle(.plain)

            Divider().background(Color.Medical.neutral.opacity(0.15))

            // ── Eliminar Cuenta ────────────────────────────────────────────────
            Button { vm.mostrandoAlertaEliminarCuenta = true } label: {
                HStack {
                    ZStack {
                        if vm.cargandoEliminarCuenta {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.Medical.danger.opacity(0.7))).scaleEffect(0.7).frame(width: 40)
                        } else {
                            Image(systemName: "trash.fill").font(.system(size: 15))
                                .foregroundColor(Color.Medical.danger.opacity(0.7)).frame(width: 40)
                        }
                    }
                    Text("Eliminar Cuenta").font(.system(size: 16)).foregroundColor(Color.Medical.danger.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 12).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(vm.cargandoEliminarCuenta)
        }
    }
}

// MARK: - Dispositivo Row Funcional (con estado reactivo)

private struct DispositivoRowFuncional: View {
    let nombre: String
    let icono: String
    let estado: EstadoDispositivo

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(estado.estaConectado ? Color.Medical.safe.opacity(0.18) : Color.Medical.neutral.opacity(0.12))
                    .frame(width: 36, height: 36)
                if case .solicitandoPermiso = estado {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.Medical.safe)).scaleEffect(0.65)
                } else {
                    Image(systemName: icono).font(.system(size: 16))
                        .foregroundColor(estado.estaConectado ? Color.Medical.safe : Color.Medical.neutral)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(nombre).font(.system(size: 15, weight: .medium)).foregroundColor(Color.Medical.textPrimary)
                Text(estado.textoEstado).font(.system(size: 12))
                    .foregroundColor(estado.estaConectado ? Color.Medical.safe : Color.Medical.neutral)
            }
            Spacer()
            Image(systemName: estado.estaConectado ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(estado.estaConectado ? Color.Medical.safe : Color.Medical.neutral.opacity(0.5))
        }
    }
}

private struct GestionNavButton: View {
    let icono: String; let titulo: String; let accion: () -> Void
    var body: some View {
        Button(action: accion) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(Color.Medical.neutral.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icono).font(.system(size: 16)).foregroundColor(Color.Medical.neutral)
                }
                Text(titulo).font(.system(size: 15)).foregroundColor(Color.Medical.textSecondary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Color.Medical.neutral.opacity(0.4))
            }.padding(.vertical, 10).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

// MARK: - Shared Card Container

private struct CardContainer<Content: View>: View {
    let titulo: String; let icono: String; let iconoColor: Color
    var botonAccion: (label: String, accion: () -> Void)?
    @ViewBuilder let content: Content

    init(titulo: String, icono: String, iconoColor: Color,
         botonAccion: (label: String, accion: () -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.titulo = titulo; self.icono = icono; self.iconoColor = iconoColor
        self.botonAccion = botonAccion; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconoColor.opacity(0.2)).frame(width: 30, height: 30)
                    Image(systemName: icono).font(.system(size: 14, weight: .semibold)).foregroundColor(iconoColor)
                }
                Text(titulo).font(.system(size: 14, weight: .semibold)).foregroundColor(Color.Medical.textSecondary).textCase(.uppercase).tracking(0.6)
                Spacer()
                if let btn = botonAccion {
                    Button(action: btn.accion) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                            Text(btn.label).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color.Medical.accent).padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.Medical.accent.opacity(0.12)).clipShape(Capsule())
                    }
                }
            }
            content
        }
        .padding(18).background(Color.Medical.card).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

private struct EmptyStateRow: View {
    let mensaje: String; let icono: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icono).font(.system(size: 20)).foregroundColor(Color.Medical.neutral.opacity(0.5))
            Text(mensaje).font(.system(size: 14)).foregroundColor(Color.Medical.neutral)
        }.padding(.vertical, 8)
    }
}

// MARK: - Sheet: Editar Datos Fisiológicos

private struct EditarFisiologicoSheet: View {
    @ObservedObject var vm: PerfilViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var sexoSeleccionado: SexoBiologico = .femenino
    @State private var fechaNacimiento: Date = Date()
    @State private var pesoSeleccionado: Int = 70

    var body: some View {
        NavigationView {
            ZStack {
                Color.Medical.background.ignoresSafeArea()
                Form {
                    Section { Picker("Sexo Biológico", selection: $sexoSeleccionado) { ForEach(SexoBiologico.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).listRowBackground(Color.Medical.card).padding(.vertical, 4)
                        DatePicker("Fecha de Nacimiento", selection: $fechaNacimiento, in: ...Date(), displayedComponents: .date).datePickerStyle(.wheel).labelsHidden().listRowBackground(Color.Medical.card).colorScheme(.dark)
                    } header: { Text("Datos Clínicos").foregroundColor(Color.Medical.textSecondary) }
                    Section {
                        Picker("Peso (kg)", selection: $pesoSeleccionado) { ForEach(20...250, id: \.self) { Text("\($0) kg").tag($0) } }.pickerStyle(.wheel).frame(height: 150).listRowBackground(Color.Medical.card).colorScheme(.dark)
                    } header: { Text("Peso Actual").foregroundColor(Color.Medical.textSecondary) }
                    footer: { Text("El peso es esencial para calcular dosis en mg/kg de tus fármacos.").foregroundColor(Color.Medical.neutral) }
                }
                .scrollContentBackground(.hidden).background(Color.Medical.background)
            }
            .navigationTitle("Perfil Fisiológico").navigationBarTitleDisplayMode(.inline).preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Color.Medical.neutral) }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { vm.perfil.sexo = sexoSeleccionado; vm.perfil.fechaNacimiento = fechaNacimiento; vm.perfil.pesoKg = pesoSeleccionado; presentationMode.wrappedValue.dismiss() }.foregroundColor(Color.Medical.accent).fontWeight(.semibold) }
            }
            .onAppear { sexoSeleccionado = vm.perfil.sexo; fechaNacimiento = vm.perfil.fechaNacimiento; pesoSeleccionado = vm.perfil.pesoKg }
        }
    }
}

// MARK: - Sheet: Agregar Medicamento

struct AgregarMedicamentoView: View {
    @ObservedObject var vm: PerfilViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var nombre = ""
    @State private var dosisSeleccionada: Int = 500
    @State private var frecuencia: FrecuenciaMedicacion = .cada12h

    private let faesComunes = ["Ácido Valproico","Carbamazepina","Clobazam","Clonazepam","Eslicarbazepina","Etosuximida","Gabapentina","Lacosamida","Lamotrigina","Levetiracetam","Oxcarbazepina","Perampanel","Fenobarbital","Fenitoína","Pregabalina","Primidona","Topiramato","Vigabatrina","Zonisamida"]
    var faeSugeridos: [String] { guard nombre.count >= 2 else { return [] }; return faesComunes.filter { $0.lowercased().contains(nombre.lowercased()) } }

    var body: some View {
        NavigationView {
            ZStack { Color.Medical.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Nombre del Fármaco", text: $nombre).autocorrectionDisabled().foregroundColor(Color.Medical.textPrimary).listRowBackground(Color.Medical.card)
                        if !faeSugeridos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(faeSugeridos, id: \.self) { s in Button(s) { nombre = s }.font(.system(size: 13, weight: .medium)).foregroundColor(Color.Medical.accent).padding(.horizontal, 12).padding(.vertical, 6).background(Color.Medical.accent.opacity(0.12)).clipShape(Capsule()) } } }.listRowBackground(Color.Medical.card)
                        }
                    } header: { Text("Fármaco Antiepiléptico").foregroundColor(Color.Medical.textSecondary) }
                    Section {
                        Picker("Dosis", selection: $dosisSeleccionada) { ForEach(Array(stride(from: 25, through: 3000, by: 25)), id: \.self) { Text("\($0) mg").tag($0) } }.pickerStyle(.wheel).frame(height: 130).listRowBackground(Color.Medical.card).colorScheme(.dark)
                        Picker("Frecuencia", selection: $frecuencia) { ForEach(FrecuenciaMedicacion.allCases) { Text($0.rawValue).tag($0) } }.listRowBackground(Color.Medical.card).foregroundColor(Color.Medical.textPrimary)
                    } header: { Text("Dosis y Posología").foregroundColor(Color.Medical.textSecondary) }
                    footer: { Text("La dosis se calcula en mg/kg con tu peso registrado.").foregroundColor(Color.Medical.neutral) }
                }
                .scrollContentBackground(.hidden).background(Color.Medical.background)
            }
            .navigationTitle("Añadir Medicación").navigationBarTitleDisplayMode(.inline).preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Color.Medical.neutral) }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { guard !nombre.isEmpty else { return }; vm.agregarMedicamento(nombre: nombre, dosis: Double(dosisSeleccionada), frecuencia: frecuencia); presentationMode.wrappedValue.dismiss() }.foregroundColor(nombre.isEmpty ? Color.Medical.neutral: Color.Medical.accent).fontWeight(.semibold).disabled(nombre.isEmpty) }
            }
        }
    }
}

// MARK: - Sheet: Agregar Tipo de Crisis

struct AgregarTipoCrisisView: View {
    @ObservedObject var vm: PerfilViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var etiqueta = ""; @State private var termino: TerminoILAE = .desconocida; @State private var descripcion = ""

    var body: some View {
        NavigationView {
            ZStack { Color.Medical.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("¿Cómo llamas a esta crisis?", text: $etiqueta).foregroundColor(Color.Medical.textPrimary).listRowBackground(Color.Medical.card)
                        TextField("Descripción o sensación (opcional)", text: $descripcion).foregroundColor(Color.Medical.textPrimary).listRowBackground(Color.Medical.card)
                    } header: { Text("Tus Palabras").foregroundColor(Color.Medical.textSecondary) }
                    footer: { Text("Ej: \"La de temblor fuerte\", \"Me quedo en blanco\"").foregroundColor(Color.Medical.neutral) }
                    Section {
                        Picker("Término Clínico", selection: $termino) { ForEach(TerminoILAE.allCases) { Text($0.rawValue).tag($0) } }.listRowBackground(Color.Medical.card).foregroundColor(Color.Medical.textPrimary)
                    } header: { Text("Clasificación ILAE").foregroundColor(Color.Medical.textSecondary) }
                    footer: { Text("Tu médico actualizará la clasificación clínica correcta.").foregroundColor(Color.Medical.neutral) }
                }
                .scrollContentBackground(.hidden).background(Color.Medical.background)
            }
            .navigationTitle("Nueva Etiqueta").navigationBarTitleDisplayMode(.inline).preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { presentationMode.wrappedValue.dismiss() }.foregroundColor(Color.Medical.neutral) }
                ToolbarItem(placement: .confirmationAction) { Button("Guardar") { guard !etiqueta.isEmpty else { return }; vm.agregarTipoCrisis(etiqueta: etiqueta, termino: termino, descripcion: descripcion.isEmpty ? nil : descripcion); presentationMode.wrappedValue.dismiss() }.foregroundColor(etiqueta.isEmpty ? Color.Medical.neutral : Color.Medical.accent).fontWeight(.semibold).disabled(etiqueta.isEmpty) }
            }
        }
    }
}

// MARK: - CNContactPickerViewController Bridge

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    var onSelectContacto: (ContactoEmergencia) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelectContacto: onSelectContacto) }
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelectContacto: (ContactoEmergencia) -> Void
        init(onSelectContacto: @escaping (ContactoEmergencia) -> Void) { self.onSelectContacto = onSelectContacto }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let nombre = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            let tel = contact.phoneNumbers.first?.value.stringValue ?? ""
            onSelectContacto(ContactoEmergencia(nombre: nombre.isEmpty ? "Sin nombre" : nombre, telefono: tel, relacion: "Familiar"))
        }
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }
}

// MARK: - Guest State (Lazy Login)
struct GuestProfileView: View {
    @ObservedObject var vm: PerfilViewModel
    @Binding var mostrandoAuthModal: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 84, weight: .light))
                    .foregroundColor(Color.Medical.accent)
                    .padding(.bottom, 8)
                
                Text("Tu Perfil Médico")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Inicia sesión o crea una cuenta para guardar tu expediente clínico, sincronizar sensores y configurar tu red de apoyo.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.Medical.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                
                Spacer()
                
                Button {
                    mostrandoAuthModal = true
                } label: {
                    Text("Iniciar Sesión / Registrarse")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black) 
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Medical.accent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Auth Modal Bottom Sheet
struct AuthModalView: View {
    @ObservedObject var vm: PerfilViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var cargando = false
    @State private var errorMensaje: String? = nil
    @State private var esRegistro = false

    var body: some View {
        ZStack {
            Color(hex: "1C1C1E").ignoresSafeArea()
            
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Text(esRegistro ? "Crear Cuenta Nueva" : "Iniciar Sesión")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Form Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    SecureField("Contraseña", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                if let error = errorMensaje {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FF3B30"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Button {
                    Task {
                        cargando = true
                        errorMensaje = nil
                        let exito: Bool
                        
                        if esRegistro {
                            exito = await SupabaseManager.shared.registrarUsuario(email: email, contrasena: password)
                        } else {
                            exito = await SupabaseManager.shared.iniciarSesion(email: email, contrasena: password)
                        }
                        
                        cargando = false
                        if exito {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            errorMensaje = SupabaseManager.shared.errorMensaje ?? "Error de autenticación"
                        }
                    }
                } label: {
                    ZStack {
                        if cargando {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(esRegistro ? "Registrarse" : "Continuar")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.Medical.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .disabled(cargando || email.isEmpty || password.isEmpty)
                .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1.0)
                
                // Toggle Login / Register
                Button {
                    withAnimation {
                        esRegistro.toggle()
                        errorMensaje = nil
                    }
                } label: {
                    Text(esRegistro ? "¿Ya tienes cuenta? Inicia Sesión" : "¿No tienes cuenta? Crea una gratis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Medical.accent)
                }
                .padding(.top, 4)
                
                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2))
                    Text("o").foregroundColor(.gray).font(.system(size: 14, weight: .medium))
                    Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2))
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                
                // Mock Apple Sign In
                Button {
                    vm.isLoggedIn = true
                    vm.perfil.nombreCompleto = "Usuario Apple"
                    vm.perfil.correo = "usuario@privaterelay.appleid.com"
                    // Dejar el perfil vacío simulando un usuario nuevo
                    vm.medicamentos = []
                    vm.tiposCrisis = []
                    vm.contactosEmergencia = []
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo").font(.system(size: 20))
                        Text("Sign in with Apple")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

