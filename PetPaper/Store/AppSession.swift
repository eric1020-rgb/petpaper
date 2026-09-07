import SwiftUI
import UIKit
import Observation

enum AppCover: String, Identifiable, Equatable {
    case tutorial
    case photoImport

    var id: String { rawValue }
}

@MainActor
@Observable
final class AppSession {
    var hasCompletedTutorial: Bool {
        didSet { UserDefaults.standard.set(hasCompletedTutorial, forKey: Self.tutorialKey) }
    }

    var presentedCover: AppCover?
    var path: [EditorRoute] = []
    var importSourceImage: UIImage?
    var pendingPhotoPet: PhotoPetCutout?

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.tutorialKey)
        hasCompletedTutorial = completed
        presentedCover = completed ? nil : .tutorial
    }

    func openEditor(template: TemplateKind, petID: String? = nil) {
        pendingPhotoPet = nil
        path.append(EditorRoute(template: template, petID: petID, usesPhotoPet: false))
    }

    func beginPhotoImport(_ image: UIImage) {
        importSourceImage = ImageProcessing.normalized(image)
        presentedCover = .photoImport
    }

    func finishPhotoImport(cutout: PhotoPetCutout, template: TemplateKind) {
        pendingPhotoPet = cutout
        importSourceImage = nil
        presentedCover = nil
        path.append(EditorRoute(template: template, petID: nil, usesPhotoPet: true))
    }

    func dismissPhotoImport() {
        presentedCover = nil
        importSourceImage = nil
    }

    /// Skip on first launch and replay: go to home, do not push the editor.
    func skipTutorial() {
        hasCompletedTutorial = true
        presentedCover = nil
    }

    /// Last-step CTA: remember completion and open the editor with the user's picks.
    func finishTutorial(template: TemplateKind, petID: String) {
        hasCompletedTutorial = true
        presentedCover = nil
        openEditor(template: template, petID: petID)
    }

    func replayTutorial() {
        presentedCover = .tutorial
    }

    private static let tutorialKey = "petpaper.hasCompletedTutorial"
}

struct EditorRoute: Hashable {
    let id = UUID()
    var template: TemplateKind
    var petID: String?
    var usesPhotoPet: Bool = false
}
