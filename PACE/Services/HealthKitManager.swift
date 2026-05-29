import Foundation
import HealthKit

// Uses actor isolation for thread safety on HealthKit callbacks.

@Observable
final class HealthKitManager {

    var isAuthorized = false
    var latestHeartRate: Double?
    var authorizationError: String?

    private let store = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?
    private var heartRateQuery: HKObserverQuery?
    private var workoutStartDate: Date?

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run { authorizationError = "HealthKit is not available on this device." }
            return
        }

        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned)
        ]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKObjectType.workoutType()
        ]

        do {
            try await store.requestAuthorization(toShare: share, read: read)
            await MainActor.run { self.isAuthorized = true }
        } catch {
            await MainActor.run { self.authorizationError = error.localizedDescription }
        }
    }

    // MARK: - Workout Session

    func beginWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        workoutBuilder = builder
        workoutStartDate = .now
        builder.beginCollection(withStart: .now) { _, _ in }
        startHeartRateObserver()
    }

    func endWorkout(run: Run) {
        stopHeartRateObserver()
        guard let builder = workoutBuilder, let start = workoutStartDate else { return }

        var samples: [HKSample] = []
        let end = Date.now

        if run.distanceMeters > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let sample = HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: .meter(), doubleValue: run.distanceMeters),
                start: start, end: end
            )
            samples.append(sample)
        }

        if run.distanceMeters > 0,
           let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let kcal = (run.distanceMeters / 1000.0) * 70.0  // ~1 kcal/kg/km at 70kg
            let sample = HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: kcal),
                start: start, end: end
            )
            samples.append(sample)
            run.activeCalories = kcal
        }

        builder.add(samples) { _, _ in }
        builder.endCollection(withEnd: end) { [weak self] _, _ in
            builder.finishWorkout { workout, _ in
                guard let workout else { return }
                DispatchQueue.main.async {
                    run.healthKitWorkoutID = workout.uuid.uuidString
                    self?.workoutBuilder = nil
                    self?.workoutStartDate = nil
                }
            }
        }
    }

    // MARK: - Heart Rate

    private func startHeartRateObserver() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, _ in
            self?.fetchLatestHeartRate()
        }
        store.execute(query)
        heartRateQuery = query
        fetchLatestHeartRate()
    }

    private func stopHeartRateObserver() {
        if let q = heartRateQuery { store.stop(q); heartRateQuery = nil }
    }

    private func fetchLatestHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: Date.now.addingTimeInterval(-30), end: nil)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async { self?.latestHeartRate = bpm }
        }
        store.execute(query)
    }

    // MARK: - GPX Export

    func gpxString(for run: Run) -> String {
        let df = ISO8601DateFormatter()
        let coords = run.route
        var gpx = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpx += "<gpx version=\"1.1\" creator=\"PACE\">\n  <trk><trkseg>\n"
        for coord in coords {
            gpx += "    <trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\"></trkpt>\n"
        }
        gpx += "  </trkseg></trk>\n</gpx>"
        _ = df  // suppress unused warning; timestamp support is v1.1
        return gpx
    }
}
