import SwiftUI
import SwiftData

struct ActiveRunView: View {
    @EnvironmentObject private var runService: RunService
    @Query private var users: [User]

    @State private var activeMetricSet: MetricSet = .primary
    @State private var showPauseOverlay = false
    @State private var pauseButtonPressProgress: CGFloat = 0
    @State private var isPauseLongPressing = false
    @State private var lapConfirmOpacity: Double = 0
    @State private var showMapStrip: Bool = false

    private var user: User? { users.first }
    private var unit: DistanceUnit { user?.preferences.distanceUnit ?? .kilometers }
    private var prefs: UserPreferences { user?.preferences ?? .default }

    // Pace smoothing for display (prevents jitter)
    @State private var displayedPace: Double = 0
    private let paceSmoothing: Double = 0.15  // lerp factor per frame

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Zone A — Primary metric (50% height)
                primaryMetricZone
                    .frame(maxHeight: .infinity)

                if showMapStrip {
                    mapStripZone
                        .frame(height: 60)
                }

                // Zone B — Secondary metrics (30% height)
                secondaryMetricsZone
                    .frame(maxHeight: .infinity)

                // Zone C — Controls (20% height)
                controlsZone
                    .frame(height: 120)
            }
            .gesture(dragGesture)

            // Lap confirm feedback
            if lapConfirmOpacity > 0 {
                lapConfirmFeedback
            }

            // Pause overlay
            if showPauseOverlay {
                PauseOverlayView(
                    onResume: { withAnimation(.spring()) { showPauseOverlay = false }; runService.resumeRun() },
                    onLap: { runService.markLap(); withAnimation(.spring()) { showPauseOverlay = false }; runService.resumeRun() },
                    onEnd: { withAnimation(.spring()) { showPauseOverlay = false }; runService.endRun() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: runService.currentPaceSecondsPerMeter) { _, newPace in
            smoothPace(toward: newPace)
        }
    }

    // MARK: - Zone A: Primary Metric

    private var primaryMetricZone: some View {
        VStack(spacing: PACESpacing.xs) {
            Spacer()

            Text(paceDisplay)
                .font(PACEFonts.metricPrimary)
                .foregroundStyle(paceColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: false))
                .animation(.easeInOut(duration: 0.3), value: paceDisplay)

            HStack(spacing: 4) {
                Text("/\(unit.displayName)")
                    .font(PACEFonts.metricLabel)
                    .foregroundStyle(PACEColors.textSecondary)
                    .tracking(3)
                if let isAtGoal = runService.isAtGoalPace {
                    Text(isAtGoal ? "+" : "−")
                        .font(PACEFonts.metricLabel)
                        .foregroundStyle(isAtGoal ? PACEColors.accentCyan : PACEColors.accentOrange)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current pace: \(paceDisplay) per \(unit.displayName)")
    }

    // MARK: - Zone B: Secondary Metrics

    private var secondaryMetricsZone: some View {
        Group {
            switch activeMetricSet {
            case .primary:  primarySecondaryMetrics
            case .secondary: secondarySetMetrics
            case .laps:     lapSetMetrics
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var primarySecondaryMetrics: some View {
        VStack(spacing: PACESpacing.sm) {
            PACESeparator()
                .padding(.horizontal, PACESpacing.xl)
            HStack(spacing: 0) {
                secondaryMetric(
                    value: PACEFormatter.distance(runService.distanceMeters, unit: unit),
                    label: unit.displayName
                )
                dividerLine
                secondaryMetric(
                    value: PACEFormatter.duration(runService.elapsedTime),
                    label: "TIME"
                )
                dividerLine
                secondaryMetric(
                    value: PACEFormatter.heartRate(runService.currentHeartRate),
                    label: "BPM",
                    accent: hrColor
                )
            }
            metricSetDots
        }
    }

    private var secondarySetMetrics: some View {
        VStack(spacing: PACESpacing.sm) {
            PACESeparator().padding(.horizontal, PACESpacing.xl)
            HStack(spacing: 0) {
                secondaryMetric(
                    value: avgPaceDisplay,
                    label: "AVG/\(unit.displayName)"
                )
                dividerLine
                secondaryMetric(
                    value: PACEFormatter.elevation(runService.elevationGain),
                    label: "ELEV+"
                )
                dividerLine
                secondaryMetric(
                    value: lapCountDisplay,
                    label: "LAPS"
                )
            }
            metricSetDots
        }
    }

    private var lapSetMetrics: some View {
        VStack(spacing: PACESpacing.sm) {
            PACESeparator().padding(.horizontal, PACESpacing.xl)
            HStack(spacing: 0) {
                secondaryMetric(
                    value: lapPaceDisplay,
                    label: "LAP/\(unit.displayName)"
                )
                dividerLine
                secondaryMetric(
                    value: PACEFormatter.distance(runService.lapDistanceMeters, unit: unit),
                    label: "LAP \(unit.displayName)"
                )
                dividerLine
                secondaryMetric(
                    value: "\(runService.currentLapIndex + 1)",
                    label: "LAP #"
                )
            }
            metricSetDots
        }
    }

    private func secondaryMetric(value: String, label: String, accent: Color = PACEColors.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(PACEFonts.metricSecondary)
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(label.uppercased())
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(PACEColors.separator)
            .frame(width: 1, height: 40)
    }

    private var metricSetDots: some View {
        HStack(spacing: 5) {
            ForEach(MetricSet.allCases, id: \.self) { set in
                Circle()
                    .fill(activeMetricSet == set ? PACEColors.accentCyan : PACEColors.textTertiary)
                    .frame(width: activeMetricSet == set ? 6 : 4, height: activeMetricSet == set ? 6 : 4)
                    .animation(.easeInOut(duration: 0.2), value: activeMetricSet)
            }
        }
        .padding(.bottom, PACESpacing.sm)
    }

    // MARK: - Zone C: Controls

    private var controlsZone: some View {
        ZStack {
            HStack {
                // Lap button
                Button {
                    triggerLapFeedback()
                    runService.markLap()
                } label: {
                    Circle()
                        .fill(PACEColors.surfaceElevated)
                        .frame(width: PACESpacing.lapButtonSize, height: PACESpacing.lapButtonSize)
                        .overlay(
                            Image(systemName: "flag.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(PACEColors.textSecondary)
                        )
                }
                .accessibilityLabel("Mark lap")

                Spacer()

                // Split arc progress
                lapProgressArc
            }
            .padding(.horizontal, PACESpacing.xxl)

            // Pause button — center
            pauseButton
        }
    }

    private var pauseButton: some View {
        ZStack {
            // Long press progress ring
            if isPauseLongPressing {
                Circle()
                    .trim(from: 0, to: pauseButtonPressProgress)
                    .stroke(PACEColors.accentCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: PACESpacing.pauseButtonSize + 8, height: PACESpacing.pauseButtonSize + 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.6), value: pauseButtonPressProgress)
            }

            Circle()
                .fill(PACEColors.surfaceElevated)
                .frame(width: PACESpacing.pauseButtonSize, height: PACESpacing.pauseButtonSize)
                .overlay(
                    Image(systemName: "pause.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(PACEColors.textPrimary)
                )
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onChanged { _ in
                    isPauseLongPressing = true
                    withAnimation(.linear(duration: 0.6)) { pauseButtonPressProgress = 1.0 }
                }
                .onEnded { _ in
                    isPauseLongPressing = false
                    pauseButtonPressProgress = 0
                    runService.pauseRun()
                    withAnimation(.spring()) { showPauseOverlay = true }
                }
        )
        .onChange(of: isPauseLongPressing) { _, pressing in
            if !pressing { pauseButtonPressProgress = 0 }
        }
        .accessibilityLabel("Pause run")
    }

    private var lapProgressArc: some View {
        ZStack {
            Circle()
                .stroke(PACEColors.surfaceElevated, lineWidth: 3)
            Circle()
                .trim(from: 0, to: lapProgress)
                .stroke(PACEColors.textSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: lapProgress)
        }
        .frame(width: 36, height: 36)
    }

    // MARK: - Map Strip

    private var mapStripZone: some View {
        Rectangle()
            .fill(PACEColors.surface)
            .overlay(
                Text("Map strip")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            )
    }

    // MARK: - Lap Confirm Feedback

    private var lapConfirmFeedback: some View {
        VStack {
            HStack {
                Spacer()
                ToastView(message: "Lap \(runService.currentLapIndex)", icon: "flag.fill")
                    .opacity(lapConfirmOpacity)
                    .padding(.trailing, PACESpacing.md)
                    .padding(.top, PACESpacing.lg)
            }
            Spacer()
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let h = value.translation.width
                let v = value.translation.height
                if abs(h) > abs(v) {
                    // Horizontal swipe: cycle metric set
                    if h < 0 {
                        cycleMetricSet(forward: true)
                    } else {
                        cycleMetricSet(forward: false)
                    }
                } else if v > 60 {
                    withAnimation(.spring()) { showMapStrip.toggle() }
                }
            }
    }

    private func cycleMetricSet(forward: Bool) {
        let sets = MetricSet.allCases
        let current = sets.firstIndex(of: activeMetricSet) ?? 0
        let next = forward
            ? (current + 1) % sets.count
            : (current - 1 + sets.count) % sets.count
        withAnimation(.easeInOut(duration: 0.2)) { activeMetricSet = sets[next] }
    }

    // MARK: - Computed Display Values

    private var paceDisplay: String {
        if displayedPace > 0 {
            return PACEFormatter.pace(displayedPace, unit: unit)
        }
        return "--:--"
    }

    private var avgPaceDisplay: String {
        guard runService.distanceMeters > 10, runService.elapsedTime > 0 else { return "--:--" }
        let avg = runService.elapsedTime / runService.distanceMeters
        return PACEFormatter.pace(avg, unit: unit)
    }

    private var lapPaceDisplay: String {
        guard runService.lapDistanceMeters > 10 else { return "--:--" }
        let lapTime = Date.now.timeIntervalSince(runService.lapStartTime)
        let lapPace = lapTime / runService.lapDistanceMeters
        return PACEFormatter.pace(lapPace, unit: unit)
    }

    private var lapCountDisplay: String { "\(runService.completedSplits.count)" }

    private var lapProgress: Double {
        guard let interval = LapInterval.oneKilometer.meters, interval > 0 else { return 0 }
        return min(runService.lapDistanceMeters / interval, 1.0)
    }

    private var paceColor: Color {
        PACEColors.paceTint(isAtGoal: runService.isAtGoalPace)
    }

    private var hrColor: Color {
        guard let hr = runService.currentHeartRate else { return PACEColors.textPrimary }
        let zone = HeartRateZone.zone(for: hr, maxHeartRate: user?.preferences.estimatedMaxHeartRate ?? 190)
        return zone == .zone4 ? PACEColors.accentOrange : zone == .zone5 ? PACEColors.error : PACEColors.textPrimary
    }

    // MARK: - Pace Smoothing

    private func smoothPace(toward target: Double) {
        guard target > 0 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedPace = displayedPace == 0 ? target : displayedPace + (target - displayedPace) * paceSmoothing
        }
    }

    // MARK: - Lap Feedback

    private func triggerLapFeedback() {
        lapConfirmOpacity = 1.0
        withAnimation(.easeOut(duration: 0.3).delay(1.2)) {
            lapConfirmOpacity = 0
        }
    }
}
