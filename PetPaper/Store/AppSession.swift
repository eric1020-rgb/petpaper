import SwiftUI
import Observation

@MainActor
@Observable
final class AppSession {
    var hasCompletedTutorial: Bool {
        didSet { UserDefaults.standard.set(hasCompletedTutorial, forKey: Self.tutorialKey) }
    }

    var showTutorial: Bool
    var path: [EditorRoute] = []

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.tutorialKey)
        hasCompletedTutorial = completed
        showTutorial = !completed
    }

    func openEditor(template: TemplateKind, petID: String? = nil) {
        path.append(EditorRoute(template: template, petID: petID))
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
}
