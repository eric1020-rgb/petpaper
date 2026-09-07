import SwiftUI

struct TemplateSceneView: View {
    let template: TemplateKind
    var palette: ColorPalette
    var hueShift: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                palette.gradient
                scene(in: geo.size)
            }
            .hueRotation(.degrees(hueShift * 360))
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func scene(in size: CGSize) -> some View {
        switch template {
        case .pastel: PastelScene(palette: palette, size: size)
        case .nightSky: NightSkyScene(palette: palette, size: size)
        case .park: ParkScene(palette: palette, size: size)
        case .cozyRoom: CozyRoomScene(palette: palette, size: size)
        case .neon: NeonScene(palette: palette, size: size)
        case .sakura: SakuraScene(palette: palette, size: size)
        case .beach: BeachScene(palette: palette, size: size)
        case .snow: SnowScene(palette: palette, size: size)
        }
    }
}

private struct PastelScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.highlight.color.opacity(0.55))
                .frame(width: size.width * 0.9)
                .offset(x: -size.width * 0.2, y: -size.height * 0.28)
            Circle()
                .fill(palette.secondary.color.opacity(0.45))
                .frame(width: size.width * 0.7)
                .offset(x: size.width * 0.28, y: -size.height * 0.18)
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.72))
                    .frame(width: size.width * 0.46, height: size.height * 0.06)
                    .offset(
                        x: CGFloat(index.isMultiple(of: 2) ? -1 : 1) * size.width * 0.12,
                        y: size.height * (0.08 + CGFloat(index) * 0.12)
                    )
                    .blur(radius: 1)
            }
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: size.width * 0.1))
                        .foregroundStyle(palette.accent.color.opacity(0.7))
                    Spacer()
                    Image(systemName: "sparkle")
                        .font(.system(size: size.width * 0.08))
                        .foregroundStyle(palette.secondary.color)
                }
                .padding(.horizontal, size.width * 0.1)
                .padding(.top, size.height * 0.12)
                Spacer()
            }
        }
    }
}

private struct NightSkyScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                for i in 0..<48 {
                    let x = CGFloat((i * 47) % 97) / 97 * canvasSize.width
                    let y = CGFloat((i * 23) % 89) / 89 * canvasSize.height * 0.72
                    let r = CGFloat((i % 4) + 1) * 1.4
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(palette.highlight.color.opacity(0.85))
                    )
                }
            }
            Circle()
                .fill(palette.accent.color.opacity(0.95))
                .frame(width: size.width * 0.28)
                .offset(x: size.width * 0.22, y: -size.height * 0.28)
            Circle()
                .fill(palette.top.color)
                .frame(width: size.width * 0.2)
                .offset(x: size.width * 0.28, y: -size.height * 0.30)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: size.width * 0.16))
                .foregroundStyle(palette.accent.color)
                .offset(x: -size.width * 0.22, y: -size.height * 0.22)
        }
    }
}

private struct ParkScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.accent.color)
                .frame(width: size.width * 0.32)
                .offset(x: size.width * 0.26, y: -size.height * 0.32)
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .fill(palette.secondary.color.opacity(0.55 + Double(i) * 0.12))
                    .frame(width: size.width * 1.4, height: size.height * 0.28)
                    .offset(y: size.height * (0.18 + CGFloat(i) * 0.14))
            }
            HStack(spacing: size.width * 0.08) {
                tree(height: size.height * 0.22)
                tree(height: size.height * 0.28)
                tree(height: size.height * 0.18)
            }
            .offset(y: size.height * 0.02)
        }
    }

    private func tree(height: CGFloat) -> some View {
        VStack(spacing: -8) {
            Circle()
                .fill(palette.secondary.color)
                .frame(width: height * 0.7, height: height * 0.7)
            Capsule()
                .fill(Color(red: 0.45, green: 0.28, blue: 0.16))
                .frame(width: 10, height: height * 0.28)
        }
    }
}

private struct CozyRoomScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(palette.top.color)
                Rectangle()
                    .fill(Color(red: 0.62, green: 0.4, blue: 0.25).opacity(0.85))
                    .frame(height: size.height * 0.32)
            }
            RoundedRectangle(cornerRadius: 18)
                .fill(palette.highlight.color)
                .overlay {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(palette.secondary.color.opacity(0.65))
                            }
                        }
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(palette.accent.color.opacity(0.35))
                            }
                        }
                    }
                    .padding(12)
                }
                .frame(width: size.width * 0.46, height: size.height * 0.22)
                .offset(y: -size.height * 0.18)
            RoundedRectangle(cornerRadius: 8)
                .fill(palette.accent.color.opacity(0.85))
                .frame(width: size.width * 0.42, height: size.height * 0.08)
                .offset(y: size.height * 0.22)
            Image(systemName: "lamp.desk.fill")
                .font(.system(size: size.width * 0.12))
                .foregroundStyle(palette.accent.color)
                .offset(x: size.width * 0.28, y: size.height * 0.08)
        }
    }
}

