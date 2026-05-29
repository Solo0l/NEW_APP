import SwiftUI
import SwiftData

// Two screens. No account. No configuration. No friction.
// Screen 1: Who we are and what we need.
// Screen 2: The permission tap (system sheet fires).

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(LocationManager.self) private var locationManager
    @Environment(HealthKitManager.self) private var healthKitManager
    @Query private var users: [User]

    @State private var step: Step = .welcome
    @State private var appeared = false

    enum Step { case welcome, permissions }

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()

            switch step {
            case .welcome:
                welcomeScreen
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .permissions:
                permissionsScreen
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: PACESpacing.md) {
                Text("PACE")
                    .font(.system(size: 52, weight: .medium, design: .rounded))
                    .foregroundStyle(PACEColors.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)

                Text("Your run.\nNothing else.")
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
            }

            Spacer()

            PACEPrimaryButton(title: "Get Started") {
                withAnimation { step = .permissions }
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.bottom, PACESpacing.xxl)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) { appeared = true }
        }
    }

    // MARK: - Screen 2: Permissions

    private var permissionsScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: PACESpacing.xl) {
                VStack(spacing: PACESpacing.sm) {
                    Text("Two quick things.")
                        .font(PACEFonts.title)
                        .foregroundStyle(PACEColors.textPrimary)
                    Text("PACE needs these to track your runs.")
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textSecondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: PACESpacing.sm) {
                    permissionRow(
                        icon: "location.fill",
                        title: "Location",
                        detail: "GPS route and distance"
                    )
                    permissionRow(
                        icon: "heart.fill",
                        title: "Health",
                        detail: "Heart rate and workout history"
                    )
                }
                .padding(.horizontal, PACESpacing.screenEdge)
            }

            Spacer()

            VStack(spacing: PACESpacing.sm) {
                PACEPrimaryButton(title: "Allow & Start Running") {
                    Task { await requestPermissionsAndComplete() }
                }

                Text("Your data stays on your device.\nNever shared, never sold.")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.bottom, PACESpacing.xxl)
        }
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: PACESpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(PACEColors.accentCyan)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textPrimary)
                Text(detail)
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }
            Spacer()
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }

    // MARK: - Permission Request + Completion

    private func requestPermissionsAndComplete() async {
        locationManager.requestPermission()
        await healthKitManager.requestAuthorization()

        await MainActor.run {
            guard let user = users.first else { return }
            user.preferences.hasCompletedOnboarding = true
            try? context.save()
        }
    }
}
