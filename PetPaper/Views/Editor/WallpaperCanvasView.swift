import SwiftUI

struct WallpaperCanvasView: View {
    @Bindable var store: EditorStore
    var isInteractive: Bool = true
    var showsSelection: Bool = true

    @State private var lastDrag: CGSize = .zero
    @State private var pinchBase: CGFloat?
    @State private var rotateBase: Double?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let layoutScale = max(size.width / 390, 0.4)
            canvasStack(in: size, layoutScale: layoutScale)
                .contentShape(Rectangle())
                .applyCanvasGestures(
                    isInteractive: isInteractive,
                    followMode: store.state.followMode,
                    drag: dragGesture(in: size),
                    magnify: magnifyGesture,
                    rotate: rotateGesture
                )
        }
        .clipped()
        .onChange(of: store.state.followMode) { _, _ in
            lastDrag = .zero
            pinchBase = nil
            rotateBase = nil
        }
    }

    private var canTransform: Bool {
        isInteractive && !store.state.followMode
    }

    @ViewBuilder
    private func canvasStack(in size: CGSize, layoutScale: CGFloat) -> some View {
        ZStack {
            TemplateSceneView(
                template: store.state.template,
                palette: store.state.palette,
                hueShift: store.state.hueShift
            )

            trailLayer(in: size, layoutScale: layoutScale)

            ForEach(store.state.stickers) { sticker in
                stickerView(sticker, in: size, layoutScale: layoutScale)
            }

            petView(in: size, layoutScale: layoutScale)

            if !store.state.overlayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textView(in: size, layoutScale: layoutScale)
            }
        }
    }

    private func trailLayer(in size: CGSize, layoutScale: CGFloat) -> some View {
        Group {
            if store.pawTrail.isEmpty {
                Color.clear
            } else {
                TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                    let now = timeline.date
                    ZStack {
                        ForEach(store.pawTrail) { dot in
                            let age = now.timeIntervalSince(dot.createdAt)
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 18 * store.state.petScale * layoutScale))
                                .foregroundStyle(store.state.palette.accent.color.opacity(max(0, 0.8 - age / 1.4)))
                                .rotationEffect(.degrees(dot.rotation + (dot.isLeft ? -12 : 12)))
                                .position(
                                    x: dot.position.x * size.width,
                                    y: dot.position.y * size.height
                                )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func petView(in size: CGSize, layoutScale: CGFloat) -> some View {
        let selected = showsSelection && store.selection == .pet && isInteractive && !store.state.followMode
        let usesPhoto = store.state.usesPhotoPet && store.photoPet != nil
        return PetLayerView(
            character: store.pet,
            photoPet: usesPhoto ? store.photoPet : nil,
            lookOffset: store.lookOffset,
            lean: store.lean + store.state.petRotation * 0.15
        )
        .frame(
            width: (usesPhoto ? 210 : 170) * layoutScale,
            height: (usesPhoto ? 230 : 190) * layoutScale
        )
        .scaleEffect(store.state.petScale)
        .rotationEffect(.degrees(store.state.petRotation))
        .padding(10)
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            }
        }
        .position(x: store.state.petPosition.x * size.width, y: store.state.petPosition.y * size.height)
        .allowsHitTesting(canTransform)
        .onTapGesture {
            store.selection = .pet
        }
    }

    private func stickerView(_ sticker: CanvasSticker, in size: CGSize, layoutScale: CGFloat) -> some View {
        let selected = showsSelection && store.selection == .sticker(sticker.id)
        return StickerGlyph(kind: sticker.kind, tint: sticker.tint.color)
            .font(.system(size: 34 * layoutScale))
            .frame(width: 52 * layoutScale, height: 52 * layoutScale)
            .scaleEffect(sticker.scale)
            .rotationEffect(.degrees(sticker.rotation))
            .overlay {
                if selected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                }
            }
            .position(x: sticker.position.x * size.width, y: sticker.position.y * size.height)
            .allowsHitTesting(canTransform)
            .onTapGesture {
                store.selection = .sticker(sticker.id)
            }
    }

    private func textView(in size: CGSize, layoutScale: CGFloat) -> some View {
        let selected = showsSelection && store.selection == .text
        return Text(store.state.overlayText)
            .font(.system(size: 28 * layoutScale, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(store.state.textColor.color)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .padding(.horizontal, 10)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .scaleEffect(store.state.textScale)
            .rotationEffect(.degrees(store.state.textRotation))
            .position(x: store.state.textPosition.x * size.width, y: store.state.textPosition.y * size.height)
            .allowsHitTesting(canTransform)
            .onTapGesture {
                store.selection = .text
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: store.state.followMode ? 0 : 4, coordinateSpace: .local)
            .onChanged { value in
                if store.state.followMode {
                    store.follow(to: value.location, in: size)
                    return
                }
                if lastDrag == .zero {
                    store.pushUndo()
                }
                let delta = CGSize(
                    width: value.translation.width - lastDrag.width,
                    height: value.translation.height - lastDrag.height
                )
                store.moveSelected(by: delta, in: size)
                lastDrag = value.translation
            }
            .onEnded { _ in
                lastDrag = .zero
                if store.state.followMode {
                    store.endFollow()
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if pinchBase == nil {
                    pinchBase = store.currentScale
                    store.pushUndo()
                }
                if let pinchBase {
                    store.setSelectedScale(pinchBase * value)
                }
            }
            .onEnded { _ in
                pinchBase = nil
            }
    }

    private var rotateGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                if rotateBase == nil {
                    rotateBase = store.currentRotation
                    store.pushUndo()
                }
                if let rotateBase {
                    store.setSelectedRotation(rotateBase + angle.degrees)
                }
            }
            .onEnded { _ in
                rotateBase = nil
            }
    }
}

