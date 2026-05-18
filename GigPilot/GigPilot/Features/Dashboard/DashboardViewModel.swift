import Foundation
import SwiftData
import Observation

@Observable
final class DashboardViewModel {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var currentShift: Shift? { appState.currentShift }

    var shiftEarningsDisplay: String {
        guard let shift = appState.currentShift else { return "$0.00" }
        return String(format: "$%.2f", shift.totalEarnings)
    }

    var shiftOrdersDisplay: String {
        guard let shift = appState.currentShift else { return "0" }
        return "\(shift.acceptedCount) / \(shift.orders.count)"
    }

    var shiftDurationDisplay: String {
        guard let shift = appState.currentShift else { return "0:00" }
        let mins = shift.durationMinutes
        return String(format: "%d:%02d", mins / 60, mins % 60)
    }

    var shiftHourlyDisplay: String {
        guard let shift = appState.currentShift else { return "$0/hr" }
        return String(format: "$%.0f/hr", shift.estimatedHourlyRate)
    }

    func toggleDoorDash() {
        appState.isDoorDashOnline.toggle()
        if appState.isDoorDashOnline { DeepLinkService.openDoorDash() }
    }

    func toggleUberEats() {
        appState.isUberEatsOnline.toggle()
        if appState.isUberEatsOnline { DeepLinkService.openUberEats() }
    }
}
