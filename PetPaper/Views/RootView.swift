import SwiftUI

struct RootView: View {
    @Bindable var session: AppSession

    var body: some View {
        NavigationStack(path: $session.path) {
            HomeView()
                .navigationDestination(for: EditorRoute.self) { route in
                    EditorView(template: route.template, petID: route.petID)
                }
        }
        .tint(AppTheme.coral)
        .fullScreenCover(isPresented: $session.showTutorial) {
            TutorialView()
                .environment(session)
        }
    }
}
