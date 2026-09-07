import SwiftUI

enum StickerKind: String, CaseIterable, Identifiable, Hashable {
    case paw
    case heart
    case star
    case moon
    case fish
    case leaf
    case sparkle
    case snowflake
    case bone
    case ball
    case bowl
    case yarn

    var id: String { rawValue }

    var nameKey: String { "sticker.\(rawValue)" }

    var systemImage: String? {
        switch self {
        case .paw: return "pawprint.fill"
        case .heart: return "heart.fill"
        case .star: return "star.fill"
        case .moon: return "moon.fill"
        case .fish: return "fish.fill"
        case .leaf: return "leaf.fill"
        case .sparkle: return "sparkle"
        case .snowflake: return "snowflake"
        case .bone, .ball, .bowl, .yarn: return nil
        }
    }
}

struct CanvasSticker: Identifiable, Equatable, Hashable {
    var id: UUID = UUID()
    var kind: StickerKind
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var tint: RGBAColor

    static func == (lhs: CanvasSticker, rhs: CanvasSticker) -> Bool {
        lhs.id == rhs.id
            && lhs.kind == rhs.kind
            && lhs.position == rhs.position
            && lhs.scale == rhs.scale
            && lhs.rotation == rhs.rotation
            && lhs.tint == rhs.tint
    }
}

struct PawTrailDot: Identifiable, Equatable {
    var id: UUID = UUID()
    var position: CGPoint
    var rotation: Double
    var createdAt: Date
    var isLeft: Bool
}
