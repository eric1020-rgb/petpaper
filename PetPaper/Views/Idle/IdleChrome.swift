import SwiftUI

struct IdleToastBanner: View {
    var key: String

    var body: some View {
        Text(LocalizedStringKey(key))
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(AppTheme.ink)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct IdlePortalOverlay: View {
    var progress: Double
    var size: CGSize

    init(progress: Double, in size: CGSize) {
        self.progress = progress
        self.size = size
    }

    var body: some View {
        let doorWidth = size.width * 0.2
        let doorHeight = size.height * 0.28
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.35, blue: 0.95),
                            Color(red: 0.35, green: 0.78, blue: 0.95),
                            Color(red: 0.95, green: 0.7, blue: 0.95)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.85), lineWidth: 3)
                .padding(7)
            Image(systemName: "door.left.hand.open")
                .font(.system(size: min(doorWidth, 36), weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: doorWidth, height: doorHeight)
        .opacity(progress)
        .scaleEffect(0.82 + 0.18 * progress)
        .position(x: size.width * 0.9, y: size.height * 0.4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct IdleSparkleOverlay: View {
    var amount: Double
    var size: CGSize
    var around: CGPoint
    var animated: Bool = true

    init(amount: Double, in size: CGSize, around: CGPoint, animated: Bool = true) {
        self.amount = amount
        self.size = size
        self.around = around
        self.animated = animated
    }

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 0.05, paused: amount < 0.04)) { timeline in
                sparkles(at: timeline.date.timeIntervalSinceReferenceDate)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            sparkles(at: 0.6)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func sparkles(at t: Double) -> some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) / 10 * .pi * 2 + t * 1.6
                let radius = min(size.width, size.height) * (0.08 + 0.04 * sin(t * 3 + Double(index)))
                Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "sparkles")
                    .font(.system(size: 10 + CGFloat(index % 3) * 3))
                    .foregroundStyle(.white.opacity(0.95))
                    .scaleEffect(0.7 + 0.4 * sin(t * 5 + Double(index)))
                    .opacity(amount * (0.45 + 0.55 * (0.5 + 0.5 * sin(t * 4 + Double(index)))))
                    .position(
                        x: around.x + CGFloat(cos(angle)) * radius,
                        y: around.y + CGFloat(sin(angle)) * radius * 0.85
                    )
            }
        }
    }
}
