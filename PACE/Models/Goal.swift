import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var type: GoalType
    var targetValue: Double
    var unit: GoalUnit
    var startDate: Date
    var endDate: Date
    var status: GoalStatus
    var achievedValue: Double?
    var achievedDate: Date?

    init(
        id: UUID = UUID(),
        type: GoalType,
        targetValue: Double,
        unit: GoalUnit,
        startDate: Date,
        endDate: Date,
        status: GoalStatus = .active
    ) {
        self.id = id
        self.type = type
        self.targetValue = targetValue
        self.unit = unit
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
    }

    var progress: Double {
        guard let achieved = achievedValue else { return 0 }
        return min(achieved / targetValue, 1.0)
    }

    var isExpired: Bool {
        endDate < .now && status == .active
    }

    static func weeklyDistanceGoal(targetKm: Double, startingFrom date: Date = .now) -> Goal {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        return Goal(
            type: .weeklyDistance,
            targetValue: targetKm,
            unit: .kilometers,
            startDate: weekStart,
            endDate: weekEnd
        )
    }

    static func weeklyRunCountGoal(targetCount: Int, startingFrom date: Date = .now) -> Goal {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        return Goal(
            type: .weeklyRunCount,
            targetValue: Double(targetCount),
            unit: .runs,
            startDate: weekStart,
            endDate: weekEnd
        )
    }

    static func monthlyDistanceGoal(targetKm: Double, startingFrom date: Date = .now) -> Goal {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? date
        return Goal(
            type: .monthlyDistance,
            targetValue: targetKm,
            unit: .kilometers,
            startDate: monthStart,
            endDate: monthEnd
        )
    }
}
