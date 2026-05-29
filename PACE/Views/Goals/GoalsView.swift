import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \Goal.startDate, order: .reverse) private var goals: [Goal]
    @Query(sort: \Run.startDate, order: .reverse) private var runs: [Run]
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    @State private var showGoalSetup = false

    private var unit: DistanceUnit { users.first?.preferences.distanceUnit ?? .kilometers }
    private var completedRuns: [Run] { runs.filter { $0.status == .completed } }
    private var activeGoal: Goal? { GoalService().activeGoal(from: goals) }
    private var pastGoals: [Goal] { goals.filter { $0.status != .active } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PACESpacing.lg) {
                    if let goal = activeGoal {
                        activeGoalCard(goal)
                    } else {
                        noGoalPrompt
                    }
                    if !pastGoals.isEmpty {
                        pastGoalsSection
                    }
                    suggestionsSection
                }
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.top, PACESpacing.md)
                .padding(.bottom, PACESpacing.xxxl)
            }
            .paceBackground()
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showGoalSetup) {
                GoalSetupView(runs: completedRuns) { newGoal in
                    context.insert(newGoal)
                    try? context.save()
                }
            }
            .onAppear { refreshGoalProgress() }
        }
    }

    // MARK: - Active Goal Card

    private func activeGoalCard(_ goal: Goal) -> some View {
        VStack(spacing: PACESpacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalTitle(goal))
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text(goalPeriod(goal))
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                }
                Spacer()
                Button("Change") { showGoalSetup = true }
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.accentCyan)
            }

            HStack(spacing: PACESpacing.xl) {
                ProgressRing(progress: goal.progress, size: 100, strokeWidth: 10)
                    .overlay(
                        VStack(spacing: 2) {
                            Text("\(Int(goal.progress * 100))%")
                                .font(PACEFonts.metricSecondary)
                                .foregroundStyle(PACEColors.textPrimary)
                            Text("done")
                                .font(PACEFonts.metricLabel)
                                .foregroundStyle(PACEColors.textSecondary)
                                .tracking(2)
                        }
                    )

                VStack(alignment: .leading, spacing: PACESpacing.sm) {
                    progressDetail("Achieved", value: achievedDisplay(goal))
                    progressDetail("Target", value: targetDisplay(goal))
                    progressDetail("Remaining", value: remainingDisplay(goal))
                }
            }
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    private func progressDetail(_ label: String, value: String) -> some View {
        HStack(spacing: PACESpacing.sm) {
            Text(label)
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textPrimary)
        }
    }

    // MARK: - No Goal Prompt

    private var noGoalPrompt: some View {
        VStack(spacing: PACESpacing.md) {
            Text("Set a weekly target.")
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.textSecondary)
            PACEPrimaryButton(title: "Set Goal") { showGoalSetup = true }
        }
        .padding(PACESpacing.xl)
        .frame(maxWidth: .infinity)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Past Goals

    private var pastGoalsSection: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Past Goals")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
                .padding(.leading, PACESpacing.xs)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PACESpacing.sm) {
                    ForEach(pastGoals.prefix(10)) { goal in
                        pastGoalBadge(goal)
                    }
                }
            }
        }
    }

    private func pastGoalBadge(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goalStatusIcon(goal))
                .font(.system(size: 18))
            Text(goalTitle(goal))
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textPrimary)
                .lineLimit(2)
            Text(PACEFormatter.shortDate(goal.startDate))
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(2)
        }
        .frame(width: 100)
        .padding(PACESpacing.sm)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        let suggestions = GoalService().suggestions(existingRuns: completedRuns)
        return VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Suggestions")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
                .padding(.leading, PACESpacing.xs)

            VStack(spacing: 1) {
                ForEach(suggestions.indices, id: \.self) { i in
                    let s = suggestions[i]
                    Button {
                        let goal = makeGoal(from: s)
                        context.insert(goal)
                        try? context.save()
                    } label: {
                        HStack {
                            Text(s.title)
                                .font(PACEFonts.body)
                                .foregroundStyle(PACEColors.textPrimary)
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
                    if i < suggestions.count - 1 {
                        PACESeparator().padding(.leading, PACESpacing.md)
                    }
                }
            }
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    // MARK: - Helpers

    private func goalTitle(_ goal: Goal) -> String {
        switch goal.type {
        case .weeklyDistance:   return "\(Int(goal.targetValue)) km / week"
        case .weeklyRunCount:   return "\(Int(goal.targetValue)) runs / week"
        case .monthlyDistance:  return "\(Int(goal.targetValue)) km / month"
        default:                return "Custom Goal"
        }
    }

    private func goalPeriod(_ goal: Goal) -> String {
        "\(PACEFormatter.shortDate(goal.startDate)) – \(PACEFormatter.shortDate(goal.endDate))"
    }

    private func achievedDisplay(_ goal: Goal) -> String {
        "\(Int(goal.achievedValue ?? 0)) \(goal.unit.rawValue)"
    }

    private func targetDisplay(_ goal: Goal) -> String {
        "\(Int(goal.targetValue)) \(goal.unit.rawValue)"
    }

    private func remainingDisplay(_ goal: Goal) -> String {
        let rem = max(0, goal.targetValue - (goal.achievedValue ?? 0))
        return "\(Int(rem)) \(goal.unit.rawValue)"
    }

    private func goalStatusIcon(_ goal: Goal) -> String {
        switch goal.status {
        case .completed: return "✓"
        case .missed:    return "✗"
        default:         return "○"
        }
    }

    private func refreshGoalProgress() {
        guard let goal = activeGoal else { return }
        GoalService().updateGoalProgress(goal: goal, allRuns: runs, context: context)
    }

    private func makeGoal(from suggestion: GoalService.GoalSuggestion) -> Goal {
        switch suggestion.type {
        case .weeklyDistance:  return Goal.weeklyDistanceGoal(targetKm: suggestion.value)
        case .weeklyRunCount:  return Goal.weeklyRunCountGoal(targetCount: Int(suggestion.value))
        case .monthlyDistance: return Goal.monthlyDistanceGoal(targetKm: suggestion.value)
        default:               return Goal.weeklyDistanceGoal(targetKm: suggestion.value)
        }
    }
}

// MARK: - Goal Setup View

struct GoalSetupView: View {
    let runs: [Run]
    let onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: GoalType = .weeklyDistance
    @State private var distanceKm: Double = 30
    @State private var runCount: Double = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: PACESpacing.xl) {
                goalTypePicker
                goalValuePicker
                Spacer()
                PACEPrimaryButton(title: "Save Goal") {
                    let goal = buildGoal()
                    onSave(goal)
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PACEColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(PACEColors.surface)
    }

    private var goalTypePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Goal type")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
            HStack(spacing: PACESpacing.sm) {
                ForEach([GoalType.weeklyDistance, GoalType.weeklyRunCount, GoalType.monthlyDistance], id: \.self) { type in
                    Button {
                        withAnimation { selectedType = type }
                    } label: {
                        Text(typeLabel(type))
                            .font(PACEFonts.caption)
                            .foregroundStyle(selectedType == type ? PACEColors.textInverse : PACEColors.textSecondary)
                            .padding(.horizontal, PACESpacing.sm)
                            .padding(.vertical, PACESpacing.xs + 2)
                            .background(selectedType == type ? PACEColors.accentCyan : PACEColors.surfaceElevated)
                            .cornerRadius(PACESpacing.sm)
                    }
                }
            }
        }
    }

    private var goalValuePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Target")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)

            HStack {
                switch selectedType {
                case .weeklyDistance, .monthlyDistance:
                    Text("\(Int(distanceKm)) km")
                        .font(PACEFonts.statMedium)
                        .foregroundStyle(PACEColors.accentCyan)
                    Slider(value: $distanceKm, in: 5...200, step: 5)
                        .tint(PACEColors.accentCyan)
                case .weeklyRunCount:
                    Text("\(Int(runCount)) runs")
                        .font(PACEFonts.statMedium)
                        .foregroundStyle(PACEColors.accentCyan)
                    Slider(value: $runCount, in: 1...14, step: 1)
                        .tint(PACEColors.accentCyan)
                default:
                    EmptyView()
                }
            }
            .padding(PACESpacing.md)
            .background(PACEColors.surfaceElevated)
            .cornerRadius(PACESpacing.cardCornerRadius)
        }
    }

    private func typeLabel(_ type: GoalType) -> String {
        switch type {
        case .weeklyDistance:  return "Weekly km"
        case .weeklyRunCount:  return "Weekly runs"
        case .monthlyDistance: return "Monthly km"
        default:               return ""
        }
    }

    private func buildGoal() -> Goal {
        switch selectedType {
        case .weeklyRunCount: return Goal.weeklyRunCountGoal(targetCount: Int(runCount))
        case .monthlyDistance: return Goal.monthlyDistanceGoal(targetKm: distanceKm)
        default: return Goal.weeklyDistanceGoal(targetKm: distanceKm)
        }
    }
}
