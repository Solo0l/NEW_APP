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
    @State private var showDeleteAlert = false
    @State private var showSplits = false

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .systemDefault }
    private var maxHR: Double { users.first?.preferences.estimatedMaxHeartRate ?? 190 }
    private var insight: PACEAnalytics.RunInsight? {
        PACEAnalytics.insight(for: run, allRuns: allRuns)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PACESpacing.lg) {
                // Insight leads — it's the most motivating data
                if let insight { insightCard(insight) }
                headerSection
                mapCard
                statsGrid
                if !run.splits.isEmpty { splitsSection }
                if !run.metrics.isEmpty || run.averageHeartRate != nil { hrSection }
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.top, PACESpacing.md)
            .padding(.bottom, PACESpacing.xxxl)
        }
        .paceBackground()
        .navigationTitle(PACEFormatter.runDate(run.startDate))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { overflowMenu }
        .fullScreenCover(isPresented: $showFullMap) { FullMapView(run: run) }
        .alert("Delete Run?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(run)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Insight (top of screen)

    private func insightCard(_ insight: PACEAnalytics.RunInsight) -> some View {
        HStack(spacing: PACESpacing.md) {
            Image(systemName: insight.isPositive ? "arrow.up.circle.fill" : "minus.circle.fill")
                .font(.system(size: 26))
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: PACESpacing.sm) {
            (Text(PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 2))
                .font(PACEFonts.statLarge)
                .foregroundStyle(PACEColors.textPrimary)
             + Text(" \(unit.displayName)")
                .font(PACEFonts.statMedium)
                .foregroundStyle(PACEColors.textSecondary))

            HStack(spacing: PACESpacing.xl) {
                statPair(value: PACEFormatter.duration(run.activeDuration), label: "TIME")
                statPair(
                    value: PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit) + "/\(unit.displayName)",
                    label: "AVG PACE"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statPair(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PACEFonts.statMedium)
                .foregroundStyle(PACEColors.textPrimary)
            Text(label)
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
        }
    }

    // MARK: - Map Card

    private var mapCard: some View {
        Button { showFullMap = true } label: {
            RouteMapView(coordinates: run.route)
                .frame(height: 180)
                .cornerRadius(PACESpacing.cardCornerRadius)
                .allowsHitTesting(false)
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: PACESpacing.cardCornerRadius)
                .stroke(PACEColors.separator, lineWidth: 1)
        )
        .accessibilityLabel("Route map — tap to expand")
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PACESpacing.sm) {
            MetricCard(value: PACEFormatter.pace(run.bestPaceSecondsPerMeter, unit: unit), label: "Best Pace")
            MetricCard(value: PACEFormatter.elevation(run.elevationGainMeters), label: "Elevation +")
            if let avgHR = run.averageHeartRate {
                MetricCard(value: PACEFormatter.heartRate(avgHR), label: "Avg HR", accent: PACEColors.hrZone2)
            }
            if let maxHRVal = run.maxHeartRate {
                MetricCard(value: PACEFormatter.heartRate(maxHRVal), label: "Max HR", accent: PACEColors.hrZone4)
            }
            if let cal = run.activeCalories {
                MetricCard(value: "\(Int(cal))", label: "Cal")
            }
            let pausedTime = run.totalDuration - run.activeDuration
            if pausedTime > 30 {
                MetricCard(value: PACEFormatter.duration(pausedTime), label: "Paused")
            }
        }
    }

    // MARK: - Splits

    private var splitsSection: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(dampingFraction: 0.8)) { showSplits.toggle() } } label: {
                HStack {
                    Text("Splits")
                        .font(PACEFonts.body).foregroundStyle(PACEColors.textPrimary)
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

    // MARK: - HR Section

    private var hrSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("HEART RATE ZONES")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
                .padding(.leading, 2)

            HeartRateZoneBar(metrics: run.metrics, maxHR: maxHR)
                .frame(height: 36)
                .padding(PACESpacing.md)
                .background(PACEColors.surface)
                .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Overflow

    @ToolbarContentBuilder
    private var overflowMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { exportGPX() } label: { Label("Export GPX", systemImage: "arrow.up.doc") }
                Divider()
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Label("Delete Run", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle").foregroundStyle(PACEColors.textPrimary)
            }
        }
    }

    private func exportGPX() {
        let gpx = HealthKitManager().gpxString(for: run)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pace_run_\(run.id).gpx")
        do {
            try gpx.write(to: url, atomically: true, encoding: .utf8)
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.rootViewController?.present(av, animated: true)
        } catch {
            // Could not write GPX — surface this in a future update
        }
    }
}

