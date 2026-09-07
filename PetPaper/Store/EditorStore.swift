import SwiftUI
import Observation
import UIKit

@MainActor
@Observable
final class EditorStore {
    var state: EditorState
    var selection: CanvasSelection = .pet
    var pawTrail: [PawTrailDot] = []
    var lookOffset: CGSize = .zero
    var lean: Double = 0
    var isFollowingTouch = false
    var lastFollowPoint: CGPoint?
    var photoPet: PhotoPetCutout?

    private var undoStack: [EditorState] = []
    private let maxUndo = 40
    private var isEditingHue = false
    private var isEditingText = false

    var pet: PetCharacter {
        PetCharacter.character(id: state.petID)
    }

    var canUndo: Bool { !undoStack.isEmpty }

    init(template: TemplateKind, petID: String? = nil, photoPet: PhotoPetCutout? = nil) {
        state = .fresh(
            template: template,
            petID: petID ?? PetCharacter.catalog[0].id,
            usesPhotoPet: photoPet != nil
        )
        self.photoPet = photoPet
    }

    func load(template: TemplateKind, petID: String?) {
        pushUndo()
        let keepPet = petID ?? state.petID
        state = .fresh(template: template, petID: keepPet)
        selection = .pet
        pawTrail.removeAll()
        lookOffset = .zero
        lean = 0
    }

    func pushUndo() {
        undoStack.append(state)
        if undoStack.count > maxUndo {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        state = previous
        selection = .pet
    }

    func reset() {
        pushUndo()
        state = .fresh(template: state.template, petID: state.petID, usesPhotoPet: state.usesPhotoPet && photoPet != nil)
        selection = .pet
        pawTrail.removeAll()
        lookOffset = .zero
        lean = 0
    }

    func selectPet(_ character: PetCharacter) {
        pushUndo()
        state.petID = character.id
        state.usesPhotoPet = false
        selection = .pet
    }

    func restorePhotoPet() {
        guard photoPet != nil else { return }
        pushUndo()
        state.usesPhotoPet = true
        selection = .pet
    }

    func setTemplate(_ template: TemplateKind) {
        guard template != state.template else { return }
        pushUndo()
        let previousPet = state.petID
        let previousText = state.overlayText
        let previousStickers = state.stickers
        let keepPhoto = state.usesPhotoPet
        state = .fresh(template: template, petID: previousPet, usesPhotoPet: keepPhoto)
        state.overlayText = previousText
        state.stickers = previousStickers
        if template.isDark {
            state.textColor = .hex(0xFFFFFF)
        }
    }

    func addSticker(_ kind: StickerKind) {
        pushUndo()
        let sticker = CanvasSticker(
            kind: kind,
            position: CGPoint(x: 0.5, y: 0.42),
            scale: 1.0,
            rotation: Double.random(in: -12...12),
            tint: state.palette.accent
        )
        state.stickers.append(sticker)
        selection = .sticker(sticker.id)
    }

    func removeSelected() {
        switch selection {
        case .sticker(let id):
            pushUndo()
            state.stickers.removeAll { $0.id == id }
            selection = .pet
        case .text:
            pushUndo()
            state.overlayText = ""
            selection = .pet
        default:
            break
        }
    }

    /// Call when the hue slider starts moving so one undo covers the whole gesture.
    func beginHueEdit() {
        guard !isEditingHue else { return }
        pushUndo()
        isEditingHue = true
    }

    func endHueEdit() {
        isEditingHue = false
    }

    func applyHue(_ value: Double) {
        state.hueShift = value
    }

    /// Call once before the first overlay-text mutation in a sheet session.
    func beginTextEdit() {
        guard !isEditingText else { return }
        pushUndo()
        isEditingText = true
    }

    func endTextEdit() {
        isEditingText = false
    }

    func setOverlayText(_ text: String) {
        state.overlayText = String(text.prefix(24))
    }

    func applyAccent(_ color: RGBAColor) {
        pushUndo()
        state.palette.accent = color
        state.textColor = color
    }

    func restoreDefaultPalette() {
        pushUndo()
        state.palette = state.template.defaultPalette
        state.hueShift = 0
        state.textColor = state.template.isDark ? .hex(0xFFFFFF) : .hex(0x3A2A32)
    }

    func moveSelected(by delta: CGSize, in canvas: CGSize) {
        guard canvas.width > 0, canvas.height > 0 else { return }
        let dx = delta.width / canvas.width
        let dy = delta.height / canvas.height
        switch selection {
        case .pet:
            state.petPosition = clamp(CGPoint(x: state.petPosition.x + dx, y: state.petPosition.y + dy))
        case .text:
            state.textPosition = clamp(CGPoint(x: state.textPosition.x + dx, y: state.textPosition.y + dy))
        case .sticker(let id):
            if let index = state.stickers.firstIndex(where: { $0.id == id }) {
                let current = state.stickers[index].position
                state.stickers[index].position = clamp(CGPoint(x: current.x + dx, y: current.y + dy))
            }
        case .none:
            break
        }
    }

    func scaleSelected(by factor: CGFloat) {
        setSelectedScale(currentScale * factor)
    }

    var currentScale: CGFloat {
        switch selection {
        case .pet: return state.petScale
        case .text: return state.textScale
        case .sticker(let id):
            return state.stickers.first(where: { $0.id == id })?.scale ?? 1
        case .none: return 1
        }
    }

    var currentRotation: Double {
        switch selection {
        case .pet: return state.petRotation
        case .text: return state.textRotation
        case .sticker(let id):
            return state.stickers.first(where: { $0.id == id })?.rotation ?? 0
        case .none: return 0
        }
    }

    func setSelectedScale(_ scale: CGFloat) {
        let clamped: CGFloat
        switch selection {
        case .pet:
            clamped = min(max(scale, 0.35), 2.6)
            state.petScale = clamped
        case .text:
            clamped = min(max(scale, 0.5), 2.4)
            state.textScale = clamped
        case .sticker(let id):
            clamped = min(max(scale, 0.4), 2.8)
            if let index = state.stickers.firstIndex(where: { $0.id == id }) {
                state.stickers[index].scale = clamped
            }
        case .none:
            break
        }
    }

    func setSelectedRotation(_ rotation: Double) {
        switch selection {
        case .pet:
            state.petRotation = rotation
        case .text:
            state.textRotation = rotation
        case .sticker(let id):
            if let index = state.stickers.firstIndex(where: { $0.id == id }) {
                state.stickers[index].rotation = rotation
            }
        case .none:
            break
        }
    }

    func rotateSelected(by degrees: Double) {
        setSelectedRotation(currentRotation + degrees)
    }

    func follow(to point: CGPoint, in canvas: CGSize) {
        guard canvas.width > 0, canvas.height > 0 else { return }
        if !isFollowingTouch {
            pushUndo()
            isFollowingTouch = true
        }
        let normalized = clamp(CGPoint(x: point.x / canvas.width, y: point.y / canvas.height))
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if let last = lastFollowPoint {
            dx = point.x - last.x
            dy = point.y - last.y
        }
        lastFollowPoint = point

        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.72, blendDuration: 0.12)) {
            state.petPosition = normalized
            lean = min(max(Double(dx / 8), -18), 18)
            lookOffset = CGSize(
                width: min(max(dx / 40, -6), 6),
                height: min(max(dy / 40, -4), 4)
            )
        }

