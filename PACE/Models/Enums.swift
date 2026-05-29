import Foundation

// MARK: - Run

enum RunStatus: String, Codable {
    case inProgress
    case paused
    case completed
}

enum DistanceUnit: String, Codable, CaseIterable {
    case kilometers
    case miles

    var displayName: String {
        switch self {
        case .kilometers: return "km"
        case .miles: return "mi"
        }
    }

    var metersPerUnit: Double {
        switch self {
        case .kilometers: return 1000.0
        case .miles: return 1609.344
        }
    }
}

// MARK: - Goal

enum GoalType: String, Codable, CaseIterable {
    case weeklyDistance
    case weeklyRunCount
    case monthlyDistance
    case singleRunDistance
    case singleRunTime
}

enum GoalUnit: String, Codable {
    case kilometers
    case miles
    case runs
    case minutes
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case missed
    case abandoned
}

// MARK: - Achievement

enum AchievementType: String, Codable {
    case firstRun
    case longestRunEver
    case fastestPaceEver
    case streak3Days
    case streak7Days
    case streak30Days
    case total10km
    case total50km
    case total100km
    case total500km
    case total10Runs
    case total50Runs
    case total100Runs
    case firstGoalCompleted
}

// MARK: - Watch

enum WatchPrimaryMetric: String, Codable, CaseIterable {
    case currentPace
    case heartRate
    case distance

    var displayName: String {
        switch self {
        case .currentPace: return "Current Pace"
        case .heartRate: return "Heart Rate"
        case .distance: return "Distance"
        }
    }
}

// MARK: - Lap

enum LapInterval: String, Codable, CaseIterable {
    case oneKilometer
    case fiveKilometers
    case off

    var displayName: String {
        switch self {
        case .oneKilometer: return "Every 1 km"
        case .fiveKilometers: return "Every 5 km"
        case .off: return "Off"
        }
    }

    var meters: Double? {
        switch self {
        case .oneKilometer: return 1000.0
        case .fiveKilometers: return 5000.0
        case .off: return nil
        }
    }
}

// MARK: - HR Zone

enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1
    case zone2
    case zone3
    case zone4
    case zone5

    var name: String {
        switch self {
        case .zone1: return "Easy"
        case .zone2: return "Aerobic"
        case .zone3: return "Tempo"
        case .zone4: return "Threshold"
        case .zone5: return "Max"
        }
    }

    // Percent of max HR
    var lowerBound: Double {
        switch self {
        case .zone1: return 0.50
        case .zone2: return 0.60
        case .zone3: return 0.70
        case .zone4: return 0.80
        case .zone5: return 0.90
        }
    }

    var upperBound: Double {
        switch self {
        case .zone1: return 0.60
        case .zone2: return 0.70
        case .zone3: return 0.80
        case .zone4: return 0.90
        case .zone5: return 1.00
        }
    }

    static func zone(for heartRate: Double, maxHeartRate: Double) -> HeartRateZone {
        let pct = heartRate / maxHeartRate
        return allCases.last(where: { pct >= $0.lowerBound }) ?? .zone1
    }
}

// MARK: - GPS Accuracy

enum GPSAccuracy {
    case acquiring
    case poor
    case fair
    case good

    init(horizontalAccuracy: Double) {
        switch horizontalAccuracy {
        case ..<0:       self = .acquiring
        case 0..<10:     self = .good
        case 10..<25:    self = .fair
        default:         self = .poor
        }
    }

    var isUsable: Bool { self != .acquiring }
}

// MARK: - Run Metric Set

enum MetricSet: Int, CaseIterable {
    case primary    // Current pace | Distance | Time | HR
    case secondary  // Avg pace | Current HR | Elevation
    case laps       // Lap pace | Lap distance | Lap count
}
