import Foundation

class GestorAPI {
    static let shared = GestorAPI()
    private let urlPrediccion = URL(string: "http://localhost:8000/predict")!
    private let urlClinica = URL(string: "http://localhost:8000/clinical-report")!
    
    func enviarDatosSalud(_ datos: DatosSalud) {
        enviar(datos, a: urlPrediccion)
    }
    
    func enviarClinicalSnapshot(_ snapshot: ClinicalSnapshot) {
        enviar(snapshot, a: urlClinica)
    }
    
    private func enviar<T: Encodable>(_ objeto: T, a url: URL) {
        var solicitud = URLRequest(url: url)
        solicitud.httpMethod = "POST"
        solicitud.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let datosJson = try JSONEncoder().encode(objeto)
            solicitud.httpBody = datosJson
            
            URLSession.shared.dataTask(with: solicitud) { datos, respuesta, error in
                if let error = error {
                    print("Error enviando datos a \(url): \(error.localizedDescription)")
                    return
                }
                
                if let respuestaHttp = respuesta as? HTTPURLResponse {
                    print("Estado de la respuesta de \(url): \(respuestaHttp.statusCode)")
                }
            }.resume()
        } catch {
            print("Error codificando datos: \(error.localizedDescription)")
        }
    }
}
