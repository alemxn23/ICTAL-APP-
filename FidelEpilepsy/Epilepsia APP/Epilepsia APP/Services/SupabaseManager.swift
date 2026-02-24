import Foundation
import Combine

// MARK: - SupabaseManager
// Nota: Requiere el paquete supabase-swift en Xcode:
// File → Add Package Dependency → https://github.com/supabase/supabase-swift
// Las credenciales se leen desde Secrets.plist (nunca exponerlas en código fuente)

// ─────────────────────────────────────────────────────────────────────────────
// Para compilar SIN el paquete instalado aún, toda la API real de Supabase
// está encapsulada aquí con imports condicionales. El resto del proyecto
// solo interactúa con SupabaseManager, no con Supabase directamente.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Modelos de Respuesta Supabase

struct PerfilClinicoDB: Codable {
    let id: String
    let user_id: String
    let nombre_completo: String?
    let correo: String?
    let fecha_nacimiento: String?
    let sexo: String?
    let peso_kg: Int?
}

struct EventoIctalDB: Codable {
    let id: String
    let user_id: String
    let fecha_inicio: String
    let duracion_segundos: Int?
    let tipo_crisis: String?
    let intensidad: Int?
    let nota_paciente: String?
}

// MARK: - Estado de Sesión

enum EstadoSesion {
    case verificando
    case autenticado(uid: String, email: String)
    case sinSesion
}

