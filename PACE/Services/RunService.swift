import Foundation
import SwiftData
import Combine

// MARK: - Run State Machine

enum RunPhase: Equatable {
    case idle
    case countdown(secondsRemaining: Int)
    case active
    case paused
    case ended(run: Run)
}

// MARK: - RunService

@Observable
@MainActor
final class RunService: ObservableObject {

    // MARK: - Phase & Metrics

    var phase: RunPhase = .idle

    // Live metrics (mirrors LocationManager, exposed for views)
    var currentPaceSecondsPerMeter: Double = 0
    var distanceMeters: Double = 0
    var elapsedTime: TimeInterval = 0
    var currentHeartRate: Double?
    var elevationGain: Double = 0
    var gpsAccuracy: GPSAccuracy = .acquiring
    var isAtGoalPace: Bool? = nil

    // Lap state
    var currentLapIndex: Int = 0
    var lapDistanceMeters: Double = 0
    var lapStartTime: Date = .now
    var completedSplits: [SplitSnapshot] = []

    // Run-level goal (set before start)
    var activeGoalType: GoalType?
    var activeGoalValueMeters: Double?
    var activeGoalValueSeconds: Double?

    // MARK: - Private

    private let locationManager: LocationManager
    private let healthKitManager: HealthKitManager
    private let modelContext: ModelContext

    private var activeRun: Run?
    private var countdownTimer: Timer?
    private var elapsedTimer: Timer?
    private var lapIntervalMeters: Double?

    // Elapsed time tracking (paused time excluded)
    private var runStartTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0

    // HR snapshot buffer
    private var hrBuffer: [Double] = []
    private var lapHRBuffer: [Double] = []

    // MARK: - Init

    init(locationManager: LocationManager, healthKitManager: HealthKitManager, modelContext: ModelContext) {
        self.locationManager = locationManager
        self.healthKitManager = healthKitManager
        self.modelContext = modelContext
    }

    // MARK: - Public API

    func startCountdown(lapInterval: LapInterval) {
        guard case .idle = phase else { return }
        lapIntervalMeters = lapInterval.meters
        locationManager.startTracking()
        beginCountdown(from: 3)
    }

    func pauseRun() {
        guard case .active = phase else { return }
        pauseStartTime = .now
        locationManager.pauseTracking()
        stopElapsedTimer()
        phase = .paused
    }

    func resumeRun() {
        guard case .paused = phase else { return }
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date.now.timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        locationManager.resumeTracking()
        startElapsedTimer()
        phase = .active
    }

    func markLap() {
        guard case .active = phase else { return }
        let now = Date.now
        let split = SplitSnapshot(
            index: currentLapIndex,
            startDate: lapStartTime,
            endDate: now,
            distanceMeters: lapDistanceMeters,
            activeDuration: now.timeIntervalSince(lapStartTime),
            paceSecondsPerMeter: lapDistanceMeters > 0 ? now.timeIntervalSince(lapStartTime) / lapDistanceMeters : 0,
            averageHeartRate: lapHRBuffer.isEmpty ? nil : lapHRBuffer.reduce(0, +) / Double(lapHRBuffer.count)
        )
        completedSplits.append(split)
        currentLapIndex += 1
        lapDistanceMeters = 0
        lapStartTime = now
        lapHRBuffer = []
        locationManager.resetLapState()
    }

    func endRun() {
        guard case .active = phase, let run = activeRun else {
            if case .paused = phase, let run = activeRun {
                finalizeRun(run)
            }
            return
        }
        finalizeRun(run)
    }

    func discardRun() {
        cleanup()
        phase = .idle
    }

    func setPreRunGoal(type: GoalType, valueMeters: Double? = nil, valueSeconds: Double? = nil) {
        activeGoalType = type
        activeGoalValueMeters = valueMeters
        activeGoalValueSeconds = valueSeconds
    }

    func clearPreRunGoal() {
        activeGoalType = nil
        activeGoalValueMeters = nil
        activeGoalValueSeconds = nil
    }

    // MARK: - Private: Countdown

