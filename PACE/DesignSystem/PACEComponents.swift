import SwiftUI

// MARK: - Primary Button

struct PACEPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PACEFonts.buttonPrimary)
                .foregroundStyle(PACEColors.textInverse)
                .frame(maxWidth: .infinity)
                .frame(height: PACESpacing.buttonHeight)
                .background(isDisabled ? PACEColors.accentCyan.opacity(0.3) : PACEColors.accentCyan)
                .cornerRadius(PACESpacing.buttonCornerRadius)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Secondary Button

struct PACESecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PACEFonts.buttonPrimary)
                .foregroundStyle(PACEColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: PACESpacing.buttonHeight)
                .background(PACEColors.surfaceElevated)
                .cornerRadius(PACESpacing.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: PACESpacing.buttonCornerRadius)
                        .stroke(PACEColors.separator, lineWidth: 1)
                )
        }
    }
}

// MARK: - Destructive Button

struct PACEDestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.error)
                .frame(height: PACESpacing.buttonHeightSmall)
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let value: String
    let label: String
    var accent: Color = .white

    var body: some View {
        VStack(spacing: PACESpacing.xs) {
            Text(value)
                .font(PACEFonts.metricSecondary)
                .foregroundStyle(accent)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
        }
        .frame(maxWidth: .infinity)
        .padding(PACESpacing.md)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.cardCornerRadius)
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    enum State {
        case acquiring, active, warning, error
    }

    let state: State
    var size: CGFloat = 8

    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(shouldPulse ? (pulse ? 1.5 : 1.0) : 1.0)
            .opacity(shouldPulse ? (pulse ? 0.4 : 1.0) : 1.0)
            .animation(shouldPulse ? .easeInOut(duration: 1.0).repeatForever() : .default, value: pulse)
            .onAppear { if shouldPulse { pulse = true } }
    }

    private var color: Color {
        switch state {
        case .acquiring: return PACEColors.textSecondary
        case .active:    return PACEColors.success
        case .warning:   return PACEColors.accentOrange
        case .error:     return PACEColors.error
        }
    }

    private var shouldPulse: Bool {
        state == .acquiring
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double   // 0.0 – 1.0
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 8
    var color: Color = PACEColors.accentCyan

    var body: some View {
        ZStack {
            Circle()
                .stroke(PACEColors.surfaceElevated, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(dampingFraction: 0.7), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - GPS Status Badge

struct GPSStatusBadge: View {
    let accuracy: GPSAccuracy

    var body: some View {
        HStack(spacing: PACESpacing.xs) {
            StatusDot(state: dotState)
            Text(label)
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textSecondary)
        }
        .padding(.horizontal, PACESpacing.sm)
        .padding(.vertical, PACESpacing.xs)
        .background(PACEColors.surface)
        .cornerRadius(PACESpacing.sm)
    }

    private var dotState: StatusDot.State {
        switch accuracy {
        case .acquiring: return .acquiring
        case .poor:      return .error
        case .fair:      return .warning
        case .good:      return .active
        }
    }

    private var label: String {
        switch accuracy {
        case .acquiring: return "Acquiring GPS…"
        case .poor:      return "GPS Weak"
        case .fair:      return "GPS Fair"
        case .good:      return "GPS Ready"
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: PACESpacing.md) {
            Text(message)
                .font(PACEFonts.body)
                .foregroundStyle(PACEColors.textSecondary)
                .multilineTextAlignment(.center)

            if let title = actionTitle, let action {
                Button(action: action) {
                    Text(title)
                        .font(PACEFonts.buttonPrimary)
                        .foregroundStyle(PACEColors.accentCyan)
                }
            }
        }
        .padding(PACESpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Separator

struct PACESeparator: View {
    var body: some View {
        Rectangle()
            .fill(PACEColors.separator)
            .frame(height: 1)
    }
}

// MARK: - Toasts / Banners

struct ToastView: View {
    let message: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: PACESpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(PACEColors.accentCyan)
            }
            Text(message)
                .font(PACEFonts.caption)
                .foregroundStyle(PACEColors.textPrimary)
        }
        .padding(.horizontal, PACESpacing.md)
        .padding(.vertical, PACESpacing.sm)
        .background(PACEColors.surfaceElevated)
        .cornerRadius(PACESpacing.sm)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
