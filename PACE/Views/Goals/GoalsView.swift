import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \Goal.startDate, order: .reverse) private var goals: [Goal]
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    @State private var showSetup = false

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .systemDefault }
    private var completed: [Run] { runs.filter { $0.status == .completed } }
    private var activeGoal: Goal? { PACEGoals.activeGoal(from: goals) }
    private var pastGoals: [Goal] { goals.filter { $0.status != .active }.prefix(10).map { $0 } }

    var body: some View {
        ScrollView {
            VStack(spacing: PACESpacing.lg) {
                if let goal = activeGoal {
                    activeGoalCard(goal)
                } else {
                    noGoalCard
                }
                if !pastGoals.isEmpty { pastGoalsSection }
                suggestionsSection
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.top, PACESpacing.md)
            .padding(.bottom, PACESpacing.xxxl)
        }
        .paceBackground()
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSetup) {
            GoalSetupView { goal in
                context.insert(goal)
                try? context.save()
            }
        }
        .onAppear { refreshActive() }
    }

    // MARK: - Active Goal

    private func activeGoalCard(_ goal: Goal) -> some View {
        VStack(spacing: PACESpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalTitle(goal))
                        .font(PACEFonts.body).foregroundStyle(PACEColors.textPrimary)
                    Text(period(goal))
                        .font(PACEFonts.caption).foregroundStyle(PACEColors.textSecondary)
                }
                Spacer()
                Button("Change") { showSetup = true }
                    .font(PACEFonts.caption).foregroundStyle(PACEColors.accentCyan)
            }

            HStack(spacing: PACESpacing.xl) {
                ProgressRing(progress: goal.progress, size: 96, strokeWidth: 10)
                    .overlay(
                        VStack(spacing: 2) {
                            Text("\(Int(goal.progress * 100))%")
                                .font(PACEFonts.metricSecondary).foregroundStyle(PACEColors.textPrimary)
                            Text("done")
                                .font(PACEFonts.metricLabel).foregroundStyle(PACEColors.textSecondary).tracking(2)
                        }
                    )

                VStack(alignment: .leading, spacing: PACESpacing.sm) {
                    goalRow("Achieved", "\(Int(goal.achievedValue ?? 0)) \(goal.unit.rawValue)")
                    goalRow("Target", "\(Int(goal.targetValue)) \(goal.unit.rawValue)")
                    goalRow("Left", "\(max(0, Int(goal.targetValue - (goal.achievedValue ?? 0)))) \(goal.unit.rawValue)")
                }
            }
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    private func goalRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: PACESpacing.sm) {
            Text(label)
                .font(PACEFonts.caption).foregroundStyle(PACEColors.textSecondary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(PACEFonts.caption).foregroundStyle(PACEColors.textPrimary)
        }
    }

    // MARK: - No Goal

    private var noGoalCard: some View {
        VStack(spacing: PACESpacing.md) {
            Text("No active goal.")
                .font(PACEFonts.body).foregroundStyle(PACEColors.textSecondary)
            PACEPrimaryButton(title: "Set a Goal") { showSetup = true }
        }
        .padding(PACESpacing.xl)
        .frame(maxWidth: .infinity)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Past Goals

    private var pastGoalsSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("PAST GOALS")
                .font(PACEFonts.metricLabel).foregroundStyle(PACEColors.textSecondary).tracking(3)
                .padding(.leading, 2)

            VStack(spacing: 1) {
                ForEach(pastGoals) { goal in
                    HStack {
                        Text(goal.status == .completed ? "✓" : "✗")
                            .font(PACEFonts.caption)
                            .foregroundStyle(goal.status == .completed ? PACEColors.success : PACEColors.textSecondary)
                            .frame(width: 20)
                        Text(goalTitle(goal))
                            .font(PACEFonts.caption).foregroundStyle(PACEColors.textPrimary)
                        Spacer()
                        Text(PACEFormatter.shortDate(goal.startDate))
                            .font(PACEFonts.caption).foregroundStyle(PACEColors.textSecondary)
                    }
                    .padding(.horizontal, PACESpacing.md)
                    .padding(.vertical, PACESpacing.sm)
                    .background(PACEColors.surface)
                }
            }
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        let suggestions = PACEGoals.suggestions(existingRuns: completed)
        guard !suggestions.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("SUGGESTIONS")
                .font(PACEFonts.metricLabel).foregroundStyle(PACEColors.textSecondary).tracking(3)
                .padding(.leading, 2)

            VStack(spacing: 1) {
                ForEach(suggestions.indices, id: \.self) { i in
                    let s = suggestions[i]
                    Button {
                        let g = makeGoal(from: s)
                        context.insert(g)
                        try? context.save()
                    } label: {
                        HStack {
                            Text(s.title)
                                .font(PACEFonts.body).foregroundStyle(PACEColors.textPrimary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PACEColors.accentCyan)
                        }
                        .padding(.horizontal, PACESpacing.md)
                        .padding(.vertical, PACESpacing.sm + 2)
                        .background(PACEColors.surface)
                    }
                    .buttonStyle(.plain)
                }
            }
            .cornerRadius(PACESpacing.cardCornerRadius)
        })
    }

    // MARK: - Helpers

    private func goalTitle(_ goal: Goal) -> String {
        switch goal.type {
        case .weeklyDistance:  return "\(Int(goal.targetValue)) km / week"
        case .weeklyRunCount:  return "\(Int(goal.targetValue)) runs / week"
        case .monthlyDistance: return "\(Int(goal.targetValue)) km / month"
        default:               return "Custom Goal"
        }
    }

    private func period(_ goal: Goal) -> String {
        "\(PACEFormatter.shortDate(goal.startDate)) – \(PACEFormatter.shortDate(goal.endDate))"
    }

    private func refreshActive() {
        guard let goal = activeGoal else { return }
        PACEGoals.updateProgress(goal: goal, allRuns: runs, context: context)
    }

    private func makeGoal(from s: PACEGoals.Suggestion) -> Goal {
        switch s.type {
        case .weeklyRunCount:  return Goal.weeklyRunCountGoal(targetCount: Int(s.value))
        case .monthlyDistance: return Goal.monthlyDistanceGoal(targetKm: s.value)
        default:               return Goal.weeklyDistanceGoal(targetKm: s.value)
        }
    }
}

