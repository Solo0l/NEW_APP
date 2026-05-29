import SwiftUI
import SwiftData

@main
struct PACEWatchApp: App {
    @State private var watchRunService = WatchRunService()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(watchRunService)
        }
        .modelContainer(for: [Run.self, Split.self])
    }
}

// MARK: - Watch Root View

struct WatchRootView: View {
    @EnvironmentObject private var service: WatchRunService

    var body: some View {
        switch service.phase {
        case .idle:        WatchHomeView()
        case .countdown:   WatchCountdownView()
        case .active:      WatchActiveRunView()
        case .paused:      WatchPauseView()
        case .ended(let r): WatchSummaryView(run: r) { service.resetToIdle() }
        }
    }
}
