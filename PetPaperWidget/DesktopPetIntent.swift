import AppIntents
import SwiftUI

enum WidgetPetOption: String, AppEnum, CaseIterable {
    case appSetting
    case photoCutout
    case catTabby = "cat-tabby"
    case catCalico = "cat-calico"
    case catTuxedo = "cat-tuxedo"
    case catSiamese = "cat-siamese"
    case catGrey = "cat-grey"
    case catWhite = "cat-white"
    case dogGolden = "dog-golden"
    case dogCorgi = "dog-corgi"
    case dogHusky = "dog-husky"
    case dogDalmatian = "dog-dalmatian"
    case dogShiba = "dog-shiba"
    case dogBlack = "dog-black"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("widget.pet"))

    static var caseDisplayRepresentations: [WidgetPetOption: DisplayRepresentation] = [
        .appSetting: DisplayRepresentation(title: LocalizedStringResource("widget.pet.appSetting")),
        .photoCutout: DisplayRepresentation(title: LocalizedStringResource("widget.pet.photoCutout")),
        .catTabby: DisplayRepresentation(title: LocalizedStringResource("pet.cat.tabby")),
        .catCalico: DisplayRepresentation(title: LocalizedStringResource("pet.cat.calico")),
        .catTuxedo: DisplayRepresentation(title: LocalizedStringResource("pet.cat.tuxedo")),
        .catSiamese: DisplayRepresentation(title: LocalizedStringResource("pet.cat.siamese")),
        .catGrey: DisplayRepresentation(title: LocalizedStringResource("pet.cat.grey")),
        .catWhite: DisplayRepresentation(title: LocalizedStringResource("pet.cat.white")),
        .dogGolden: DisplayRepresentation(title: LocalizedStringResource("pet.dog.golden")),
        .dogCorgi: DisplayRepresentation(title: LocalizedStringResource("pet.dog.corgi")),
        .dogHusky: DisplayRepresentation(title: LocalizedStringResource("pet.dog.husky")),
        .dogDalmatian: DisplayRepresentation(title: LocalizedStringResource("pet.dog.dalmatian")),
        .dogShiba: DisplayRepresentation(title: LocalizedStringResource("pet.dog.shiba")),
        .dogBlack: DisplayRepresentation(title: LocalizedStringResource("pet.dog.black"))
    ]
}

enum WidgetTemplateOption: String, AppEnum, CaseIterable {
    case appSetting
    case pastel, nightSky, park, cozyRoom, neon, sakura, beach, snow

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("widget.template"))

    static var caseDisplayRepresentations: [WidgetTemplateOption: DisplayRepresentation] = [
        .appSetting: DisplayRepresentation(title: LocalizedStringResource("widget.template.appSetting")),
        .pastel: DisplayRepresentation(title: LocalizedStringResource("template.pastel.name")),
        .nightSky: DisplayRepresentation(title: LocalizedStringResource("template.nightSky.name")),
        .park: DisplayRepresentation(title: LocalizedStringResource("template.park.name")),
        .cozyRoom: DisplayRepresentation(title: LocalizedStringResource("template.cozyRoom.name")),
        .neon: DisplayRepresentation(title: LocalizedStringResource("template.neon.name")),
        .sakura: DisplayRepresentation(title: LocalizedStringResource("template.sakura.name")),
        .beach: DisplayRepresentation(title: LocalizedStringResource("template.beach.name")),
        .snow: DisplayRepresentation(title: LocalizedStringResource("template.snow.name"))
    ]
}

enum WidgetIntervalOption: String, AppEnum, CaseIterable {
    case appSetting
    case thirtyMinutes
    case oneHour
    case twoHours
    case fourHours
    case demo

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("idle.interval"))

    static var caseDisplayRepresentations: [WidgetIntervalOption: DisplayRepresentation] = [
        .appSetting: DisplayRepresentation(title: LocalizedStringResource("widget.interval.appSetting")),
        .thirtyMinutes: DisplayRepresentation(title: LocalizedStringResource("idle.interval.thirtyMinutes")),
        .oneHour: DisplayRepresentation(title: LocalizedStringResource("idle.interval.oneHour")),
        .twoHours: DisplayRepresentation(title: LocalizedStringResource("idle.interval.twoHours")),
        .fourHours: DisplayRepresentation(title: LocalizedStringResource("idle.interval.fourHours")),
        .demo: DisplayRepresentation(title: LocalizedStringResource("idle.interval.demo"))
    ]
}

enum WidgetIdleMode: String, AppEnum, CaseIterable {
    case appSetting
    case on
    case off

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("idle.enabled"))

    static var caseDisplayRepresentations: [WidgetIdleMode: DisplayRepresentation] = [
        .appSetting: DisplayRepresentation(title: LocalizedStringResource("widget.idle.appSetting")),
        .on: DisplayRepresentation(title: LocalizedStringResource("a11y.on")),
        .off: DisplayRepresentation(title: LocalizedStringResource("a11y.off"))
    ]
}

struct DesktopPetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget.displayName")
    static var description = IntentDescription(LocalizedStringResource("widget.description"))

    @Parameter(title: LocalizedStringResource("widget.pet"), default: WidgetPetOption.appSetting)
    var pet: WidgetPetOption

    @Parameter(title: LocalizedStringResource("widget.template"), default: WidgetTemplateOption.appSetting)
    var template: WidgetTemplateOption

    @Parameter(title: LocalizedStringResource("idle.enabled"), default: WidgetIdleMode.appSetting)
    var idleMode: WidgetIdleMode

    @Parameter(title: LocalizedStringResource("idle.interval"), default: WidgetIntervalOption.appSetting)
    var interval: WidgetIntervalOption

    init() {
        pet = .appSetting
        template = .appSetting
        idleMode = .appSetting
        interval = .appSetting
    }

    init(pet: WidgetPetOption, template: WidgetTemplateOption, idleMode: WidgetIdleMode, interval: WidgetIntervalOption) {
        self.pet = pet
        self.template = template
        self.idleMode = idleMode
        self.interval = interval
    }

    var resolvedPetID: String {
        let raw: String
        switch pet {
        case .appSetting, .photoCutout:
            raw = AppGroupStore.lastPetID
        default:
            raw = AppGroupStore.validatedPetID(pet.rawValue)
        }
        return PetCharacter.resolvedID(raw, hasPlusAccess: AppGroupStore.hasPlusAccess)
    }

    var resolvedUsesPhoto: Bool {
        guard AppGroupStore.hasPlusAccess else { return false }
        switch pet {
        case .photoCutout:
            return AppGroupStore.loadPhotoCutout() != nil
        case .appSetting:
            return AppGroupStore.usesPhotoPet && AppGroupStore.loadPhotoCutout() != nil
        default:
            return false
        }
    }

    var resolvedTemplate: TemplateKind {
        switch template {
        case .appSetting:
            return AppGroupStore.lastTemplate
        default:
            return TemplateKind(rawValue: template.rawValue) ?? .pastel
        }
    }

    var resolvedIdleEnabled: Bool {
        guard AppGroupStore.hasPlusAccess else { return false }
        switch idleMode {
        case .appSetting: return AppGroupStore.idleEnabled
        case .on: return true
        case .off: return false
        }
    }

    var resolvedInterval: IdleInterval {
        switch interval {
        case .appSetting: return AppGroupStore.idleInterval
        default: return IdleInterval(rawValue: interval.rawValue) ?? .twoHours
        }
    }
}
