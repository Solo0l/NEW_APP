import SwiftUI

struct PreRunConfigView: View {
    let onStart: (LapInterval, GoalType?, Double?, Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var goal: GoalMode = .none
    @State private var lapInterval: LapInterval = .oneKilometer
    @State private var distanceKm: Double = 5
    @State private var durationMinutes: Double = 30

    enum GoalMode: Equatable { case none, distance, time }

    var body: some View {
        NavigationStack {
            VStack(spacing: PACESpacing.xl) {
                goalSelector
                if goal == .distance { distancePicker }
                if goal == .time { timePicker }
                lapPicker
                Spacer()
                PACEPrimaryButton(title: "Start Run") { commit() }
            }
            .padding(PACESpacing.screenEdge)
            .paceBackground()
            .navigationTitle("Before You Run")
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
        .presentationDragIndicator(.visible)
    }

    private var goalSelector: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("GOAL")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
            HStack(spacing: PACESpacing.sm) {
                modeChip("None", mode: .none)
                modeChip("Distance", mode: .distance)
                modeChip("Time", mode: .time)
                Spacer()
            }
        }
    }

    private func modeChip(_ label: String, mode: GoalMode) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { goal = mode } } label: {
            Text(label)
                .font(PACEFonts.body)
                .foregroundStyle(goal == mode ? PACEColors.textInverse : PACEColors.textSecondary)
                .padding(.horizontal, PACESpacing.md)
                .padding(.vertical, PACESpacing.sm)
                .background(goal == mode ? PACEColors.accentCyan : PACEColors.surfaceElevated)
                .cornerRadius(PACESpacing.sm)
        }
    }

    private var distancePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("DISTANCE")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
            HStack(spacing: PACESpacing.md) {
                Text("\(Int(distanceKm)) km")
                    .font(PACEFonts.statMedium)
                    .foregroundStyle(PACEColors.accentCyan)
                    .frame(width: 72, alignment: .leading)
                Slider(value: $distanceKm, in: 1...42, step: 1)
                    .tint(PACEColors.accentCyan)
            }
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("DURATION")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
            HStack(spacing: PACESpacing.md) {
                Text("\(Int(durationMinutes)) min")
                    .font(PACEFonts.statMedium)
                    .foregroundStyle(PACEColors.accentCyan)
                    .frame(width: 72, alignment: .leading)
                Slider(value: $durationMinutes, in: 5...180, step: 5)
                    .tint(PACEColors.accentCyan)
            }
        }
    }

    private var lapPicker: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text("LAP ALERT")
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
            Picker("Lap Alert", selection: $lapInterval) {
                ForEach(LapInterval.allCases, id: \.self) { i in Text(i.displayName).tag(i) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func commit() {
        switch goal {
        case .none:     onStart(lapInterval, nil, nil, nil)
        case .distance: onStart(lapInterval, .singleRunDistance, distanceKm * 1000, nil)
        case .time:     onStart(lapInterval, .singleRunTime, nil, durationMinutes * 60)
        }
    }
}
