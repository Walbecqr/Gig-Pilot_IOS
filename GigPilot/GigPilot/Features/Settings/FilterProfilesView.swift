import SwiftUI
import SwiftData

struct FilterProfilesView: View {
    @Environment(AppState.self)  private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Query(sort: \FilterProfile.name) private var profiles: [FilterProfile]

    @State private var editingProfile: FilterProfile?
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                List {
                    ForEach(profiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: appState.activeFilterProfile?.id == profile.id,
                            onSelect: { appState.activeFilterProfile = profile },
                            onEdit: { editingProfile = profile }
                        )
                        .listRowBackground(DesignSystem.surface)
                        .listRowSeparatorTint(DesignSystem.surfaceHigh)
                    }
                    .onDelete { offsets in
                        offsets.map { profiles[$0] }.forEach { profile in
                            if appState.activeFilterProfile?.id == profile.id {
                                appState.activeFilterProfile = profiles.first(where: { $0.id != profile.id })
                            }
                            modelContext.delete(profile)
                        }
                        try? modelContext.save()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateSheet = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DesignSystem.acceptGreen)
                    }
                }
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditSheet(profile: profile)
            }
            .sheet(isPresented: $showCreateSheet) {
                ProfileCreateSheet()
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: FilterProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isActive ? DesignSystem.acceptGreen : DesignSystem.textSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundStyle(DesignSystem.textPrimary)
                        Text("Min $\(String(format: "%.0f", profile.minimumPayout)) • $\(String(format: "%.1f", profile.minimumPayPerMile))/mi • $\(String(format: "%.0f", profile.minimumHourlyRate))/hr • \(String(format: "%.0f", profile.maximumPickupDistanceMiles))mi max")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.textSecondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(DesignSystem.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfileEditSheet: View {
    @Bindable var profile: FilterProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    var body: some View {
        NavigationStack {
            ProfileForm(
                name: $profile.name,
                minimumPayout: $profile.minimumPayout,
                minimumPayPerMile: $profile.minimumPayPerMile,
                minimumHourlyRate: $profile.minimumHourlyRate,
                maximumPickupDistanceMiles: $profile.maximumPickupDistanceMiles
            )
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.acceptGreen)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
        }
    }
}

private struct ProfileCreateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var name = ""
    @State private var minimumPayout: Double = 5.0
    @State private var minimumPayPerMile: Double = 1.5
    @State private var minimumHourlyRate: Double = 15.0
    @State private var maximumPickupDistanceMiles: Double = 3.0

    var body: some View {
        NavigationStack {
            ProfileForm(
                name: $name,
                minimumPayout: $minimumPayout,
                minimumPayPerMile: $minimumPayPerMile,
                minimumHourlyRate: $minimumHourlyRate,
                maximumPickupDistanceMiles: $maximumPickupDistanceMiles
            )
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !name.isEmpty else { return }
                        let profile = FilterProfile(
                            name: name,
                            minimumPayout: minimumPayout,
                            minimumPayPerMile: minimumPayPerMile,
                            minimumHourlyRate: minimumHourlyRate,
                            maximumPickupDistanceMiles: maximumPickupDistanceMiles
                        )
                        modelContext.insert(profile)
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundStyle(name.isEmpty ? DesignSystem.textSecondary : DesignSystem.acceptGreen)
                    .disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
        }
    }
}

private struct ProfileForm: View {
    @Binding var name: String
    @Binding var minimumPayout: Double
    @Binding var minimumPayPerMile: Double
    @Binding var minimumHourlyRate: Double
    @Binding var maximumPickupDistanceMiles: Double

    var body: some View {
        ZStack {
            DesignSystem.background.ignoresSafeArea()
            Form {
                Section("Name") {
                    TextField("Profile name", text: $name)
                        .foregroundStyle(DesignSystem.textPrimary)
                }
                .listRowBackground(DesignSystem.surface)

                Section("Thresholds") {
                    SliderRow(label: "Min Payout",    value: $minimumPayout,                  range: 1...20,  format: "$%.0f")
                    SliderRow(label: "Min $/Mile",    value: $minimumPayPerMile,               range: 0.5...5, format: "$%.1f/mi")
                    SliderRow(label: "Min $/Hour",    value: $minimumHourlyRate,               range: 5...40,  format: "$%.0f/hr")
                    SliderRow(label: "Max Distance",  value: $maximumPickupDistanceMiles,      range: 0.5...10, format: "%.1f mi")
                }
                .listRowBackground(DesignSystem.surface)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                Text(String(format: format, value))
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(DesignSystem.acceptGreen)
            }
            Slider(value: $value, in: range)
                .tint(DesignSystem.acceptGreen)
        }
    }
}
