import Foundation
import Observation

@Observable
final class DashboardViewModel {

    func shiftEarningsDisplay(for shift: Shift) -> String {
        String(format: "$%.2f", shift.totalEarnings)
    }

    func shiftOrdersDisplay(for shift: Shift) -> String {
        "\(shift.acceptedCount) / \(shift.orders.count)"
    }

    func shiftDurationDisplay(for shift: Shift) -> String {
        let mins = shift.durationMinutes
        return String(format: "%d:%02d", mins / 60, mins % 60)
    }

    func shiftHourlyDisplay(for shift: Shift) -> String {
        String(format: "$%.0f/hr", shift.estimatedHourlyRate)
    }

    func toggleDoorDash(appState: AppState) {
        appState.isDoorDashOnline.toggle()
        if appState.isDoorDashOnline { DeepLinkService.openDoorDash() }
    }

    func toggleUberEats(appState: AppState) {
        appState.isUberEatsOnline.toggle()
        if appState.isUberEatsOnline { DeepLinkService.openUberEats() }
    }
}
