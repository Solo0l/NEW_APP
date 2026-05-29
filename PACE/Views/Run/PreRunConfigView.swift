import SwiftUI

struct PreRunConfigView: View {
    // Callback: lapInterval, goalType (optional), goalMeters (optional), goalSeconds (optional)
    let onStart: (LapInterval, GoalType?, Double?, Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGoal: GoalOption = .none
    @State private var lapInterval: LapInterval = .oneKilometer
    @State private var distanceKm: Double = 5
    @State private var durationMinutes: Double = 30
    @State private var showAdvanced = false

    enum GoalOption: Equatable {
        case none, distance, time
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: PACESpacing.xl) {
                goalSelector
                if selectedGoal == .distance { distancePicker }
                if selectedGoal == .time { timePicker }

                Spacer()

                if showAdvanced { advancedSettings }

                VStack(spacing: PACESpacing.sm) {
                    PACEPrimaryButton(title: "Start Run") { startRun() }
                    Button("Advanced ↓") { withAnimation { showAdvanced.toggle() } }
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                }
            }
            .padding(PACESpacing.screenEdge)
            .paceBackground()
            .navigationTitle("Set Up Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PACEColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(PACEColors.surface)
        .presentationDragIndicator(.visible)
    }

    // MARK: - Goal Selector

    private var goalSelector: some View {
        HStack(spacing: PACESpacing.sm) {
            GoalChip(title: "No Goal", isSelected: selectedGoal == .none) { selectedGoal = .none }
            GoalChip(title: "Distance", isSelected: selectedGoal == .distance) { selectedGoal = .distance }
            GoalChip(title: "Time", isSelected: selectedGoal == .time) { selectedGoal = .time }
        }
    }

    // MARK: - Distance Picker

    private var distancePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Target Distance")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
            HStack {
                Text("\(Int(distanceKm)) km")
                    .font(PACEFonts.statMedium)
                    .foregroundStyle(PACEColors.accentCyan)
                Slider(value: $distanceKm, in: 1...42, step: 1)
                    .tint(PACEColors.accentCyan)
            }
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surfaceElevated)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Time Picker

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("Target Duration")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
            HStack {
                Text("\(Int(durationMinutes)) min")
                    .font(PACEFonts.statMedium)
                    .foregroundStyle(PACEColors.accentCyan)
                Slider(value: $durationMinutes, in: 5...180, step: 5)
                    .tint(PACEColors.accentCyan)
            }
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surfaceElevated)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Advanced Settings

    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: PACESpacing.md) {
            PACESeparator()
            Text("Advanced")
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)

            VStack(spacing: PACESpacing.sm) {
                HStack {
                    Text("Split alert")
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                    Spacer()
                    Picker("Split", selection: $lapInterval) {
                        ForEach(LapInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(PACEColors.accentCyan)
                }
            }
        }
    }

    // MARK: - Start Action

    private func startRun() {
        switch selectedGoal {
        case .none:
            onStart(lapInterval, nil, nil, nil)
        case .distance:
            onStart(lapInterval, .singleRunDistance, distanceKm * 1000, nil)
        case .time:
            onStart(lapInterval, .singleRunTime, nil, durationMinutes * 60)
        }
    }
}

// MARK: - Goal Chip

private struct GoalChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PACEFonts.body)
                .foregroundStyle(isSelected ? PACEColors.textInverse : PACEColors.textSecondary)
                .padding(.horizontal, PACESpacing.md)
                .padding(.vertical, PACESpacing.sm)
                .background(isSelected ? PACEColors.accentCyan : PACEColors.surfaceElevated)
                .cornerRadius(PACESpacing.sm)
        }
    }
}
