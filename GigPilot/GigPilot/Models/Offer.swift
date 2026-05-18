import Foundation

enum Platform: String, Codable, CaseIterable, Equatable {
    case doorDash = "DoorDash"
    case uberEats = "Uber Eats"
    case unknown = "Unknown"
}

enum OrderType: String, Codable, CaseIterable, Equatable {
    case food = "food"
    case grocery = "grocery"
    case convenience = "convenience"
    case alcohol = "alcohol"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .food: return "Food"
        case .grocery: return "Grocery"
        case .convenience: return "Convenience"
        case .alcohol: return "Alcohol"
        case .unknown: return "Other"
        }
    }
}

struct Offer: Identifiable, Equatable {
    let id: UUID
    let platform: Platform
    let payout: Double
    let pickupDistanceMiles: Double
    let estimatedDurationMinutes: Double
    let restaurantName: String?
    let orderType: OrderType?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        platform: Platform,
        payout: Double,
        pickupDistanceMiles: Double,
        estimatedDurationMinutes: Double,
        restaurantName: String? = nil,
        orderType: OrderType? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.platform = platform
        self.payout = payout
        self.pickupDistanceMiles = pickupDistanceMiles
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.restaurantName = restaurantName
        self.orderType = orderType
        self.timestamp = timestamp
    }

    var payPerMile: Double {
        guard pickupDistanceMiles > 0 else { return 0 }
        return payout / pickupDistanceMiles
    }

    var estimatedHourlyRate: Double {
        guard estimatedDurationMinutes > 0 else { return 0 }
        return (payout / estimatedDurationMinutes) * 60.0
    }
}
