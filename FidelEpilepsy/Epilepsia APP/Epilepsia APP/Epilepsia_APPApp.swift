import SwiftUI
import SwiftData

@main
struct Epilepsia_APPApp: App {
    // Auth router — observa el estado de sesión para mostrar Login o App principal
    @StateObject private var supabase = SupabaseManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("No se pudo crear ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(supabase)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Splash / Verificando Sesión

struct SplashAuthView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("ICTAL")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "007AFF")))
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - LoginView

struct LoginView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var email      = ""
    @State private var contrasena = ""
    @State private var cargando   = false
    @State private var mostrandoError = false

    var body: some View {
        ZStack {
            // Fondo con gradiente sutil
            LinearGradient(colors: [Color.black, Color(hex: "0a0a15")],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logotipo
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 84, height: 84)
                            .shadow(color: Color(hex: "007AFF").opacity(0.4), radius: 20, x: 0, y: 10)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    Text("ICTAL")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Monitoreo inteligente de epilepsia")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.5))
                }

                // Formulario
                VStack(spacing: 14) {
                    // Email
                    HStack {
                        Image(systemName: "envelope").foregroundColor(Color(hex: "8E8E93")).frame(width: 24)
                        TextField("", text: $email, prompt: Text("Correo electrónico").foregroundColor(Color(hex: "8E8E93")))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    // Contraseña
                    HStack {
                        Image(systemName: "lock").foregroundColor(Color(hex: "8E8E93")).frame(width: 24)
                        SecureField("", text: $contrasena,
                                    prompt: Text("Contraseña").foregroundColor(Color(hex: "8E8E93")))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    // Error
                    if let error = supabase.errorMensaje {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FF3B30"))
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 28)

                // Botón Iniciar Sesión
                Button {
                    guard !email.isEmpty, !contrasena.isEmpty else { return }
                    cargando = true
                    Task {
                        _ = await supabase.iniciarSesion(email: email, contrasena: contrasena)
                        await MainActor.run { cargando = false }
                    }
                } label: {
                    ZStack {
                        if cargando {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Iniciar Sesión")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        LinearGradient(colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(hex: "007AFF").opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 28)
                .disabled(cargando || email.isEmpty || contrasena.isEmpty)
                .opacity(email.isEmpty || contrasena.isEmpty ? 0.5 : 1.0)

                // Aviso médico
                Text("Este acceso es exclusivo para pacientes registrados.\nNo reemplaza la consulta médica profesional.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
