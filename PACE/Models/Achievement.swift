import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var type: AchievementType
    var unlockedDate: Date
    var associatedRunID: UUID?
    var value: Double?

    init(
        id: UUID = UUID(),
        type: AchievementType,
        unlockedDate: Date = .now,
        associatedRunID: UUID? = nil,
        value: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.unlockedDate = unlockedDate
        self.associatedRunID = associatedRunID
        self.value = value
    }

    var title: String {
        switch type {
        case .firstRun:          return "First Run"
        case .longestRunEver:    return "Longest Run"
        case .fastestPaceEver:   return "Personal Best"
        case .streak3Days:       return "3-Day Streak"
        case .streak7Days:       return "7-Day Streak"
        case .streak30Days:      return "30-Day Streak"
        case .total10km:         return "10 km Club"
        case .total50km:         return "50 km Club"
        case .total100km:        return "100 km Club"
        case .total500km:        return "500 km Club"
        case .total10Runs:       return "10 Runs"
        case .total50Runs:       return "50 Runs"
        case .total100Runs:      return "100 Runs"
        case .firstGoalCompleted: return "Goal Crusher"
        }
    }
}
