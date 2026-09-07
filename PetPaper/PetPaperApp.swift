import SwiftUI

@main
struct PetPaperApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
                .environment(session)
                .onOpenURL { url in
                    session.handleDeepLink(url)
                }
        }
    }
}
