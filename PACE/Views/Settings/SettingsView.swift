import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    private var user: User? { users.first }
    private var prefs: Binding<UserPreferences> {
        Binding(
            get: { user?.preferences ?? .default },
            set: { newPrefs in
                user?.preferences = newPrefs
                try? context.save()
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                runningSection
                watchSection
                healthSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(PACEColors.backgroundPrimary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var runningSection: some View {
        Section("Running") {
            settingRow(title: "Distance Unit") {
                Picker("Distance Unit", selection: prefs.distanceUnit) {
                    ForEach(DistanceUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .tint(PACEColors.accentCyan)
            }

            settingToggle(title: "Auto-Pause", isOn: prefs.autoPauseEnabled)

            settingToggle(title: "Resume Countdown", isOn: prefs.resumeCountdownEnabled)

            settingRow(title: "Lap Alert") {
                Picker("Lap Alert", selection: prefs.lapInterval) {
                    ForEach(LapInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .tint(PACEColors.accentCyan)
            }

            settingToggle(title: "Audio Split Cues", isOn: prefs.audioSplitCues)
        }
        .listRowBackground(PACEColors.surface)
    }

    private var watchSection: some View {
        Section("Apple Watch") {
            settingRow(title: "Primary Metric") {
                Picker("Primary Metric", selection: prefs.watchPrimaryMetric) {
                    ForEach(WatchPrimaryMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.menu)
                .tint(PACEColors.accentCyan)
            }

            settingToggle(title: "Show HR Zone Color", isOn: prefs.showHeartRateZone)
        }
        .listRowBackground(PACEColors.surface)
    }

    private var healthSection: some View {
        Section("Health") {
            HStack {
                Text("HealthKit Sync")
                    .foregroundStyle(PACEColors.textPrimary)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(PACEColors.success)
                Text("On")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }

            settingRow(title: "Estimated Max HR") {
                HStack {
                    Slider(value: prefs.estimatedMaxHeartRate, in: 160...220, step: 5)
                        .tint(PACEColors.accentCyan)
                    Text("\(Int(user?.preferences.estimatedMaxHeartRate ?? 190))")
                        .font(PACEFonts.caption)
                        .foregroundStyle(PACEColors.textSecondary)
                        .frame(width: 36)
                }
            }
        }
        .listRowBackground(PACEColors.surface)
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                    .foregroundStyle(PACEColors.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(PACEColors.textSecondary)
            }

            Link(destination: URL(string: "https://example.com/privacy")!) {
                Text("Privacy Policy")
                    .foregroundStyle(PACEColors.accentCyan)
            }
        }
        .listRowBackground(PACEColors.surface)
    }

    // MARK: - Row Helpers

    private func settingRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            Text(title)
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.textPrimary)
            content()
        }
        .padding(.vertical, PACESpacing.xs)
    }

    private func settingToggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.textPrimary)
        }
        .tint(PACEColors.accentCyan)
    }
}