// MARK: - SupabaseManager

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    // MARK: Estado publicado
    @Published var estadoSesion: EstadoSesion = .verificando
    @Published var errorMensaje: String?

    var sesionActiva: Bool {
        if case .autenticado = estadoSesion { return true }
        return false
    }

    var userID: String? {
        if case .autenticado(let uid, _) = estadoSesion { return uid }
        return nil
    }

    // MARK: Configuración desde Secrets.plist
    private let supabaseURL: URL
    private let anonKey: String

    private init() {
        // Lee credenciales desde Secrets.plist (NO del código fuente)
        guard
            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: String],
            let urlString = dict["SUPABASE_URL"],
            let key = dict["SUPABASE_ANON_KEY"],
            let url = URL(string: urlString)
        else {
            // Credenciales de placeholder para desarrollo sin Secrets.plist
            self.supabaseURL = URL(string: "https://TU_PROYECTO.supabase.co")!
            self.anonKey = "TU_ANON_KEY"
            self.estadoSesion = .sinSesion
            print("⚠️ [Supabase] Secrets.plist no encontrado — usando placeholders.")
            return
        }
        self.supabaseURL = url
        self.anonKey = key
        Task { await verificarSesionActual() }
    }

    // MARK: - Auth: Verificar sesión persistida

    func verificarSesionActual() async {
        // curl GET /auth/v1/user con token guardado en UserDefaults
        guard let token = UserDefaults.standard.string(forKey: "supabase.access_token"),
              !token.isEmpty else {
            estadoSesion = .sinSesion
            return
        }
        let url = supabaseURL.appendingPathComponent("auth/v1/user")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                limpiarSesionLocal()
                return
            }
            if let json = try? JSONDecoder().decode(SupabaseUser.self, from: data) {
                estadoSesion = .autenticado(uid: json.id, email: json.email ?? "")
            }
        } catch {
            limpiarSesionLocal()
        }
    }

    // MARK: - Auth: Iniciar sesión email/contraseña

    func iniciarSesion(email: String, contrasena: String) async -> Bool {
        let url = supabaseURL.appendingPathComponent("auth/v1/token")
            .appendingQueryItem("grant_type", value: "password")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "password": contrasena]
        req.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let sesion = try? JSONDecoder().decode(SesionSupabase.self, from: data) else {
                errorMensaje = "Credenciales incorrectas. Verifica tu email y contraseña."
                return false
            }
            UserDefaults.standard.set(sesion.access_token, forKey: "supabase.access_token")
            UserDefaults.standard.set(sesion.refresh_token, forKey: "supabase.refresh_token")
            estadoSesion = .autenticado(uid: sesion.user.id, email: sesion.user.email ?? "")
            return true
        } catch {
            errorMensaje = error.localizedDescription
            return false
        }
    }

    // MARK: - Auth: Registrar Usuario nuevo
    
    func registrarUsuario(email: String, contrasena: String) async -> Bool {
        let url = supabaseURL.appendingPathComponent("auth/v1/signup")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "password": contrasena]
        req.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let sesion = try? JSONDecoder().decode(SesionSupabase.self, from: data) else {
                
                // Si la respuesta no es 200, intentar leer el JSON del error de Supabase
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = errorJson["msg"] as? String ?? errorJson["message"] as? String {
                    errorMensaje = "Error al crear cuenta: \(msg)"
                } else {
                    errorMensaje = "Error al crear la cuenta. Intenta de nuevo."
                }
                return false
            }
            
            // Si Supabase requiere confirmación de email, el access_token puede venir nulo.
            // Para cuentas autoconfirmadas (configurado en tu proyecto Supabase), llega un token válido.
            if !sesion.access_token.isEmpty {
                UserDefaults.standard.set(sesion.access_token, forKey: "supabase.access_token")
                UserDefaults.standard.set(sesion.refresh_token, forKey: "supabase.refresh_token")
                estadoSesion = .autenticado(uid: sesion.user.id, email: sesion.user.email ?? "")
                return true
            } else {
                errorMensaje = "Cuenta creada. Verifica tu correo para confirmar."
                // No autenticamos totalmente hasta que inicie sesión o confirme.
                return false
            }
            
        } catch {
            errorMensaje = error.localizedDescription
            return false
        }
    }

    // MARK: - Auth: Cerrar sesión

    func cerrarSesion() async {
        guard let token = UserDefaults.standard.string(forKey: "supabase.access_token") else {
            limpiarSesionLocal()
            return
        }
        // Invalidar token en el servidor
        var req = URLRequest(url: supabaseURL.appendingPathComponent("auth/v1/logout"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        _ = try? await URLSession.shared.data(for: req)
        limpiarSesionLocal()
    }

    private func limpiarSesionLocal() {
        // 🔴 GDPR / Limpieza médica: borrar todo dato sensible en caché
        UserDefaults.standard.removeObject(forKey: "supabase.access_token")
        UserDefaults.standard.removeObject(forKey: "supabase.refresh_token")
        UserDefaults.standard.removeObject(forKey: "perfil.cache")
        UserDefaults.standard.synchronize()
        estadoSesion = .sinSesion
    }

    // MARK: - Fetch: Perfil Clínico

    func fetchPerfilClinico() async throws -> PerfilClinicoDB? {
        guard let uid = userID, let token = accessToken else { return nil }
        var url = supabaseURL.appendingPathComponent("rest/v1/perfil_clinico")
        url = url.appendingQueryItem("user_id", value: "eq.\(uid)")
             .appendingQueryItem("select", value: "*")
             .appendingQueryItem("limit", value: "1")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: req)
        let lista = try JSONDecoder().decode([PerfilClinicoDB].self, from: data)
        return lista.first
    }

    // MARK: - Fetch: Eventos Ictales (últimos N días)

    func fetchEventosIctales(dias: Int = 30) async throws -> [EventoIctalDB] {
        guard let uid = userID, let token = accessToken else { return [] }
        let fecha = ISO8601DateFormatter().string(from: Calendar.current.date(
            byAdding: .day, value: -dias, to: Date()) ?? Date())

        var url = supabaseURL.appendingPathComponent("rest/v1/eventos_ictales")
        url = url.appendingQueryItem("user_id", value: "eq.\(uid)")
             .appendingQueryItem("fecha_inicio", value: "gte.\(fecha)")
             .appendingQueryItem("order", value: "fecha_inicio.desc")
             .appendingQueryItem("select", value: "*")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode([EventoIctalDB].self, from: data)
    }

    // MARK: - Edge Function: Eliminar Cuenta (Cascade Delete)

    func invocarEliminarCuenta() async throws {
        guard let token = accessToken else {
            throw SupabaseError.noAutenticado
        }
        let url = supabaseURL.appendingPathComponent("functions/v1/eliminar-cuenta")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "{}".data(using: .utf8)

        let (_, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw SupabaseError.errorServidor("Error al eliminar la cuenta. Intenta de nuevo.")
        }
        await cerrarSesion()
    }

    // MARK: - Helpers

    private var accessToken: String? {
        UserDefaults.standard.string(forKey: "supabase.access_token")
    }
}

// MARK: - Tipos Auth Internos

private struct SupabaseUser: Codable {
    let id: String
    let email: String?
}

private struct SesionSupabase: Codable {
    let access_token: String
    let refresh_token: String
    let user: SupabaseUser
}

enum SupabaseError: LocalizedError {
    case noAutenticado
    case errorServidor(String)

    var errorDescription: String? {
        switch self {
        case .noAutenticado: return "No hay una sesión activa."
        case .errorServidor(let msg): return msg
        }
    }
}

// MARK: - URL Extension helpers

private extension URL {
    func appendingQueryItem(_ name: String, value: String) -> URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        var items = comps.queryItems ?? []
        items.append(URLQueryItem(name: name, value: value))
        comps.queryItems = items
        return comps.url!
    }
}
