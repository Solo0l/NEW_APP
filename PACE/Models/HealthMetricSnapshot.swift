import Foundation
import SwiftData

@Model
final class HealthMetricSnapshot {
    var id: UUID
    var timestamp: Date
    var heartRate: Double?
    var cadence: Double?              // Steps per minute
    var groundContactTime: Double?    // milliseconds
    var verticalOscillation: Double?  // centimeters
    var speed: Double?                // meters per second

    @Relationship(inverse: \Run.metrics)
    var run: Run?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        heartRate: Double? = nil,
        cadence: Double? = nil,
        groundContactTime: Double? = nil,
        verticalOscillation: Double? = nil,
        speed: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.cadence = cadence
        self.groundContactTime = groundContactTime
        self.verticalOscillation = verticalOscillation
        self.speed = speed
    }
}
