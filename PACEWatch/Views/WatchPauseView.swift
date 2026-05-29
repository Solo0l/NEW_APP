import SwiftUI

struct WatchPauseView: View {
    @Environment(WatchRunService.self) private var service
    @State private var showEndConfirm = false

    var body: some View {
        VStack(spacing: 8) {
            // RESUME — full width, primary
            Button { service.resumeRun() } label: {
                Text("RESUME")
                    .font(PACEWatchFonts.buttonLabel)
                    .foregroundStyle(Color(hex: "0A0A0A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color(hex: "00D4FF"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // LAP — secondary
            Button {
                service.markLap()
                service.resumeRun()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flag")
                        .font(.system(size: 11, weight: .medium))
                    Text("Mark Lap")
                        .font(PACEWatchFonts.buttonLabel)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // END — two taps to confirm, no swipe gesture (unreliable on Watch)
            if showEndConfirm {
                HStack(spacing: 6) {
                    Button { showEndConfirm = false } label: {
                        Text("No")
                            .font(PACEWatchFonts.metricLabel)
                            .foregroundStyle(Color(hex: "606060"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(Color(hex: "1E1E1E"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button { service.endRun() } label: {
                        Text("Finish")
                            .font(PACEWatchFonts.metricLabel)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .background(Color(hex: "FF3B30"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button { withAnimation { showEndConfirm = true } } label: {
                    Text("End Run")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            Color(hex: "0A0A0A").opacity(0.96)
                .cornerRadius(16, corners: [.topLeft, .topRight])
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
