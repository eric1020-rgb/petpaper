import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreTransferable

struct HomeView: View {
    @Environment(AppSession.self) private var session
    @State private var pickedItem: PhotosPickerItem?
    @State private var lastPickedItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var loadFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                uploadCard
                Text("home.upload.emptyTip")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                if lastPickedItem != nil, !isLoadingPhoto {
                    retryRow
                }
                tutorialCard
                Text("home.section.templates")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 20)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(TemplateKind.allCases) { template in
                        Button {
                            session.openEditor(template: template)
                        } label: {
                            TemplateCard(template: template, isLastUsed: session.hasRememberedEditor && template == session.lastTemplate)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(Text(LocalizedStringKey(template.nameKey)))
                        .accessibilityHint(Text(LocalizedStringKey(template.captionKey)))
                        .accessibilityValue(session.hasRememberedEditor && template == session.lastTemplate ? Text("home.lastUsed") : Text(""))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task { await loadPickedPhoto(item) }
        }
        .alert(String(localized: "import.loadFailed.title"), isPresented: $loadFailed) {
            Button(String(localized: "import.retry")) {
                retryLastPick()
            }
            Button(String(localized: "common.ok"), role: .cancel) {}
        } message: {
            Text("import.loadFailed.detail")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("home.title")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.ink)
            Text("home.subtitle")
                .font(.body)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var uploadCard: some View {
        PhotosPicker(selection: $pickedItem, matching: .images) {
            HStack(spacing: 14) {
                ZStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundStyle(.white)
                    if isLoadingPhoto {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(width: 48, height: 48)
                .background(AppTheme.sky)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.upload.title")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("home.upload.caption")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .disabled(isLoadingPhoto)
        .accessibilityLabel(Text("home.upload.title"))
        .accessibilityHint(Text("a11y.upload.hint"))
        .accessibilityValue(Text(isLoadingPhoto ? "import.processing" : "home.upload.caption"))
    }

    private var retryRow: some View {
        Button {
            retryLastPick()
        } label: {
            Label(String(localized: "import.retry"), systemImage: "arrow.clockwise")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.coral)
        .padding(.horizontal, 20)
        .accessibilityLabel(Text("import.retry"))
        .accessibilityHint(Text("import.loadFailed.detail"))
    }

    private var tutorialCard: some View {
        Button {
            session.replayTutorial()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("home.tutorial")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("home.tutorial.caption")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private func retryLastPick() {
        guard let item = lastPickedItem else { return }
        Task { await loadPickedPhoto(item) }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        lastPickedItem = item
        defer { isLoadingPhoto = false }
        if let image = await PhotoPickerLoader.uiImage(from: item) {
            pickedItem = nil
            lastPickedItem = nil
            session.beginPhotoImport(image)
            return
        }
        pickedItem = nil
        loadFailed = true
    }
}

enum PhotoPickerLoader {
    static func uiImage(from item: PhotosPickerItem) async -> UIImage? {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = ImageProcessing.uiImage(fromPhotoData: data) {
            return image
        }
        if let payload = try? await item.loadTransferable(type: PickedImagePayload.self),
           let image = ImageProcessing.uiImage(fromPhotoData: payload.data) {
            return image
        }
        return nil
    }
}

/// Typed transferable so HEIC / JPEG / PNG still decode when generic `Data` fails.
struct PickedImagePayload: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedImagePayload(data: data)
        }
        DataRepresentation(importedContentType: .heic) { data in
            PickedImagePayload(data: data)
        }
        DataRepresentation(importedContentType: .jpeg) { data in
            PickedImagePayload(data: data)
        }
        DataRepresentation(importedContentType: .png) { data in
            PickedImagePayload(data: data)
        }
    }
}

struct TemplateCard: View {
    let template: TemplateKind
    var isLastUsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottom) {
                TemplateSceneView(template: template, palette: template.defaultPalette)
                PetIllustration(character: previewPet)
                    .frame(width: 78, height: 88)
                    .offset(y: 8)
            }
            .aspectRatio(9 / 16, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                if isLastUsed {
                    Text("home.lastUsed")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(AppTheme.ink)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(LocalizedStringKey(template.nameKey))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(LocalizedStringKey(template.captionKey))
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(2)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
    }

    private var previewPet: PetCharacter {
        switch template {
        case .pastel, .sakura: return PetCharacter.character(id: "cat-calico")
        case .nightSky, .neon: return PetCharacter.character(id: "cat-tuxedo")
        case .park, .beach: return PetCharacter.character(id: "dog-corgi")
        case .cozyRoom: return PetCharacter.character(id: "cat-tabby")
        case .snow: return PetCharacter.character(id: "dog-husky")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppSession())
}
