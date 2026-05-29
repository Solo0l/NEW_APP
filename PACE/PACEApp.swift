import SwiftUI
import SwiftData

@main
struct PACEApp: App {
    private let locationManager = LocationManager()
    private let healthKitManager = HealthKitManager()
    private let analyticsEngine = AnalyticsEngine()

    var body: some Scene {
        WindowGroup {
            PACEAppRoot(
                locationManager: locationManager,
                healthKitManager: healthKitManager,
                analyticsEngine: analyticsEngine
            )
        }
        .modelContainer(for: [
            User.self,
            Run.self,
            Split.self,
            Goal.self,
            Achievement.self,
            HealthMetricSnapshot.self
        ])
    }
}

// MARK: - App Root (provides environment objects)

struct PACEAppRoot: View {
    let locationManager: LocationManager
    let healthKitManager: HealthKitManager
    let analyticsEngine: AnalyticsEngine

    @Environment(\.modelContext) private var context
    @State private var runService: RunService?

    var body: some View {
        Group {
            if let service = runService {
                RootView()
                    .environmentObject(service)
                    .environmentObject(analyticsEngine)
                    .environment(service)
            } else {
                Color(hex: "0A0A0A")
                    .ignoresSafeArea()
            }
        }
        .task {
            if runService == nil {
                runService = RunService(
                    locationManager: locationManager,
                    healthKitManager: healthKitManager,
                    modelContext: context
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
