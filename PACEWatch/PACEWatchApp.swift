import SwiftUI
import SwiftData

@main
struct PACEWatchApp: App {
    @State private var service = WatchRunService()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(service)
        }
        .modelContainer(for: [Run.self, Split.self])
    }
}

// MARK: - Watch Root View

struct WatchRootView: View {
    @Environment(WatchRunService.self) private var service

    var body: some View {
        switch service.phase {
        case .idle:
            WatchHomeView()
        case .countdown:
            WatchCountdownView()
        case .active, .paused:
            WatchActiveRunView()
        case .ended(let runID):
            WatchSummaryWrapper(runID: runID)
        }
    }
}

// MARK: - Watch Summary Wrapper

struct WatchSummaryWrapper: View {
    let runID: UUID
    @Environment(WatchRunService.self) private var service
    @Query private var runs: [Run]

    private var run: Run? { runs.first { $0.id == runID } }

    var body: some View {
        if let run {
            WatchSummaryView(run: run) { service.resetToIdle() }
        } else {
            // Fallback while SwiftData syncs
            ProgressView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if run == nil { service.resetToIdle() }
                    }
                }
        }
    }
}
