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
        .fullScreenCover(item: $session.presentedCover) { cover in
            switch cover {
            case .tutorial:
                TutorialView()
                    .environment(session)
                    .interactiveDismissDisabled(!session.hasCompletedTutorial)
            case .photoImport:
                if let image = session.importSourceImage {
                    PhotoImportView(original: image)
                        .environment(session)
                } else {
                    PhotoImportMissingView()
                        .environment(session)
                }
            }
        }
        .onChange(of: session.presentedCover) { _, cover in
            if cover != .photoImport {
                session.importSourceImage = nil
            }
        }
    }
}

private struct PhotoImportMissingView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        VStack(spacing: 16) {
            Text("import.failed.unsupported")
                .multilineTextAlignment(.center)
                .padding()
            Button(String(localized: "import.cancel")) {
                session.dismissPhotoImport()
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.coral)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
}
