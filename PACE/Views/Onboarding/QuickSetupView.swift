import SwiftUI
import SwiftData

struct QuickSetupView: View {
    let user: User?
    let onComplete: () -> Void

    @State private var selectedUnit: DistanceUnit = Locale.current.measurementSystem == .metric ? .kilometers : .miles
    @State private var audioCuesEnabled: Bool = false
    @State private var watchConnected: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: PACESpacing.xl) {
                VStack(alignment: .leading, spacing: PACESpacing.sm) {
                    Text("Quick Setup")
                        .font(PACEFonts.title)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text("Three things. Done in seconds.")
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textSecondary)
                }
                .padding(.top, PACESpacing.xxl)

                // Distance Unit
                SetupSection(number: "1", title: "Distance unit") {
                    HStack(spacing: PACESpacing.sm) {
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Toggle(unit.displayName, isOn: Binding(
                                get: { selectedUnit == unit },
                                set: { if $0 { selectedUnit = unit } }
                            ))
                            .toggleStyle(PillToggleStyle(isSelected: selectedUnit == unit))
                        }
                        Spacer()
                    }
                }

                // Audio Cues
                SetupSection(number: "2", title: "Audio split cues") {
                    Toggle("Play a chime every km", isOn: $audioCuesEnabled)
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textPrimary)
                        .tint(PACEColors.accentCyan)
                }

                // Apple Watch
                SetupSection(number: "3", title: "Apple Watch") {
                    VStack(alignment: .leading, spacing: PACESpacing.sm) {
                        Text("PACE runs independently on Apple Watch. Make sure the app is installed.")
                            .font(PACEFonts.caption)
                            .foregroundStyle(PACEColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, PACESpacing.screenEdge)

            Spacer()

            PACEPrimaryButton(title: "Start Running") {
                applySettings()
                onComplete()
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.bottom, PACESpacing.xxl)
        }
        .paceBackground()
    }

    private func applySettings() {
        guard let user else { return }
        user.preferences.distanceUnit = selectedUnit
        user.preferences.audioSplitCues = audioCuesEnabled
        user.preferences.hasCompletedQuickSetup = true
    }
}

// MARK: - Setup Section

private struct SetupSection<Content: View>: View {
    let number: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: PACESpacing.sm) {
            HStack(spacing: PACESpacing.sm) {
                Text(number)
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.accentCyan)
                    .frame(width: 20, height: 20)
                    .background(PACEColors.accentCyanDim)
                    .clipShape(Circle())
                Text(title)
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textPrimary)
            }
            content
                .padding(.leading, PACESpacing.xl)
        }
    }
}

// MARK: - Pill Toggle Style

struct PillToggleStyle: ToggleStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .font(PACEFonts.body)
                .foregroundStyle(isSelected ? PACEColors.textInverse : PACEColors.textSecondary)
                .padding(.horizontal, PACESpacing.md)
                .padding(.vertical, PACESpacing.sm)
                .background(isSelected ? PACEColors.accentCyan : PACEColors.surface)
                .cornerRadius(PACESpacing.sm)
        }
    }
}
