import Foundation
import SwiftData
import CoreLocation

@Model
final class Run {
    var id: UUID
    var startDate: Date
    var endDate: Date?

    // Durations
    var activeDuration: TimeInterval       // Excludes paused time
    var totalDuration: TimeInterval        // Includes paused time

    // Distance & Pace (always stored in SI units: meters, seconds/meter)
    var distanceMeters: Double
    var averagePaceSecondsPerMeter: Double
    var bestPaceSecondsPerMeter: Double

    // Heart Rate
    var averageHeartRate: Double?
    var maxHeartRate: Double?

    // Elevation
    var elevationGainMeters: Double?
    var elevationLossMeters: Double?

    // Energy
    var activeCalories: Double?

    // Route — encoded as [CLLocationCoordinate2D] via Codable wrapper
    var routeData: Data?

    // Status
    var status: RunStatus

    // Per-run goal
    var goalType: GoalType?
    var goalValueMeters: Double?          // Distance goal in meters
    var goalValueSeconds: Double?         // Time goal in seconds

    // HealthKit cross-reference
    var healthKitWorkoutID: String?       // UUID as string

    @Relationship(deleteRule: .cascade)
    var splits: [Split] = []

    @Relationship(deleteRule: .cascade)
    var metrics: [HealthMetricSnapshot] = []

    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        status: RunStatus = .inProgress
    ) {
        self.id = id
        self.startDate = startDate
        self.activeDuration = 0
        self.totalDuration = 0
        self.distanceMeters = 0
        self.averagePaceSecondsPerMeter = 0
        self.bestPaceSecondsPerMeter = 0
        self.status = status
    }

    // MARK: - Computed Display Helpers

    func distance(in unit: DistanceUnit) -> Double {
        distanceMeters / unit.metersPerUnit
    }

    func averagePace(in unit: DistanceUnit) -> TimeInterval {
        averagePaceSecondsPerMeter * unit.metersPerUnit
    }

    func bestPace(in unit: DistanceUnit) -> TimeInterval {
        bestPaceSecondsPerMeter * unit.metersPerUnit
    }

    var route: [CLLocationCoordinate2D] {
        get {
            guard let data = routeData else { return [] }
            return (try? JSONDecoder().decode([CodableCoordinate].self, from: data))?.map(\.coordinate) ?? []
        }
        set {
            routeData = try? JSONEncoder().encode(newValue.map(CodableCoordinate.init))
        }
    }
}

// Lightweight Codable wrapper for CLLocationCoordinate2D
struct CodableCoordinate: Codable {
    var latitude: Double
    var longitude: Double

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
