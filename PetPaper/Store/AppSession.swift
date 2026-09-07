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

    var lastTemplate: TemplateKind {
        didSet { UserDefaults.standard.set(lastTemplate.rawValue, forKey: Self.lastTemplateKey) }
    }

    var lastPetID: String {
        didSet { UserDefaults.standard.set(lastPetID, forKey: Self.lastPetIDKey) }
    }

    /// False until the user has opened the editor (or placed a photo pet) at least once.
    var hasRememberedEditor: Bool

    var presentedCover: AppCover?
    var path: [EditorRoute] = []
    var importSourceImage: UIImage?
    var pendingPhotoPet: PhotoPetCutout?

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.tutorialKey)
        hasCompletedTutorial = completed
        presentedCover = completed ? nil : .tutorial
        if let raw = UserDefaults.standard.string(forKey: Self.lastTemplateKey),
           let template = TemplateKind(rawValue: raw) {
            lastTemplate = template
        } else {
            lastTemplate = .pastel
        }
        let storedPet = UserDefaults.standard.string(forKey: Self.lastPetIDKey)
        lastPetID = Self.validatedPetID(storedPet)
        hasRememberedEditor = UserDefaults.standard.object(forKey: Self.lastTemplateKey) != nil
    }

    func openEditor(template: TemplateKind, petID: String? = nil) {
        pendingPhotoPet = nil
        let resolvedPet = Self.validatedPetID(petID ?? lastPetID)
        remember(template: template, petID: resolvedPet)
        path.append(EditorRoute(template: template, petID: resolvedPet, usesPhotoPet: false))
    }

    func beginPhotoImport(_ image: UIImage) {
        importSourceImage = ImageProcessing.preparedForImport(image)
        presentedCover = .photoImport
    }

    func finishPhotoImport(cutout: PhotoPetCutout, template: TemplateKind) {
        pendingPhotoPet = cutout
        importSourceImage = nil
        presentedCover = nil
        remember(template: template, petID: nil)
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

    func remember(template: TemplateKind, petID: String?) {
        lastTemplate = template
        hasRememberedEditor = true
        if let petID {
            lastPetID = Self.validatedPetID(petID)
        }
    }

    func clearPendingPhotoPetIfNeeded(for path: [EditorRoute]) {
        if !path.contains(where: \.usesPhotoPet) {
            pendingPhotoPet = nil
        }
    }

    private static func validatedPetID(_ petID: String?) -> String {
        if let petID, PetCharacter.catalog.contains(where: { $0.id == petID }) {
            return petID
        }
        return PetCharacter.catalog[0].id
    }

    private static let tutorialKey = "petpaper.hasCompletedTutorial"
    private static let lastTemplateKey = "petpaper.lastTemplate"
    private static let lastPetIDKey = "petpaper.lastPetID"
}

struct EditorRoute: Hashable {
    let id = UUID()
    var template: TemplateKind
    var petID: String?
    var usesPhotoPet: Bool = false
}
