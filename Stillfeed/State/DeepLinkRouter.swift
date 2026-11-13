import Foundation
import Observation
import StillfeedCore

struct ActiveBrowserSession: Identifiable, Equatable {
    let id = UUID()
    let platform: SocialPlatform
    let initialURL: URL?
}

@MainActor
@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    var activeSession: ActiveBrowserSession?

    private let parser = DeepLinkParser()

    private init() {}

    @discardableResult
    func handle(url: URL) -> Bool {
        guard let target = parser.parse(url) else {
            return false
        }
        open(target.platform, initialURL: target.initialURL)
        return true
    }

    func open(_ platform: SocialPlatform, initialURL: URL? = nil) {
        let next = ActiveBrowserSession(platform: platform, initialURL: initialURL)
        if activeSession != nil {
            activeSession = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                self.activeSession = next
            }
        } else {
            activeSession = next
        }
    }
}
