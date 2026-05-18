import Foundation
import CoreLocation
import MapKit
import Observation

@Observable
final class ZoneMapViewModel {
    var zones: [Zone] = Zone.veroBeachZones
    var selectedZone: Zone?
    var showZoneSheet: Bool = false

    static let veroBeachRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 27.6386, longitude: -80.3973),
        span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
    )

    func setHotness(_ hotness: ZoneHotness, for zone: Zone) {
        if let idx = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[idx].hotness = hotness
        }
        showZoneSheet = false
        selectedZone  = nil
    }

    func tapZone(_ zone: Zone) {
        selectedZone  = zone
        showZoneSheet = true
    }
}
