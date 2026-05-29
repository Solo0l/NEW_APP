import SwiftUI

struct CountdownView: View {
    @EnvironmentObject private var runService: RunService

    @State private var displayedNumber: Int = 3
    @State private var scale: CGFloat = 1.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: PACESpacing.xxl) {
                Spacer()

                countdownNumber

                Spacer()

                gpsStatus
                    .padding(.bottom, PACESpacing.xxl)
            }
        }
        }

    // MARK: - Countdown Number

    private var countdownNumber: some View {
        Group {
            if case .countdown(let n) = runService.phase {
                Text("\(n)")
                    .font(PACEFonts.countdown)
                    .foregroundStyle(PACEColors.textPrimary)
                    .id(n)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.3).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeOut(duration: 0.5), value: displayedNumber)
        .onChange(of: runService.phase) { _, phase in
            if case .countdown(let n) = phase { displayedNumber = n }
        }
    }

    // MARK: - GPS Status

    private var gpsStatus: some View {
        GPSStatusBadge(accuracy: runService.gpsAccuracy)
    }
}
