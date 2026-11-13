import AppIntents
import StillfeedCore

struct OpenInstagramIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Instagram in Stillfeed"
    static var description = IntentDescription("Opens Instagram inside Stillfeed with Reels and Explore filtered out.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkRouter.shared.open(.instagram)
        return .result()
    }
}

struct OpenYouTubeIntent: AppIntent {
    static var title: LocalizedStringResource = "Open YouTube in Stillfeed"
    static var description = IntentDescription("Opens YouTube inside Stillfeed with Shorts and Home feed filtered out.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLinkRouter.shared.open(.youtube)
        return .result()
    }
}

struct StillfeedAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenInstagramIntent(),
            phrases: [
                "Open Instagram in \(.applicationName)",
                "Launch filtered Instagram in \(.applicationName)"
            ],
            shortTitle: "Open Instagram",
            systemImageName: "camera.aperture"
        )
        AppShortcut(
            intent: OpenYouTubeIntent(),
            phrases: [
                "Open YouTube in \(.applicationName)",
                "Launch filtered YouTube in \(.applicationName)"
            ],
            shortTitle: "Open YouTube",
            systemImageName: "play.rectangle"
        )
    }
}
