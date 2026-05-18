import UserNotifications

// Lightweight profile read from UserDefaults app group (no SwiftData in extension process)
private struct ExtFilterProfile {
    let minimumPayout: Double
    let minimumPayPerMile: Double
    let minimumHourlyRate: Double
    let maximumPickupDistanceMiles: Double

    static func load() -> ExtFilterProfile {
        let defaults = UserDefaults(suiteName: "group.com.gigpilot.app") ?? .standard
        return ExtFilterProfile(
            minimumPayout:               defaults.double(forKey: "gp_min_payout").nonzero(or: 5.0),
            minimumPayPerMile:           defaults.double(forKey: "gp_min_ppm").nonzero(or: 1.5),
            minimumHourlyRate:           defaults.double(forKey: "gp_min_hr").nonzero(or: 15.0),
            maximumPickupDistanceMiles:  defaults.double(forKey: "gp_max_dist").nonzero(or: 3.0)
        )
    }
}

private extension Double {
    func nonzero(or fallback: Double) -> Double { self == 0 ? fallback : self }
}

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler    = contentHandler
        bestAttemptContent     = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let content = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let title    = content.title
        let body     = content.body
        let userInfo = content.userInfo

        guard let parsed = NotificationParserService.parse(title: title, body: body, userInfo: userInfo) else {
            contentHandler(content)
            return
        }

        let profile = ExtFilterProfile.load()
        let offer   = buildOffer(from: parsed)
        let result  = scoreOffer(offer, against: profile)

        content.title = "\(result.label) — \(title)"
        contentHandler(content)
    }

    override func serviceExtensionTimeWillExpire() {
        if let handler = contentHandler, let content = bestAttemptContent {
            handler(content)
        }
    }

    // MARK: – Helpers

    private func buildOffer(from parsed: NotificationParserService.ParsedOffer) -> Offer {
        Offer(
            platform:                parsed.platform,
            payout:                  parsed.payout,
            pickupDistanceMiles:     parsed.distanceMiles,
            estimatedDurationMinutes: 25,   // unknown from notification; use conservative estimate
            restaurantName:          parsed.restaurantName
        )
    }

    private func scoreOffer(_ offer: Offer, against profile: ExtFilterProfile) -> ScoringResult {
        if offer.payout < profile.minimumPayout {
            return .decline(reason: "payout below min")
        }
        if offer.pickupDistanceMiles > profile.maximumPickupDistanceMiles && offer.pickupDistanceMiles > 0 {
            return .decline(reason: "distance exceeds max")
        }

        var failures = 0
        if offer.payPerMile < profile.minimumPayPerMile && offer.pickupDistanceMiles > 0 { failures += 1 }
        if offer.estimatedHourlyRate < profile.minimumHourlyRate { failures += 1 }

        if failures == 0 { return .accept(reason: "all criteria met") }
        if failures == 1 { return .marginal(reason: "one criterion below threshold") }
        return .decline(reason: "multiple criteria below threshold")
    }
}
