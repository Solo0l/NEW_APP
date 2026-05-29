import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var createdAt: Date
    var preferences: UserPreferences

    init(id: UUID = UUID(), createdAt: Date = .now, preferences: UserPreferences = UserPreferences()) {
        self.id = id
        self.createdAt = createdAt
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    var distanceUnit: DistanceUnit = .kilometers
    var autoPauseEnabled: Bool = false
    var resumeCountdownEnabled: Bool = true
    var lapInterval: LapInterval = .oneKilometer
    var audioSplitCues: Bool = false
    var watchPrimaryMetric: WatchPrimaryMetric = .currentPace
    var showHeartRateZone: Bool = true
    var outdoorModeEnabled: Bool = false
    var screenDimDelay: TimeInterval = 60
    var hasCompletedOnboarding: Bool = false
    var hasCompletedQuickSetup: Bool = false
    var appLaunchCount: Int = 0
    var estimatedMaxHeartRate: Double = 190

    static var `default`: UserPreferences { UserPreferences() }
}
