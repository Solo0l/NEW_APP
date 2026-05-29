import Foundation
import HealthKit

@Observable
final class HealthKitManager {

    var isAuthorized = false
    var latestHeartRate: Double?

    private let store = HKHealthStore()
    private var workoutBuilder: HKWorkoutBuilder?
    private var heartRateQuery: HKObserverQuery?
    private var activeWorkoutStartDate: Date?

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.runningSpeed)
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.vo2Max),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.runningSpeed),
            HKObjectType.workoutType()
        ]

        do {
            try await store.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Workout Session

    func beginWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor
        workoutBuilder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        activeWorkoutStartDate = .now
        workoutBuilder?.beginCollection(withStart: .now) { _, _ in }
        startHeartRateObserver()
    }

    func endWorkout(run: Run) {
        guard let builder = workoutBuilder,
              let startDate = activeWorkoutStartDate else { return }

        stopHeartRateObserver()

        var samples: [HKSample] = []
        let endDate = Date.now

        // Distance
        if run.distanceMeters > 0,
           let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let qty = HKQuantity(unit: .meter(), doubleValue: run.distanceMeters)
            let sample = HKQuantitySample(type: distType, quantity: qty, start: startDate, end: endDate)
            samples.append(sample)
        }

        // Calories (estimated: ~1 kcal/kg/km, assume 70kg runner)
        if run.distanceMeters > 0,
           let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let kcal = (run.distanceMeters / 1000.0) * 70.0
            let qty = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
            let sample = HKQuantitySample(type: energyType, quantity: qty, start: startDate, end: endDate)
            samples.append(sample)
            run.activeCalories = kcal
        }

        builder.add(samples) { _, _ in }
        builder.endCollection(withEnd: endDate) { [weak self] _, _ in
            builder.finishWorkout { workout, _ in
                guard let workout else { return }
                DispatchQueue.main.async {
                    run.healthKitWorkoutID = workout.uuid.uuidString
                    self?.workoutBuilder = nil
                    self?.activeWorkoutStartDate = nil
                }
            }
        }
    }

    // MARK: - Heart Rate Observer

    private func startHeartRateObserver() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, _, _ in
            self?.fetchLatestHeartRate()
        }
        store.execute(query)
        heartRateQuery = query
        fetchLatestHeartRate()
    }

    private func stopHeartRateObserver() {
        if let query = heartRateQuery {
            store.stop(query)
            heartRateQuery = nil
        }
    }

    private func fetchLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(
            withStart: Date.now.addingTimeInterval(-30),
            end: nil,
            options: .strictStartDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self?.latestHeartRate = bpm
            }
        }
        store.execute(query)
    }

    // MARK: - Resting HR (for zone calculation)

    func fetchRestingHeartRate() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }

    // MARK: - GPX Export

    func exportGPX(run: Run) -> String {
        let coords = run.route
        let dateFormatter = ISO8601DateFormatter()
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PACE" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>Run – \(dateFormatter.string(from: run.startDate))</name>
            <trkseg>
        """
        for coord in coords {
            gpx += "\n      <trkpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\"></trkpt>"
        }
        gpx += "\n    </trkseg>\n  </trk>\n</gpx>"
        return gpx
    }
}
