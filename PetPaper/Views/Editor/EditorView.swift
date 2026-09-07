import SwiftUI
import UIKit

struct EditorView: View {
    @Environment(AppSession.self) private var session
    @State private var store: EditorStore
    @State private var activeSheet: EditorSheet?
    @State private var isExporting = false
    @State private var exportMessage: ExportMessage?
    @State private var hueDraft: Double = 0
    @Environment(\.scenePhase) private var scenePhase

    init(template: TemplateKind, petID: String?, photoPet: PhotoPetCutout? = nil) {
        _store = State(initialValue: EditorStore(template: template, petID: petID, photoPet: photoPet))
        _hueDraft = State(initialValue: 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    if session.idleToastEnabled, let key = store.idle.toastKey {
                        IdleToastBanner(key: key)
                            .padding(.top, 16)
                    }
                }
            hintRow
            EditorToolTray(
                followMode: $store.state.followMode,
                pawTrailEnabled: $store.state.pawTrailEnabled,
                canUndo: store.canUndo,
                canDelete: canDeleteSelection,
                onUndo: store.undo,
                onReset: store.reset,
                onDelete: store.removeSelected,
                onOpen: { activeSheet = $0 },
                onPreviewIdle: {
                    store.idle.showToast = session.idleToastEnabled
                    store.previewIdleAction()
                }
            )
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("editor.title"))
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await exportWallpaper() }
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Label(String(localized: "editor.save"), systemImage: "square.and.arrow.down")
                    }
                }
                .disabled(isExporting)
                .accessibilityLabel(Text("editor.save"))
                .accessibilityHint(Text("a11y.save.hint"))
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
                .presentationDetents(sheet == .text ? [.medium] : [.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(item: $exportMessage) { message in
            if message.showsOpenSettings {
                Alert(
                    title: Text(message.title),
                    message: Text(message.body),
                    primaryButton: .default(Text("export.openSettings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel(Text("common.ok"))
                )
            } else {
                Alert(
                    title: Text(message.title),
                    message: Text(message.body),
                    dismissButton: .default(Text("common.ok"))
                )
            }
        }
        .onChange(of: store.state.followMode) { _, enabled in
            if enabled {
                store.selection = .pet
                store.pawTrail.removeAll()
                store.idle.cancel()
            } else {
                store.state.pawTrailEnabled = false
                store.pawTrail.removeAll()
                store.endFollow()
            }
        }
        .onChange(of: store.state.template) { _, template in
            rememberDraft(template: template)
        }
        .onChange(of: store.state.petID) { _, petID in
            rememberDraft(petID: petID)
        }
        .onAppear {
            hueDraft = store.state.hueShift
            rememberDraft()
            store.idle.showToast = session.idleToastEnabled
        }
        .onChange(of: session.idleToastEnabled) { _, enabled in
            store.idle.showToast = enabled
        }
        .task(id: editorIdleTaskID) {
            guard session.idleEnabled, scenePhase == .active else { return }
            store.idle.showToast = session.idleToastEnabled
            await store.idle.runScheduledLoop(
                interval: session.idleInterval.seconds,
                cooldown: session.idleInterval.cooldown,
                photoCutout: { store.usesPhotoPetNow },
                shouldPause: { store.state.followMode || store.isFollowingTouch }
            )
        }
        .onDisappear {
            store.idle.cancel()
        }
    }

    private var editorIdleTaskID: String {
        "\(session.idleEnabled)-\(session.idleInterval.rawValue)-\(scenePhase)"
    }

    private var canvasCard: some View {
        WallpaperCanvasView(store: store)
            .aspectRatio(9 / 19.5, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.65), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxHeight: .infinity)
    }

    private var hintRow: some View {
        Text(store.state.followMode ? "editor.followHint" : "editor.placeHint")
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.muted)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }

    private var canDeleteSelection: Bool {
        switch store.selection {
        case .sticker, .text:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: EditorSheet) -> some View {
        switch sheet {
        case .template:
            TemplatePickerSheet(current: store.state.template) { template in
                store.setTemplate(template)
                hueDraft = 0
                activeSheet = nil
            }
        case .pet:
            PetPickerSheet(
                currentID: store.state.petID,
                photoPet: store.photoPet,
                usesPhotoPet: store.state.usesPhotoPet
            ) { pet in
                store.selectPet(pet)
                activeSheet = nil
            } onPickPhoto: {
                store.restorePhotoPet()
                activeSheet = nil
            }
        case .sticker:
            StickerPickerSheet { kind in
                store.addSticker(kind)
                activeSheet = nil
            }
        case .color:
            ColorEditorSheet(
                hue: $hueDraft,
                accent: store.state.palette.accent,
                onHueEditingBegan: store.beginHueEdit,
                onHueEditingEnded: store.endHueEdit,
                onHueChange: store.applyHue,
                onAccent: store.applyAccent,
                onReset: {
                    store.restoreDefaultPalette()
                    hueDraft = 0
                }
            )
            .onDisappear {
                store.endHueEdit()
            }
        case .idle:
            IdleSettingsSheet(
                onPreview: {
                    store.idle.showToast = session.idleToastEnabled
                    store.previewIdleAction()
                },
                onClose: { activeSheet = nil }
            )
        case .text:
            TextEditorSheet(
                initialText: store.state.overlayText,
                onBeginEdit: store.beginTextEdit,
                onTextChange: store.setOverlayText
            ) {
                store.endTextEdit()
                store.selection = store.state.overlayText.isEmpty ? .pet : .text
                activeSheet = nil
            }
            .onDisappear {
                store.endTextEdit()
            }
        }
    }

    private func rememberDraft(template: TemplateKind? = nil, petID: String? = nil) {
        session.remember(
            template: template ?? store.state.template,
            petID: store.state.usesPhotoPet ? nil : (petID ?? store.state.petID)
        )
    }

    @MainActor
    private func exportWallpaper() async {
        isExporting = true
        defer { isExporting = false }
        guard let image = WallpaperExporter.render(state: store.state, pet: store.pet, photoPet: store.photoPet) else {
            exportMessage = ExportMessage(title: String(localized: "export.error.title"), body: String(localized: "export.error.render"))
            return
        }
        do {
            try await WallpaperExporter.saveToPhotos(image)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            exportMessage = ExportMessage(title: String(localized: "export.success.title"), body: String(localized: "export.success.message"))
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            let denied = (error as? WallpaperExportError) == .permissionDenied
            exportMessage = ExportMessage(
                title: String(localized: "export.error.title"),
                body: error.localizedDescription,
                showsOpenSettings: denied
            )
        }
    }
}

enum EditorSheet: String, Identifiable {
    case template, pet, sticker, color, text, idle
    var id: String { rawValue }
}

struct ExportMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    var showsOpenSettings = false
}

