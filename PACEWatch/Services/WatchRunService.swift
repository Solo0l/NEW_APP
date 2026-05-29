import Foundation
import HealthKit
import WatchKit
import SwiftData

// RunPhase is defined in PACE/Models/Enums.swift, shared via project.yml
// SplitSnapshot is redefined here for Watch independence

@Observable
@MainActor
final class WatchRunService {

    // MARK: - Phase & Metrics

    var phase: RunPhase = .idle
    var currentPaceSecondsPerMeter: Double = 0
    var distanceMeters: Double = 0
    var elapsedTime: TimeInterval = 0
    var currentHeartRate: Double?
    var elevationGain: Double = 0
    var lapDistanceMeters: Double = 0
    var currentLapIndex: Int = 0
    var lapStartTime: Date = .now
    var completedSplits: [WatchSplitSnapshot] = []

    // MARK: - Private

    private let store = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var elapsedTimer: Timer?
    private var runStartTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private let lapIntervalMeters: Double = 1000
    private var activeRunID: UUID?

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

    // MARK: - Start

    func startCountdown() {
        guard case .idle = phase else { return }
        phase = .countdown(secondsRemaining: 3)
        var remaining = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            remaining -= 1
            if remaining > 0 {
                Task { @MainActor [weak self] in
                    self?.phase = .countdown(secondsRemaining: remaining)
                    WKInterfaceDevice.current().play(.click)
                }
            } else {
                timer.invalidate()
                Task { @MainActor [weak self] in await self?.beginWorkout() }
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
            workoutSession = session
            workoutBuilder = builder
            session.delegate = WorkoutSessionDelegate.shared(service: self)
            builder.delegate = WorkoutBuilderDelegate.shared(service: self)
            session.startActivity(with: .now)
            try await builder.beginCollection(at: .now)
        } catch {
            // Workout session failed — continue with timer-only mode
        }

        let runID = UUID()
        activeRunID = runID
        runStartTime = .now
        totalPausedTime = 0
        lapStartTime = .now
        currentLapIndex = 0
        lapDistanceMeters = 0
        completedSplits = []
        startElapsedTimer()
        WKInterfaceDevice.current().play(.start)
        phase = .active
    }

    // MARK: - Pause / Resume

    func pauseRun() {
        guard case .active = phase else { return }
        workoutSession?.pause()
        pauseStartTime = .now
        stopElapsedTimer()
        WKInterfaceDevice.current().play(.stop)
        phase = .paused
    }

    func resumeRun() {
        guard case .paused = phase else { return }
        if let ps = pauseStartTime {
            totalPausedTime += Date.now.timeIntervalSince(ps)
        }
        pauseStartTime = nil
        workoutSession?.resume()
        startElapsedTimer()
        WKInterfaceDevice.current().play(.start)
        phase = .active
    }

    func markLap() {
        let now = Date.now
        let lapTime = now.timeIntervalSince(lapStartTime)
        completedSplits.append(WatchSplitSnapshot(
            index: currentLapIndex,
            distanceMeters: lapDistanceMeters,
            activeDuration: lapTime,
            paceSecondsPerMeter: lapDistanceMeters > 0 ? lapTime / lapDistanceMeters : 0
        ))
        currentLapIndex += 1
        lapDistanceMeters = 0
        lapStartTime = now
        WKInterfaceDevice.current().play(.notification)
    }

    func endRun() {
        switch phase {
        case .active, .paused: break
        default: return
        }
        stopElapsedTimer()
        workoutSession?.end()

        let id = activeRunID ?? UUID()
        activeRunID = nil
        WKInterfaceDevice.current().play(.success)
        phase = .ended(runID: id)
    }

    func resetToIdle() {
        stopElapsedTimer()
        workoutSession = nil
        workoutBuilder = nil
        resetMetrics()
        phase = .idle
    }

    // MARK: - HealthKit Callbacks

    func didReceiveHeartRate(_ bpm: Double) {
        currentHeartRate = bpm
    }

    func didReceiveDistance(_ meters: Double) {
        let delta = meters - distanceMeters
        distanceMeters = meters
        lapDistanceMeters += max(0, delta)
        if elapsedTime > 0, distanceMeters > 0 {
            currentPaceSecondsPerMeter = elapsedTime / distanceMeters
        }
        if lapDistanceMeters >= lapIntervalMeters { markLap() }
    }

    // MARK: - Timer

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.runStartTime else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsedTime = max(0, Date.now.timeIntervalSince(start) - self.totalPausedTime)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate(); elapsedTimer = nil
    }

    private func resetMetrics() {
        elapsedTime = 0; distanceMeters = 0; currentPaceSecondsPerMeter = 0
        currentHeartRate = nil; lapDistanceMeters = 0; currentLapIndex = 0
        completedSplits = []; runStartTime = nil; pauseStartTime = nil; totalPausedTime = 0
    }
}

// MARK: - Watch Split Snapshot

struct WatchSplitSnapshot {
    var index: Int
    var distanceMeters: Double
    var activeDuration: TimeInterval
    var paceSecondsPerMeter: Double
}

// MARK: - Workout Delegates

final class WorkoutSessionDelegate: NSObject, HKWorkoutSessionDelegate {
    private weak var service: WatchRunService?
    static func shared(service: WatchRunService) -> WorkoutSessionDelegate {
        let d = WorkoutSessionDelegate(); d.service = service; return d
    }
    func workoutSession(_ session: HKWorkoutSession, didChangeTo: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {}
}

final class WorkoutBuilderDelegate: NSObject, HKLiveWorkoutBuilderDelegate {
    private weak var service: WatchRunService?
    static func shared(service: WatchRunService) -> WorkoutBuilderDelegate {
        let d = WorkoutBuilderDelegate(); d.service = service; return d
    }
    func workoutBuilderDidCollectEvent(_ builder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ builder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        for type in types {
            guard let qt = type as? HKQuantityType else { continue }
            let stats = builder.statistics(for: qt)
            if qt == HKQuantityType(.heartRate), let qty = stats?.mostRecentQuantity() {
                let bpm = qty.doubleValue(for: HKUnit(from: "count/min"))
                Task { @MainActor [weak self] in self?.service?.didReceiveHeartRate(bpm) }
            }
            if qt == HKQuantityType(.distanceWalkingRunning), let qty = stats?.sumQuantity() {
                let m = qty.doubleValue(for: .meter())
                Task { @MainActor [weak self] in self?.service?.didReceiveDistance(m) }
            }
        }
    }
}
