import SwiftUI
import SwiftData

struct ShiftTrackerView: View {
    @Environment(AppState.self)         private var appState
    @Environment(\.modelContext)        private var modelContext
    @Query(sort: \Shift.startTime, order: .reverse) private var shifts: [Shift]

    @State private var vm             = ShiftTrackerViewModel()
    @State private var showExportSheet = false
    @State private var exportText      = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.spacing) {
                        shiftControlSection
                        if let shift = appState.currentShift {
                            liveStatsSection(shift: shift)
                            ordersSection(shift: shift)
                        } else if let last = shifts.first(where: { !$0.isActive }) {
                            pastShiftSection(shift: last)
                        }
                    }
                    .padding(DesignSystem.spacing)
                }
            }
            .navigationTitle("Shift Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $vm.showLogOrderSheet) {
                LogOrderSheet(vm: vm, onSave: {
                    vm.logOrder(context: modelContext, appState: appState)
                })
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(text: exportText)
            }
        }
    }

    // MARK: – Sections

    private var shiftControlSection: some View {
        GigCard {
            VStack(spacing: 12) {
                if appState.currentShift != nil {
                    Button {
                        vm.endShift(context: modelContext, appState: appState)
                    } label: {
                        Label("End Shift", systemImage: "stop.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.declineRed)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        vm.showLogOrderSheet = true
                    } label: {
                        Label("Log Order", systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DesignSystem.acceptGreen)
                    }
                } else {
                    Button {
                        vm.startShift(context: modelContext, appState: appState)
                    } label: {
                        Label("Start Shift", systemImage: "play.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(DesignSystem.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DesignSystem.acceptGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func liveStatsSection(shift: Shift) -> some View {
        GigCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Live Stats")
                HStack {
                    StatTile2(label: "EARNED",   value: String(format: "$%.2f", shift.totalEarnings),             color: DesignSystem.acceptGreen)
                    StatTile2(label: "ACCEPTED",  value: "\(shift.acceptedCount)",                                 color: DesignSystem.textPrimary)
                    StatTile2(label: "DECLINED",  value: "\(shift.declinedCount)",                                 color: DesignSystem.declineRed)
                    StatTile2(label: "EST $/HR",  value: String(format: "$%.0f", shift.estimatedHourlyRate),       color: DesignSystem.marginalAmber)
                }
            }
        }
    }

    private func ordersSection(shift: Shift) -> some View {
        GigCard {
            VStack(spacing: 12) {
                HStack {
                    SectionHeader(title: "Orders This Shift")
                    Spacer()
                    Button {
                        exportText      = vm.csvExport(for: shift)
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(DesignSystem.textSecondary)
                    }
                }

                if shift.orders.isEmpty {
                    Text("No orders logged yet")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(shift.orders.sorted(by: { $0.timestamp > $1.timestamp })) { order in
                        OrderRow(order: order)
                        Divider().background(DesignSystem.surfaceHigh)
                    }
                }
            }
        }
    }

    private func pastShiftSection(shift: Shift) -> some View {
        GigCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Last Shift")
                HStack {
                    StatTile2(label: "EARNED",  value: String(format: "$%.2f", shift.totalEarnings),             color: DesignSystem.acceptGreen)
                    StatTile2(label: "ORDERS",  value: "\(shift.orders.count)",                                   color: DesignSystem.textPrimary)
                    StatTile2(label: "ACCEPT%", value: String(format: "%.0f%%", shift.acceptanceRate * 100),      color: DesignSystem.marginalAmber)
                }
                Button {
                    exportText      = vm.csvExport(for: shift)
                    showExportSheet = true
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
        }
    }
}

// MARK: – Sub-views

private struct StatTile2: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OrderRow: View {
    let order: ShiftOrder

    var body: some View {
        HStack {
            Image(systemName: order.wasAccepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(order.wasAccepted ? DesignSystem.acceptGreen : DesignSystem.declineRed)
            VStack(alignment: .leading, spacing: 2) {
                Text(order.platform)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.textPrimary)
                Text(String(format: "%.1f mi", order.pickupDistanceMiles))
                    .font(.caption2)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
            Spacer()
            Text(String(format: "$%.2f", order.payout))
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(DesignSystem.textPrimary)
        }
    }
}

private struct LogOrderSheet: View {
    @Bindable var vm: ShiftTrackerViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                Form {
                    Section("Order Details") {
                        Picker("Platform", selection: $vm.logPlatform) {
                            ForEach(Platform.allCases.filter { $0 != .unknown }, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        TextField("Payout ($)", text: $vm.logPayout)
                            .keyboardType(.decimalPad)
                        TextField("Distance (mi)", text: $vm.logDistance)
                            .keyboardType(.decimalPad)
                        Toggle("Accepted", isOn: $vm.logWasAccepted)
                            .tint(DesignSystem.acceptGreen)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Log Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .foregroundStyle(DesignSystem.acceptGreen)
                        .disabled(vm.logPayout.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
