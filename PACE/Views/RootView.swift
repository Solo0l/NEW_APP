import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(RunService.self) private var runService
    @Environment(\.modelContext) private var context
    @Query private var users: [User]

    private var needsOnboarding: Bool {
        users.first.map { !$0.preferences.hasCompletedOnboarding } ?? true
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView()
            } else {
                switch runService.phase {
                case .idle:
                    MainTabView()
                case .countdown:
                    CountdownView()
                case .active, .paused:
                    ActiveRunView()
                case .ended(let runID):
                    PostRunSummaryWrapper(runID: runID)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: needsOnboarding)
        .onAppear { ensureUser() }
    }

    private func ensureUser() {
        guard users.isEmpty else { return }
        let user = User()
        context.insert(user)
        try? context.save()
    }
}

// MARK: - Post-run summary wrapper (fetches Run from ID)

struct PostRunSummaryWrapper: View {
    let runID: UUID
    @Environment(RunService.self) private var runService
    @Query private var runs: [Run]

    private var run: Run? { runs.first { $0.id == runID } }

    var body: some View {
        if let run {
            NavigationStack {
                RunSummaryView(run: run)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { runService.discardAndReset() }
                                .foregroundStyle(PACEColors.accentCyan)
                        }
                    }
            }
        } else {
            // Run not yet saved (rare) — wait or fall back to home
            PACEColors.backgroundPrimary.ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if run == nil { runService.discardAndReset() }
                    }
                }
        }
    }
}

// MARK: - Main Tab View (3 tabs)

struct MainTabView: View {
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(PACEColors.accentCyan)
        .toolbarBackground(PACEColors.backgroundPrimary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear { incrementLaunchCount() }
    }

    private func incrementLaunchCount() {
        guard let user = users.first else { return }
        user.preferences.appLaunchCount += 1
        try? context.save()
    }
}
