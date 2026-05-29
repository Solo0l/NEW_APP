import SwiftUI
import SwiftData

struct ActiveRunView: View {
    @Environment(RunService.self) private var runService
    @Query private var users: [User]

    @State private var activeSet: MetricSet = .primary
    @State private var showPauseOverlay = false
    @State private var pausePressProgress: CGFloat = 0
    @State private var isPressing = false
    @State private var lapFeedback: String? = nil
    @State private var lapFeedbackOpacity: Double = 0
    @State private var displayedPace: Double = 0

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .systemDefault }
    private var maxHR: Double { users.first?.preferences.estimatedMaxHeartRate ?? 190 }

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                zoneA          // Primary metric — 50%
                zoneSeparator
                zoneB          // Secondary metrics — 30%
                zoneC          // Controls — 20%
            }
            .gesture(horizontalSwipe)

            if let feedback = lapFeedback {
                lapFeedbackBanner(feedback)
            }

            if showPauseOverlay {
                PauseOverlayView(
                    onResume: {
                        withAnimation(.spring(dampingFraction: 0.8)) { showPauseOverlay = false }
                        runService.resumeRun()
                    },
                    onLap: {
                        runService.markLap()
                        withAnimation(.spring(dampingFraction: 0.8)) { showPauseOverlay = false }
                        runService.resumeRun()
                    },
                    onEnd: {
                        withAnimation(.spring(dampingFraction: 0.8)) { showPauseOverlay = false }
                        runService.finishRun()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: runService.currentPaceSecondsPerMeter) { _, newPace in
            guard newPace > 0 else { return }
            let target = newPace
            withAnimation(.linear(duration: 1.0)) {
                displayedPace = displayedPace == 0 ? target : displayedPace * 0.85 + target * 0.15
            }
        }
        .onChange(of: runService.phase) { _, phase in
            // Show pause overlay when phase transitions to .paused
            if case .paused = phase {
                withAnimation(.spring(dampingFraction: 0.8)) { showPauseOverlay = true }
            }
        }
    }

    // MARK: - Zone A: Primary Metric

    private var zoneA: some View {
        VStack(spacing: PACESpacing.xs) {
            Spacer()
            Text(paceDisplay)
                .font(PACEFonts.metricPrimary)
                .foregroundStyle(paceColor)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: false))
                .accessibilityLabel("Pace: \(paceDisplay) per \(unit.displayName)")

            HStack(spacing: 6) {
                Text("/\(unit.displayName)")
                    .font(PACEFonts.metricLabel)
                    .foregroundStyle(PACEColors.textSecondary)
                    .tracking(3)
                // Color-independent pace indicator
                if let onGoal = runService.isAtGoalPace {
                    Image(systemName: onGoal ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(onGoal ? PACEColors.accentCyan : PACEColors.accentOrange)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Zone Separator

    private var zoneSeparator: some View {
        PACESeparator().padding(.horizontal, PACESpacing.xl)
    }

    // MARK: - Zone B: Secondary Metrics

    private var zoneB: some View {
        Group {
            switch activeSet {
            case .primary:
                HStack(spacing: 0) {
                    secondaryMetric(PACEFormatter.distance(runService.distanceMeters, unit: unit), label: unit.displayName.uppercased())
                    verticalDivider
                    secondaryMetric(PACEFormatter.duration(runService.elapsedTime), label: "TIME")
                    verticalDivider
                    secondaryMetric(PACEFormatter.heartRate(runService.currentHeartRate), label: "BPM", accent: hrColor)
                }
            case .secondary:
                HStack(spacing: 0) {
                    secondaryMetric(avgPaceDisplay, label: "AVG/\(unit.displayName.uppercased())")
                    verticalDivider
                    secondaryMetric(PACEFormatter.elevation(runService.elevationGain), label: "ELEV+")
                    verticalDivider
                    secondaryMetric(lapPaceDisplay, label: "LAP")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) { setIndicator }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.15), value: activeSet)
    }

    private func secondaryMetric(_ value: String, label: String, accent: Color = PACEColors.textPrimary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(PACEFonts.metricSecondary)
                .foregroundStyle(accent)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(label)
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(PACEColors.separator)
            .frame(width: 1, height: 36)
    }

    private var setIndicator: some View {
        HStack(spacing: 5) {
            ForEach(MetricSet.allCases, id: \.self) { set in
                Circle()
                    .fill(activeSet == set ? PACEColors.accentCyan : PACEColors.textTertiary)
                    .frame(width: activeSet == set ? 6 : 4, height: activeSet == set ? 6 : 4)
                    .animation(.easeInOut(duration: 0.15), value: activeSet)
            }
        }
        .padding(.bottom, PACESpacing.sm)
    }

    // MARK: - Zone C: Controls

    private var zoneC: some View {
        HStack(spacing: 0) {
            // Lap button — left
            Button {
                runService.markLap()
                showLapFeedback()
            } label: {
                Circle()
                    .fill(PACEColors.surfaceElevated)
                    .frame(width: PACESpacing.lapButtonSize, height: PACESpacing.lapButtonSize)
                    .overlay(
                        Image(systemName: "flag")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(PACEColors.textSecondary)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark lap")
            .frame(maxWidth: .infinity)

            // Pause button — center
            ZStack {
                if isPressing {
                    Circle()
                        .trim(from: 0, to: pausePressProgress)
                        .stroke(PACEColors.accentCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: PACESpacing.pauseButtonSize + 10, height: PACESpacing.pauseButtonSize + 10)
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
            .gesture(pauseGesture)
            .accessibilityLabel("Pause run — hold to activate")
            .frame(maxWidth: .infinity)

            // Lap progress arc — right
            lapArc.frame(maxWidth: .infinity)
        }
        .frame(height: 120)
    }

    private var lapArc: some View {
        let lapInterval = users.first?.preferences.lapInterval.meters
        let progress: Double = {
            guard let interval = lapInterval, interval > 0 else { return 0 }
            return min(runService.lapDistanceMeters / interval, 1.0)
        }()

        return ZStack {
            Circle().stroke(PACEColors.surfaceElevated, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(PACEColors.textSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)
        }
        .frame(width: 34, height: 34)
    }

    // MARK: - Lap Feedback Banner

    private func lapFeedbackBanner(_ text: String) -> some View {
        VStack {
            HStack {
                Spacer()
                ToastView(message: text, icon: "flag.fill")
                    .opacity(lapFeedbackOpacity)
                    .padding(.trailing, PACESpacing.md)
                    .padding(.top, PACESpacing.lg)
            }
            Spacer()
        }
    }

    // MARK: - Gestures

    private var horizontalSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    activeSet = activeSet == .primary ? .secondary : .primary
                }
            }
    }

    private var pauseGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.6)
            .onChanged { _ in
                isPressing = true
                withAnimation(.linear(duration: 0.6)) { pausePressProgress = 1.0 }
            }
            .onEnded { _ in
                isPressing = false
                pausePressProgress = 0
                runService.pauseRun()
                // PauseOverlay will appear via .onChange(of: runService.phase)
            }
    }

    // MARK: - Computed

    private var paceDisplay: String {
        displayedPace > 0 ? PACEFormatter.pace(displayedPace, unit: unit) : "--:--"
    }

    private var avgPaceDisplay: String {
        guard runService.distanceMeters > 10, runService.elapsedTime > 0 else { return "--:--" }
        return PACEFormatter.pace(runService.elapsedTime / runService.distanceMeters, unit: unit)
    }

    private var lapPaceDisplay: String {
        guard runService.lapDistanceMeters > 10 else { return "--:--" }
        let lapTime = Date.now.timeIntervalSince(runService.lapStartTime)
        return PACEFormatter.pace(lapTime / runService.lapDistanceMeters, unit: unit)
    }

    private var paceColor: Color {
        PACEColors.paceTint(isAtGoal: runService.isAtGoalPace)
    }

    private var hrColor: Color {
        guard let hr = runService.currentHeartRate else { return PACEColors.textPrimary }
        let zone = HeartRateZone.zone(for: hr, maxHeartRate: maxHR)
        switch zone {
        case .zone4: return PACEColors.accentOrange
        case .zone5: return PACEColors.error
        default:     return PACEColors.textPrimary
        }
    }

    // MARK: - Lap Feedback

    private func showLapFeedback() {
        let count = runService.currentLapIndex
        lapFeedback = "Lap \(count)"
        lapFeedbackOpacity = 1
        withAnimation(.easeOut(duration: 0.3).delay(1.5)) { lapFeedbackOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { lapFeedback = nil }
    }
}
