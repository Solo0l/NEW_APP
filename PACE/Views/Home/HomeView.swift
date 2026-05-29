import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query private var users: [User]

    @EnvironmentObject private var runService: RunService

    @State private var showPreRunConfig = false
    @State private var showIncompleteRunAlert = false
    @State private var incompleteRuns: [Run] = []
    @State private var pulseStart = false

    private var user: User? { users.first }
    private var recentRuns: [Run] { Array(runs.filter { $0.status == .completed }.prefix(3)) }
    private var lastRun: Run? { runs.first { $0.status == .completed } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PACESpacing.lg) {
                    startRunCard
                    if !recentRuns.isEmpty {
                        recentRunsSection
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.top, PACESpacing.lg)
                .padding(.bottom, PACESpacing.xxxl)
            }
            .paceBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PACE")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(PACEColors.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showPreRunConfig) {
            PreRunConfigView { lapInterval, goalType, goalMeters, goalSeconds in
                showPreRunConfig = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let goalType {
                        runService.setPreRunGoal(type: goalType, valueMeters: goalMeters, valueSeconds: goalSeconds)
                    } else {
                        runService.clearPreRunGoal()
                    }
                    runService.startCountdown(lapInterval: lapInterval)
                }
            }
        }
        .alert("Incomplete Run Found", isPresented: $showIncompleteRunAlert) {
            if let run = incompleteRuns.first {
                Button("Save It") { saveIncompleteRun(run) }
                Button("Discard", role: .destructive) { discardIncompleteRun(run) }
            }
        } message: {
            if let run = incompleteRuns.first {
                let dist = PACEFormatter.distanceWithUnit(run.distanceMeters, unit: user?.preferences.distanceUnit ?? .kilometers)
                Text("Found a run with \(dist) recorded. Save or discard?")
            }
        }
        .onAppear { checkForIncompleteRuns() }
    }

    // MARK: - Start Run Card

    private var startRunCard: some View {
        Button {
            // Direct start with defaults — swipe up for config
            showPreRunConfig = true
        } label: {
            VStack(spacing: PACESpacing.md) {
                ZStack {
                    Circle()
                        .fill(PACEColors.accentCyan.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseStart ? 1.15 : 1.0)
                        .opacity(pulseStart ? 0 : 1)
                    Image(systemName: "figure.run")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(PACEColors.accentCyan)
                }

                Text("START RUN")
                    .font(PACEFonts.buttonLarge)
                    .foregroundStyle(PACEColors.textPrimary)
                    .tracking(2)

                if let last = lastRun {
                    Text(lastRunSummary(last))
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PACESpacing.xxl)
            .background(PACEColors.surface)
            .cornerRadius(PACESpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: PACESpacing.cardCornerRadius)
                    .stroke(PACEColors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) { pulseStart = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { pulseStart = false }
        }
    }

    private func lastRunSummary(_ run: Run) -> String {
        let unit = user?.preferences.distanceUnit ?? .kilometers
        let dist = PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 1)
        let pace = PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit)
        return "\(PACEFormatter.runDate(run.startDate)) · \(dist) \(unit.displayName) · \(pace)/\(unit.displayName)"
    }

    // MARK: - Recent Runs

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Recent")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
                .padding(.leading, PACESpacing.xs)

            VStack(spacing: 1) {
                ForEach(recentRuns) { run in
                    NavigationLink(destination: RunSummaryView(run: run)) {
                        CompactRunRow(run: run, unit: user?.preferences.distanceUnit ?? .kilometers)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(PACEColors.surface)
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(message: "Your first run is waiting.")
    }

    // MARK: - Incomplete Run Recovery

    private func checkForIncompleteRuns() {
        let engine = AnalyticsEngine()
        let found = engine.findIncompleteRuns(from: runs)
        if !found.isEmpty {
            incompleteRuns = found
            showIncompleteRunAlert = true
        }
    }

    private func saveIncompleteRun(_ run: Run) {
        run.status = .completed
        run.endDate = run.endDate ?? run.startDate.addingTimeInterval(run.activeDuration)
        try? context.save()
        incompleteRuns.removeFirst()
        if !incompleteRuns.isEmpty { showIncompleteRunAlert = true }
    }

    private func discardIncompleteRun(_ run: Run) {
        context.delete(run)
        try? context.save()
        incompleteRuns.removeFirst()
        if !incompleteRuns.isEmpty { showIncompleteRunAlert = true }
    }
}

// MARK: - Compact Run Row

struct CompactRunRow: View {
    let run: Run
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: PACESpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(PACEFormatter.runDate(run.startDate))
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
                Text(PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 2) + " " + unit.displayName)
                    .font(PACEFonts.listPrimary)
                    .foregroundStyle(PACEColors.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(PACEFormatter.duration(run.activeDuration))
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
                Text(PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit) + "/\(unit.displayName)")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PACEColors.textTertiary)
        }
        .padding(.horizontal, PACESpacing.md)
        .padding(.vertical, PACESpacing.sm + 2)
    }
}