        if state.pawTrailEnabled {
            appendPawIfNeeded(at: normalized, heading: atan2(dy, dx))
        }
    }

    func endFollow() {
        isFollowingTouch = false
        lastFollowPoint = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            lean = 0
            lookOffset = .zero
        }
        pruneTrail()
    }

    func pruneTrail(now: Date = Date()) {
        pawTrail.removeAll { now.timeIntervalSince($0.createdAt) > 1.35 }
    }

    private func appendPawIfNeeded(at point: CGPoint, heading: CGFloat) {
        if let last = pawTrail.last {
            let dx = point.x - last.position.x
            let dy = point.y - last.position.y
            let distance = sqrt(dx * dx + dy * dy)
            guard distance > 0.045 else { return }
        }
        let isLeft = (pawTrail.count % 2 == 0)
        let offset = CGPoint(
            x: point.x + (isLeft ? -0.018 : 0.018),
            y: point.y + 0.012
        )
        pawTrail.append(
            PawTrailDot(
                position: offset,
                rotation: Double(heading) * 180 / .pi + 90,
                createdAt: Date(),
                isLeft: isLeft
            )
        )
        if pawTrail.count > 28 {
            pawTrail.removeFirst(pawTrail.count - 28)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.45)
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0.08), 0.92),
            y: min(max(point.y, 0.1), 0.9)
        )
    }
}
