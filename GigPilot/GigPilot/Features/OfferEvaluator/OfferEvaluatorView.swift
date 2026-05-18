import SwiftUI

struct OfferEvaluatorView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = OfferEvaluatorViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case payout, distance, duration }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.spacing) {
                        inputSection
                        if let result = vm.scoringResult, let offer = vm.scoredOffer {
                            ResultCard(result: result, offer: offer) {
                                vm.reset()
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(DesignSystem.spacing)
                }
            }
            .navigationTitle("Evaluate Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var inputSection: some View {
        GigCard {
            VStack(spacing: 16) {
                SectionHeader(title: "Offer Details")

                Picker("Platform", selection: $vm.selectedPlatform) {
                    ForEach(Platform.allCases.filter { $0 != .unknown }, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                GigTextField(label: "Payout ($)", placeholder: "0.00",
                             text: $vm.payout, keyboard: .decimalPad,
                             focused: $focusedField, field: .payout)

                HStack(spacing: 12) {
                    GigTextField(label: "Distance (mi)", placeholder: "0.0",
                                 text: $vm.distanceMiles, keyboard: .decimalPad,
                                 focused: $focusedField, field: .distance)

                    GigTextField(label: "Est. Minutes", placeholder: "30",
                                 text: $vm.durationMinutes, keyboard: .numberPad,
                                 focused: $focusedField, field: .duration)
                }

                Picker("Order Type", selection: $vm.selectedOrderType) {
                    ForEach(OrderType.allCases.filter { $0 != .unknown }, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(DesignSystem.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    focusedField = nil
                    vm.score(against: appState.activeFilterProfile, appState: appState)
                } label: {
                    Text("SCORE IT")
                        .font(.system(.headline, design: .monospaced).weight(.bold))
                        .foregroundStyle(DesignSystem.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.acceptGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!vm.canScore)
                .opacity(vm.canScore ? 1 : 0.4)

                if appState.activeFilterProfile == nil {
                    Text("⚠️ No active filter profile — select one in Settings")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.marginalAmber)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: – Result Card

private struct ResultCard: View {
    let result: ScoringResult
    let offer: Offer
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(result.label)
                .font(.system(.title2, design: .monospaced).weight(.black))
                .foregroundStyle(result.color)

            Text(result.reason)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(DesignSystem.textPrimary)
                .multilineTextAlignment(.center)

            Divider().background(result.color.opacity(0.3))

            HStack(spacing: 20) {
                MetricPill(label: "PAYOUT",   value: String(format: "$%.2f", offer.payout))
                MetricPill(label: "$/MI",     value: offer.pickupDistanceMiles > 0 ? String(format: "$%.2f", offer.payPerMile) : "—")
                MetricPill(label: "EST $/HR", value: offer.estimatedDurationMinutes > 0 ? String(format: "$%.0f", offer.estimatedHourlyRate) : "—")
            }

            Button(action: onReset) {
                Text("Clear")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
        }
        .padding(DesignSystem.spacing)
        .background(result.color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.cardCorner).stroke(result.color.opacity(0.4), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCorner))
    }
}

private struct MetricPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(DesignSystem.textPrimary)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(DesignSystem.textSecondary)
        }
    }
}

private struct GigTextField: View {
    let label: String
    let placeholder: String
    let text: Binding<String>
    let keyboard: UIKeyboardType
    var focused: FocusState<OfferEvaluatorView.Field?>.Binding
    let field: OfferEvaluatorView.Field

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(DesignSystem.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(DesignSystem.textPrimary)
                .focused(focused, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(DesignSystem.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }
}
