import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FilterProfile.name) private var profiles: [FilterProfile]
    @State private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.spacing) {
                        platformSection
                        shiftSummarySection
                        filterProfileSection
                    }
                    .padding(DesignSystem.spacing)
                }
            }
            .navigationTitle("GigPilot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: – Platform Section

    private var platformSection: some View {
        GigCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Platforms")
                HStack(spacing: 12) {
                    PlatformToggle(
                        name: "DoorDash",
                        color: Color(hex: "FF3008"),
                        isOnline: appState.isDoorDashOnline,
                        action: { vm.toggleDoorDash(appState: appState) }
                    )
                    PlatformToggle(
                        name: "Uber Eats",
                        color: Color(hex: "06C167"),
                        isOnline: appState.isUberEatsOnline,
                        action: { vm.toggleUberEats(appState: appState) }
                    )
                }
            }
        }
    }

    // MARK: – Shift Summary Section

    private var shiftSummarySection: some View {
        GigCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Current Shift")

                if let shift = appState.currentShift {
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        HStack {
                            StatTile(label: "Earned",  value: vm.shiftEarningsDisplay(for: shift),  accent: DesignSystem.acceptGreen)
                            StatTile(label: "Orders",  value: vm.shiftOrdersDisplay(for: shift),    accent: DesignSystem.textPrimary)
                            StatTile(label: "Time",    value: vm.shiftDurationDisplay(for: shift),  accent: DesignSystem.textPrimary)
                            StatTile(label: "Rate",    value: vm.shiftHourlyDisplay(for: shift),    accent: DesignSystem.marginalAmber)
                        }
                    }
                } else {
                    Text("No active shift — start one in the Shift tab")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: – Filter Profile Section

    private var filterProfileSection: some View {
        GigCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Active Filter Profile")

                if profiles.isEmpty {
                    Text("No profiles — add one in Settings")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profiles) { profile in
                                ProfileChip(
                                    profile: profile,
                                    isSelected: appState.activeFilterProfile?.id == profile.id,
                                    action: { appState.activeFilterProfile = profile }
                                )
                            }
                        }
                    }

                    if let active = appState.activeFilterProfile {
                        Divider().background(DesignSystem.surfaceHigh)
                        ProfileThresholdRow(profile: active)
                    }
                }
            }
        }
    }
}

// MARK: – Sub-views

private struct PlatformToggle: View {
    let name: String
    let color: Color
    let isOnline: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isOnline ? color : DesignSystem.textSecondary)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.system(.subheadline, design: .default).weight(.semibold))
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                Text(isOnline ? "ONLINE" : "OFFLINE")
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .foregroundStyle(isOnline ? color : DesignSystem.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isOnline ? color.opacity(0.12) : DesignSystem.surfaceHigh)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(accent)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileChip: View {
    let profile: FilterProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(profile.name)
                .font(.system(.caption, design: .default).weight(.semibold))
                .foregroundStyle(isSelected ? DesignSystem.background : DesignSystem.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? DesignSystem.acceptGreen : DesignSystem.surfaceHigh)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileThresholdRow: View {
    let profile: FilterProfile

    var body: some View {
        HStack(spacing: 16) {
            ThresholdBadge(label: "MIN PAY",  value: String(format: "$%.0f",    profile.minimumPayout))
            ThresholdBadge(label: "$/MI",     value: String(format: "$%.1f",    profile.minimumPayPerMile))
            ThresholdBadge(label: "$/HR",     value: String(format: "$%.0f",    profile.minimumHourlyRate))
            ThresholdBadge(label: "MAX DIST", value: String(format: "%.0fmi",   profile.maximumPickupDistanceMiles))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ThresholdBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(DesignSystem.textPrimary)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
