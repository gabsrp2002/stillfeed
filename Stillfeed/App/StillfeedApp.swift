import SwiftUI

@main
struct StillfeedApp: App {
    @State private var settingsStore = FilterSettingsStore()
    @State private var deepLinkRouter = DeepLinkRouter.shared

    var body: some Scene {
        WindowGroup {
            LauncherHomeView()
                .environment(settingsStore)
                .environment(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
