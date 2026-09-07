import Foundation
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Shared App Group container so the Home Screen widget and the app use the same idle settings.
enum AppGroupStore {
    static let suiteName = "group.com.eric1020.petpaper"
    static let widgetKind = "DesktopPetWidget"
    static let urlScheme = "petpaper"

    static let lastTemplateKey = "petpaper.lastTemplate"
    static let lastPetIDKey = "petpaper.lastPetID"
    static let idleEnabledKey = "petpaper.idleEnabled"
    static let idleIntervalKey = "petpaper.idleInterval"
    static let idleToastKey = "petpaper.idleToast"
    static let usesPhotoPetKey = "petpaper.usesPhotoPet"
    static let photoShadowKey = "petpaper.photoShadow"
    static let photoTintKey = "petpaper.photoTint"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var lastTemplate: TemplateKind {
        get {
            let raw = string(forKey: lastTemplateKey, migratingFromStandard: true)
            return TemplateKind(rawValue: raw ?? "") ?? .pastel
        }
        set { defaults.set(newValue.rawValue, forKey: lastTemplateKey) }
    }

    static var lastPetID: String {
        get {
            let stored = string(forKey: lastPetIDKey, migratingFromStandard: true)
            return validatedPetID(stored)
        }
        set { defaults.set(validatedPetID(newValue), forKey: lastPetIDKey) }
    }

    static var idleEnabled: Bool {
        get { bool(forKey: idleEnabledKey, default: true, migratingFromStandard: true) }
        set { defaults.set(newValue, forKey: idleEnabledKey) }
    }

    static var idleInterval: IdleInterval {
        get {
            let raw = string(forKey: idleIntervalKey, migratingFromStandard: true)
            return IdleInterval(rawValue: raw ?? "") ?? .twoHours
        }
        set { defaults.set(newValue.rawValue, forKey: idleIntervalKey) }
    }

    static var idleToastEnabled: Bool {
        get { bool(forKey: idleToastKey, default: true, migratingFromStandard: true) }
        set { defaults.set(newValue, forKey: idleToastKey) }
    }

    static var usesPhotoPet: Bool {
        get { defaults.bool(forKey: usesPhotoPetKey) }
        set { defaults.set(newValue, forKey: usesPhotoPetKey) }
    }

    static func savePhotoCutout(_ cutout: PhotoPetCutout) {
        guard let url = photoCutoutURL, let data = cutout.cutout.pngData() else { return }
        try? data.write(to: url, options: .atomic)
        defaults.set(cutout.shadowEnabled, forKey: photoShadowKey)
        defaults.set(cutout.tintAmount, forKey: photoTintKey)
        usesPhotoPet = true
    }

    static func loadPhotoCutout() -> PhotoPetCutout? {
        guard let url = photoCutoutURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return PhotoPetCutout(
            original: image,
            cutout: image,
            instanceIndex: 0,
            shadowEnabled: defaults.object(forKey: photoShadowKey) as? Bool ?? true,
            tintAmount: defaults.object(forKey: photoTintKey) as? Double ?? 0
        )
    }

    static func editorURL(petID: String, template: TemplateKind) -> URL {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = "editor"
        components.queryItems = [
            URLQueryItem(name: "pet", value: petID),
            URLQueryItem(name: "template", value: template.rawValue)
        ]
        return components.url ?? URL(string: "\(urlScheme)://editor")!
    }

    static func reloadDesktopPetWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        #endif
    }

    private static var photoCutoutURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: suiteName)?
            .appendingPathComponent("widget-photo-cutout.png")
    }

    private static func string(forKey key: String, migratingFromStandard: Bool) -> String? {
        if let value = defaults.string(forKey: key) {
            return value
        }
        guard migratingFromStandard, let value = UserDefaults.standard.string(forKey: key) else {
            return nil
        }
        defaults.set(value, forKey: key)
        return value
    }

    private static func bool(forKey key: String, default defaultValue: Bool, migratingFromStandard: Bool) -> Bool {
        if defaults.object(forKey: key) != nil {
            return defaults.bool(forKey: key)
        }
        if migratingFromStandard, UserDefaults.standard.object(forKey: key) != nil {
            let value = UserDefaults.standard.bool(forKey: key)
            defaults.set(value, forKey: key)
            return value
        }
        return defaultValue
    }

    static func validatedPetID(_ petID: String?) -> String {
        if let petID, PetCharacter.catalog.contains(where: { $0.id == petID }) {
            return petID
        }
        return PetCharacter.catalog[0].id
    }
}
