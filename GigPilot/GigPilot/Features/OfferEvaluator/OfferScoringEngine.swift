import Foundation

final class OfferScoringEngine {

    static func score(offer: Offer, against profile: FilterProfile) -> ScoringResult {
        // Hard declines checked first
        if offer.payout < profile.minimumPayout {
            return .decline(reason: "Payout $\(f2(offer.payout)) below minimum $\(f2(profile.minimumPayout))")
        }

        if offer.pickupDistanceMiles > profile.maximumPickupDistanceMiles {
            return .decline(reason: "Pickup \(f1(offer.pickupDistanceMiles))mi exceeds max \(f1(profile.maximumPickupDistanceMiles))mi")
        }

        // Soft criteria
        let ppm = offer.payPerMile
        let hr  = offer.estimatedHourlyRate

        var failures: [String] = []

        if ppm < profile.minimumPayPerMile {
            failures.append("$\(f2(ppm))/mi below $\(f2(profile.minimumPayPerMile))/mi minimum")
        }

        if hr < profile.minimumHourlyRate && offer.estimatedDurationMinutes > 0 {
            failures.append("~$\(f0(hr))/hr below $\(f0(profile.minimumHourlyRate))/hr minimum")
        }

        if let orderType = offer.orderType {
            let preferred = profile.preferredOrderTypes
            if !preferred.isEmpty && !preferred.contains(orderType) {
                failures.append("\(orderType.displayName) not in preferred types")
            }
        }

        switch failures.count {
        case 0:
            let summary = "$\(f2(offer.payout)) | $\(f2(ppm))/mi | ~$\(f0(hr))/hr"
            return .accept(reason: summary)
        case 1:
            return .marginal(reason: failures[0])
        default:
            return .decline(reason: failures.joined(separator: "; "))
        }
    }

    static func voiceScript(for result: ScoringResult, offer: Offer) -> String {
        let platform = offer.platform.rawValue
        let payoutWords = spokenCurrency(offer.payout)
        let distance = String(format: "%.1f miles", offer.pickupDistanceMiles)

        switch result {
        case .accept:
            return "\(platform) offer. \(payoutWords). \(distance). Accept."
        case .decline:
            return "\(platform) offer. \(payoutWords). Decline."
        case .marginal:
            return "\(platform) offer. \(payoutWords). \(distance). Marginal."
        }
    }

    // MARK: – Helpers

    private static func spokenCurrency(_ amount: Double) -> String {
        let dollars = Int(amount)
        let cents   = Int(((amount - Double(dollars)) * 100).rounded())
        let d = "\(dollars) dollar\(dollars == 1 ? "" : "s")"
        if cents == 0 { return d }
        return "\(d) \(cents) cent\(cents == 1 ? "" : "s")"
    }

    private static func f2(_ v: Double) -> String { String(format: "%.2f", v) }
    private static func f1(_ v: Double) -> String { String(format: "%.1f", v) }
    private static func f0(_ v: Double) -> String { String(format: "%.0f", v) }
}
