import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var users: [User]
    @Environment(\.modelContext) private var context

    @EnvironmentObject private var runService: RunService

    private var user: User? { users.first }
    private var needsOnboarding: Bool {
        guard let user else { return true }
        return !user.preferences.hasCompletedOnboarding
    }

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingFlow()
            } else {
                switch runService.phase {
                case .idle:
                    MainTabView()
                case .countdown:
                    CountdownView()
                case .active:
                    ActiveRunView()
                case .paused:
                    ActiveRunView()  // PauseOverlay is rendered inside ActiveRunView
                case .ended(let run):
                    NavigationStack {
                        RunSummaryView(run: run)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Done") {
                                        // Transition back to idle
                                        Task { @MainActor in
                                            withAnimation { runService.discardRun() }
                                        }
                                    }
                                    .foregroundStyle(PACEColors.accentCyan)
                                }
                            }
                    }
                }
            }
        }
        .onAppear { ensureUserExists() }
    }

    private func ensureUserExists() {
        if users.isEmpty {
            let user = User()
            context.insert(user)
            try? context.save()
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showLabels: Bool = false
    @Query private var users: [User]

    enum Tab { case home, history, goals, settings }

    private var user: User? { users.first }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.history)

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(Tab.goals)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(PACEColors.accentCyan)
        .toolbarBackground(PACEColors.backgroundPrimary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear { trackLaunch() }
    }

    private func trackLaunch() {
        guard let user else { return }
        user.preferences.appLaunchCount += 1
    }
}
