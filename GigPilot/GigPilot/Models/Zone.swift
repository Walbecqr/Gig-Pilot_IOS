import Foundation
import CoreLocation

enum ZoneHotness: String, CaseIterable, Equatable {
    case hot = "hot"
    case warm = "warm"
    case dead = "dead"
    case unknown = "unknown"

    var displayName: String {
        rawValue.capitalized
    }

    var colorHex: String {
        switch self {
        case .hot: return "39FF14"
        case .warm: return "FF9F0A"
        case .dead: return "FF3B30"
        case .unknown: return "8E8E93"
        }
    }
}

struct Zone: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let radiusMeters: Double
    var hotness: ZoneHotness

    static func == (lhs: Zone, rhs: Zone) -> Bool {
        lhs.id == rhs.id
    }
}

extension Zone {
    static let veroBeachZones: [Zone] = [
        Zone(id: "downtown",        name: "Downtown Vero",        coordinate: CLLocationCoordinate2D(latitude: 27.6386, longitude: -80.3973), radiusMeters: 600,  hotness: .unknown),
        Zone(id: "miracle-mile",    name: "Miracle Mile",         coordinate: CLLocationCoordinate2D(latitude: 27.6407, longitude: -80.3780), radiusMeters: 500,  hotness: .unknown),
        Zone(id: "us1-corridor",    name: "US-1 Corridor",        coordinate: CLLocationCoordinate2D(latitude: 27.6200, longitude: -80.3700), radiusMeters: 800,  hotness: .unknown),
        Zone(id: "ir-shores",       name: "Indian River Shores",  coordinate: CLLocationCoordinate2D(latitude: 27.6700, longitude: -80.4050), radiusMeters: 700,  hotness: .unknown),
        Zone(id: "airport-area",    name: "Airport / 58th Area",  coordinate: CLLocationCoordinate2D(latitude: 27.6556, longitude: -80.4178), radiusMeters: 600,  hotness: .unknown),
        Zone(id: "sebastian",       name: "Sebastian",            coordinate: CLLocationCoordinate2D(latitude: 27.8168, longitude: -80.4718), radiusMeters: 900,  hotness: .unknown),
        Zone(id: "fort-pierce-n",   name: "Ft. Pierce North",     coordinate: CLLocationCoordinate2D(latitude: 27.4467, longitude: -80.3256), radiusMeters: 700,  hotness: .unknown),
        Zone(id: "treasure-coast",  name: "Treasure Coast Mall",  coordinate: CLLocationCoordinate2D(latitude: 27.6139, longitude: -80.3912), radiusMeters: 500,  hotness: .unknown),
    ]
}
