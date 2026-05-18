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

    func syncActiveProfile() {
        guard let defaults = UserDefaults(suiteName: "group.com.gigpilot.app"),
              let profile = activeFilterProfile else { return }
        defaults.set(profile.minimumPayout,              forKey: "gp_min_payout")
        defaults.set(profile.minimumPayPerMile,          forKey: "gp_min_ppm")
        defaults.set(profile.minimumHourlyRate,          forKey: "gp_min_hr")
        defaults.set(profile.maximumPickupDistanceMiles, forKey: "gp_max_dist")
    }
}
