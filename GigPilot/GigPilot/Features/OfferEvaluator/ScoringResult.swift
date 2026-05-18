import Foundation

enum ScoringResult: Equatable {
    case accept(reason: String)
    case decline(reason: String)
    case marginal(reason: String)

    var label: String {
        switch self {
        case .accept:   return "✅ ACCEPT"
        case .decline:  return "❌ DECLINE"
        case .marginal: return "⚠️ MARGINAL"
        }
    }

    var shortLabel: String {
        switch self {
        case .accept:   return "Accept"
        case .decline:  return "Decline"
        case .marginal: return "Marginal"
        }
    }

    var reason: String {
        switch self {
        case .accept(let r), .decline(let r), .marginal(let r): return r
        }
    }

    var isAccept:   Bool { if case .accept   = self { return true }; return false }
    var isDecline:  Bool { if case .decline  = self { return true }; return false }
    var isMarginal: Bool { if case .marginal = self { return true }; return false }
}
