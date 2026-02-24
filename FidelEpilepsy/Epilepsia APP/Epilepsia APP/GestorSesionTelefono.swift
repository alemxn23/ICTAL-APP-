import WatchConnectivity
import Combine
import Foundation

class GestorSesionTelefono: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = GestorSesionTelefono()
    
    @Published var ultimosDatosRecibidos: DatosSalud?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        procesarDatosRecibidos(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        procesarDatosRecibidos(userInfo)
    }
    
    private func procesarDatosRecibidos(_ diccionarioDatos: [String: Any]) {
        DispatchQueue.main.async {
            if let datosJson = try? JSONSerialization.data(withJSONObject: diccionarioDatos, options: []),
               let datosSalud = try? JSONDecoder().decode(DatosSalud.self, from: datosJson) {
                
                self.ultimosDatosRecibidos = datosSalud
                
                // Enviar a la API
                GestorAPI.shared.enviarDatosSalud(datosSalud)
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
