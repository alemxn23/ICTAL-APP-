import Foundation
import AVFoundation
import WatchKit

/// Singleton for voice narration and haptic feedback during epileptic events on the Apple Watch.
final class WatchSeizureNarrator: NSObject, AVSpeechSynthesizerDelegate {
    
    static let shared = WatchSeizureNarrator()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isEnabled: Bool = true
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    // MARK: - Public API
    
    /// Speaks the given text in Mexican Spanish and triggers a haptic alert.
    func speak(_ text: String) {
        guard isEnabled else { return }
        
        // Interrupt if speaking
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        
        // Haptic feedback to get user attention on the wrist
        WKInterfaceDevice.current().play(.notification)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = 0.48 // Clear, easy to understand rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 0.3
        
        synthesizer.speak(utterance)
    }
    
    /// Immediately stop narration.
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled { stop() }
    }
    
    // MARK: - Audio Session
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("WatchSeizureNarrator: Error configuring audio session: \(error)")
        }
    }
}
