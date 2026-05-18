import Foundation
import Observation

@Observable
final class OfferEvaluatorViewModel {
    var payout: String = ""
    var distanceMiles: String = ""
    var durationMinutes: String = ""
    var selectedPlatform: Platform = .doorDash
    var selectedOrderType: OrderType = .food
    var scoringResult: ScoringResult?
    var scoredOffer: Offer?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var canScore: Bool {
        payoutValue > 0 && distanceValue >= 0
    }

    var payoutValue:    Double { Double(payout)          ?? 0 }
    var distanceValue:  Double { Double(distanceMiles)   ?? 0 }
    var durationValue:  Double { Double(durationMinutes) ?? 0 }

    func score() {
        guard let profile = appState.activeFilterProfile else { return }

        let offer = Offer(
            platform:               selectedPlatform,
            payout:                 payoutValue,
            pickupDistanceMiles:    distanceValue,
            estimatedDurationMinutes: durationValue,
            orderType:              selectedOrderType
        )

        let result = OfferScoringEngine.score(offer: offer, against: profile)
        scoringResult = result
        scoredOffer   = offer
        appState.lastEvaluatedOffer  = offer
        appState.lastScoringResult   = result

        if appState.voiceAlertsEnabled {
            appState.voice.speakResult(result, offer: offer)
        }
    }

    func reset() {
        payout          = ""
        distanceMiles   = ""
        durationMinutes = ""
        scoringResult   = nil
        scoredOffer     = nil
    }
}
