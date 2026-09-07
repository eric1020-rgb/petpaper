import SwiftUI
import UIKit
import Observation

@MainActor
@Observable
final class AppSession {
    var hasCompletedTutorial: Bool {
        didSet { UserDefaults.standard.set(hasCompletedTutorial, forKey: Self.tutorialKey) }
    }

    var showTutorial: Bool
    var path: [EditorRoute] = []
    var showPhotoImport = false
    var importSourceImage: UIImage?
    var pendingPhotoPet: PhotoPetCutout?

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.tutorialKey)
        hasCompletedTutorial = completed
        showTutorial = !completed
    }

    func openEditor(template: TemplateKind, petID: String? = nil) {
        pendingPhotoPet = nil
        path.append(EditorRoute(template: template, petID: petID, usesPhotoPet: false))
    }

    func openEditor(template: TemplateKind, photoPet: PhotoPetCutout) {
        pendingPhotoPet = photoPet
        path.append(EditorRoute(template: template, petID: nil, usesPhotoPet: true))
    }

    func beginPhotoImport(_ image: UIImage) {
        importSourceImage = ImageProcessing.normalized(image)
        showPhotoImport = true
    }

    func finishPhotoImport(cutout: PhotoPetCutout, template: TemplateKind) {
        pendingPhotoPet = cutout
        showPhotoImport = false
        path.append(EditorRoute(template: template, petID: nil, usesPhotoPet: true))
    }

    func dismissPhotoImport() {
        showPhotoImport = false
        importSourceImage = nil
    }

    func completeTutorial(template: TemplateKind, petID: String) {
        hasCompletedTutorial = true
        showTutorial = false
        openEditor(template: template, petID: petID)
    }

    func replayTutorial() {
        showTutorial = true
    }

    private static let tutorialKey = "petpaper.hasCompletedTutorial"
}

struct EditorRoute: Hashable {
    let id = UUID()
    var template: TemplateKind
    var petID: String?
    var usesPhotoPet: Bool = false
}
