import SwiftUI

/// Pet idle is in-process (`PetIdleDirector`) plus a WidgetKit extension.
/// There is no uninstall callback, push, or `UIBackgroundModes` work that can outlive the app.
@main
struct PetPaperApp: App {
    @State private var session = AppSession()
    @State private var subscriptions = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
                .environment(session)
                .environment(subscriptions)
                .onOpenURL { url in
                    session.handleDeepLink(url, hasPlusAccess: subscriptions.hasPlusAccess)
                }
        }
    }
}
