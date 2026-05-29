import SwiftUI
import SwiftData
import MapKit

struct RunSummaryView: View {
    let run: Run

    @Query private var allRuns: [Run]
    @Query private var users: [User]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showFullMap = false
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var showSplits = false

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .kilometers }
    private var insight: RunInsight? {
        AnalyticsEngine().insight(for: run, allRuns: allRuns)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PACESpacing.lg) {
                headerSection
                mapCard
                if let insight { insightCard(insight) }
                statsGrid
                if !run.splits.isEmpty { splitsSection }
                if run.averageHeartRate != nil { heartRateSection }
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.top, PACESpacing.md)
            .padding(.bottom, PACESpacing.xxxl)
        }
        .paceBackground()
        .navigationTitle(PACEFormatter.runDate(run.startDate))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { overflowMenu }
        .sheet(isPresented: $showFullMap) { FullMapView(run: run) }
        .alert("Delete Run", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(run)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This run will be permanently deleted.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: PACESpacing.sm) {
            Text(PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 2))
                .font(PACEFonts.statLarge)
                .foregroundStyle(PACEColors.textPrimary)
            + Text(" \(unit.displayName)")
                .font(PACEFonts.statMedium)
                .foregroundStyle(PACEColors.textSecondary)

            HStack(spacing: PACESpacing.xl) {
                VStack(spacing: 2) {
                    Text(PACEFormatter.duration(run.activeDuration))
                        .font(PACEFonts.statMedium)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text("TIME")
                        .font(PACEFonts.metricLabel)
                        .foregroundStyle(PACEColors.textSecondary)
                        .tracking(3)
                }
                VStack(spacing: 2) {
                    Text(PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit) + "/\(unit.displayName)")
                        .font(PACEFonts.statMedium)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text("AVG PACE")
                        .font(PACEFonts.metricLabel)
                        .foregroundStyle(PACEColors.textSecondary)
                        .tracking(3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, PACESpacing.sm)
    }

    // MARK: - Map Card

    private var mapCard: some View {
        Button { showFullMap = true } label: {
            RouteMapView(coordinates: run.route, isInteractive: false)
                .frame(height: 200)
                .cornerRadius(PACESpacing.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: PACESpacing.cardCornerRadius)
                        .stroke(PACEColors.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Insight Card

    private func insightCard(_ insight: RunInsight) -> some View {
        HStack(spacing: PACESpacing.md) {
            Image(systemName: insight.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(insight.isPositive ? PACEColors.accentCyan : PACEColors.accentOrange)
            Text(insight.headline)
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.textPrimary)
            Spacer()
        }
        .padding(PACESpacing.md)
        .background(insight.isPositive ? PACEColors.accentCyanDim : PACEColors.accentOrange.opacity(0.1))
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PACESpacing.sm) {
            MetricCard(
                value: PACEFormatter.pace(run.bestPaceSecondsPerMeter, unit: unit),
                label: "Best Pace"
            )
            MetricCard(
                value: PACEFormatter.elevation(run.elevationGainMeters),
                label: "Elevation +"
            )
            if let avgHR = run.averageHeartRate {
                MetricCard(
                    value: PACEFormatter.heartRate(avgHR),
                    label: "Avg HR",
                    accent: PACEColors.hrZone2
                )
            }
            if let maxHR = run.maxHeartRate {
                MetricCard(
                    value: PACEFormatter.heartRate(maxHR),
                    label: "Max HR",
                    accent: PACEColors.hrZone4
                )
            }
            if let cal = run.activeCalories {
                MetricCard(value: "\(Int(cal))", label: "Calories")
            }
            MetricCard(
                value: PACEFormatter.duration(run.totalDuration - run.activeDuration),
                label: "Paused"
            )
        }
    }

    // MARK: - Splits Section

    private var splitsSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring()) { showSplits.toggle() }
            } label: {
                HStack {
                    Text("Splits")
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                    Spacer()
                    Image(systemName: showSplits ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PACEColors.textSecondary)
                }
                .padding(PACESpacing.md)
                .background(PACEColors.surface)
                .cornerRadius(showSplits ? 16 : 16, corners: showSplits ? [.topLeft, .topRight] : .allCorners)
            }
            .buttonStyle(.plain)

            if showSplits {
                SplitsTableView(splits: run.splits.sorted { $0.index < $1.index }, unit: unit)
            }
        }
    }

    // MARK: - Heart Rate Section

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Heart Rate Zones")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
                .padding(.leading, PACESpacing.xs)
            HeartRateZoneBar(metrics: run.metrics)
                .frame(height: 48)
                .padding(PACESpacing.md)
                .background(PACEColors.surface)
                .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Overflow Menu

    @ToolbarContentBuilder
    private var overflowMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { exportGPX() } label: {
                    Label("Export GPX", systemImage: "arrow.up.doc")
                }
                Button { showShareSheet = true } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete Run", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(PACEColors.textPrimary)
            }
        }
    }

    private func exportGPX() {
        let gpx = HealthKitManager().exportGPX(run: run)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("run_\(run.id).gpx")
        try? gpx.write(to: url, atomically: true, encoding: .utf8)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(av, animated: true)
    }
}

