import SwiftUI
import SwiftData
import CoreLocation

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [User]

    @State private var step: OnboardingStep = .identity
    @State private var locationManager = LocationManager()

    private var user: User? { users.first }

    enum OnboardingStep: Int, CaseIterable {
        case identity, location, health, quickSetup
    }

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()
            switch step {
            case .identity:
                IdentityView { advance() }
            case .location:
                LocationPermissionView(locationManager: locationManager) { advance() }
            case .health:
                HealthPermissionView { advance() }
            case .quickSetup:
                QuickSetupView(user: user) { completeOnboarding() }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    private func advance() {
        let next = OnboardingStep(rawValue: step.rawValue + 1) ?? .quickSetup
        withAnimation { step = next }
    }

    private func completeOnboarding() {
        if let user {
            user.preferences.hasCompletedOnboarding = true
            try? context.save()
        }
    }
}

// MARK: - Identity Screen

struct IdentityView: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: PACESpacing.md) {
                Text("PACE")
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .foregroundStyle(PACEColors.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text("Your run. Nothing else.")
                    .font(PACEFonts.body)
                    .foregroundStyle(PACEColors.textSecondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
            }
            Spacer()
            PACEPrimaryButton(title: "Get Started", action: onContinue)
                .padding(.horizontal, PACESpacing.screenEdge)
                .padding(.bottom, PACESpacing.xxl)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) { appeared = true }
        }
    }
}

// MARK: - Location Permission

struct LocationPermissionView: View {
    let locationManager: LocationManager
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: PACESpacing.lg) {
                Image(systemName: "location.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PACEColors.accentCyan)

                VStack(spacing: PACESpacing.sm) {
                    Text("Run anywhere.")
                        .font(PACEFonts.title)
                        .foregroundStyle(PACEColors.textPrimary)

                    Text("PACE uses GPS to track your route and distance accurately.")
                        .font(PACEFonts.body)
                        .foregroundStyle(PACEColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PACESpacing.xl)
                }
            }
            Spacer()

            VStack(spacing: PACESpacing.md) {
                PACEPrimaryButton(title: "Allow Location") {
                    locationManager.requestPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onContinue() }
                }
                Text("Required for distance tracking. Your location is never shared.")
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.bottom, PACESpacing.xxl)
        }
    }
}

// MARK: - Health Permission

struct HealthPermissionView: View {
    @State private var healthKitManager = HealthKitManager()
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: PACESpacing.lg) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PACEColors.accentCyan)

                VStack(spacing: PACESpacing.sm) {
                    Text("Smarter every run.")
                        .font(PACEFonts.title)
                        .foregroundStyle(PACEColors.textPrimary)
                }

                VStack(spacing: PACESpacing.md) {
                    PermissionRow(icon: "heart.fill", title: "Heart Rate", description: "Live from Apple Watch or paired sensor")
                    PermissionRow(icon: "bell.fill", title: "Notifications", description: "Pace alerts during your run")
                }
                .padding(.horizontal, PACESpacing.screenEdge)
            }
            Spacer()

            VStack(spacing: PACESpacing.sm) {
                PACEPrimaryButton(title: "Allow Both") {
                    Task {
                        await healthKitManager.requestAuthorization()
                        await MainActor.run { onContinue() }
                    }
                }
                Button("Skip for now") { onContinue() }
                    .font(PACEFonts.caption)
                    .foregroundStyle(PACEColors.textSecondary)
            }
            .padding(.horizontal, PACESpacing.screenEdge)
            .padding(.bottom, PACESpacing.xxl)
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: PACESpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(PACEColors.accentCyan)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PACEFonts.body).foregroundStyle(PACEColors.textPrimary)
                Text(description).font(PACEFonts.caption).foregroundStyle(PACEColors.textSecondary)
            }
            Spacer()
        }
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }
}
