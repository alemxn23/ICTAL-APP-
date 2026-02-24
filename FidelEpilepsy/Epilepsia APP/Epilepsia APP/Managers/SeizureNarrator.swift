import AVFoundation

/// Singleton para narración de voz durante eventos epilépticos.
/// Usa la voz en español de México (es-MX) para dar instrucciones en tiempo real.
final class SeizureNarrator: NSObject, AVSpeechSynthesizerDelegate {
    
    static let shared = SeizureNarrator()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled: Bool = true
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    // MARK: - Public API
    
    /// Habla el texto dado en voz alta en español (México).
    func speak(_ text: String) {
        guard isEnabled else { return }
        
        // Si ya está hablando, no interrumpir
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.48              // Velocidad clara, no rápida
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 0.3
        
        synthesizer.speak(utterance)
    }
    
    /// Detiene la narración inmediatamente.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Activa o desactiva la narración de voz.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { stop() }
    }
    
    // MARK: - Audio Session
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback permite sonar sobre modo silencio del teléfono (crítico en emergencia)
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("SeizureNarrator: Error configurando sesión de audio: \(error)")
        }
    }
}
