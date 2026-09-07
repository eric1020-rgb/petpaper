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
        didSet {
            AppGroupStore.lastTemplate = lastTemplate
            UserDefaults.standard.set(lastTemplate.rawValue, forKey: Self.lastTemplateKey)
        }
    }

    var lastPetID: String {
        didSet {
            AppGroupStore.lastPetID = lastPetID
            UserDefaults.standard.set(lastPetID, forKey: Self.lastPetIDKey)
        }
    }

    /// False until the user has opened the editor (or placed a photo pet) at least once.
    var hasRememberedEditor: Bool

    var idleEnabled: Bool {
        didSet {
            AppGroupStore.idleEnabled = idleEnabled
            AppGroupStore.reloadDesktopPetWidget()
        }
    }

    var idleInterval: IdleInterval {
        didSet {
            AppGroupStore.idleInterval = idleInterval
            AppGroupStore.reloadDesktopPetWidget()
        }
    }

    var idleToastEnabled: Bool {
        didSet {
            AppGroupStore.idleToastEnabled = idleToastEnabled
        }
    }

    var presentedCover: AppCover?
    var path: [EditorRoute] = []
    var importSourceImage: UIImage?
    var pendingPhotoPet: PhotoPetCutout?

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.tutorialKey)
        hasCompletedTutorial = completed
        presentedCover = completed ? nil : .tutorial
        if let raw = AppGroupStore.defaults.string(forKey: AppGroupStore.lastTemplateKey) ?? UserDefaults.standard.string(forKey: Self.lastTemplateKey),
           let template = TemplateKind(rawValue: raw) {
            lastTemplate = template
        } else {
            lastTemplate = .pastel
        }
        let storedPet = AppGroupStore.defaults.string(forKey: AppGroupStore.lastPetIDKey)
            ?? UserDefaults.standard.string(forKey: Self.lastPetIDKey)
        lastPetID = Self.validatedPetID(storedPet)
        hasRememberedEditor = UserDefaults.standard.object(forKey: Self.lastTemplateKey) != nil
            || AppGroupStore.defaults.object(forKey: AppGroupStore.lastTemplateKey) != nil
        idleEnabled = AppGroupStore.idleEnabled
        idleInterval = AppGroupStore.idleInterval
        idleToastEnabled = AppGroupStore.idleToastEnabled
        AppGroupStore.lastTemplate = lastTemplate
        AppGroupStore.lastPetID = lastPetID
        AppGroupStore.idleEnabled = idleEnabled
        AppGroupStore.idleInterval = idleInterval
        AppGroupStore.idleToastEnabled = idleToastEnabled
    }

    func openEditor(template: TemplateKind, petID: String? = nil, hasPlusAccess: Bool = false) {
        pendingPhotoPet = nil
        if let petID, PetCharacter.catalog.contains(where: { $0.id == petID }) {
            lastPetID = petID
        }
        let resolvedPet = PetCharacter.resolvedID(lastPetID, hasPlusAccess: hasPlusAccess)
        remember(template: template, petID: resolvedPet, usesPhotoPet: false)
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
        remember(template: template, petID: nil, usesPhotoPet: true)
        AppGroupStore.savePhotoCutout(cutout)
        AppGroupStore.reloadDesktopPetWidget()
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
    func finishTutorial(template: TemplateKind, petID: String, hasPlusAccess: Bool) {
        hasCompletedTutorial = true
        presentedCover = nil
        openEditor(template: template, petID: petID, hasPlusAccess: hasPlusAccess)
    }

    func replayTutorial() {
        presentedCover = .tutorial
    }

    func remember(template: TemplateKind, petID: String?, usesPhotoPet: Bool? = nil) {
        lastTemplate = template
        hasRememberedEditor = true
        if let petID {
            lastPetID = Self.validatedPetID(petID)
        }
        if let usesPhotoPet {
            AppGroupStore.usesPhotoPet = usesPhotoPet
        } else if petID != nil {
            AppGroupStore.usesPhotoPet = false
        }
        AppGroupStore.reloadDesktopPetWidget()
    }

    func handleDeepLink(_ url: URL, hasPlusAccess: Bool = false) {
        guard url.scheme == AppGroupStore.urlScheme else { return }
        presentedCover = nil
        var template = lastTemplate
        var petID = lastPetID
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            if let raw = items.first(where: { $0.name == "template" })?.value,
               let parsed = TemplateKind(rawValue: raw) {
                template = parsed
            }
            if let raw = items.first(where: { $0.name == "pet" })?.value {
                petID = Self.validatedPetID(raw)
            }
        }
        if path.isEmpty {
            if hasPlusAccess, AppGroupStore.usesPhotoPet, let cutout = AppGroupStore.loadPhotoCutout() {
                pendingPhotoPet = cutout
                remember(template: template, petID: nil, usesPhotoPet: true)
                path.append(EditorRoute(template: template, petID: nil, usesPhotoPet: true))
            } else {
                openEditor(template: template, petID: petID, hasPlusAccess: hasPlusAccess)
            }
        }
    }

    func clearPendingPhotoPetIfNeeded(for path: [EditorRoute]) {
        if !path.contains(where: \.usesPhotoPet) {
            pendingPhotoPet = nil
        }
    }

    private static func validatedPetID(_ petID: String?) -> String {
        PetCharacter.resolvedID(petID, hasPlusAccess: true)
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
