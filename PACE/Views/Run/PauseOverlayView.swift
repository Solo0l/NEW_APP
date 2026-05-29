import SwiftUI

struct PauseOverlayView: View {
    let onResume: () -> Void
    let onLap: () -> Void
    let onEnd: () -> Void

    @State private var endConfirmationShown = false
    @State private var endSwipeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Dimmed background
            PACEColors.backgroundPrimary.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Action card
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: PACESpacing.sm) {
                    // Resume — primary
                    Button(action: onResume) {
                        Text("RESUME")
                            .font(PACEFonts.buttonLarge)
                            .foregroundStyle(PACEColors.textInverse)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(PACEColors.accentCyan)
                            .cornerRadius(PACESpacing.buttonCornerRadius)
                    }

                    // Lap — secondary
                    Button(action: onLap) {
                        HStack(spacing: PACESpacing.sm) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 16))
                            Text("Mark Lap")
                                .font(PACEFonts.buttonPrimary)
                        }
                        .foregroundStyle(PACEColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: PACESpacing.buttonHeight)
                        .background(PACEColors.surfaceElevated)
                        .cornerRadius(PACESpacing.buttonCornerRadius)
                    }

                    // End — swipe to confirm
                    if endConfirmationShown {
                        endConfirmRow
                    } else {
                        Button { withAnimation(.spring(dampingFraction: 0.7)) { endConfirmationShown = true } } label: {
                            Text("Finish Run")
                                .font(PACEFonts.body)
                                .foregroundStyle(PACEColors.error)
                                .frame(height: PACESpacing.buttonHeightSmall)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(PACESpacing.screenEdge)
                .background(
                    PACEColors.surface
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                )
            }
        }
    }

    // MARK: - End Confirmation

    private var endConfirmRow: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: PACESpacing.buttonCornerRadius)
                .fill(PACEColors.error.opacity(0.15))
                .frame(height: PACESpacing.buttonHeight)

            RoundedRectangle(cornerRadius: PACESpacing.buttonCornerRadius)
                .fill(PACEColors.error)
                .frame(width: max(60, endSwipeOffset + 60), height: PACESpacing.buttonHeight)
                .animation(.interactiveSpring(), value: endSwipeOffset)

            HStack {
                Image(systemName: "chevron.right.2")
                    .foregroundStyle(endSwipeOffset > 200 ? .white : PACEColors.error)
                    .padding(.leading, PACESpacing.md)
                Text("Swipe to finish")
                    .font(PACEFonts.body)
                    .foregroundStyle(endSwipeOffset > 200 ? .white : PACEColors.error)
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    endSwipeOffset = max(0, value.translation.width)
                }
                .onEnded { value in
                    if value.translation.width > 220 {
                        onEnd()
                    } else {
                        withAnimation(.spring()) { endSwipeOffset = 0 }
                    }
                }
        )
    }
}

// MARK: - Rounded Corners Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
