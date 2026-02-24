import Foundation

struct DatosSalud: Codable {
    let frecuenciaCardiaca: Double
    let variabilidadFrecuenciaCardiaca: Double
    let marcaTiempo: Date
    
    // Campos del Algoritmo ICTAL
    let nivelRiesgo: String // "NORMAL", "AURA_RIESGO_ALTO", "CRISIS_INMINENTE"
    let motivoDisparo: String // Descripción del gatillo
    let frecuenciaBasal: Double? // Frecuencia cardíaca en reposo actual
    let puntuacionZHRV: Double? // Z-Score de la VFC actual
    let estadoAceleracion: String // "REPOSO", "ACTIVO"
}
