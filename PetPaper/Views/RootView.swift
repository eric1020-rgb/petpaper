import SwiftUI

struct RootView: View {
    @Bindable var session: AppSession

    var body: some View {
        NavigationStack(path: $session.path) {
            HomeView()
                .navigationDestination(for: EditorRoute.self) { route in
                    EditorView(
                        template: route.template,
                        petID: route.petID,
                        photoPet: route.usesPhotoPet ? session.pendingPhotoPet : nil
                    )
                }
        }
        .tint(AppTheme.coral)
        .fullScreenCover(isPresented: $session.showTutorial) {
            TutorialView()
                .environment(session)
        }
        .fullScreenCover(isPresented: $session.showPhotoImport) {
            if let image = session.importSourceImage {
                PhotoImportView(original: image)
                    .environment(session)
            }
        }
    }
}
