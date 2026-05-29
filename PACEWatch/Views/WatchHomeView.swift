import SwiftUI

struct WatchHomeView: View {
    @Environment(WatchRunService.self) private var service

    var body: some View {
        VStack(spacing: 10) {
            Text("PACE")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "606060"))
                .tracking(3)

            Button {
                service.startCountdown()
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
        .task { await service.requestAuthorization() }
    }
}

// MARK: - Countdown

struct WatchCountdownView: View {
    @Environment(WatchRunService.self) private var service

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
