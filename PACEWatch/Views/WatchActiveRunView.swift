import SwiftUI

struct WatchActiveRunView: View {
    @EnvironmentObject private var service: WatchRunService

    @State private var metricPage: Int = 0
    private let pageCount = 3

    var body: some View {
        TabView(selection: $metricPage) {
            primaryMetricsPage.tag(0)
            secondaryMetricsPage.tag(1)
            lapMetricsPage.tag(2)
        }
        .tabViewStyle(.page)
        .background(Color(hex: "0A0A0A"))
        // Side button triggers pause via Digital Crown long press — handled in WatchPauseView presentation
        .gesture(
            // Double tap = mark lap
            TapGesture(count: 2).onEnded { service.markLap() }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    service.pauseRun()
                } label: {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(Color(hex: "00D4FF"))
                }
            }
        }
    }

    // MARK: - Page 0: Primary Metrics

    private var primaryMetricsPage: some View {
        VStack(spacing: 4) {
            // Primary: Current Pace
            VStack(spacing: 0) {
                Text(paceDisplay)
                    .font(PACEWatchFonts.metricPrimary)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("/km")
                    .font(PACEWatchFonts.metricLabel)
                    .foregroundStyle(Color(hex: "606060"))
                    .tracking(2)
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color(hex: "2A2A2A"))

            // Secondary row
            HStack(spacing: 0) {
                watchSecondaryMetric(
                    value: PACEFormatter.distance(service.distanceMeters, unit: .kilometers),
                    label: "KM"
                )
                Divider()
                    .frame(width: 1, height: 30)
                    .background(Color(hex: "2A2A2A"))
                watchSecondaryMetric(
                    value: PACEFormatter.shortDuration(service.elapsedTime),
                    label: "TIME"
                )
            }
            .frame(maxHeight: .infinity)

            // HR row
            if let hr = service.currentHeartRate {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
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
        .padding(.horizontal, 8)
    }

    // MARK: - Page 1: Secondary Metrics

    private var secondaryMetricsPage: some View {
        VStack(spacing: 8) {
            watchLabeledMetric(
                value: avgPaceDisplay,
                label: "AVG PACE /KM"
            )
            watchLabeledMetric(
                value: PACEFormatter.elevation(service.elevationGain),
                label: "ELEVATION +"
            )
            watchLabeledMetric(
                value: "\(service.completedSplits.count)",
                label: "LAPS"
            )
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Page 2: Lap Metrics

    private var lapMetricsPage: some View {
        VStack(spacing: 8) {
            watchLabeledMetric(
                value: lapPaceDisplay,
                label: "LAP PACE /KM"
            )
            watchLabeledMetric(
                value: PACEFormatter.distance(service.lapDistanceMeters, unit: .kilometers),
                label: "LAP KM"
            )
            Text("LAP \(service.currentLapIndex + 1)")
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "00D4FF"))
                .tracking(3)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Sub-views

    private func watchSecondaryMetric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PACEWatchFonts.metricSecondary)
                .foregroundStyle(.white)
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

    private func watchLabeledMetric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PACEWatchFonts.metricSecondary)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "606060"))
                .tracking(3)
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
        let lapTime = Date.now.timeIntervalSince(service.lapStartTime)
        return PACEFormatter.pace(lapTime / service.lapDistanceMeters, unit: .kilometers)
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