// MARK: - Goal Setup Sheet

struct GoalSetupView: View {
    let onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: GoalType = .weeklyDistance
    @State private var distanceKm: Double = 30
    @State private var runCount: Double = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: PACESpacing.xl) {
                typePicker
                valuePicker
                Spacer()
                PACEPrimaryButton(title: "Save") {
                    onSave(build())
                    dismiss()
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.bottom, PACESpacing.xl)
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.top, PACESpacing.lg)
            .paceBackground()
            .navigationTitle("Set Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(PACEColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(PACEColors.surface)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("TYPE").font(PACEFonts.metricLabel).foregroundStyle(PACEColors.textSecondary).tracking(3)
            HStack(spacing: PACESpacing.sm) {
                ForEach([GoalType.weeklyDistance, .weeklyRunCount, .monthlyDistance], id: \.self) { t in
                    Button { withAnimation { type = t } } label: {
                        Text(typeLabel(t))
                            .font(PACEFonts.caption)
                            .foregroundStyle(type == t ? PACEColors.textInverse : PACEColors.textSecondary)
                            .padding(.horizontal, PACESpacing.sm)
                            .padding(.vertical, PACESpacing.xs + 2)
                            .background(type == t ? PACEColors.accentCyan : PACEColors.surfaceElevated)
                            .cornerRadius(PACESpacing.sm)
                    }
                }
            }
        }
    }

    private var valuePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("TARGET").font(PACEFonts.metricLabel).foregroundStyle(PACEColors.textSecondary).tracking(3)
            HStack(spacing: PACESpacing.md) {
                switch type {
                case .weeklyRunCount:
                    Text("\(Int(runCount)) runs")
                        .font(PACEFonts.statMedium).foregroundStyle(PACEColors.accentCyan)
                        .frame(width: 90, alignment: .leading)
                    Slider(value: $runCount, in: 1...14, step: 1).tint(PACEColors.accentCyan)
                default:
                    Text("\(Int(distanceKm)) km")
                        .font(PACEFonts.statMedium).foregroundStyle(PACEColors.accentCyan)
                        .frame(width: 90, alignment: .leading)
                    Slider(value: $distanceKm, in: 5...200, step: 5).tint(PACEColors.accentCyan)
                }
            }
            .padding(PACESpacing.md)
            .background(PACEColors.surfaceElevated)
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    private func typeLabel(_ t: GoalType) -> String {
        switch t {
        case .weeklyDistance:  return "Weekly km"
        case .weeklyRunCount:  return "Weekly runs"
        case .monthlyDistance: return "Monthly km"
        default:               return ""
        }
    }

    private func build() -> Goal {
        switch type {
        case .weeklyRunCount:  return Goal.weeklyRunCountGoal(targetCount: Int(runCount))
        case .monthlyDistance: return Goal.monthlyDistanceGoal(targetKm: distanceKm)
        default:               return Goal.weeklyDistanceGoal(targetKm: distanceKm)
        }
    }
}
