import SwiftUI

struct CountdownView: View {
    @Environment(RunService.self) private var runService
    @State private var displayedNumber: Int = 3

    var body: some View {
        ZStack {
            PACEColors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: PACESpacing.xxl) {
                Spacer()

                if case .countdown(let n) = runService.phase {
                    Text("\(n)")
                        .font(PACEFonts.countdown)
                        .foregroundStyle(PACEColors.textPrimary)
                        .id(n)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.3).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)
                        ))
                        .animation(.easeOut(duration: 0.45), value: n)
                }

                Spacer()

                GPSStatusBadge(accuracy: runService.gpsAccuracy)
                    .padding(.bottom, PACESpacing.xxl)
            }
        }
    }
}
