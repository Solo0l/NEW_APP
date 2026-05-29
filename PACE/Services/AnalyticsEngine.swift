import Foundation
import SwiftData

struct RunInsight {
    let headline: String
    let isPositive: Bool
}

struct WeeklyStats {
    let weekStart: Date
    let totalDistanceMeters: Double
    let runCount: Int
}

@Observable
final class AnalyticsEngine: ObservableObject {

    // MARK: - Run Insight (post-run comparison)

    func insight(for run: Run, allRuns: [Run]) -> RunInsight? {
        let completed = allRuns.filter { $0.status == .completed && $0.id != run.id }
        guard completed.count >= 3 else { return nil }

        // Find comparable runs (within 20% of this run's distance)
        let comparable = completed.filter { r in
            guard run.distanceMeters > 100 else { return false }
            let ratio = r.distanceMeters / run.distanceMeters
            return ratio > 0.8 && ratio < 1.2
        }.sorted { $0.startDate > $1.startDate }

        if comparable.count >= 3 {
            let recentPaces = comparable.prefix(5).map(\.averagePaceSecondsPerMeter)
            let avgPace = recentPaces.reduce(0, +) / Double(recentPaces.count)
            let thisPace = run.averagePaceSecondsPerMeter

            if thisPace > 0, avgPace > 0 {
                let percentFaster = (avgPace - thisPace) / avgPace * 100
                if percentFaster > 2 {
                    return RunInsight(headline: String(format: "%.0f%% faster than your recent average", percentFaster), isPositive: true)
                } else if percentFaster < -2 {
                    return RunInsight(headline: "Below your recent average pace", isPositive: false)
                } else {
                    return RunInsight(headline: "Right on your average pace", isPositive: true)
                }
            }
        }

        // Longest run ever?
        if run.distanceMeters >= (allRuns.map(\.distanceMeters).max() ?? 0) {
            return RunInsight(headline: "Your longest run ever", isPositive: true)
        }

        // Fastest pace ever?
        let bestPace = completed.compactMap { $0.averagePaceSecondsPerMeter > 0 ? $0.averagePaceSecondsPerMeter : nil }.min()
        if let best = bestPace, run.averagePaceSecondsPerMeter > 0, run.averagePaceSecondsPerMeter <= best {
            return RunInsight(headline: "Your fastest pace ever", isPositive: true)
        }

        return nil
    }

    // MARK: - Weekly Stats (12-week chart)

    func weeklyStats(from runs: [Run], weeksBack: Int = 12) -> [WeeklyStats] {
        let calendar = Calendar.current
        let now = Date.now
        var stats: [WeeklyStats] = []

        for i in 0..<weeksBack {
            let weekOffset = DateComponents(weekOfYear: -i)
            guard let weekDate = calendar.date(byAdding: weekOffset, to: now),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { continue }

            let weekRuns = runs.filter {
                $0.status == .completed &&
                $0.startDate >= interval.start &&
                $0.startDate < interval.end
            }

            stats.insert(WeeklyStats(
                weekStart: interval.start,
                totalDistanceMeters: weekRuns.reduce(0) { $0 + $1.distanceMeters },
                runCount: weekRuns.count
            ), at: 0)
        }
        return stats
    }

    // MARK: - Current Week Progress

    func currentWeekDistance(from runs: [Run]) -> Double {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return runs
            .filter { $0.status == .completed && $0.startDate >= interval.start }
            .reduce(0) { $0 + $1.distanceMeters }
    }

    func currentWeekRunCount(from runs: [Run]) -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return runs.filter { $0.status == .completed && $0.startDate >= interval.start }.count
    }

    // MARK: - Incomplete Run Recovery

    func findIncompleteRuns(from runs: [Run]) -> [Run] {
        let cutoff = Date.now.addingTimeInterval(-6 * 3600)
        return runs.filter {
            ($0.status == .inProgress || $0.status == .paused) &&
            $0.startDate < cutoff
        }
    }
}
