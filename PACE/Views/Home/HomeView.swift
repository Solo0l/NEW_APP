import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(RunService.self) private var runService
    @Environment(\.modelContext) private var context
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query(sort: \Goal.startDate, order: .reverse) private var goals: [Goal]
    @Query private var users: [User]

    @State private var showPreRunConfig = false
    @State private var showIncompleteAlert = false
    @State private var incompleteRun: Run?
    @State private var startCardPulsed = false

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .systemDefault }
    private var completedRuns: [Run] { runs.filter { $0.status == .completed } }
    private var recentRuns: [Run] { Array(completedRuns.prefix(3)) }
    private var lastRun: Run? { completedRuns.first }
    private var activeGoal: Goal? { PACEGoals.activeGoal(from: goals) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PACESpacing.lg) {
                    startCard
                    if let goal = activeGoal { goalCard(goal) }
                    if !recentRuns.isEmpty { recentSection }
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.top, PACESpacing.md)
                .padding(.bottom, 100)
            }
            .paceBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PACE")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(PACEColors.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showPreRunConfig) {
            PreRunConfigView { lapInterval, goalType, goalMeters, goalSeconds in
                showPreRunConfig = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    configureAndStart(lapInterval: lapInterval, goalType: goalType,
                                     goalMeters: goalMeters, goalSeconds: goalSeconds)
                }
            }
        }
        .alert("Incomplete Run Found", isPresented: $showIncompleteAlert, presenting: incompleteRun) { run in
            Button("Save") { saveIncomplete(run) }
            Button("Discard", role: .destructive) { discardIncomplete(run) }
            Button("Cancel", role: .cancel) {}
        } message: { run in
            let dist = PACEFormatter.distanceWithUnit(run.distanceMeters, unit: unit)
            Text("\(dist) recorded. Keep it?")
        }
        .onAppear { checkForIncompleteRuns() }
    }

    // MARK: - Start Card

    private var startCard: some View {
        Button {
            // Tap = immediate start with saved preferences
            immediateStart()
        } label: {
            VStack(spacing: PACESpacing.md) {
                ZStack {
                    Circle()
                        .fill(PACEColors.accentCyan.opacity(startCardPulsed ? 0 : 0.12))
                        .frame(width: 84, height: 84)
                        .scaleEffect(startCardPulsed ? 1.2 : 1.0)

                    Image(systemName: "figure.run")
                        .font(.system(size: 40))
                        .foregroundStyle(PACEColors.accentCyan)
                }

                Text("START RUN")
                    .font(PACEFonts.buttonLarge)
                    .foregroundStyle(PACEColors.textPrimary)
                    .tracking(2)

                if let last = lastRun {
                    Text(lastRunLine(last))
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
        .contextMenu {
            Button {
                showPreRunConfig = true
            } label: {
                Label("Set Goal Before Running", systemImage: "target")
            }
        }
        .onAppear { pulseOnce() }
    }

    // Long press → config sheet. Tap → immediate start.
    // Context menu surfaces the config as a discoverable option.

    // MARK: - Goal Card (inline, no separate tab)

    private func goalCard(_ goal: Goal) -> some View {
        let progress = goal.progress
        let achieved = goal.achievedValue ?? 0
        let unit = goal.unit

        return HStack(spacing: PACESpacing.md) {
            ProgressRing(progress: progress, size: 52, strokeWidth: 6)
                .overlay(
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(PACEColors.textPrimary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(goalTitle(goal))
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textPrimary)
                Text("\(Int(achieved)) / \(Int(goal.targetValue)) \(unit.rawValue)")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }

            Spacer()

            NavigationLink(destination: GoalsView()) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PACEColors.textTertiary)
            }
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Recent Runs

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("RECENT")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
                .padding(.leading, 2)

            VStack(spacing: 1) {
                ForEach(recentRuns) { run in
                    NavigationLink(destination: RunSummaryView(run: run)) {
                        CompactRunRow(run: run, unit: unit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(PACEColors.surface)
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Actions

    private func immediateStart() {
        let prefs = users.first?.preferences ?? .default
        runService.clearPreRunGoal()
        runService.startCountdown(lapInterval: prefs.lapInterval)
    }

    private func configureAndStart(lapInterval: LapInterval, goalType: GoalType?,
                                   goalMeters: Double?, goalSeconds: Double?) {
        if let goalType {
            runService.setPreRunGoal(type: goalType, valueMeters: goalMeters, valueSeconds: goalSeconds)
        } else {
            runService.clearPreRunGoal()
        }
        runService.startCountdown(lapInterval: lapInterval)
    }

    private func checkForIncompleteRuns() {
        if let orphan = incompleteOrphan(from: runs) {
            incompleteRun = orphan
            showIncompleteAlert = true
        }
    }

    private func saveIncomplete(_ run: Run) {
        run.status = .completed
        run.endDate = run.endDate ?? run.startDate.addingTimeInterval(run.activeDuration)
        try? context.save()
        incompleteRun = nil
    }

    private func discardIncomplete(_ run: Run) {
        context.delete(run)
        try? context.save()
        incompleteRun = nil
    }

    private func pulseOnce() {
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) { startCardPulsed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { startCardPulsed = false }
    }

    private func lastRunLine(_ run: Run) -> String {
        let dist = PACEFormatter.distance(run.distanceMeters, unit: unit, decimals: 1)
        let pace = PACEFormatter.pace(run.averagePaceSecondsPerMeter, unit: unit)
        return "\(PACEFormatter.runDate(run.startDate))  ·  \(dist) \(unit.displayName)  ·  \(pace)/\(unit.displayName)"
    }

    private func goalTitle(_ goal: Goal) -> String {
        switch goal.type {
        case .weeklyDistance:  return "\(Int(goal.targetValue)) km this week"
        case .weeklyRunCount:  return "\(Int(goal.targetValue)) runs this week"
        case .monthlyDistance: return "\(Int(goal.targetValue)) km this month"
        default:               return "Goal"
        }
    }
}

// Inline instead of calling the top-level enum to avoid circular naming issues
private func incompleteOrphan(from runs: [Run]) -> Run? {
    let cutoff = Date.now.addingTimeInterval(-2 * 3600)
    return runs.first { ($0.status == .inProgress || $0.status == .paused) && $0.startDate < cutoff }
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
