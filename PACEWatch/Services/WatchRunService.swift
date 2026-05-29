import Foundation
import HealthKit
import CoreLocation
import WatchKit

// Re-use the same RunPhase enum from the iOS app
// (In a real project this would live in a shared Swift Package)

@Observable
@MainActor
final class WatchRunService: ObservableObject {

    // MARK: - State

    var phase: RunPhase = .idle

    // Live metrics
    var currentPaceSecondsPerMeter: Double = 0
    var distanceMeters: Double = 0
    var elapsedTime: TimeInterval = 0
    var currentHeartRate: Double?
    var elevationGain: Double = 0
    var lapDistanceMeters: Double = 0
    var currentLapIndex: Int = 0
    var lapStartTime: Date = .now
    var completedSplits: [SplitSnapshot] = []

    // MARK: - Private

    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    private var elapsedTimer: Timer?
    private var runStartTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var lapIntervalMeters: Double = 1000

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned)
        ]
        try? await store.requestAuthorization(toShare: types, read: types)
    }

    // MARK: - Start Flow

    func startCountdown() {
        phase = .countdown(secondsRemaining: 3)
        var remaining = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            remaining -= 1
            if remaining > 0 {
                Task { @MainActor in self.phase = .countdown(secondsRemaining: remaining) }
                WKInterfaceDevice.current().play(.click)
            } else {
                timer.invalidate()
                WKInterfaceDevice.current().play(.start)
                Task { @MainActor in await self.beginWorkout() }
            }
        }
    }

    private func beginWorkout() async {
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            self.workoutSession = session
            self.workoutBuilder = builder

            session.delegate = WorkoutSessionDelegate(service: self)
            builder.delegate = WorkoutBuilderDelegate(service: self)

            session.startActivity(with: .now)
            try await builder.beginCollection(at: .now)

            runStartTime = .now
            totalPausedTime = 0
            lapStartTime = .now
            currentLapIndex = 0
            lapDistanceMeters = 0
            completedSplits = []
            startElapsedTimer()
            phase = .active
        } catch {
            // Fallback: still enter active phase with local timer only
            runStartTime = .now
            startElapsedTimer()
            phase = .active
        }
    }

    // MARK: - Pause / Resume

    func pauseRun() {
        workoutSession?.pause()
        pauseStartTime = .now
        stopElapsedTimer()
        phase = .paused
        WKInterfaceDevice.current().play(.stop)
    }

    func resumeRun() {
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date.now.timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        workoutSession?.resume()
        startElapsedTimer()
        phase = .active
        WKInterfaceDevice.current().play(.start)
    }

    func markLap() {
        let now = Date.now
        let split = SplitSnapshot(
            index: currentLapIndex,
            startDate: lapStartTime,
            endDate: now,
            distanceMeters: lapDistanceMeters,
            activeDuration: now.timeIntervalSince(lapStartTime),
            paceSecondsPerMeter: lapDistanceMeters > 0 ? now.timeIntervalSince(lapStartTime) / lapDistanceMeters : 0,
            averageHeartRate: nil
        )
        completedSplits.append(split)
        currentLapIndex += 1
        lapDistanceMeters = 0
        lapStartTime = now
        WKInterfaceDevice.current().play(.notification)
    }

    func endRun() {
        stopElapsedTimer()
        workoutSession?.end()

        // Build a Run object for the summary view
        let run = Run(startDate: runStartTime ?? .now, status: .completed)
        run.endDate = .now
        run.activeDuration = elapsedTime
        run.distanceMeters = distanceMeters
        run.elevationGainMeters = elevationGain
        if distanceMeters > 0, elapsedTime > 0 {
            run.averagePaceSecondsPerMeter = elapsedTime / distanceMeters
        }
        if let hr = currentHeartRate {
            run.averageHeartRate = hr
        }

        WKInterfaceDevice.current().play(.success)
        phase = .ended(run: run)
    }

    func resetToIdle() {
        phase = .idle
        distanceMeters = 0
        elapsedTime = 0
        currentPaceSecondsPerMeter = 0
        currentHeartRate = nil
        lapDistanceMeters = 0
        completedSplits = []
        workoutSession = nil
        workoutBuilder = nil
    }

    // MARK: - HealthKit Callbacks (called by delegates)

    func updateHeartRate(_ bpm: Double) {
        currentHeartRate = bpm
    }

    func updateDistance(_ meters: Double) {
        let delta = meters - distanceMeters
        distanceMeters = meters
        lapDistanceMeters += delta

        // Speed → pace
        if elapsedTime > 0, distanceMeters > 0 {
            let instantPace = elapsedTime / distanceMeters
            currentPaceSecondsPerMeter = instantPace
        }

        // Auto-lap
        if lapDistanceMeters >= lapIntervalMeters {
            markLap()
        }
    }

    // MARK: - Timer

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.runStartTime else { return }
            Task { @MainActor in
                self.elapsedTime = max(0, Date.now.timeIntervalSince(start) - self.totalPausedTime)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
}

// MARK: - HKWorkoutSessionDelegate Wrapper

final class WorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate {
    weak var service: WatchRunService?
    init(service: WatchRunService) { self.service = service }

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}

// MARK: - HKLiveWorkoutBuilderDelegate Wrapper

final class WorkoutBuilderDelegate: NSObject, HKLiveWorkoutBuilderDelegate {
    weak var service: WatchRunService?
    init(service: WatchRunService) { self.service = service }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let stats = workoutBuilder.statistics(for: quantityType)

            if quantityType == HKQuantityType(.heartRate),
               let qty = stats?.mostRecentQuantity() {
                let bpm = qty.doubleValue(for: HKUnit(from: "count/min"))
                Task { @MainActor in service?.updateHeartRate(bpm) }
            }

            if quantityType == HKQuantityType(.distanceWalkingRunning),
               let qty = stats?.sumQuantity() {
                let meters = qty.doubleValue(for: .meter())
                Task { @MainActor in service?.updateDistance(meters) }
            }
        }
    }
}
