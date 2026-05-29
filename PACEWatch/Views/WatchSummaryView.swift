import SwiftUI

struct WatchSummaryView: View {
    let run: Run
    let onDismiss: () -> Void

    @State private var page: Int = 0

    var body: some View {
        TabView(selection: $page) {
            mainSummaryPage.tag(0)
            splitsPage.tag(1)
            iPhonePage.tag(2)
        }
        .tabViewStyle(.page)
        .background(Color(hex: "0A0A0A"))
    }

    // MARK: - Page 0: Summary

    private var mainSummaryPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "30D158"))
                    .font(.system(size: 14))
                Text("Run Complete")
                    .font(PACEWatchFonts.metricLabel)
                    .foregroundStyle(Color(hex: "606060"))
                    .tracking(2)
            }

            Text(PACEFormatter.distance(run.distanceMeters, unit: .kilometers, decimals: 2) + " km")
                .font(PACEWatchFonts.metricPrimary)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(PACEFormatter.shortDuration(run.activeDuration))
                        .font(PACEWatchFonts.metricSecondary)
                        .foregroundStyle(.white)
                    Text("TIME")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "606060"))
                        .tracking(3)
                }
                VStack(spacing: 2) {
                    Text(PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: .kilometers) + "/km")
                        .font(PACEWatchFonts.metricSecondary)
                        .foregroundStyle(.white)
                    Text("AVG PACE")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "606060"))
                        .tracking(3)
                }
            }

            if let hr = run.averageHeartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "FF9030"))
                    Text("avg \(Int(hr)) bpm")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "606060"))
                }
            }

            Button("Done") { onDismiss() }
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "00D4FF"))
                .padding(.top, 4)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Page 1: Splits

    private var splitsPage: some View {
        ScrollView {
            VStack(spacing: 4) {
                Text("SPLITS")
                    .font(PACEWatchFonts.metricLabel)
                    .foregroundStyle(Color(hex: "606060"))
                    .tracking(3)
                    .padding(.bottom, 4)

                ForEach(run.splits.sorted { $0.index < $1.index }) { split in
                    HStack {
                        Text("\(split.index + 1)")
                            .font(PACEWatchFonts.metricLabel)
                            .foregroundStyle(Color(hex: "606060"))
                            .frame(width: 20, alignment: .leading)
                        Spacer()
                        Text(PACEFormatter.pace(split.paceSecondsPerMeter, unit: .kilometers) + "/km")
                            .font(PACEWatchFonts.metricSecondary)
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 4)
                    Divider().background(Color(hex: "2A2A2A"))
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Page 2: iPhone CTA

    private var iPhonePage: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "606060"))
            Text("Full details\non iPhone")
                .font(PACEWatchFonts.metricLabel)
                .foregroundStyle(Color(hex: "606060"))
                .multilineTextAlignment(.center)
                .tracking(2)
        }
    }
}
