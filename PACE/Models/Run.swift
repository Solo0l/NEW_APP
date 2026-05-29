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

    // Distance & Pace (always stored in SI: meters, seconds/meter)
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

    // Route — stored as flat arrays to avoid repeated JSON decode
    var routeLatitudes: [Double]
    var routeLongitudes: [Double]

    // Status
    var status: RunStatus

    // Per-run goal
    var goalType: GoalType?
    var goalValueMeters: Double?
    var goalValueSeconds: Double?

    // HealthKit cross-reference
    var healthKitWorkoutID: String?

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
        self.routeLatitudes = []
        self.routeLongitudes = []
        self.status = status
    }

    // MARK: - Route access (O(1), no JSON decode)

    var route: [CLLocationCoordinate2D] {
        get {
            zip(routeLatitudes, routeLongitudes).map {
                CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
            }
        }
        set {
            routeLatitudes = newValue.map(\.latitude)
            routeLongitudes = newValue.map(\.longitude)
        }
    }

    func appendRoutePoint(_ coordinate: CLLocationCoordinate2D) {
        routeLatitudes.append(coordinate.latitude)
        routeLongitudes.append(coordinate.longitude)
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
}
