import Foundation

struct SeizureEvent: Identifiable, Codable {
    let id: UUID
    var date: Date
    
    // Quick Log
    var isQuickLog: Bool = false
    var quickLogType: String? = nil
    var missedMedication: Bool
    var triggers: Set<SeizureTrigger>
    var aura: String? // nil if no aura
    
    // Ictal
    var lossOfAwareness: Bool
    var focalSymptoms: Set<FocalSymptom>? // Only if lossOfAwareness == false
    var automatisms: Bool // Only if lossOfAwareness == true
    var generalizedConvulsion: Bool // Only if lossOfAwareness == true
    var duration: TimeInterval
    
    // Post-Ictal
    var recoveryTime: RecoveryDuration
    var deficits: Set<PostIctalDeficit>
    
    // Risk Calculation
    var recurrenceRisk: Double {
        var risk = 10.0 // Base risk
        
        if missedMedication {
            risk += 40.0
        }
        
        if triggers.contains(.sleepDeprivation) {
            risk += 20.0
        }
        
        if triggers.contains(.feverInfection) {
            risk += 15.0
        }
        
        if triggers.contains(.alcoholDrugs) {
            risk += 15.0
        }
        
        // Aura isolated (if aura exists but no major seizure yet - simplifying logic here based on prompt)
        // Note: The prompt says "Aura aislada (sin progresar a crisis mayor aún)".
        // Since this model represents a recorded event, we assume if they are recording an event,
        // it might be just an aura or a full seizure.
        // For now, if aura is present, add 30%.
        if aura != nil && !aura!.isEmpty {
            risk += 30.0
        }
        
        return min(risk, 100.0) // Cap at 100%
    }
}

enum SeizureTrigger: String, Codable, CaseIterable, Identifiable {
    case sleepDeprivation = "Falta de sueño (<6 hrs)"
    case alcoholDrugs = "Alcohol/Drogas"
    case feverInfection = "Fiebre/Infección"
    case extremeStress = "Estrés extremo"
    case menstruation = "Menstruación"
    case none = "Ninguno"
    
    var id: String { self.rawValue }
}

enum FocalSymptom: String, Codable, CaseIterable, Identifiable {
    case motor = "Motores (sacudidas)"
    case sensory = "Sensitivos (hormigueo)"
    case autonomic = "Autonómicos (sudoración)"
    
    var id: String { self.rawValue }
}

enum RecoveryDuration: String, Codable, CaseIterable, Identifiable {
    case immediate = "Inmediato"
    case lessThan15 = "< 15 min"
    case between15And60 = "15-60 min"
    case moreThan1Hour = "> 1 hora"
    
    var id: String { self.rawValue }
}

enum PostIctalDeficit: String, Codable, CaseIterable, Identifiable {
    case speechDifficulty = "Dificultad para hablar"
    case weakness = "Debilidad en un lado"
    case confusion = "Confusión severa"
    case headache = "Cefalea/Dolor muscular"
    case none = "Ninguno"
    
    var id: String { self.rawValue }
}
