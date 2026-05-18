import Foundation
import SwiftData
import Observation

@Observable
final class ShiftTrackerViewModel {
    var showLogOrderSheet: Bool = false
    var logPayout: String = ""
    var logDistance: String = ""
    var logPlatform: Platform = .doorDash
    var logWasAccepted: Bool = true

    private let appState: AppState
    private let modelContext: ModelContext

    init(appState: AppState, modelContext: ModelContext) {
        self.appState     = appState
        self.modelContext = modelContext
    }

    var isShiftActive: Bool { appState.currentShift != nil }
    var currentShift: Shift? { appState.currentShift }

    func startShift() {
        let shift = Shift()
        modelContext.insert(shift)
        try? modelContext.save()
        appState.currentShift = shift
    }

    func endShift() {
        appState.currentShift?.isActive = false
        appState.currentShift?.endTime = Date()
        try? modelContext.save()
        appState.currentShift = nil
    }

    func logOrder() {
        guard let shift = appState.currentShift else { return }
        let order = ShiftOrder(
            platform:            logPlatform.rawValue,
            payout:              Double(logPayout) ?? 0,
            pickupDistanceMiles: Double(logDistance) ?? 0,
            wasAccepted:         logWasAccepted
        )
        order.shift = shift
        shift.orders.append(order)
        modelContext.insert(order)
        try? modelContext.save()
        resetLogForm()
        showLogOrderSheet = false
    }

    func csvExport(for shift: Shift) -> String {
        var lines = ["Platform,Payout,Distance(mi),Accepted,Time"]
        for order in shift.orders.sorted(by: { $0.timestamp < $1.timestamp }) {
            let row = "\(order.platform),\(String(format: "%.2f", order.payout)),\(String(format: "%.1f", order.pickupDistanceMiles)),\(order.wasAccepted ? "Yes" : "No"),\(ISO8601DateFormatter().string(from: order.timestamp))"
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    private func resetLogForm() {
        logPayout   = ""
        logDistance = ""
        logPlatform = .doorDash
        logWasAccepted = true
    }
}
