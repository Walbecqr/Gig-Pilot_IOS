import Foundation

enum NotificationParserService {
    struct ParsedOffer {
        let payout: Double
        let distanceMiles: Double
        let platform: Platform
        let restaurantName: String?
    }

    static func parse(title: String, body: String, userInfo: [AnyHashable: Any]) -> ParsedOffer? {
        let platform = detectPlatform(from: userInfo)
        let combined = "\(title) \(body)"

        guard let payout = extractPayout(from: combined), payout > 0 else { return nil }

        let distance   = extractDistance(from: combined) ?? 0.0
        let restaurant = extractRestaurant(from: combined)

        return ParsedOffer(payout: payout, distanceMiles: distance, platform: platform, restaurantName: restaurant)
    }

    private static func detectPlatform(from userInfo: [AnyHashable: Any]) -> Platform {
        for key in userInfo.keys {
            if let s = (userInfo[key] as? String)?.lowercased() {
                if s.contains("doordash") { return .doorDash }
                if s.contains("ubereats") || s.contains("uber eats") { return .uberEats }
            }
        }
        return .unknown
    }

    private static func extractPayout(from text: String) -> Double? {
        let pattern = #"\$(\d{1,3}(?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[range])
    }

    private static func extractDistance(from text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)\s*mi(?:les?)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[range])
    }

    private static func extractRestaurant(from text: String) -> String? {
        // Matches "• RestaurantName" or "- RestaurantName" after the distance marker
        let pattern = #"mi\s*[•·\-]\s*([^•·\-\n\r]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        let name = String(text[range]).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}
