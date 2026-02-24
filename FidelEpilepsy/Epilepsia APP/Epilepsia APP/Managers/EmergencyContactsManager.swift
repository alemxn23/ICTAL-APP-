import Foundation
import CoreLocation
import MessageUI

// MARK: - Emergency Contact Model

struct EmergencyContact: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var relationship: String
}

// MARK: - Emergency Contacts Manager

final class EmergencyContactsManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = EmergencyContactsManager()
    
    @Published var contacts: [EmergencyContact] = []
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationStatus: String = "Obteniendo ubicación..."
    
    private let locationManager = CLLocationManager()
    private let storageKey = "emergencyContacts_v1"
    
    private override init() {
        super.init()
        loadContacts()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Contact Persistence
    
    func addContact(_ contact: EmergencyContact) {
        contacts.append(contact)
        saveContacts()
    }
    
    func removeContact(at offsets: IndexSet) {
        contacts.remove(atOffsets: offsets)
        saveContacts()
    }
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadContacts() {
        if let saved = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: saved) {
            contacts = decoded
        } else {
            // Demo contact for first launch
            contacts = [
                EmergencyContact(name: "Contacto Emergencia", phone: "5555555555", relationship: "Familiar")
            ]
        }
    }
    
    // MARK: - Location
    
    func requestLocationForEmergency() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc.coordinate
        locationStatus = "Ubicación obtenida ✓"
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatus = "No se pudo obtener la ubicación"
        print("LocationManager error: \(error)")
    }
    
    // MARK: - SMS Builder
    
    /// Construye el mensaje de emergencia con ubicación GPS.
    func buildEmergencyMessage(coordinate: CLLocationCoordinate2D?) -> String {
        let baseMsg = "🚨 ALERTA ICTAL: \(getUserName()) tiene una crisis epiléptica activa en este momento y necesita ayuda URGENTE."
        
        if let coord = coordinate {
            let mapsLink = "https://maps.google.com/?q=\(coord.latitude),\(coord.longitude)"
            return baseMsg + " Ubicación en tiempo real: \(mapsLink) — Enviado por FidelEpilepsy"
        } else {
            return baseMsg + " No se pudo obtener ubicación GPS. — Enviado por FidelEpilepsy"
        }
    }
    
    private func getUserName() -> String {
        return UserDefaults.standard.string(forKey: "userName") ?? "El paciente"
    }
    
    /// Abre la pantalla de SMS de iOS pre-rellenada para cada contacto.
    /// Returns: lista de números de teléfono para el SMS compose.
    func getPhoneNumbers() -> [String] {
        return contacts.map { $0.phone }
    }
}
