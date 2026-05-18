import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showProfiles = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                List {
                    // Filter Profiles
                    Section("Offer Filters") {
                        Button {
                            showProfiles = true
                        } label: {
                            HStack {
                                Label("Filter Profiles", systemImage: "slider.horizontal.3")
                                    .foregroundStyle(DesignSystem.textPrimary)
                                Spacer()
                                if let active = appState.activeFilterProfile {
                                    Text(active.name)
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.acceptGreen)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(DesignSystem.textSecondary)
                            }
                        }
                        .listRowBackground(DesignSystem.surface)
                    }

                    // Voice Alerts
                    Section("Alerts") {
                        Toggle(isOn: Binding(
                            get: { appState.voiceAlertsEnabled },
                            set: { appState.voiceAlertsEnabled = $0 }
                        )) {
                            Label("Voice Alerts", systemImage: "speaker.wave.2.fill")
                                .foregroundStyle(DesignSystem.textPrimary)
                        }
                        .tint(DesignSystem.acceptGreen)
                        .listRowBackground(DesignSystem.surface)
                    }

                    // Platform Links
                    Section("Launch Platforms") {
                        Button {
                            DeepLinkService.openDoorDash()
                        } label: {
                            Label("Open DoorDash", systemImage: "arrow.up.forward.app")
                                .foregroundStyle(DesignSystem.textPrimary)
                        }
                        .listRowBackground(DesignSystem.surface)

                        Button {
                            DeepLinkService.openUberEats()
                        } label: {
                            Label("Open Uber Eats", systemImage: "arrow.up.forward.app")
                                .foregroundStyle(DesignSystem.textPrimary)
                        }
                        .listRowBackground(DesignSystem.surface)
                    }

                    // About
                    Section("About") {
                        HStack {
                            Text("Version")
                                .foregroundStyle(DesignSystem.textPrimary)
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(DesignSystem.textSecondary)
                        }
                        .listRowBackground(DesignSystem.surface)

                        HStack {
                            Text("Zone Coverage")
                                .foregroundStyle(DesignSystem.textPrimary)
                            Spacer()
                            Text("Vero Beach, FL")
                                .foregroundStyle(DesignSystem.textSecondary)
                        }
                        .listRowBackground(DesignSystem.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showProfiles) {
                FilterProfilesView()
            }
        }
    }
}
