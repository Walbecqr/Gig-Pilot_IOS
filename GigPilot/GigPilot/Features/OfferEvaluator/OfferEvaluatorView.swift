import SwiftUI

struct OfferEvaluatorView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: OfferEvaluatorViewModel?
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case payout, distance, duration }

    private func viewModel() -> OfferEvaluatorViewModel {
        if let existing = vm { return existing }
        let new = OfferEvaluatorViewModel(appState: appState)
        vm = new
        return new
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.spacing) {
                        inputSection
                        if let result = viewModel().scoringResult, let offer = viewModel().scoredOffer {
                            ResultCard(result: result, offer: offer)
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

                // Platform picker
                Picker("Platform", selection: Binding(
                    get: { viewModel().selectedPlatform },
                    set: { viewModel().selectedPlatform = $0 }
                )) {
                    ForEach(Platform.allCases.filter { $0 != .unknown }, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                // Numeric fields
                GigTextField(label: "Payout ($)", placeholder: "0.00", text: Binding(
                    get: { viewModel().payout },
                    set: { viewModel().payout = $0 }
                ), keyboard: .decimalPad, focused: $focusedField, field: .payout)

                HStack(spacing: 12) {
                    GigTextField(label: "Distance (mi)", placeholder: "0.0", text: Binding(
                        get: { viewModel().distanceMiles },
                        set: { viewModel().distanceMiles = $0 }
                    ), keyboard: .decimalPad, focused: $focusedField, field: .distance)

                    GigTextField(label: "Est. Minutes", placeholder: "30", text: Binding(
                        get: { viewModel().durationMinutes },
                        set: { viewModel().durationMinutes = $0 }
                    ), keyboard: .numberPad, focused: $focusedField, field: .duration)
                }

                // Order type
                Picker("Order Type", selection: Binding(
                    get: { viewModel().selectedOrderType },
                    set: { viewModel().selectedOrderType = $0 }
                )) {
                    ForEach(OrderType.allCases.filter { $0 != .unknown }, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(DesignSystem.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Score button
                Button {
                    focusedField = nil
                    viewModel().score()
                } label: {
                    Text("SCORE IT")
                        .font(.system(.headline, design: .monospaced).weight(.bold))
                        .foregroundStyle(DesignSystem.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.acceptGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!viewModel().canScore)
                .opacity(viewModel().canScore ? 1 : 0.4)
            }
        }
    }
}

// MARK: – Result Card

private struct ResultCard: View {
    let result: ScoringResult
    let offer: Offer

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
                MetricPill(label: "PAYOUT",  value: String(format: "$%.2f", offer.payout))
                MetricPill(label: "$/MI",    value: offer.pickupDistanceMiles > 0 ? String(format: "$%.2f", offer.payPerMile) : "—")
                MetricPill(label: "EST $/HR", value: offer.estimatedDurationMinutes > 0 ? String(format: "$%.0f", offer.estimatedHourlyRate) : "—")
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
