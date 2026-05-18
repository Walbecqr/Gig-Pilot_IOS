import SwiftUI
import SwiftData

@main
struct GigPilotApp: App {
    @State private var appState = AppState()

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([FilterProfile.self, Shift.self, ShiftOrder.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    seedDefaultProfilesIfNeeded()
                    appState.location.requestAuthorization()
                }
        }
    }

    private func seedDefaultProfilesIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<FilterProfile>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else {
            // Load the default profile into appState
            if let profiles = try? context.fetch(descriptor) {
                appState.activeFilterProfile = profiles.first(where: \.isDefault) ?? profiles.first
            }
            return
        }

        let profiles = [
            FilterProfile.makeStandard(),
            FilterProfile.makeRushHour(),
            FilterProfile.makeEndOfShift()
        ]
        profiles.forEach { context.insert($0) }
        try? context.save()
        appState.activeFilterProfile = profiles[0]
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.high") }

            OfferEvaluatorView()
                .tabItem { Label("Evaluate", systemImage: "checkmark.circle") }

            ShiftTrackerView()
                .tabItem { Label("Shift", systemImage: "clock.fill") }

            ZoneMapView()
                .tabItem { Label("Zones", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(DesignSystem.acceptGreen)
        .preferredColorScheme(.dark)
    }
}
