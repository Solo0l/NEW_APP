import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var service: WatchRunService

    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task { @MainActor in service.startCountdown() }
            } label: {
                Text("RUN")
                    .font(PACEWatchFonts.buttonLabel)
                    .foregroundStyle(Color(hex: "0A0A0A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "00D4FF"))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .navigationTitle("PACE")
        .navigationBarTitleDisplayMode(.large)
        .task { await service.requestAuthorization() }
    }
}

// MARK: - Countdown

struct WatchCountdownView: View {
    @EnvironmentObject private var service: WatchRunService

    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()
            if case .countdown(let n) = service.phase {
                Text("\(n)")
                    .font(PACEWatchFonts.countdown)
                    .foregroundStyle(.white)
                    .id(n)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.3).combined(with: .opacity),
                        removal: .scale(scale: 0.7).combined(with: .opacity)
                    ))
                    .animation(.easeOut(duration: 0.4), value: n)
            }
        }
    }
}
