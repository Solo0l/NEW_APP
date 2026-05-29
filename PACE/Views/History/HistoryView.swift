import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query private var users: [User]

    @State private var selectedFilter: HistoryFilter = .all

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .kilometers }
    private var completedRuns: [Run] { runs.filter { $0.status == .completed } }
    private var filteredRuns: [Run] { selectedFilter.filter(completedRuns) }
    private var weeklyStats: [WeeklyStats] { AnalyticsEngine().weeklyStats(from: completedRuns) }

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case thisWeek = "Week"
        case thisMonth = "Month"
        case thisYear = "Year"

        func filter(_ runs: [Run]) -> [Run] {
            let calendar = Calendar.current
            let now = Date.now
            switch self {
            case .all: return runs
            case .thisWeek:
                guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            case .thisMonth:
                guard let interval = calendar.dateInterval(of: .month, for: now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            case .thisYear:
                guard let interval = calendar.dateInterval(of: .year, for: now) else { return runs }
                return runs.filter { $0.startDate >= interval.start }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PACESpacing.lg) {
                    weeklyChart
                    filterRow
                    if filteredRuns.isEmpty {
                        emptyState
                    } else {
                        runList
                    }
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.top, PACESpacing.md)
                .padding(.bottom, PACESpacing.xxxl)
            }
            .paceBackground()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        WeeklyDistanceChart(stats: weeklyStats, unit: unit)
            .frame(height: 120)
            .padding(PACESpacing.md)
            .background(PACEColors.surface)
            .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PACESpacing.sm) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter }
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
    }

    // MARK: - Run List

    private var runList: some View {
        VStack(spacing: 1) {
            ForEach(filteredRuns) { run in
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
        EmptyStateView(message: selectedFilter == .all ? "No runs yet. Start your first run." : "No runs in this period.")
    }
}

// MARK: - History Run Row

struct HistoryRunRow: View {
    let run: Run
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: PACESpacing.md) {
            // Date badge
            VStack(spacing: 0) {
                Text(dayOfWeek(run.startDate))
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
                Text(dayNumber(run.startDate))
                    .font(PACEFonts.listPrimary)
                    .foregroundStyle(PACEColors.textPrimary)
            }
            .frame(width: 36)

            // Metrics
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PACESpacing.sm) {
                    Text(PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 2) + " " + unit.displayName)
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                }
                HStack(spacing: PACESpacing.sm) {
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

    private func dayOfWeek(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

// MARK: - Weekly Distance Chart

struct WeeklyDistanceChart: View {
    let stats: [WeeklyStats]
    let unit: DistanceUnit

    private var maxDistance: Double {
        (stats.map(\.totalDistanceMeters).max() ?? 1000) / unit.metersPerUnit
    }

    var body: some View {
        GeometryReader { geo in
            let barWidth = (geo.size.width - CGFloat(max(stats.count - 1, 0)) * 6) / CGFloat(max(stats.count, 1))

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(stats.indices, id: \.self) { i in
                    let stat = stats[i]
                    let distance = stat.totalDistanceMeters / unit.metersPerUnit
                    let fraction = maxDistance > 0 ? distance / maxDistance : 0
                    let barHeight = max(4, geo.size.height * CGFloat(fraction))
                    let isCurrentWeek = Calendar.current.isDate(stat.weekStart, equalTo: .now, toGranularity: .weekOfYear)

                    VStack(spacing: 2) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isCurrentWeek ? PACEColors.accentCyan : PACEColors.textSecondary.opacity(0.4))
                            .frame(width: barWidth, height: barHeight)
                            .animation(.spring(dampingFraction: 0.8).delay(Double(i) * 0.03), value: barHeight)
                    }
                }
            }
        }
    }
}
