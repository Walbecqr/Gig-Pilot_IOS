import Foundation
import SwiftData

@Model
final class FilterProfile {
    var id: UUID
    var name: String
    var minimumPayout: Double
    var minimumPayPerMile: Double
    var minimumHourlyRate: Double
    var maximumPickupDistanceMiles: Double
    var preferredOrderTypesJSON: String
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        minimumPayout: Double = 5.0,
        minimumPayPerMile: Double = 1.5,
        minimumHourlyRate: Double = 15.0,
        maximumPickupDistanceMiles: Double = 3.0,
        preferredOrderTypesJSON: String = "[\"food\",\"grocery\",\"convenience\",\"alcohol\",\"unknown\"]",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.minimumPayout = minimumPayout
        self.minimumPayPerMile = minimumPayPerMile
        self.minimumHourlyRate = minimumHourlyRate
        self.maximumPickupDistanceMiles = maximumPickupDistanceMiles
        self.preferredOrderTypesJSON = preferredOrderTypesJSON
        self.isDefault = isDefault
    }

    var preferredOrderTypes: [OrderType] {
        get {
            guard let data = preferredOrderTypesJSON.data(using: .utf8),
                  let raw = try? JSONDecoder().decode([String].self, from: data) else {
                return OrderType.allCases
            }
            return raw.compactMap { OrderType(rawValue: $0) }
        }
        set {
            let raw = newValue.map(\.rawValue)
            let data = (try? JSONEncoder().encode(raw)) ?? Data()
            preferredOrderTypesJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    static func makeStandard() -> FilterProfile {
        FilterProfile(
            name: "Standard",
            minimumPayout: 5.0,
            minimumPayPerMile: 1.5,
            minimumHourlyRate: 15.0,
            maximumPickupDistanceMiles: 3.0,
            isDefault: true
        )
    }

    static func makeRushHour() -> FilterProfile {
        FilterProfile(
            name: "Rush Hour",
            minimumPayout: 7.0,
            minimumPayPerMile: 2.0,
            minimumHourlyRate: 20.0,
            maximumPickupDistanceMiles: 2.0
        )
    }

    static func makeEndOfShift() -> FilterProfile {
        FilterProfile(
            name: "End of Shift",
            minimumPayout: 4.0,
            minimumPayPerMile: 1.0,
            minimumHourlyRate: 12.0,
            maximumPickupDistanceMiles: 5.0
        )
    }
}
