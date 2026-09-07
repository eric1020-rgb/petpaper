import SwiftUI

struct StickerGlyph: View {
    let kind: StickerKind
    var tint: Color = AppTheme.coral

    var body: some View {
        Group {
            if let symbol = kind.systemImage {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
            } else {
                customGlyph
                    .foregroundStyle(tint)
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }

    @ViewBuilder
    private var customGlyph: some View {
        switch kind {
        case .bone:
            BoneShape()
                .fill(tint)
        case .ball:
            ZStack {
                Circle().fill(tint)
                Circle().stroke(.white.opacity(0.7), lineWidth: 3)
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 18))
                    path.addQuadCurve(to: CGPoint(x: 32, y: 18), control: CGPoint(x: 18, y: 4))
                }
                .stroke(.white.opacity(0.85), lineWidth: 3)
            }
            .frame(width: 36, height: 36)
        case .bowl:
            ZStack {
                Ellipse()
                    .fill(tint.opacity(0.35))
                    .frame(width: 40, height: 10)
                    .offset(y: 10)
                Capsule()
                    .fill(tint)
                    .frame(width: 36, height: 16)
                    .offset(y: 4)
                Ellipse()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 28, height: 8)
                    .offset(y: -2)
            }
            .frame(width: 40, height: 32)
        case .yarn:
            ZStack {
                Circle().stroke(tint, lineWidth: 4)
                Path { path in
                    path.addArc(center: CGPoint(x: 16, y: 16), radius: 10, startAngle: .degrees(-20), endAngle: .degrees(200), clockwise: false)
                    path.addArc(center: CGPoint(x: 16, y: 16), radius: 6, startAngle: .degrees(200), endAngle: .degrees(40), clockwise: true)
                }
                .stroke(tint, lineWidth: 2)
            }
            .frame(width: 32, height: 32)
        default:
            Image(systemName: "sparkle")
                .foregroundStyle(tint)
        }
    }
}

private struct BoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(rect.width, rect.height) * 0.22
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY + 2, width: r * 1.4, height: r * 1.4))
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.maxY - r * 1.5, width: r * 1.4, height: r * 1.4))
        path.addEllipse(in: CGRect(x: rect.maxX - r * 1.4, y: rect.minY + 2, width: r * 1.4, height: r * 1.4))
        path.addEllipse(in: CGRect(x: rect.maxX - r * 1.4, y: rect.maxY - r * 1.5, width: r * 1.4, height: r * 1.4))
        path.addRoundedRect(
            in: CGRect(x: rect.minX + r * 0.7, y: rect.midY - r * 0.45, width: rect.width - r * 1.4, height: r * 0.9),
            cornerSize: CGSize(width: 6, height: 6)
        )
        return path
    }
}