    private func beginCountdown(from count: Int) {
        phase = .countdown(secondsRemaining: count)
        var remaining = count
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            remaining -= 1
            if remaining > 0 {
                self.phase = .countdown(secondsRemaining: remaining)
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                Task { @MainActor in self.beginActiveRun() }
            }
        }
    }

    private func beginActiveRun() {
        let run = Run(startDate: .now, status: .inProgress)
        run.goalType = activeGoalType
        run.goalValueMeters = activeGoalValueMeters
        run.goalValueSeconds = activeGoalValueSeconds
        modelContext.insert(run)
        activeRun = run

        runStartTime = .now
        totalPausedTime = 0
        lapStartTime = .now
        currentLapIndex = 0
        lapDistanceMeters = 0
        completedSplits = []
        hrBuffer = []
        lapHRBuffer = []

        healthKitManager.beginWorkout()
        startElapsedTimer()
        startMetricsPolling()
        phase = .active
    }

    // MARK: - Private: Timers

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.runStartTime else { return }
            let raw = Date.now.timeIntervalSince(start)
            self.elapsedTime = max(0, raw - self.totalPausedTime)
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Private: Metrics Polling

    private var metricsPollingTimer: Timer?

    private func startMetricsPolling() {
        metricsPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.syncFromLocationManager()
            self.checkAutomaticLap()
            self.updateGoalPaceIndicator()
        }
    }

    private func syncFromLocationManager() {
        currentPaceSecondsPerMeter = locationManager.currentPaceSecondsPerMeter
        distanceMeters = locationManager.totalDistanceMeters
        elevationGain = locationManager.elevationGainMeters
        gpsAccuracy = locationManager.gpsAccuracy

        // Lap tracking
        let previousLapTotal = completedSplits.reduce(0) { $0 + $1.distanceMeters }
        lapDistanceMeters = max(0, distanceMeters - previousLapTotal)

        // HR from HealthKit live stream
        if let hr = healthKitManager.latestHeartRate {
            currentHeartRate = hr
            hrBuffer.append(hr)
            lapHRBuffer.append(hr)
        }
    }

    private func checkAutomaticLap() {
        guard let interval = lapIntervalMeters, interval > 0 else { return }
        if lapDistanceMeters >= interval {
            markLap()
        }
    }

    private func updateGoalPaceIndicator() {
        guard let goalType = activeGoalType else {
            isAtGoalPace = nil
            return
        }
        switch goalType {
        case .singleRunDistance:
            guard let targetMeters = activeGoalValueMeters, targetMeters > 0 else { return }
            // At goal if projected finish time is within 5% of a comfortable pace
            isAtGoalPace = distanceMeters <= targetMeters
        case .singleRunTime:
            guard let targetSeconds = activeGoalValueSeconds, targetSeconds > 0 else { return }
            isAtGoalPace = elapsedTime <= targetSeconds
        default:
            isAtGoalPace = nil
        }
    }

    // MARK: - Private: Finalize

    private func finalizeRun(_ run: Run) {
        stopElapsedTimer()
        metricsPollingTimer?.invalidate()
        metricsPollingTimer = nil
        locationManager.stopTracking()

        let now = Date.now
        run.endDate = now
        run.status = .completed
        run.activeDuration = elapsedTime
        run.totalDuration = runStartTime.map { now.timeIntervalSince($0) } ?? elapsedTime
        run.distanceMeters = distanceMeters
        run.elevationGainMeters = elevationGain
        run.elevationLossMeters = locationManager.elevationLossMeters

        if distanceMeters > 0, elapsedTime > 0 {
            run.averagePaceSecondsPerMeter = elapsedTime / distanceMeters
        }
        if currentPaceSecondsPerMeter > 0 {
            let allPaces = completedSplits.map(\.paceSecondsPerMeter).filter { $0 > 0 }
            run.bestPaceSecondsPerMeter = allPaces.min() ?? currentPaceSecondsPerMeter
        }

        if !hrBuffer.isEmpty {
            run.averageHeartRate = hrBuffer.reduce(0, +) / Double(hrBuffer.count)
            run.maxHeartRate = hrBuffer.max()
        }

        run.route = locationManager.routeCoordinates

        // Persist completed splits
        for s in completedSplits {
            let split = Split(
                index: s.index,
                startDate: s.startDate,
                endDate: s.endDate,
                distanceMeters: s.distanceMeters,
                activeDuration: s.activeDuration,
                paceSecondsPerMeter: s.paceSecondsPerMeter,
                averageHeartRate: s.averageHeartRate,
                elevationGainMeters: s.elevationGainMeters
            )
            split.run = run
            modelContext.insert(split)
        }

        // Final lap if partial
        let finalLapDist = lapDistanceMeters
        if finalLapDist > 50 {  // Only record if >50m into the lap
            let finalSplit = Split(
                index: currentLapIndex,
                startDate: lapStartTime,
                endDate: now,
                distanceMeters: finalLapDist,
                activeDuration: now.timeIntervalSince(lapStartTime),
                paceSecondsPerMeter: finalLapDist > 0 ? now.timeIntervalSince(lapStartTime) / finalLapDist : 0,
                averageHeartRate: lapHRBuffer.isEmpty ? nil : lapHRBuffer.reduce(0, +) / Double(lapHRBuffer.count)
            )
            finalSplit.run = run
            modelContext.insert(finalSplit)
        }

        try? modelContext.save()

        healthKitManager.endWorkout(run: run)
        cleanup()
        phase = .ended(run: run)
    }

    private func cleanup() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopElapsedTimer()
        metricsPollingTimer?.invalidate()
        metricsPollingTimer = nil

        activeRun = nil
        runStartTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
        elapsedTime = 0
        distanceMeters = 0
        currentPaceSecondsPerMeter = 0
        elevationGain = 0
        lapDistanceMeters = 0
        completedSplits = []
        hrBuffer = []
        lapHRBuffer = []
    }
}

// MARK: - SplitSnapshot (in-memory, before persisting)

struct SplitSnapshot {
    var index: Int
    var startDate: Date
    var endDate: Date
    var distanceMeters: Double
    var activeDuration: TimeInterval
    var paceSecondsPerMeter: Double
    var averageHeartRate: Double?
    var elevationGainMeters: Double?
}
