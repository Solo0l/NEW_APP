import SwiftUI

enum PACEColors {
    // MARK: - Backgrounds
    static let backgroundPrimary   = Color(hex: "0A0A0A")
    static let surface             = Color(hex: "141414")
    static let surfaceElevated     = Color(hex: "1E1E1E")
    static let overlay             = Color(hex: "0A0A0A").opacity(0.92)

    // MARK: - Text
    static let textPrimary         = Color(hex: "FFFFFF")
    static let textSecondary       = Color(hex: "606060")
    static let textTertiary        = Color(hex: "3A3A3A")
    static let textInverse         = Color(hex: "0A0A0A")

    // MARK: - Accent
    static let accentCyan          = Color(hex: "00D4FF")
    static let accentOrange        = Color(hex: "FF6B35")
    static let accentCyanDim       = Color(hex: "00D4FF").opacity(0.15)

    // MARK: - Semantic
    static let success             = Color(hex: "30D158")
    static let warning             = Color(hex: "FFD60A")
    static let error               = Color(hex: "FF3B30")
    static let separator           = Color(hex: "2A2A2A")

    // MARK: - HR Zones
    static let hrZone1             = Color(hex: "60D0A0")
    static let hrZone2             = Color(hex: "A8D060")
    static let hrZone3             = Color(hex: "FFD060")
    static let hrZone4             = Color(hex: "FF9030")
    static let hrZone5             = Color(hex: "FF3060")

    static func hrZoneColor(_ zone: HeartRateZone) -> Color {
        switch zone {
        case .zone1: return hrZone1
        case .zone2: return hrZone2
        case .zone3: return hrZone3
        case .zone4: return hrZone4
        case .zone5: return hrZone5
        }
    }

    // Pace tint for active run: cyan if at/above goal, orange if below
    static func paceTint(isAtGoal: Bool?) -> Color {
        guard let isAtGoal else { return .white }
        return isAtGoal ? Color(hex: "D0F8FF") : Color(hex: "FFE0CC")
    }
}
