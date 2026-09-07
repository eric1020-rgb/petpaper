import SwiftUI

struct RGBAColor: Equatable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double = 1

    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    static func hex(_ hex: UInt32, alpha: Double = 1) -> RGBAColor {
        RGBAColor(
            r: Double((hex >> 16) & 0xFF) / 255,
            g: Double((hex >> 8) & 0xFF) / 255,
            b: Double(hex & 0xFF) / 255,
            a: alpha
        )
    }
}

struct ColorPalette: Equatable, Hashable {
    var top: RGBAColor
    var bottom: RGBAColor
    var accent: RGBAColor
    var secondary: RGBAColor
    var highlight: RGBAColor

    var gradient: LinearGradient {
        LinearGradient(
            colors: [top.color, bottom.color],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
