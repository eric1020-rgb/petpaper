import SwiftUI

struct EditorState: Equatable {
    var template: TemplateKind
    var palette: ColorPalette
    var hueShift: Double
    var petID: String
    var petPosition: CGPoint
    var petScale: CGFloat
    var petRotation: Double
    var stickers: [CanvasSticker]
    var overlayText: String
    var textPosition: CGPoint
    var textScale: CGFloat
    var textRotation: Double
    var textColor: RGBAColor
    var followMode: Bool
    var pawTrailEnabled: Bool
    var usesPhotoPet: Bool

    static func fresh(template: TemplateKind, petID: String = PetCharacter.catalog[0].id, usesPhotoPet: Bool = false) -> EditorState {
        EditorState(
            template: template,
            palette: template.defaultPalette,
            hueShift: 0,
            petID: petID,
            petPosition: CGPoint(x: 0.5, y: 0.62),
            petScale: 1.0,
            petRotation: 0,
            stickers: [],
            overlayText: "",
            textPosition: CGPoint(x: 0.5, y: 0.18),
            textScale: 1.0,
            textRotation: 0,
            textColor: template.isDark ? .hex(0xFFFFFF) : .hex(0x3A2A32),
            followMode: false,
            pawTrailEnabled: false,
            usesPhotoPet: usesPhotoPet
        )
    }
}

enum CanvasSelection: Equatable {
    case none
    case pet
    case text
    case sticker(UUID)
}
