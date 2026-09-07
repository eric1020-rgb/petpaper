import SwiftUI
import Photos
import UIKit

enum WallpaperExportError: LocalizedError {
    case renderFailed
    case permissionDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return String(localized: "export.error.render")
        case .permissionDenied:
            return String(localized: "export.error.permission")
        case .saveFailed:
            return String(localized: "export.error.save")
        }
    }
}

enum WallpaperExporter {
    static let canvasSize = CGSize(width: 1290, height: 2796)

    @MainActor
    static func render(state: EditorState, pet: PetCharacter, photoPet: PhotoPetCutout? = nil) -> UIImage? {
        let content = ExportableWallpaperView(state: state, pet: pet, photoPet: photoPet, size: canvasSize)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(canvasSize)
        return renderer.uiImage
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await requestAddOnlyAccess()
        guard status == .authorized || status == .limited else {
            throw WallpaperExportError.permissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw WallpaperExportError.saveFailed
        }
    }

    private static func requestAddOnlyAccess() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        return current
    }
}
