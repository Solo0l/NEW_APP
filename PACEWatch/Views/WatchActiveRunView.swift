import SwiftUI

// Watch Active Run — handles both .active and .paused phases.
// Pause: Digital Crown button (toolbar) + side button via .onLongPressGesture.
// Pause overlay slides in from bottom when phase == .paused.

struct WatchActiveRunView: View {
    @Environment(WatchRunService.self) private var service

    @State private var page: Int = 0  // 0 = primary, 1 = secondary

    var body: some View {
        ZStack {
            metricsView

            if case .paused = service.phase {
                WatchPauseView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPaused)
        // Side button long-press = pause (best approximation on Watch)
        .onLongPressGesture(minimumDuration: 0.5) {
            if case .active = service.phase { service.pauseRun() }
        }
        .toolbar {
            // Toolbar button as secondary pause affordance
            ToolbarItem(placement: .topBarTrailing) {
                if case .active = service.phase {
                    Button { service.pauseRun() } label: {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(Color(hex: "00D4FF"))
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var isPaused: Bool {
        if case .paused = service.phase { return true }
        return false
    }

    // MARK: - Metrics

    private var metricsView: some View {
        TabView(selection: $page) {
            primaryPage.tag(0)
            secondaryPage.tag(1)
        }
        .tabViewStyle(.page)
        .background(Color(hex: "0A0A0A"))
        // Double tap = mark lap (only in active state)
        .onTapGesture(count: 2) {
            if case .active = service.phase { service.markLap() }
        }
    }

    // MARK: - Page 0: Primary

    private var primaryPage: some View {
        VStack(spacing: 0) {
            // Primary: Current Pace — top half
            VStack(spacing: 2) {
                Text(paceDisplay)
                    .font(PACEWatchFonts.metricPrimary)
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("/km")
                    .font(PACEWatchFonts.metricLabel)
                    .foregroundStyle(Color(hex: "606060"))
                    .tracking(2)
            }
            .frame(maxHeight: .infinity)

            Divider().background(Color(hex: "2A2A2A"))

            // Secondary row: Distance | Time
            HStack(spacing: 0) {
                watchMetric(PACEFormatter.distance(service.distanceMeters, unit: .kilometers), label: "KM")
                Divider().frame(width: 1, height: 28).background(Color(hex: "2A2A2A"))
                watchMetric(PACEFormatter.shortDuration(service.elapsedTime), label: "TIME")
            }
            .frame(maxHeight: .infinity)

            // HR row
            if let hr = service.currentHeartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(hrColor(hr))
                    Text(PACEFormatter.heartRate(hr))
                        .font(PACEWatchFonts.metricSecondary)
                        .foregroundStyle(hrColor(hr))
                    Text("BPM")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "606060"))
                        .tracking(2)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Page 1: Secondary (avg pace, elevation, lap)

    private var secondaryPage: some View {
        VStack(spacing: 10) {
            watchLabeledMetric(avgPaceDisplay, label: "AVG PACE /KM")
            watchLabeledMetric(PACEFormatter.elevation(service.elevationGain), label: "ELEVATION +")
            HStack(spacing: 12) {
                watchLabeledMetric(lapPaceDisplay, label: "LAP PACE")
                watchLabeledMetric("\(service.currentLapIndex + 1)", label: "LAP #")
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Sub-views

    private func watchMetric(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PACEWatchFonts.metricSecondary)
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
            Text(label)
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "606060"))
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
    }

    private func watchLabeledMetric(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PACEWatchFonts.metricSecondary)
                .foregroundStyle(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "606060"))
                .tracking(2)
        }
    }

    // MARK: - Computed

    private var paceDisplay: String {
        PACEFormatter.pace(service.currentPaceSecondsPerMeter, unit: .kilometers)
    }
    private var avgPaceDisplay: String {
        guard service.distanceMeters > 10, service.elapsedTime > 0 else { return "--:--" }
        return PACEFormatter.pace(service.elapsedTime / service.distanceMeters, unit: .kilometers)
    }
    private var lapPaceDisplay: String {
        guard service.lapDistanceMeters > 10 else { return "--:--" }
        return PACEFormatter.pace(Date.now.timeIntervalSince(service.lapStartTime) / service.lapDistanceMeters, unit: .kilometers)
    }

    private func hrColor(_ hr: Double) -> Color {
        let zone = HeartRateZone.zone(for: hr, maxHeartRate: 190)
        switch zone {
        case .zone4: return Color(hex: "FF9030")
        case .zone5: return Color(hex: "FF3060")
        default:     return .white
        }
    }
}
