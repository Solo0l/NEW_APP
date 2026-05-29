import Foundation
import SwiftData

@Observable
final class GoalService {

    // MARK: - Active Goal

    func activeGoal(from goals: [Goal]) -> Goal? {
        goals.first { $0.status == .active && !$0.isExpired }
    }

    func updateGoalProgress(goal: Goal, allRuns: [Run], context: ModelContext) {
        let relevantRuns = allRuns.filter {
            $0.status == .completed &&
            $0.startDate >= goal.startDate &&
            $0.startDate <= goal.endDate
        }

        switch goal.type {
        case .weeklyDistance, .monthlyDistance:
            let totalMeters = relevantRuns.reduce(0) { $0 + $1.distanceMeters }
            let totalKm = totalMeters / 1000.0
            goal.achievedValue = totalKm
            if totalKm >= goal.targetValue {
                goal.status = .completed
                goal.achievedDate = Date.now
            }

        case .weeklyRunCount:
            let count = Double(relevantRuns.count)
            goal.achievedValue = count
            if count >= goal.targetValue {
                goal.status = .completed
                goal.achievedDate = Date.now
            }

        case .singleRunDistance, .singleRunTime:
            break  // Per-run goals evaluated in RunService
        }

        // Mark expired goals
        if goal.isExpired && goal.status == .active {
            goal.status = .missed
        }

        try? context.save()
    }

    // MARK: - Preset Suggestions

    struct GoalSuggestion {
        let title: String
        let type: GoalType
        let value: Double
        let unit: GoalUnit
    }

    func suggestions(existingRuns: [Run]) -> [GoalSuggestion] {
        let avgWeeklyKm = averageWeeklyKm(from: existingRuns)

        if existingRuns.isEmpty {
            return [
                GoalSuggestion(title: "Run 3 times this week", type: .weeklyRunCount, value: 3, unit: .runs),
                GoalSuggestion(title: "Run 20 km this week", type: .weeklyDistance, value: 20, unit: .kilometers)
            ]
        }

        // Suggest 10% above current weekly average
        let suggestedKm = ceil((avgWeeklyKm * 1.1) / 5) * 5  // Round up to nearest 5
        return [
            GoalSuggestion(title: "\(Int(suggestedKm)) km this week", type: .weeklyDistance, value: suggestedKm, unit: .kilometers),
            GoalSuggestion(title: "3 runs this week", type: .weeklyRunCount, value: 3, unit: .runs),
            GoalSuggestion(title: "\(Int(suggestedKm * 4)) km this month", type: .monthlyDistance, value: suggestedKm * 4, unit: .kilometers)
        ]
    }

    private func averageWeeklyKm(from runs: [Run]) -> Double {
        let completed = runs.filter { $0.status == .completed }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current
        let oldestDate = completed.map(\.startDate).min() ?? Date.now
        let weeksSpanned = max(1, calendar.dateComponents([.weekOfYear], from: oldestDate, to: .now).weekOfYear ?? 1)
        let totalKm = completed.reduce(0) { $0 + $1.distanceMeters } / 1000.0
        return totalKm / Double(weeksSpanned)
    }
}
