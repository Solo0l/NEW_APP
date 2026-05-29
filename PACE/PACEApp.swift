import SwiftUI
import SwiftData

@main
struct PACEApp: App {

    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
        .modelContainer(for: [
            User.self, Run.self, Split.self,
            Goal.self, Achievement.self, HealthMetricSnapshot.self
        ])
    }
}

// MARK: - App Root

// Services are created once here and injected via @Environment (the @Observable pattern).
// Never use EnvironmentObject — that requires ObservableObject which conflicts with @Observable.

struct AppRoot: View {
    @Environment(\.modelContext) private var context
    @State private var locationManager = LocationManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var runService: RunService?

    var body: some View {
        Group {
            if let service = runService {
                RootView()
                    .environment(service)
                    .environment(locationManager)
                    .environment(healthKitManager)
            } else {
                PACEColors.backgroundPrimary.ignoresSafeArea()
            }
        }
        .task {
            guard runService == nil else { return }
            runService = RunService(
                locationManager: locationManager,
                healthKitManager: healthKitManager,
                modelContext: context
            )
        }
        .preferredColorScheme(.dark)
    }
}
