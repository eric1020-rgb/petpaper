import SwiftUI

struct RootView: View {
    @Bindable var session: AppSession
    @Environment(SubscriptionManager.self) private var subscriptions

    var body: some View {
        @Bindable var subscriptions = subscriptions
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
                    PhotoImportView(original: image, initialTemplate: session.lastTemplate)
                        .environment(session)
                        .interactiveDismissDisabled()
                } else {
                    PhotoImportMissingView()
                        .environment(session)
                }
            }
        }
        .sheet(isPresented: paywallFromRoot) {
            PaywallView()
                .environment(subscriptions)
        }
        .onChange(of: session.presentedCover) { _, cover in
            if cover != .photoImport {
                session.importSourceImage = nil
            }
        }
        .onChange(of: session.path) { _, path in
            session.clearPendingPhotoPetIfNeeded(for: path)
        }
        .onChange(of: subscriptions.hasPlusAccess) { _, hasPlus in
            if !hasPlus, session.presentedCover == .photoImport {
                session.dismissPhotoImport()
            }
        }
    }

    /// Avoid competing with the tutorial / import fullScreenCover.
    private var paywallFromRoot: Binding<Bool> {
        Binding(
            get: { subscriptions.isPaywallPresented && session.presentedCover == nil },
            set: { newValue in
                if newValue {
                    if session.presentedCover == nil {
                        subscriptions.presentPaywall()
                    }
                } else {
                    subscriptions.dismissPaywall()
                }
            }
        )
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
