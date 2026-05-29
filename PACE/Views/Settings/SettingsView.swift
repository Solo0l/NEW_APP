import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    private var user: User? { users.first }

    var body: some View {
        NavigationStack {
            List {
                runningSection
                watchSection
                healthSection
                goalsSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(PACEColors.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func save() {
        try? context.save()
    }

    // MARK: - Sections

    private var runningSection: some View {
        Section("Running") {
            // Distance unit — auto-detected on install, user can override
            Picker("Distance", selection: unitBinding) {
                ForEach(DistanceUnit.allCases, id: \.self) { u in Text(u.displayName).tag(u) }
            }
            .tint(PACEColors.accentCyan)
            .foregroundStyle(PACEColors.textPrimary)

            Picker("Lap Alert", selection: lapBinding) {
                ForEach(LapInterval.allCases, id: \.self) { i in Text(i.displayName).tag(i) }
            }
            .tint(PACEColors.accentCyan)
            .foregroundStyle(PACEColors.textPrimary)

            Toggle("Audio Split Cues", isOn: audioBinding)
                .tint(PACEColors.accentCyan)
                .foregroundStyle(PACEColors.textPrimary)

            Toggle("Resume Countdown", isOn: resumeCountdownBinding)
                .tint(PACEColors.accentCyan)
                .foregroundStyle(PACEColors.textPrimary)
        }
        .listRowBackground(PACEColors.surface)
    }

    private var watchSection: some View {
        Section("Apple Watch") {
            Picker("Primary Metric", selection: watchMetricBinding) {
                ForEach(WatchPrimaryMetric.allCases, id: \.self) { m in Text(m.displayName).tag(m) }
            }
            .tint(PACEColors.accentCyan)
            .foregroundStyle(PACEColors.textPrimary)

            Toggle("HR Zone Color", isOn: hrZoneBinding)
                .tint(PACEColors.accentCyan)
                .foregroundStyle(PACEColors.textPrimary)
        }
        .listRowBackground(PACEColors.surface)
    }

    private var healthSection: some View {
        Section("Health") {
            HStack {
                Text("HealthKit Sync")
                    .foregroundStyle(PACEColors.textPrimary)
                Spacer()
                Label("Active", systemImage: "checkmark.circle.fill")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.success)
                    .labelStyle(.iconOnly)
                Text("Active")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }

            HStack {
                Text("Max Heart Rate")
                    .foregroundStyle(PACEColors.textPrimary)
                Spacer()
                Stepper("\(Int(user?.preferences.estimatedMaxHeartRate ?? 190)) bpm",
                        value: maxHRBinding, in: 160...220, step: 5)
                .foregroundStyle(PACEColors.textPrimary)
            }
        }
        .listRowBackground(PACEColors.surface)
    }

    private var goalsSection: some View {
        Section("Goals") {
            NavigationLink(destination: GoalsView()) {
                Text("Manage Goals").foregroundStyle(PACEColors.textPrimary)
            }
        }
        .listRowBackground(PACEColors.surface)
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version").foregroundStyle(PACEColors.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(PACEColors.textSecondary)
            }
            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                .foregroundStyle(PACEColors.accentCyan)
        }
        .listRowBackground(PACEColors.surface)
    }

    // MARK: - Bindings (all save on change)

    private var unitBinding: Binding<DistanceUnit> {
        Binding(get: { user?.preferences.distanceUnit ?? .systemDefault },
                set: { user?.preferences.distanceUnit = $0; save() })
    }
    private var lapBinding: Binding<LapInterval> {
        Binding(get: { user?.preferences.lapInterval ?? .oneKilometer },
                set: { user?.preferences.lapInterval = $0; save() })
    }
    private var audioBinding: Binding<Bool> {
        Binding(get: { user?.preferences.audioSplitCues ?? false },
                set: { user?.preferences.audioSplitCues = $0; save() })
    }
    private var resumeCountdownBinding: Binding<Bool> {
        Binding(get: { user?.preferences.resumeCountdownEnabled ?? true },
                set: { user?.preferences.resumeCountdownEnabled = $0; save() })
    }
    private var watchMetricBinding: Binding<WatchPrimaryMetric> {
        Binding(get: { user?.preferences.watchPrimaryMetric ?? .currentPace },
                set: { user?.preferences.watchPrimaryMetric = $0; save() })
    }
    private var hrZoneBinding: Binding<Bool> {
        Binding(get: { user?.preferences.showHeartRateZone ?? true },
                set: { user?.preferences.showHeartRateZone = $0; save() })
    }
    private var maxHRBinding: Binding<Double> {
        Binding(get: { user?.preferences.estimatedMaxHeartRate ?? 190 },
                set: { user?.preferences.estimatedMaxHeartRate = $0; save() })
    }
}
