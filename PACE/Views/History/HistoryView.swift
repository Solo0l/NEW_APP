import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query private var users: [User]

    @State private var selectedFilter: Filter = .all

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .systemDefault }
    private var completed: [Run] { runs.filter { $0.status == .completed } }
    private var filtered: [Run] { selectedFilter.apply(to: completed) }
    private var weeklyStats: [PACEAnalytics.WeeklyStats] { PACEAnalytics.weeklyStats(from: completed) }

    enum Filter: String, CaseIterable {
        case all = "All"
        case week = "Week"
        case month = "Month"
        case year = "Year"

        func apply(to runs: [Run]) -> [Run] {
            let calendar = Calendar.current
            switch self {
            case .all:   return runs
            case .week:
                guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            case .month:
                guard let interval = calendar.dateInterval(of: .month, for: .now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            case .year:
                guard let interval = calendar.dateInterval(of: .year, for: .now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Chart + filter — pulled up by scroll, not a fixed header
                LazyVStack(pinnedViews: []) {
                    weeklyChartSection
                    filterRow
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        runListSection
                    }
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.top, PACESpacing.md)
                .padding(.bottom, PACESpacing.xxxl)
            }
            .paceBackground()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            let totalKm = completed.reduce(0) { $0 + $1.distanceMeters } / 1000.0
            let thisWeekKm = PACEAnalytics.currentWeekDistance(from: completed) / 1000.0
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f \(unit.displayName) this week", thisWeekKm))
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text(String(format: "%.0f \(unit.displayName) total", totalKm))
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                }
                Spacer()
                Text("\(completed.count) runs")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }

            WeeklyDistanceChart(stats: weeklyStats, unit: unit)
                .frame(height: 80)
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
        .padding(.bottom, PACESpacing.sm)
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PACESpacing.sm) {
                ForEach(Filter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(PACEFonts.caption)
                            .foregroundStyle(selectedFilter == filter ? PACEColors.textInverse : PACEColors.textSecondary)
                            .padding(.horizontal, PACESpacing.md)
                            .padding(.vertical, PACESpacing.xs + 2)
                            .background(selectedFilter == filter ? PACEColors.accentCyan : PACEColors.surface)
                            .cornerRadius(PACESpacing.sm)
                    }
                }
            }
        }
        .padding(.bottom, PACESpacing.sm)
    }

    // MARK: - Run List

    private var runListSection: some View {
        VStack(spacing: 1) {
            ForEach(filtered) { run in
                NavigationLink(destination: RunSummaryView(run: run)) {
                    HistoryRunRow(run: run, unit: unit)
                }
                .buttonStyle(.plain)
            }
        }
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    private var emptyState: some View {
        EmptyStateView(message: selectedFilter == .all
            ? "No runs yet.\nHead out for your first one."
            : "No runs in this period."
        )
    }
}

// MARK: - History Run Row

struct HistoryRunRow: View {
    let run: Run
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: PACESpacing.md) {
            VStack(spacing: 0) {
                Text(dayAbbrev(run.startDate))
                    .font(PACEFonts.metricLabel)
                    .foregroundStyle(PACEColors.textSecondary)
                    .tracking(2)
                Text(dayNum(run.startDate))
                    .font(PACEFonts.listPrimary)
                    .foregroundStyle(PACEColors.textPrimary)
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 2) + " " + unit.displayName)
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textPrimary)
                HStack(spacing: 4) {
                    Text(PACEFormatter.duration(run.activeDuration))
                    Text("·")
                    Text(PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit) + "/\(unit.displayName)")
                }
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PACEColors.textTertiary)
        }
        .padding(.horizontal, PACESpacing.md)
        .padding(.vertical, PACESpacing.sm + 2)
    }

    private func dayAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date).uppercased()
    }
    private func dayNum(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
}

// MARK: - Weekly Distance Chart

struct WeeklyDistanceChart: View {
    let stats: [PACEAnalytics.WeeklyStats]
    let unit: DistanceUnit

    private var maxDist: Double {
        (stats.map { $0.totalDistanceMeters / unit.metersPerUnit }.max() ?? 1.0).clamped(to: 1...Double.infinity)
    }

    var body: some View {
        GeometryReader { geo in
            let barW = stats.isEmpty ? 0 : (geo.size.width - CGFloat(max(stats.count - 1, 0)) * 4) / CGFloat(stats.count)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(stats.indices, id: \.self) { i in
                    let stat = stats[i]
                    let dist = stat.totalDistanceMeters / unit.metersPerUnit
                    let fraction = maxDist > 0 ? dist / maxDist : 0
                    let barH = max(4, geo.size.height * CGFloat(fraction))
                    let isCurrent = Calendar.current.isDate(stat.weekStart, equalTo: .now, toGranularity: .weekOfYear)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isCurrent ? PACEColors.accentCyan : PACEColors.textSecondary.opacity(0.35))
                            .frame(width: barW, height: barH)
                    }
                }
            }
        }
    }
}