// MARK: - Route Map View (correct MapKit polyline approach)

struct RouteMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isUserInteractionEnabled = false
        map.overrideUserInterfaceStyle = .dark
        map.mapType = .standard
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.showsScale = false
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard coordinates.count > 1 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        // Fit to route with padding
        if let region = coordinates.boundingRegion {
            mapView.setRegion(region, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color(hex: "00D4FF"))
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Full Map View

struct FullMapView: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            InteractiveRouteMapView(coordinates: run.route)
                .ignoresSafeArea()
                .navigationTitle("Route")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }.foregroundStyle(PACEColors.accentCyan)
                    }
                }
        }
    }
}

struct InteractiveRouteMapView: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        map.mapType = .standard
        map.pointOfInterestFilter = .excludingAll
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard coordinates.count > 1 else { return }
        mapView.addOverlay(MKPolyline(coordinates: coordinates, count: coordinates.count))
        if let region = coordinates.boundingRegion {
            mapView.setRegion(region, animated: false)
        }
    }

    func makeCoordinator() -> RouteMapView.Coordinator { RouteMapView.Coordinator() }
}

// MARK: - Splits Table

struct SplitsTableView: View {
    let splits: [Split]
    let unit: DistanceUnit

    private var avgPace: Double {
        let paces = splits.map(\.paceSecondsPerMeter).filter { $0 > 0 }
        return paces.isEmpty ? 0 : paces.reduce(0, +) / Double(paces.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(splits.indices, id: \.self) { i in
                let split = splits[i]
                HStack(spacing: PACESpacing.sm) {
                    Text("\(split.index + 1)")
                        .font(PACEFonts.caption).foregroundStyle(PACEColors.textSecondary)
                        .frame(width: 24, alignment: .leading)
                    paceBar(for: split)
                    Spacer()
                    Text(PACEFormatter.pace(split.paceSecondsPerMeter, unit: unit) + "/\(unit.displayName)")
                        .font(PACEFonts.caption).foregroundStyle(PACEColors.textPrimary)
                        .frame(width: 72, alignment: .trailing)
                }
                .padding(.horizontal, PACESpacing.md)
                .padding(.vertical, PACESpacing.sm)
                .background(PACEColors.surface)

                if i < splits.count - 1 {
                    PACESeparator().padding(.leading, 44)
                }
            }
        }
        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
    }

    private func paceBar(for split: Split) -> some View {
        let pace = split.paceSecondsPerMeter
        let isFaster = pace > 0 && avgPace > 0 && pace < avgPace
        let deviation = avgPace > 0 ? abs(pace - avgPace) / avgPace : 0
        let barWidth = CGFloat(min(deviation * 3, 1.0)) * 60 + 4

        return HStack(spacing: 0) {
            Rectangle()
                .fill(isFaster ? PACEColors.accentCyan : PACEColors.accentOrange)
                .frame(width: barWidth, height: 4)
                .cornerRadius(2)
            Spacer()
        }
        .frame(width: 80)
    }
}

// MARK: - HR Zone Bar

struct HeartRateZoneBar: View {
    let metrics: [HealthMetricSnapshot]
    let maxHR: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(HeartRateZone.allCases, id: \.rawValue) { zone in
                    let fraction = zoneFraction(zone)
                    if fraction > 0.01 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(PACEColors.hrZoneColor(zone))
                            .frame(width: geo.size.width * CGFloat(fraction))
                    }
                }
            }
        }
    }

    private func zoneFraction(_ zone: HeartRateZone) -> Double {
        let samples = metrics.compactMap(\.heartRate)
        guard !samples.isEmpty else { return zone == .zone2 ? 1.0 : 0 }
        let inZone = samples.filter { $0 >= zone.lowerBound * maxHR && $0 < zone.upperBound * maxHR }
        return Double(inZone.count) / Double(samples.count)
    }
}