// MARK: - Route Map View

struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var isInteractive: Bool = true

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, interactionModes: isInteractive ? .all : [])
            .overlay(routeOverlay)
            .onAppear { fitRoute() }
    }

    private var routeOverlay: some View {
        GeometryReader { geo in
            Canvas { context, size in
                guard coordinates.count > 1 else { return }
                var path = Path()
                let points = coordinates.map { coord -> CGPoint in
                    let x = (coord.longitude - (region.center.longitude - region.span.longitudeDelta / 2)) /
                            region.span.longitudeDelta * size.width
                    let y = size.height - (coord.latitude - (region.center.latitude - region.span.latitudeDelta / 2)) /
                            region.span.latitudeDelta * size.height
                    return CGPoint(x: x, y: y)
                }
                path.move(to: points[0])
                for point in points.dropFirst() { path.addLine(to: point) }
                context.stroke(path, with: .color(PACEColors.accentCyan), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func fitRoute() {
        if let fitRegion = coordinates.boundingRegion {
            region = fitRegion
        }
    }
}

// MARK: - Full Map View

struct FullMapView: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RouteMapView(coordinates: run.route, isInteractive: true)
                .ignoresSafeArea()
                .navigationTitle("Route")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Splits Table

struct SplitsTableView: View {
    let splits: [Split]
    let unit: DistanceUnit

    private var paces: [Double] { splits.map(\.paceSecondsPerMeter).filter { $0 > 0 } }
    private var avgPace: Double { paces.isEmpty ? 0 : paces.reduce(0, +) / Double(paces.count) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(splits.indices, id: \.self) { i in
                let split = splits[i]
                HStack(spacing: PACESpacing.md) {
                    Text("\(split.index + 1)")
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                        .frame(width: 24, alignment: .leading)

                    paceBar(for: split)

                    Spacer()

                    Text(PACEFormatter.pace(split.paceSecondsPerMeter, unit: unit) + "/\(unit.displayName)")
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textPrimary)
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, PACESpacing.md)
                .padding(.vertical, PACESpacing.sm)
                .background(PACEColors.surface)

                if i < splits.count - 1 {
                    PACESeparator().padding(.leading, PACESpacing.xl)
                }
            }
        }
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func paceBar(for split: Split) -> some View {
        let pace = split.paceSecondsPerMeter
        let isFaster = pace > 0 && avgPace > 0 && pace < avgPace
        let ratio = avgPace > 0 ? min(pace / avgPace, 2.0) : 1.0
        let width = isFaster ? CGFloat(2.0 - ratio) * 60 : CGFloat(ratio - 1.0) * 40

        return HStack(spacing: 0) {
            if isFaster {
                Spacer()
                Rectangle()
                    .fill(PACEColors.accentCyan)
                    .frame(width: max(4, width), height: 4)
                    .cornerRadius(2)
            } else {
                Rectangle()
                    .fill(PACEColors.accentOrange)
                    .frame(width: max(4, width), height: 4)
                    .cornerRadius(2)
                Spacer()
            }
        }
        .frame(width: 80)
    }
}

// MARK: - HR Zone Bar

struct HeartRateZoneBar: View {
    let metrics: [HealthMetricSnapshot]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    let fraction = zoneFraction(zone)
                    if fraction > 0 {
                        Rectangle()
                            .fill(PACEColors.hrZoneColor(zone))
                            .frame(width: geo.size.width * CGFloat(fraction))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    private func zoneFraction(_ zone: HeartRateZone) -> Double {
        let hrSamples = metrics.compactMap(\.heartRate)
        guard !hrSamples.isEmpty else { return zone == .zone2 ? 1.0 : 0 }
        let maxHR = 190.0
        let inZone = hrSamples.filter { hr in
            hr >= zone.lowerBound * maxHR && hr < zone.upperBound * maxHR
        }
        return Double(inZone.count) / Double(hrSamples.count)
    }
}
