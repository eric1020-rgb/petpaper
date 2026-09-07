import SwiftUI

struct PetIllustration: View {
    let character: PetCharacter
    var lookOffset: CGSize = .zero
    var lean: Double = 0

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let ground = size.height * 0.86
            let bodyW = size.width * character.bodyWidth * 0.42
            let bodyH = size.height * 0.34
            let legH = size.height * (0.12 + character.legLength * 0.12)
            let headR = size.width * (0.18 * character.headScale)

            drawTail(context: &context, size: size, cx: cx, ground: ground, bodyH: bodyH)
            drawLegs(context: &context, size: size, cx: cx, ground: ground, bodyW: bodyW, legH: legH)
            drawBody(context: &context, size: size, cx: cx, ground: ground, bodyW: bodyW, bodyH: bodyH, legH: legH)
            drawHead(context: &context, size: size, cx: cx, ground: ground, bodyH: bodyH, legH: legH, headR: headR)
        }
        .rotationEffect(.degrees(lean))
        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.7), value: lean)
        .accessibilityHidden(true)
    }

    private func drawTail(context: inout GraphicsContext, size: CGSize, cx: CGFloat, ground: CGFloat, bodyH: CGFloat) {
        let origin = CGPoint(x: cx + size.width * 0.12, y: ground - bodyH * 0.55)
        var path = Path()
        switch character.tail {
        case .short:
            path.addEllipse(in: CGRect(x: origin.x, y: origin.y, width: size.width * 0.08, height: size.height * 0.07))
        case .curled:
            path.addArc(center: CGPoint(x: origin.x + 10, y: origin.y - 8), radius: size.width * 0.08, startAngle: .degrees(40), endAngle: .degrees(300), clockwise: false)
        case .fluffy:
            path.addEllipse(in: CGRect(x: origin.x - 4, y: origin.y - size.height * 0.12, width: size.width * 0.14, height: size.height * 0.22))
        case .longCurve:
            path.move(to: origin)
            path.addQuadCurve(
                to: CGPoint(x: origin.x + size.width * 0.18, y: origin.y - size.height * 0.22),
                control: CGPoint(x: origin.x + size.width * 0.22, y: origin.y + 8)
            )
        }
        let style = StrokeStyle(lineWidth: character.tail == .longCurve || character.tail == .curled ? size.width * 0.055 : 0, lineCap: .round)
        if character.tail == .longCurve || character.tail == .curled {
            context.stroke(path, with: .color(character.secondary.color), style: style)
        } else {
            context.fill(path, with: .color(character.secondary.color))
        }
    }

    private func drawLegs(context: inout GraphicsContext, size: CGSize, cx: CGFloat, ground: CGFloat, bodyW: CGFloat, legH: CGFloat) {
        let y = ground - legH
        let positions: [CGFloat] = [-0.28, -0.1, 0.08, 0.24]
        for (index, t) in positions.enumerated() {
            let rect = CGRect(
                x: cx + bodyW * t - size.width * 0.045,
                y: y,
                width: size.width * 0.09,
                height: legH
            )
            context.fill(Path(roundedRect: rect, cornerRadius: 10), with: .color(legColor(index: index)))
        }
    }

    private func drawBody(context: inout GraphicsContext, size: CGSize, cx: CGFloat, ground: CGFloat, bodyW: CGFloat, bodyH: CGFloat, legH: CGFloat) {
        let bodyRect = CGRect(x: cx - bodyW / 2, y: ground - legH - bodyH * 0.72, width: bodyW, height: bodyH)
        context.fill(Path(ellipseIn: bodyRect), with: .color(character.body.color))

        let belly = CGRect(
            x: bodyRect.midX - bodyW * 0.28,
            y: bodyRect.midY - bodyH * 0.1,
            width: bodyW * 0.56,
            height: bodyH * 0.5
        )
        context.fill(Path(ellipseIn: belly), with: .color(character.belly.color.opacity(0.92)))
        applyPattern(context: &context, in: bodyRect, kind: .body)
    }

    private func drawHead(context: inout GraphicsContext, size: CGSize, cx: CGFloat, ground: CGFloat, bodyH: CGFloat, legH: CGFloat, headR: CGFloat) {
        let headCenter = CGPoint(x: cx - size.width * 0.02, y: ground - legH - bodyH * 0.88)
        drawEars(context: &context, size: size, headCenter: headCenter, headR: headR)

        let headRect = CGRect(x: headCenter.x - headR, y: headCenter.y - headR, width: headR * 2, height: headR * 2.05)
        context.fill(Path(ellipseIn: headRect), with: .color(character.body.color))
        applyPattern(context: &context, in: headRect, kind: .head)

        let snoutW = headR * (0.7 + character.snoutLength * 0.5)
        let snoutH = headR * (0.42 + character.snoutLength * 0.15)
        let snout = CGRect(x: headCenter.x - snoutW * 0.2, y: headCenter.y + headR * 0.18, width: snoutW, height: snoutH)
        context.fill(Path(ellipseIn: snout), with: .color(character.belly.color))

        drawFace(context: &context, size: size, headCenter: headCenter, headR: headR)
    }

    private func drawEars(context: inout GraphicsContext, size: CGSize, headCenter: CGPoint, headR: CGFloat) {
        let earOffsets: [(CGFloat, CGFloat)] = [(-0.72, -0.78), (0.62, -0.82)]
        for (i, offset) in earOffsets.enumerated() {
            let origin = CGPoint(x: headCenter.x + headR * offset.0, y: headCenter.y + headR * offset.1)
            var path = Path()
            switch character.ear {
            case .triangle:
                path.move(to: CGPoint(x: origin.x, y: origin.y + headR * 0.55))
                path.addLine(to: CGPoint(x: origin.x + headR * (i == 0 ? -0.45 : 0.45), y: origin.y - headR * 0.15))
                path.addLine(to: CGPoint(x: origin.x + headR * (i == 0 ? 0.38 : -0.38), y: origin.y + headR * 0.2))
                path.closeSubpath()
            case .rounded:
                path.addEllipse(in: CGRect(x: origin.x - headR * 0.28, y: origin.y - headR * 0.1, width: headR * 0.52, height: headR * 0.62))
            case .floppy:
                path.addEllipse(in: CGRect(x: origin.x - headR * 0.18, y: origin.y + headR * 0.05, width: headR * 0.42, height: headR * 0.85))
            }
            context.fill(path, with: .color(earColor(index: i)))
            var inner = path
            inner = inner.applying(CGAffineTransform(translationX: i == 0 ? 6 : -6, y: 8).scaledBy(x: 0.55, y: 0.55))
            context.fill(inner, with: .color(character.innerEar.color.opacity(0.85)))
        }
    }

    private func drawFace(context: inout GraphicsContext, size: CGSize, headCenter: CGPoint, headR: CGFloat) {
        let eyeY = headCenter.y - headR * 0.08
        let eyeW = headR * 0.28
        let eyeH = headR * 0.32
        let left = CGPoint(x: headCenter.x - headR * 0.32, y: eyeY)
        let right = CGPoint(x: headCenter.x + headR * 0.28, y: eyeY)
        for center in [left, right] {
            let white = CGRect(x: center.x - eyeW / 2, y: center.y - eyeH / 2, width: eyeW, height: eyeH)
            context.fill(Path(ellipseIn: white), with: .color(.white))
            let pupil = CGRect(
                x: center.x - eyeW * 0.22 + lookOffset.width,
                y: center.y - eyeH * 0.18 + lookOffset.height,
                width: eyeW * 0.46,
                height: eyeH * 0.55
            )
            context.fill(Path(ellipseIn: pupil), with: .color(character.eye.color))
            context.fill(
                Path(ellipseIn: CGRect(x: pupil.minX + 2, y: pupil.minY + 2, width: 4, height: 5)),
                with: .color(.white.opacity(0.9))
            )
        }

        let nose = CGRect(x: headCenter.x + headR * 0.12, y: headCenter.y + headR * 0.28, width: headR * 0.18, height: headR * 0.14)
        context.fill(Path(ellipseIn: nose), with: .color(character.nose.color))

        var smile = Path()
        smile.addArc(center: CGPoint(x: headCenter.x + headR * 0.18, y: headCenter.y + headR * 0.42), radius: headR * 0.14, startAngle: .degrees(10), endAngle: .degrees(150), clockwise: false)
        context.stroke(smile, with: .color(character.tertiary.color.opacity(0.75)), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        if character.species == .cat {
            for side in [-1.0, 1.0] {
                for i in 0..<3 {
                    var whisker = Path()
                    let y = headCenter.y + headR * (0.32 + CGFloat(i) * 0.08)
                    whisker.move(to: CGPoint(x: headCenter.x + headR * 0.18, y: y))
                    whisker.addLine(to: CGPoint(x: headCenter.x + headR * CGFloat(side) * 0.85, y: y + CGFloat(i - 1) * 4))
                    context.stroke(whisker, with: .color(.white.opacity(0.65)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                }
            }
        }
    }

    private enum PatternTarget { case body, head }

    private func applyPattern(context: inout GraphicsContext, in rect: CGRect, kind: PatternTarget) {
        switch character.pattern {
        case .solid:
            break
        case .stripes:
            for i in 0..<4 {
                let x = rect.minX + rect.width * (0.18 + CGFloat(i) * 0.18)
                let stripe = CGRect(x: x, y: rect.minY + 6, width: 7, height: rect.height * 0.7)
                context.fill(Path(roundedRect: stripe, cornerRadius: 3), with: .color(character.secondary.color.opacity(0.55)))
            }
        case .spots:
            let spots = [(0.25, 0.3), (0.62, 0.22), (0.48, 0.55), (0.3, 0.62), (0.7, 0.48)]
            for spot in spots {
                let r = kind == .head ? 7.0 : 10.0
                let box = CGRect(x: rect.minX + rect.width * spot.0, y: rect.minY + rect.height * spot.1, width: r, height: r)
                context.fill(Path(ellipseIn: box), with: .color(character.secondary.color))
            }
        case .tuxedo:
            if kind == .head {
                let blaze = CGRect(x: rect.midX - 8, y: rect.minY + 10, width: 16, height: rect.height * 0.55)
                context.fill(Path(ellipseIn: blaze), with: .color(character.secondary.color))
            } else {
                context.fill(Path(ellipseIn: CGRect(x: rect.midX - rect.width * 0.18, y: rect.midY, width: rect.width * 0.36, height: rect.height * 0.4)), with: .color(character.secondary.color))
            }
        case .calico:
            let patches = [(0.15, 0.2, character.secondary), (0.6, 0.15, character.tertiary), (0.45, 0.55, character.secondary)]
            for patch in patches {
                let box = CGRect(x: rect.minX + rect.width * patch.0, y: rect.minY + rect.height * patch.1, width: rect.width * 0.28, height: rect.height * 0.28)
                context.fill(Path(ellipseIn: box), with: .color(patch.2.color.opacity(0.9)))
            }
        case .huskyMask:
            if kind == .head {
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + 4, y: rect.minY + 8, width: rect.width * 0.4, height: rect.height * 0.45)), with: .color(character.secondary.color.opacity(0.9)))
                context.fill(Path(ellipseIn: CGRect(x: rect.maxX - rect.width * 0.42, y: rect.minY + 8, width: rect.width * 0.4, height: rect.height * 0.45)), with: .color(character.secondary.color.opacity(0.9)))
            }
        case .siamese:
            if kind == .head {
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + 6, y: rect.minY + 4, width: rect.width - 12, height: rect.height * 0.55)), with: .color(character.secondary.color.opacity(0.85)))
            } else {
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + 8, y: rect.maxY - rect.height * 0.35, width: 22, height: 22)), with: .color(character.secondary.color.opacity(0.8)))
                context.fill(Path(ellipseIn: CGRect(x: rect.maxX - 30, y: rect.maxY - rect.height * 0.35, width: 22, height: 22)), with: .color(character.secondary.color.opacity(0.8)))
            }
        case .saddle:
            if kind == .body {
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + 4, width: rect.width * 0.84, height: rect.height * 0.42)), with: .color(character.body.color))
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.15, y: rect.midY, width: rect.width * 0.7, height: rect.height * 0.5)), with: .color(character.secondary.color))
            } else {
                context.fill(Path(ellipseIn: CGRect(x: rect.midX - 10, y: rect.maxY - rect.height * 0.45, width: 28, height: 24)), with: .color(character.secondary.color))
            }
        }
    }

    private func earColor(index: Int) -> Color {
        if character.pattern == .calico && index == 1 {
            return character.tertiary.color
        }
        if character.pattern == .siamese || character.pattern == .huskyMask {
            return character.secondary.color
        }
        return character.body.color
    }

    private func legColor(index: Int) -> Color {
        if character.pattern == .tuxedo && index >= 2 {
            return character.secondary.color
        }
        if character.pattern == .siamese {
            return character.secondary.color
        }
        if character.pattern == .calico && index.isMultiple(of: 2) {
            return character.tertiary.color
        }
        return character.body.color
    }
}
