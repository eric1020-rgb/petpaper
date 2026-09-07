import SwiftUI
import UIKit

struct EditorView: View {
    @State private var store: EditorStore
    @State private var activeSheet: EditorSheet?
    @State private var isExporting = false
    @State private var exportMessage: ExportMessage?
    @State private var hueDraft: Double = 0

    init(template: TemplateKind, petID: String?, photoPet: PhotoPetCutout? = nil) {
        _store = State(initialValue: EditorStore(template: template, petID: petID, photoPet: photoPet))
        _hueDraft = State(initialValue: 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasCard
            hintRow
            EditorToolTray(
                followMode: $store.state.followMode,
                pawTrailEnabled: $store.state.pawTrailEnabled,
                canUndo: store.canUndo,
                canDelete: canDeleteSelection,
                onUndo: store.undo,
                onReset: store.reset,
                onDelete: store.removeSelected,
                onOpen: { activeSheet = $0 }
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
            }
        }
        .onAppear { hueDraft = store.state.hueShift }
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
    }

    private var hintRow: some View {
        Text(store.state.followMode ? "editor.followHint" : "editor.placeHint")
            .font(.footnote.weight(.medium))
            .foregroundStyle(AppTheme.muted)
            .multilineTextAlignment(.center)
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
            } onPickPhoto: {
                store.restorePhotoPet()
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
                onAccent: store.applyAccent,
                onReset: {
                    store.restoreDefaultPalette()
                    hueDraft = 0
                }
            )
            .onChange(of: hueDraft) { _, value in
                store.applyHue(value)
            }
        case .text:
            TextEditorSheet(text: $store.state.overlayText) {
                store.selection = store.state.overlayText.isEmpty ? .pet : .text
                activeSheet = nil
            }
        }
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
    case template, pet, sticker, color, text
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

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                toggleChip(
                    title: String(localized: "editor.follow"),
                    systemImage: "hand.draw.fill",
                    isOn: $followMode
                )
                toggleChip(
                    title: String(localized: "editor.trail"),
                    systemImage: "pawprint.fill",
                    isOn: $pawTrailEnabled
                )
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    trayButton("editor.tool.template", "rectangle.portrait.fill", .template)
                    trayButton("editor.tool.pet", "pawprint.circle.fill", .pet)
                    trayButton("editor.tool.sticker", "face.smiling.fill", .sticker)
                    trayButton("editor.tool.color", "paintpalette.fill", .color)
                    trayButton("editor.tool.text", "textformat", .text)
                    actionButton("editor.undo", "arrow.uturn.backward", enabled: canUndo, action: onUndo)
                    actionButton("editor.reset", "arrow.counterclockwise", enabled: true, action: onReset)
                    actionButton("editor.delete", "trash", enabled: canDelete, action: onDelete)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private func toggleChip(title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isOn.wrappedValue ? AppTheme.coral : Color.white)
                .foregroundStyle(isOn.wrappedValue ? Color.white : AppTheme.ink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func trayButton(_ key: String, _ systemImage: String, _ sheet: EditorSheet) -> some View {
        Button {
            onOpen(sheet)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(LocalizedStringKey(key))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(AppTheme.ink)
            .frame(width: 72, height: 64)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ key: String, _ systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(LocalizedStringKey(key))
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(enabled ? AppTheme.ink : AppTheme.muted.opacity(0.5))
            .frame(width: 72, height: 64)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
            .navigationTitle(Text("editor.tool.sticker"))
        }
    }
}

struct ColorEditorSheet: View {
    @Binding var hue: Double
    var accent: RGBAColor
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
                Slider(value: $hue, in: 0...1)
                    .tint(AppTheme.coral)

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
    @Binding var text: String
    var onDone: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField(String(localized: "editor.text.placeholder"), text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onChange(of: text) { _, value in
                        if value.count > 24 {
                            text = String(value.prefix(24))
                        }
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
            .onAppear { focused = true }
        }
    }
}

#Preview {
    NavigationStack {
        EditorView(template: .pastel, petID: "cat-tabby")
    }
    .environment(AppSession())
}
