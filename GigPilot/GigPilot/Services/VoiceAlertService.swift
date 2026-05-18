import AVFoundation
import Observation

@Observable
final class VoiceAlertService: NSObject {
    var isEnabled: Bool = true

    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard isEnabled, !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate  = 0.52
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func speakResult(_ result: ScoringResult, offer: Offer) {
        let script = OfferScoringEngine.voiceScript(for: result, offer: offer)
        speak(script)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
