import Foundation
import Observation

@Observable
final class AppState {
    var activeFilterProfile: FilterProfile?
    var currentShift: Shift?
    var isDoorDashOnline: Bool = false
    var isUberEatsOnline: Bool = false
    var lastEvaluatedOffer: Offer?
    var lastScoringResult: ScoringResult?

    let voice    = VoiceAlertService()
    let location = LocationService()

    var voiceAlertsEnabled: Bool {
        get { voice.isEnabled }
        set { voice.isEnabled = newValue }
    }

    var isAnyPlatformOnline: Bool {
        isDoorDashOnline || isUberEatsOnline
    }
}
