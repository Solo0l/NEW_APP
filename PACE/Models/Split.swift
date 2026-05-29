import Foundation
import SwiftData

@Model
final class Split {
    var id: UUID
    var index: Int
    var startDate: Date
    var endDate: Date
    var distanceMeters: Double
    var activeDuration: TimeInterval
    var paceSecondsPerMeter: Double
    var averageHeartRate: Double?
    var elevationGainMeters: Double?

    @Relationship(inverse: \Run.splits)
    var run: Run?

    init(
        id: UUID = UUID(),
        index: Int,
        startDate: Date,
        endDate: Date,
        distanceMeters: Double,
        activeDuration: TimeInterval,
        paceSecondsPerMeter: Double,
        averageHeartRate: Double? = nil,
        elevationGainMeters: Double? = nil
    ) {
        self.id = id
        self.index = index
        self.startDate = startDate
        self.endDate = endDate
        self.distanceMeters = distanceMeters
        self.activeDuration = activeDuration
        self.paceSecondsPerMeter = paceSecondsPerMeter
        self.averageHeartRate = averageHeartRate
        self.elevationGainMeters = elevationGainMeters
    }

    func pace(in unit: DistanceUnit) -> TimeInterval {
        paceSecondsPerMeter * unit.metersPerUnit
    }

    func distance(in unit: DistanceUnit) -> Double {
        distanceMeters / unit.metersPerUnit
    }
}
