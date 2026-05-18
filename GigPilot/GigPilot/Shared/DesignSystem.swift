import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum DesignSystem {
    static let background   = Color(hex: "0F1117")
    static let surface      = Color(hex: "1C1F26")
    static let surfaceHigh  = Color(hex: "262B35")
    static let acceptGreen  = Color(hex: "39FF14")
    static let declineRed   = Color(hex: "FF3B30")
    static let marginalAmber = Color(hex: "FF9F0A")
    static let textPrimary  = Color.white
    static let textSecondary = Color(hex: "8E8E93")
    static let cardCorner: CGFloat = 12
    static let spacing: CGFloat = 16
}

extension ScoringResult {
    var color: Color {
        switch self {
        case .accept:   return DesignSystem.acceptGreen
        case .decline:  return DesignSystem.declineRed
        case .marginal: return DesignSystem.marginalAmber
        }
    }
}

extension ZoneHotness {
    var color: Color {
        Color(hex: colorHex)
    }
}

struct GigCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(DesignSystem.spacing)
            .background(DesignSystem.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.cardCorner))
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(.caption, design: .monospaced).weight(.semibold))
            .foregroundStyle(DesignSystem.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
