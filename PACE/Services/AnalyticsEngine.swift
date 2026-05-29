import Foundation

// Stateless analytics — no @Observable needed.
// All functions are pure transformations of run data.

enum PACEAnalytics {

    // MARK: - Run Insight

    struct RunInsight {
        let headline: String
        let isPositive: Bool
    }

    static func insight(for run: Run, allRuns: [Run]) -> RunInsight? {
        let completed = allRuns.filter { $0.status == .completed && $0.id != run.id }
        guard completed.count >= 3 else { return nil }

        // Comparable: within 20% distance
        guard run.distanceMeters > 100 else { return nil }
        let comparable = completed.filter { r in
            let ratio = r.distanceMeters / run.distanceMeters
            return ratio > 0.8 && ratio < 1.2
        }
        .sorted { $0.startDate > $1.startDate }

        if comparable.count >= 3 {
            let recentPaces = comparable.prefix(5).map(\.averagePaceSecondsPerMeter).filter { $0 > 0 }
            guard !recentPaces.isEmpty else { return nil }
            let avgPace = recentPaces.reduce(0, +) / Double(recentPaces.count)
            let thisPace = run.averagePaceSecondsPerMeter
            guard thisPace > 0, avgPace > 0 else { return nil }

            let pctFaster = (avgPace - thisPace) / avgPace * 100
            if pctFaster > 2 {
                return RunInsight(headline: String(format: "%.0f%% faster than your recent average", pctFaster), isPositive: true)
            } else if pctFaster < -2 {
                return RunInsight(headline: "Below your recent pace — rest days pay off", isPositive: false)
            } else {
                return RunInsight(headline: "Right on your average pace", isPositive: true)
            }
        }

        // Longest run ever?
        let maxDist = completed.map(\.distanceMeters).max() ?? 0
        if run.distanceMeters >= maxDist {
            return RunInsight(headline: "Your longest run ever", isPositive: true)
        }

        // Fastest pace ever?
        let bestPace = completed.compactMap { r -> Double? in
            r.averagePaceSecondsPerMeter > 0 ? r.averagePaceSecondsPerMeter : nil
        }.min()
        if let best = bestPace, run.averagePaceSecondsPerMeter > 0, run.averagePaceSecondsPerMeter <= best {
            return RunInsight(headline: "Your fastest pace ever", isPositive: true)
        }

        return nil
    }

    // MARK: - Weekly Stats (12-week chart)

    struct WeeklyStats {
        let weekStart: Date
        let totalDistanceMeters: Double
        let runCount: Int
    }

    static func weeklyStats(from runs: [Run], weeksBack: Int = 12) -> [WeeklyStats] {
        let calendar = Calendar.current
        let now = Date.now
        // Build stats oldest-to-newest (append, not insert-at-0)
        return (0..<weeksBack).reversed().compactMap { offset -> WeeklyStats? in
            guard let weekDate = calendar.date(byAdding: DateComponents(weekOfYear: -offset), to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { return nil }

            let weekRuns = runs.filter {
                $0.status == .completed &&
                $0.startDate >= interval.start &&
                $0.startDate < interval.end
            }
            return WeeklyStats(
                weekStart: interval.start,
                totalDistanceMeters: weekRuns.reduce(0) { $0 + $1.distanceMeters },
                runCount: weekRuns.count
            )
        }
    }

    // MARK: - Period Aggregates

    static func currentWeekDistance(from runs: [Run]) -> Double {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return runs.filter { $0.status == .completed && $0.startDate >= interval.start }
            .reduce(0) { $0 + $1.distanceMeters }
    }

    static func currentWeekRunCount(from runs: [Run]) -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return runs.filter { $0.status == .completed && $0.startDate >= interval.start }.count
    }

    // MARK: - Incomplete Run Recovery

    static func findIncompleteRuns(from runs: [Run]) -> [Run] {
        // Runs stuck in-progress or paused for more than 2 hours are recoverable orphans
        let cutoff = Date.now.addingTimeInterval(-2 * 3600)
        return runs.filter {
            ($0.status == .inProgress || $0.status == .paused) && $0.startDate < cutoff
        }
    }
}
