import SwiftUI

struct WatchPauseView: View {
    @EnvironmentObject private var service: WatchRunService

    @State private var endSwipeOffset: CGFloat = 0
    @State private var showEndConfirm = false

    var body: some View {
        VStack(spacing: 8) {
            // RESUME — largest, most prominent
            Button { service.resumeRun() } label: {
                Text("RESUME")
                    .font(PACEWatchFonts.buttonLabel)
                    .foregroundStyle(Color(hex: "0A0A0A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "00D4FF"))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // LAP
            Button { service.markLap(); service.resumeRun() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                    Text("Lap")
                        .font(PACEWatchFonts.buttonLabel)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            // FINISH — swipe to confirm
            if showEndConfirm {
                endConfirmSlider
            } else {
                Button { withAnimation { showEndConfirm = true } } label: {
                    Text("Finish")
                        .font(PACEWatchFonts.metricLabel)
                        .foregroundStyle(Color(hex: "FF3B30"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(Color(hex: "0A0A0A"))
    }

    private var endConfirmSlider: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "FF3B30").opacity(0.15))
                .frame(height: 32)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "FF3B30"))
                .frame(width: max(32, endSwipeOffset + 32), height: 32)
                .animation(.interactiveSpring(), value: endSwipeOffset)
            HStack {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(endSwipeOffset > 80 ? .white : Color(hex: "FF3B30"))
                    .padding(.leading, 8)
                Text("Finish")
                    .font(PACEWatchFonts.metricLabel)
                    .foregroundStyle(endSwipeOffset > 80 ? .white : Color(hex: "FF3B30"))
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { endSwipeOffset = max(0, $0.translation.width) }
                .onEnded { value in
                    if value.translation.width > 100 { service.endRun() }
                    else { withAnimation(.spring()) { endSwipeOffset = 0; showEndConfirm = false } }
                }
        )
    }
}
