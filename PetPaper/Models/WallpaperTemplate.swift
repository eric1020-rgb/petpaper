import SwiftUI

enum TemplateKind: String, CaseIterable, Identifiable, Hashable {
    case pastel
    case nightSky
    case park
    case cozyRoom
    case neon
    case sakura
    case beach
    case snow

    var id: String { rawValue }

    var nameKey: String { "template.\(rawValue).name" }
    var captionKey: String { "template.\(rawValue).caption" }

    var defaultPalette: ColorPalette {
        switch self {
        case .pastel:
            return ColorPalette(
                top: .hex(0xFFD6E8),
                bottom: .hex(0xD9C7FF),
                accent: .hex(0xFF8FAB),
                secondary: .hex(0xBDE0FE),
                highlight: .hex(0xFFF6F0)
            )
        case .nightSky:
            return ColorPalette(
                top: .hex(0x0B1026),
                bottom: .hex(0x2A1B4A),
                accent: .hex(0xF4E1A1),
                secondary: .hex(0x7AA2FF),
                highlight: .hex(0xE8DDFF)
            )
        case .park:
            return ColorPalette(
                top: .hex(0x9ED8FF),
                bottom: .hex(0x7BC47F),
                accent: .hex(0xFFD166),
                secondary: .hex(0x4C9A56),
                highlight: .hex(0xFFF7D6)
            )
        case .cozyRoom:
            return ColorPalette(
                top: .hex(0xF4D7B8),
                bottom: .hex(0xC9895A),
                accent: .hex(0xE07A5F),
                secondary: .hex(0x81B29A),
                highlight: .hex(0xFFF1E0)
            )
        case .neon:
            return ColorPalette(
                top: .hex(0x12061F),
                bottom: .hex(0x2A0A3C),
                accent: .hex(0xFF2BD6),
                secondary: .hex(0x2DE2E6),
                highlight: .hex(0xF9F871)
            )
        case .sakura:
            return ColorPalette(
                top: .hex(0xFFD3E0),
                bottom: .hex(0xF7B5C8),
                accent: .hex(0xE85D75),
                secondary: .hex(0x8FBF9F),
                highlight: .hex(0xFFF5F8)
            )
        case .beach:
            return ColorPalette(
                top: .hex(0x7EC8E3),
                bottom: .hex(0xF2D2A9),
                accent: .hex(0xFF9F1C),
                secondary: .hex(0x2EC4B6),
                highlight: .hex(0xFFF8E7)
            )
        case .snow:
            return ColorPalette(
                top: .hex(0xD7E8F7),
                bottom: .hex(0x8FB3D1),
                accent: .hex(0x5C80A8),
                secondary: .hex(0xE9F2FB),
                highlight: .hex(0xFFFFFF)
            )
        }
    }

    var isDark: Bool {
        self == .nightSky || self == .neon
    }
}