struct ExportableWallpaperView: View {
    let state: EditorState
    let pet: PetCharacter
    var photoPet: PhotoPetCutout? = nil
    var size: CGSize = WallpaperExporter.canvasSize

    var body: some View {
        let layoutScale = max(size.width / 390, 0.4)
        let usesPhoto = state.usesPhotoPet && photoPet != nil
        ZStack {
            TemplateSceneView(template: state.template, palette: state.palette, hueShift: state.hueShift)
                .frame(width: size.width, height: size.height)

            ForEach(state.stickers) { sticker in
                StickerGlyph(kind: sticker.kind, tint: sticker.tint.color)
                    .font(.system(size: 34 * layoutScale))
                    .frame(width: 52 * layoutScale, height: 52 * layoutScale)
                    .scaleEffect(sticker.scale)
                    .rotationEffect(.degrees(sticker.rotation))
                    .position(x: sticker.position.x * size.width, y: sticker.position.y * size.height)
            }

            PetLayerView(character: pet, photoPet: usesPhoto ? photoPet : nil)
                .frame(
                    width: (usesPhoto ? 210 : 170) * layoutScale,
                    height: (usesPhoto ? 230 : 190) * layoutScale
                )
                .scaleEffect(state.petScale)
                .rotationEffect(.degrees(state.petRotation))
                .position(x: state.petPosition.x * size.width, y: state.petPosition.y * size.height)

            if !state.overlayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(state.overlayText)
                    .font(.system(size: 28 * layoutScale, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(state.textColor.color)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .scaleEffect(state.textScale)
                    .rotationEffect(.degrees(state.textRotation))
                    .position(x: state.textPosition.x * size.width, y: state.textPosition.y * size.height)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

private extension View {
    @ViewBuilder
    func applyCanvasGestures<Drag: Gesture, Magnify: Gesture, Rotate: Gesture>(
        isInteractive: Bool,
        followMode: Bool,
        drag: Drag,
        magnify: Magnify,
        rotate: Rotate
    ) -> some View {
        if !isInteractive {
            self
        } else if followMode {
            self.highPriorityGesture(drag)
        } else {
            self
                .gesture(drag)
                .simultaneousGesture(magnify)
                .simultaneousGesture(rotate)
        }
    }
}
