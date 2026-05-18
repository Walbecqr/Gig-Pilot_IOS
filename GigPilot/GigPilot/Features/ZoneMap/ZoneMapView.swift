import SwiftUI
import MapKit

struct ZoneMapView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: ZoneMapViewModel?
    @State private var position: MapCameraPosition = .region(ZoneMapViewModel.veroBeachRegion)

    private func model() -> ZoneMapViewModel {
        if let existing = vm { return existing }
        let new = ZoneMapViewModel(appState: appState)
        vm = new
        return new
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $position) {
                    ForEach(model().zones) { zone in
                        MapCircle(
                            center: zone.coordinate,
                            radius: zone.radiusMeters
                        )
                        .foregroundStyle(zone.hotness.color.opacity(0.25))
                        .stroke(zone.hotness.color, lineWidth: 2)

                        Annotation(zone.name, coordinate: zone.coordinate) {
                            ZoneAnnotationView(zone: zone)
                                .onTapGesture { model().tapZone(zone) }
                        }
                    }

                    if let loc = model().currentLocation {
                        Annotation("You", coordinate: loc.coordinate) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                .ignoresSafeArea(edges: .top)

                zoneLegend
            }
            .navigationTitle("Zone Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: Binding(
                get: { model().showZoneSheet },
                set: { model().showZoneSheet = $0 }
            )) {
                if let zone = model().selectedZone {
                    ZoneDetailSheet(zone: zone, onSelect: { model().setHotness($0, for: zone) })
                }
            }
        }
    }

    private var zoneLegend: some View {
        HStack(spacing: 12) {
            ForEach(ZoneHotness.allCases, id: \.self) { hotness in
                HStack(spacing: 4) {
                    Circle().fill(hotness.color).frame(width: 8, height: 8)
                    Text(hotness.displayName)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 8)
    }
}

private struct ZoneAnnotationView: View {
    let zone: Zone

    var body: some View {
        Text(zone.name)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(zone.hotness.color.opacity(0.85))
            .clipShape(Capsule())
    }
}

private struct ZoneDetailSheet: View {
    let zone: Zone
    let onSelect: (ZoneHotness) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text(zone.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DesignSystem.textPrimary)

                    Text("Mark this zone:")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.textSecondary)

                    VStack(spacing: 10) {
                        ForEach(ZoneHotness.allCases, id: \.self) { hotness in
                            Button {
                                onSelect(hotness)
                            } label: {
                                HStack {
                                    Circle().fill(hotness.color).frame(width: 14, height: 14)
                                    Text(hotness.displayName)
                                        .font(.headline)
                                        .foregroundStyle(DesignSystem.textPrimary)
                                    Spacer()
                                    if zone.hotness == hotness {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(DesignSystem.acceptGreen)
                                    }
                                }
                                .padding()
                                .background(DesignSystem.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(DesignSystem.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
