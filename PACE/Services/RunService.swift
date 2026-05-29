import Foundation
import SwiftData

// MARK: - RunService
// Single source of truth for the active run state machine.
// @Observable only — no ObservableObject conformance.

@Observable
@MainActor
final class RunService {

    // MARK: - Phase

    var phase: RunPhase = .idle

    // MARK: - Live Metrics (read by views)

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
    var lapIntervalMeters: Double? = nil

    // Per-run goal
    var activeGoalType: GoalType?
    var activeGoalValueMeters: Double?
    var activeGoalValueSeconds: Double?

    // MARK: - Private

    private let locationManager: LocationManager
    private let healthKitManager: HealthKitManager
    private let modelContext: ModelContext

    private var activeRunID: UUID?
    private var countdownTimer: Timer?
    private var elapsedTimer: Timer?
    private var metricsTimer: Timer?

    private var runStartTime: Date?
    private var pauseStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
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
        countdown(from: 3)
    }

    func pauseRun() {
        guard case .active = phase else { return }
        pauseStartTime = .now
        locationManager.pauseTracking()
        stopTimers()
        phase = .paused
    }

    func resumeRun() {
        guard case .paused = phase else { return }
        if let ps = pauseStartTime {
            totalPausedTime += Date.now.timeIntervalSince(ps)
        }
        pauseStartTime = nil
        locationManager.resumeTracking()
        startElapsedTimer()
        startMetricsTimer()
        phase = .active
    }

    func markLap() {
        guard case .active = phase else { return }
        let now = Date.now
        let lapTime = now.timeIntervalSince(lapStartTime)
        let snapshot = SplitSnapshot(
            index: currentLapIndex,
            startDate: lapStartTime,
            endDate: now,
            distanceMeters: lapDistanceMeters,
            activeDuration: lapTime,
            paceSecondsPerMeter: lapDistanceMeters > 0 ? lapTime / lapDistanceMeters : 0,
            averageHeartRate: lapHRBuffer.average
        )
        completedSplits.append(snapshot)
        currentLapIndex += 1
        lapDistanceMeters = 0
        lapStartTime = now
        lapHRBuffer = []
    }

    func finishRun() {
        switch phase {
        case .active, .paused:
            finalizeRun()
        default:
            break
        }
    }

    func discardAndReset() {
        stopTimers()
        locationManager.stopTracking()
        resetState()
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

    private func countdown(from count: Int) {
        phase = .countdown(secondsRemaining: count)
        var remaining = count
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            remaining -= 1
            if remaining > 0 {
                Task { @MainActor [weak self] in
                    self?.phase = .countdown(secondsRemaining: remaining)
                }
            } else {
                timer.invalidate()
                Task { @MainActor [weak self] in self?.beginActiveRun() }
            }
        }
    }

    private func beginActiveRun() {
        let run = Run(startDate: .now, status: .inProgress)
        run.goalType = activeGoalType
        run.goalValueMeters = activeGoalValueMeters
        run.goalValueSeconds = activeGoalValueSeconds
        modelContext.insert(run)
        do {
            try modelContext.save()
        } catch {
            // Run record created in-memory even if initial save fails
        }
        activeRunID = run.id

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
        startMetricsTimer()
        phase = .active
    }

    // MARK: - Private: Timers

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let start = self.runStartTime else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsedTime = max(0, Date.now.timeIntervalSince(start) - self.totalPausedTime)
            }
        }
    }

    private func startMetricsTimer() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.syncMetrics() }
        }
    }

    private func stopTimers() {
        countdownTimer?.invalidate(); countdownTimer = nil
        elapsedTimer?.invalidate(); elapsedTimer = nil
        metricsTimer?.invalidate(); metricsTimer = nil
    }

    // MARK: - Private: Metrics Sync

    private func syncMetrics() {
        currentPaceSecondsPerMeter = locationManager.currentPaceSecondsPerMeter
        distanceMeters = locationManager.totalDistanceMeters
        elevationGain = locationManager.elevationGainMeters
        gpsAccuracy = locationManager.gpsAccuracy

        let splitTotal = completedSplits.reduce(0) { $0 + $1.distanceMeters }
        lapDistanceMeters = max(0, distanceMeters - splitTotal)

        if let hr = healthKitManager.latestHeartRate {
            currentHeartRate = hr
            hrBuffer.append(hr)
            lapHRBuffer.append(hr)
        }

        checkAutoLap()
        updateGoalPaceIndicator()
    }

    private func checkAutoLap() {
        guard let interval = lapIntervalMeters, interval > 0,
              lapDistanceMeters >= interval else { return }
        markLap()
    }

    private func updateGoalPaceIndicator() {
        switch activeGoalType {
        case .singleRunDistance:
            guard let t = activeGoalValueMeters, t > 0 else { isAtGoalPace = nil; return }
            isAtGoalPace = distanceMeters <= t
        case .singleRunTime:
            guard let t = activeGoalValueSeconds, t > 0 else { isAtGoalPace = nil; return }
            isAtGoalPace = elapsedTime <= t
        default:
            isAtGoalPace = nil
        }
    }

    // MARK: - Private: Finalize

    private func finalizeRun() {
        stopTimers()
        locationManager.stopTracking()

        guard let runID = activeRunID else {
            resetState()
            phase = .idle
            return
        }

        let fetchDescriptor = FetchDescriptor<Run>(predicate: #Predicate { $0.id == runID })
        guard let run = (try? modelContext.fetch(fetchDescriptor))?.first else {
            resetState()
            phase = .idle
            return
        }

        let now = Date.now
        run.endDate = now
        run.status = .completed
        run.activeDuration = elapsedTime
        run.totalDuration = runStartTime.map { now.timeIntervalSince($0) } ?? elapsedTime
        run.distanceMeters = distanceMeters
        run.elevationGainMeters = elevationGain
        run.elevationLossMeters = locationManager.elevationLossMeters
        run.route = locationManager.routeCoordinates

        if distanceMeters > 0, elapsedTime > 0 {
            run.averagePaceSecondsPerMeter = elapsedTime / distanceMeters
        }

        let allSplitPaces = completedSplits.map(\.paceSecondsPerMeter).filter { $0 > 0 }
        run.bestPaceSecondsPerMeter = allSplitPaces.min() ?? run.averagePaceSecondsPerMeter

        if !hrBuffer.isEmpty {
            run.averageHeartRate = hrBuffer.average
            run.maxHeartRate = hrBuffer.max()
        }

        for snapshot in completedSplits {
            let split = Split(
                index: snapshot.index, startDate: snapshot.startDate, endDate: snapshot.endDate,
                distanceMeters: snapshot.distanceMeters, activeDuration: snapshot.activeDuration,
                paceSecondsPerMeter: snapshot.paceSecondsPerMeter, averageHeartRate: snapshot.averageHeartRate
            )
            split.run = run
            modelContext.insert(split)
        }

        // Final partial lap (only if meaningful distance covered)
        if lapDistanceMeters > 50 {
            let lapTime = now.timeIntervalSince(lapStartTime)
            let finalSplit = Split(
                index: currentLapIndex, startDate: lapStartTime, endDate: now,
                distanceMeters: lapDistanceMeters, activeDuration: lapTime,
                paceSecondsPerMeter: lapDistanceMeters > 0 ? lapTime / lapDistanceMeters : 0,
                averageHeartRate: lapHRBuffer.average
            )
            finalSplit.run = run
            modelContext.insert(finalSplit)
        }

        do {
            try modelContext.save()
        } catch {
            // Run is still in the context in-memory; user won't lose data this session
        }

        healthKitManager.endWorkout(run: run)

        let completedID = runID
        resetState()
        phase = .ended(runID: completedID)
    }

    private func resetState() {
        activeRunID = nil
        runStartTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
        elapsedTime = 0
        distanceMeters = 0
        currentPaceSecondsPerMeter = 0
        elevationGain = 0
        lapDistanceMeters = 0
        currentLapIndex = 0
        completedSplits = []
        hrBuffer = []
        lapHRBuffer = []
        currentHeartRate = nil
        isAtGoalPace = nil
    }
}

// MARK: - SplitSnapshot

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

// MARK: - Array<Double> helper

private extension Array where Element == Double {
    var average: Double? {
        isEmpty ? nil : reduce(0, +) / Double(count)
    }
}
