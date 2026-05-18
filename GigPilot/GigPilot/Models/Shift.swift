import Foundation
import SwiftData

@Model
final class Shift {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var orders: [ShiftOrder]

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.orders = []
    }

    var totalEarnings: Double {
        orders.filter(\.wasAccepted).reduce(0) { $0 + $1.payout }
    }

    var acceptedCount: Int {
        orders.filter(\.wasAccepted).count
    }

    var declinedCount: Int {
        orders.filter { !$0.wasAccepted }.count
    }

    var acceptanceRate: Double {
        guard !orders.isEmpty else { return 0 }
        return Double(acceptedCount) / Double(orders.count)
    }

    var durationMinutes: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime) / 60)
    }

    var estimatedHourlyRate: Double {
        let hours = Double(durationMinutes) / 60.0
        guard hours > 0 else { return 0 }
        return totalEarnings / hours
    }
}

@Model
final class ShiftOrder {
    var id: UUID
    var platform: String
    var payout: Double
    var pickupDistanceMiles: Double
    var wasAccepted: Bool
    var timestamp: Date
    var shift: Shift?

    init(
        id: UUID = UUID(),
        platform: String,
        payout: Double,
        pickupDistanceMiles: Double,
        wasAccepted: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.platform = platform
        self.payout = payout
        self.pickupDistanceMiles = pickupDistanceMiles
        self.wasAccepted = wasAccepted
        self.timestamp = timestamp
    }
}
