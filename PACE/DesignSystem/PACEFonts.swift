import SwiftUI

enum PACEFonts {
    // MARK: - Active Run Metrics
    static let metricPrimary    = Font.system(size: 88, weight: .regular, design: .rounded)
    static let metricSecondary  = Font.system(size: 28, weight: .regular, design: .rounded)
    static let metricLabel      = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - UI
    static let title            = Font.system(size: 28, weight: .medium, design: .rounded)
    static let body             = Font.system(size: 17, weight: .regular, design: .default)
    static let caption          = Font.system(size: 13, weight: .regular, design: .default)
    static let listPrimary      = Font.system(size: 20, weight: .regular, design: .rounded)
    static let buttonPrimary    = Font.system(size: 17, weight: .medium, design: .rounded)
    static let buttonLarge      = Font.system(size: 22, weight: .semibold, design: .rounded)

    // MARK: - Large Numerals (History, Summary)
    static let statLarge        = Font.system(size: 64, weight: .regular, design: .rounded)
    static let statMedium       = Font.system(size: 34, weight: .regular, design: .rounded)

    // MARK: - Countdown
    static let countdown        = Font.system(size: 144, weight: .regular, design: .rounded)
}

// MARK: - Watch Fonts

enum PACEWatchFonts {
    static let metricPrimary    = Font.system(size: 52, weight: .regular, design: .rounded)
    static let metricSecondary  = Font.system(size: 20, weight: .regular, design: .rounded)
    static let metricLabel      = Font.system(size: 11, weight: .medium, design: .default)
    static let countdown        = Font.system(size: 80, weight: .regular, design: .rounded)
    static let buttonLabel      = Font.system(size: 16, weight: .semibold, design: .rounded)
}
