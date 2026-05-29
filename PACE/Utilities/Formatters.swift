import Foundation

enum PACEFormatter {

    // MARK: - Pace (seconds per meter → "5:42" string)

    static func pace(_ secondsPerMeter: Double, unit: DistanceUnit) -> String {
        let secondsPerUnit = secondsPerMeter * unit.metersPerUnit
        return formatSecondsPerUnit(secondsPerUnit)
    }

    static func formatSecondsPerUnit(_ totalSeconds: Double) -> String {
        guard totalSeconds > 0, totalSeconds < 3600, !totalSeconds.isNaN, !totalSeconds.isInfinite else {
            return "--:--"
        }
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Distance

    static func distance(_ meters: Double, unit: DistanceUnit, decimals: Int = 2) -> String {
        let value = meters / unit.metersPerUnit
        return String(format: "%.\(decimals)f", value)
    }

    static func distanceWithUnit(_ meters: Double, unit: DistanceUnit) -> String {
        "\(distance(meters, unit: unit)) \(unit.displayName)"
    }

    // MARK: - Duration

    static func duration(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let s = Int(interval) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

    static func shortDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Heart Rate

    static func heartRate(_ bpm: Double?) -> String {
        guard let bpm else { return "—" }
        return "\(Int(bpm))"
    }

    // MARK: - Elevation

    static func elevation(_ meters: Double?) -> String {
        guard let meters else { return "—" }
        return String(format: "+%.0fm", meters)
    }

    // MARK: - Date

    static func runDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    static func weekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: date) ?? date
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "d"
        return "\(formatter.string(from: date))–\(endFormatter.string(from: end))"
    }

    // MARK: - Calories

    static func calories(_ kcal: Double?) -> String {
        guard let kcal else { return "—" }
        return "\(Int(kcal)) kcal"
    }
}