private struct NeonScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                for row in 0..<14 {
                    let y = canvasSize.height * 0.45 + CGFloat(row) * 18
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                    context.stroke(path, with: .color(palette.secondary.color.opacity(0.25)), lineWidth: 1)
                }
                for col in stride(from: 0, to: 20, by: 1) {
                    let t = CGFloat(col) / 20
                    var path = Path()
                    path.move(to: CGPoint(x: canvasSize.width * t, y: canvasSize.height * 0.45))
                    path.addLine(to: CGPoint(x: canvasSize.width * (0.5 + (t - 0.5) * 2.4), y: canvasSize.height))
                    context.stroke(path, with: .color(palette.accent.color.opacity(0.18)), lineWidth: 1)
                }
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [palette.accent.color, palette.accent.color.opacity(0)],
                        center: .center,
                        startRadius: 4,
                        endRadius: size.width * 0.4
                    )
                )
                .frame(width: size.width * 0.8)
                .offset(y: -size.height * 0.18)
            Circle()
                .stroke(palette.secondary.color, lineWidth: 6)
                .frame(width: size.width * 0.55)
                .offset(y: -size.height * 0.18)
                .shadow(color: palette.secondary.color, radius: 16)
            Image(systemName: "bolt.fill")
                .font(.system(size: size.width * 0.12))
                .foregroundStyle(palette.highlight.color)
                .shadow(color: palette.highlight.color, radius: 10)
                .offset(y: -size.height * 0.32)
        }
    }
}

private struct SakuraScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Circle()
                    .fill(palette.highlight.color.opacity(0.85))
                    .frame(width: 10 + CGFloat(i % 5) * 4)
                    .offset(
                        x: CGFloat((i * 37) % 90 - 45) / 90 * size.width,
                        y: CGFloat((i * 19) % 80 - 20) / 80 * size.height * 0.7
                    )
            }
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color(red: 0.42, green: 0.26, blue: 0.2))
                        .frame(width: 14, height: size.height * 0.45)
                        .rotationEffect(.degrees(-18))
                    Spacer()
                }
                .padding(.leading, size.width * 0.08)
            }
            Circle()
                .fill(palette.accent.color.opacity(0.35))
                .frame(width: size.width * 0.42)
                .offset(x: -size.width * 0.2, y: size.height * 0.08)
            Image(systemName: "leaf.fill")
                .font(.system(size: size.width * 0.12))
                .foregroundStyle(palette.secondary.color)
                .offset(x: size.width * 0.28, y: size.height * 0.22)
        }
    }
}

private struct BeachScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [palette.top.color, palette.secondary.color.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [palette.secondary.color, palette.bottom.color],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size.height * 0.42)
            }
            Circle()
                .fill(palette.accent.color)
                .frame(width: size.width * 0.28)
                .offset(x: -size.width * 0.22, y: -size.height * 0.28)
            WaveShape()
                .fill(palette.secondary.color.opacity(0.55))
                .frame(height: size.height * 0.18)
                .offset(y: size.height * 0.08)
            Image(systemName: "sun.max.fill")
                .font(.system(size: size.width * 0.12))
                .foregroundStyle(palette.accent.color)
                .offset(x: size.width * 0.28, y: -size.height * 0.3)
        }
    }
}

private struct SnowScene: View {
    let palette: ColorPalette
    let size: CGSize

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.white.opacity(0.9))
                .frame(width: size.width * 1.4, height: size.height * 0.32)
                .offset(y: size.height * 0.28)
            HStack(alignment: .bottom, spacing: 18) {
                pine(size.height * 0.18)
                pine(size.height * 0.26)
                pine(size.height * 0.16)
            }
            .offset(y: size.height * 0.08)
            Canvas { context, canvasSize in
                for i in 0..<30 {
                    let x = CGFloat((i * 53) % 97) / 97 * canvasSize.width
                    let y = CGFloat((i * 29) % 91) / 91 * canvasSize.height
                    let r = CGFloat((i % 3) + 2)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                        with: .color(.white.opacity(0.9))
                    )
                }
            }
            Image(systemName: "snowflake")
                .font(.system(size: size.width * 0.1))
                .foregroundStyle(palette.accent.color.opacity(0.7))
                .offset(x: size.width * 0.24, y: -size.height * 0.24)
        }
    }

    private func pine(_ height: CGFloat) -> some View {
        VStack(spacing: -6) {
            Triangle()
                .fill(Color(red: 0.25, green: 0.45, blue: 0.38))
                .frame(width: height * 0.7, height: height * 0.7)
            Capsule()
                .fill(Color(red: 0.4, green: 0.26, blue: 0.18))
                .frame(width: 8, height: height * 0.18)
        }
    }
}

private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.25, y: 0),
            control2: CGPoint(x: rect.width * 0.75, y: rect.height)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