struct EditorToolTray: View {
    @Binding var followMode: Bool
    @Binding var pawTrailEnabled: Bool
    var canUndo: Bool
    var canDelete: Bool
    var onUndo: () -> Void
    var onReset: () -> Void
    var onDelete: () -> Void
    var onOpen: (EditorSheet) -> Void
    var onPreviewIdle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    followChip
                    trailChip
                }
                VStack(spacing: 8) {
                    followChip
                    trailChip
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    trayButton("editor.tool.template", "rectangle.portrait.fill", .template)
                    trayButton("editor.tool.pet", "pawprint.circle.fill", .pet)
                    trayButton("editor.tool.sticker", "face.smiling.fill", .sticker)
                    trayButton("editor.tool.color", "paintpalette.fill", .color)
                    trayButton("editor.tool.text", "textformat", .text)
                    trayButton("editor.tool.idle", "moon.zzz.fill", .idle)
                    actionButton("idle.preview", "play.circle.fill", enabled: true, action: onPreviewIdle)
                    actionButton("editor.undo", "arrow.uturn.backward", enabled: canUndo, action: onUndo)
                    actionButton("editor.reset", "arrow.counterclockwise", enabled: true, action: onReset)
                    actionButton("editor.delete", "trash", enabled: canDelete, action: onDelete)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var followChip: some View {
        toggleChip(
            title: String(localized: "editor.follow"),
            systemImage: "hand.draw.fill",
            isOn: $followMode,
            enabled: true,
            hintKey: "a11y.follow.hint"
        )
    }

    private var trailChip: some View {
        toggleChip(
            title: String(localized: "editor.trail"),
            systemImage: "pawprint.fill",
            isOn: $pawTrailEnabled,
            enabled: followMode,
            hintKey: followMode ? "a11y.trail.hint" : "a11y.trail.disabled"
        )
    }

    private func toggleChip(title: String, systemImage: String, isOn: Binding<Bool>, enabled: Bool, hintKey: String) -> some View {
        Button {
            guard enabled else { return }
            isOn.wrappedValue.toggle()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(isOn.wrappedValue && enabled ? AppTheme.coral : Color.white)
                .foregroundStyle(isOn.wrappedValue && enabled ? Color.white : AppTheme.ink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(isOn.wrappedValue && enabled ? "a11y.on" : "a11y.off"))
        .accessibilityHint(Text(LocalizedStringKey(hintKey)))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isOn.wrappedValue && enabled ? .isSelected : [])
    }

    private func trayButton(_ key: String, _ systemImage: String, _ sheet: EditorSheet) -> some View {
        Button {
            onOpen(sheet)
        } label: {
            trayLabel(key, systemImage, enabled: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(LocalizedStringKey(key)))
    }

    private func actionButton(_ key: String, _ systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            trayLabel(key, systemImage, enabled: enabled)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Text(LocalizedStringKey(key)))
    }

    private func trayLabel(_ key: String, _ systemImage: String, enabled: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(LocalizedStringKey(key))
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(enabled ? AppTheme.ink : AppTheme.muted.opacity(0.5))
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(minWidth: 64, minHeight: 64)
        .fixedSize(horizontal: true, vertical: true)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct TemplatePickerSheet: View {
    var current: TemplateKind
    var onPick: (TemplateKind) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(TemplateKind.allCases) { template in
                        Button {
                            onPick(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                TemplateSceneView(template: template, palette: template.defaultPalette)
                                    .aspectRatio(9 / 19.5, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                Text(LocalizedStringKey(template.nameKey))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            .padding(8)
                            .background(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(template == current ? AppTheme.coral : Color.clear, lineWidth: 3)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(LocalizedStringKey(template.nameKey)))
                        .accessibilityHint(Text("a11y.template.hint"))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAddTraits(template == current ? .isSelected : [])
                    }
                }
                .padding(16)
            }
            .background(AppTheme.cream)
            .navigationTitle(Text("editor.tool.template"))
        }
    }
}

struct PetPickerSheet: View {
    var currentID: String
    var photoPet: PhotoPetCutout?
    var usesPhotoPet: Bool
    var onPick: (PetCharacter) -> Void
    var onPickPhoto: () -> Void
    @State private var species: PetSpecies = .cat

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker(String(localized: "editor.tool.pet"), selection: $species) {
                    ForEach(PetSpecies.allCases) { item in
                        Text(LocalizedStringKey(item.titleKey)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        if let photoPet {
                            Button(action: onPickPhoto) {
                                VStack(spacing: 8) {
                                    PhotoPetView(cutout: photoPet)
                                        .frame(height: 140)
                                    Text("editor.photoPet")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(usesPhotoPet ? AppTheme.coral : Color.clear, lineWidth: 3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(PetCharacter.catalog.filter { $0.species == species }) { pet in
                            Button {
                                onPick(pet)
                            } label: {
                                VStack(spacing: 8) {
                                    PetIllustration(character: pet)
                                        .frame(height: 140)
                                    Text(LocalizedStringKey(pet.nameKey))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(!usesPhotoPet && pet.id == currentID ? AppTheme.coral : Color.clear, lineWidth: 3)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .background(AppTheme.cream)
            .navigationTitle(Text("editor.tool.pet"))
            .onAppear {
                species = PetCharacter.character(id: currentID).species
            }
        }
    }
}

struct StickerPickerSheet: View {
    var onPick: (StickerKind) -> Void

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(StickerKind.allCases) { kind in
                    Button {
                        onPick(kind)
                    } label: {
                        VStack(spacing: 8) {
                            StickerGlyph(kind: kind, tint: AppTheme.coral)
                                .font(.system(size: 28))
                                .frame(width: 54, height: 54)
                                .background(Circle().fill(Color.white))
                            Text(LocalizedStringKey(kind.nameKey))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(AppTheme.cream)
            .navigationTitle(Text("editor.tool.sticker"))
        }
    }
}

struct ColorEditorSheet: View {
    @Binding var hue: Double
    var accent: RGBAColor
    var onHueEditingBegan: () -> Void
    var onHueEditingEnded: () -> Void
    var onHueChange: (Double) -> Void
    var onAccent: (RGBAColor) -> Void
    var onReset: () -> Void

    private let swatches: [RGBAColor] = [
        .hex(0xFF8FAB), .hex(0xFF6B4A), .hex(0xFFD166), .hex(0x7BC47F),
        .hex(0x5B9DFF), .hex(0x9B7BFF), .hex(0x2DE2E6), .hex(0xFFFFFF),
        .hex(0x2B2B2B)
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("editor.hue")
                    .font(.headline)
                Slider(value: $hue, in: 0...1) { editing in
                    if editing {
                        onHueEditingBegan()
                    } else {
                        onHueEditingEnded()
                    }
                }
                .tint(AppTheme.coral)
                .accessibilityLabel(Text("editor.hue"))
                .onChange(of: hue) { _, value in
                    onHueChange(value)
                }

                Text("editor.accent")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(swatches, id: \.self) { color in
                        Button {
                            onAccent(color)
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                                }
                                .overlay {
                                    if color == accent {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(color.r + color.g + color.b > 2 ? AppTheme.ink : Color.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button(String(localized: "editor.palette.reset"), action: onReset)
                    .buttonStyle(.bordered)
                    .tint(AppTheme.coral)
                Spacer()
            }
            .padding(20)
            .navigationTitle(Text("editor.tool.color"))
        }
    }
}

struct TextEditorSheet: View {
    var initialText: String
    var onBeginEdit: () -> Void
    var onTextChange: (String) -> Void
    var onDone: () -> Void
    @State private var draft = ""
    @State private var didBeginEdit = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField(String(localized: "editor.text.placeholder"), text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onChange(of: draft) { _, value in
                        let clipped = String(value.prefix(24))
                        if clipped != value {
                            draft = clipped
                            return
                        }
                        if !didBeginEdit && clipped != initialText {
                            onBeginEdit()
                            didBeginEdit = true
                        }
                        onTextChange(clipped)
                    }
                Text("editor.text.limit")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                Spacer()
            }
            .padding(20)
            .navigationTitle(Text("editor.tool.text"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "editor.text.done"), action: onDone)
                }
            }
            .onAppear {
                draft = initialText
                didBeginEdit = false
                focused = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditorView(template: .pastel, petID: "cat-tabby")
    }
    .environment(AppSession())
}
