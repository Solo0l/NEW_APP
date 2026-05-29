import Foundation
import SwiftData

// Stateless goal logic — no @Observable needed.

enum PACEGoals {

    // MARK: - Active Goal

    static func activeGoal(from goals: [Goal]) -> Goal? {
        goals.first { $0.status == .active && !$0.isExpired }
    }

    static func updateProgress(goal: Goal, allRuns: [Run], context: ModelContext) {
        let relevant = allRuns.filter {
            $0.status == .completed &&
            $0.startDate >= goal.startDate &&
            $0.startDate <= goal.endDate
        }

        switch goal.type {
        case .weeklyDistance, .monthlyDistance:
            let totalKm = relevant.reduce(0) { $0 + $1.distanceMeters } / 1000.0
            goal.achievedValue = totalKm
            if totalKm >= goal.targetValue {
                goal.status = .completed
                goal.achievedDate = .now
            }

        case .weeklyRunCount:
            let count = Double(relevant.count)
            goal.achievedValue = count
            if count >= goal.targetValue {
                goal.status = .completed
                goal.achievedDate = .now
            }

        default:
            break
        }

        if goal.isExpired && goal.status == .active {
            goal.status = .missed
        }

        try? context.save()
    }

    // MARK: - Suggestions

    struct Suggestion {
        let title: String
        let type: GoalType
        let value: Double
        let unit: GoalUnit
    }

    static func suggestions(existingRuns: [Run]) -> [Suggestion] {
        let avgKm = averageWeeklyKm(from: existingRuns)

        guard !existingRuns.isEmpty else {
            return [
                Suggestion(title: "Run 3 times this week", type: .weeklyRunCount, value: 3, unit: .runs),
                Suggestion(title: "20 km this week", type: .weeklyDistance, value: 20, unit: .kilometers)
            ]
        }

        let target = (ceil(avgKm * 1.1 / 5) * 5).clamped(to: 10...200)
        return [
            Suggestion(title: "\(Int(target)) km this week", type: .weeklyDistance, value: target, unit: .kilometers),
            Suggestion(title: "3 runs this week", type: .weeklyRunCount, value: 3, unit: .runs)
        ]
    }

    private static func averageWeeklyKm(from runs: [Run]) -> Double {
        let completed = runs.filter { $0.status == .completed }
        guard !completed.isEmpty else { return 0 }
        let oldest = completed.map(\.startDate).min() ?? .now
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: oldest, to: .now).weekOfYear ?? 1)
        return completed.reduce(0) { $0 + $1.distanceMeters } / 1000.0 / Double(weeks)
    }
}

// MARK: - Comparable helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
