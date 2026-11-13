import Foundation

public struct DeepLinkTarget: Equatable, Sendable {
    public let platform: SocialPlatform
    public let initialURL: URL?

    public init(platform: SocialPlatform, initialURL: URL? = nil) {
        self.platform = platform
        self.initialURL = initialURL
    }
}

public struct DeepLinkParser: Sendable {
    public static let scheme = "stillfeed"

    public init() {}

    public func parse(_ url: URL) -> DeepLinkTarget? {
        guard url.scheme?.lowercased() == Self.scheme else {
            return nil
        }

        let host = url.host?.lowercased() ?? ""
        switch host {
        case "instagram":
            return DeepLinkTarget(platform: .instagram, initialURL: optionalTargetURL(from: url, platform: .instagram))
        case "youtube":
            return DeepLinkTarget(platform: .youtube, initialURL: optionalTargetURL(from: url, platform: .youtube))
        case "open":
            guard let targetURL = extractQueryURL(from: url),
                  let targetHost = targetURL.host,
                  let platform = SocialPlatform.allCases.first(where: { $0.ownsHost(targetHost) }) else {
                return nil
            }
            return DeepLinkTarget(platform: platform, initialURL: targetURL)
        default:
            return nil
        }
    }

    private func optionalTargetURL(from deepLink: URL, platform: SocialPlatform) -> URL? {
        guard let targetURL = extractQueryURL(from: deepLink),
              let targetHost = targetURL.host,
              platform.ownsHost(targetHost) else {
            return nil
        }
        return targetURL
    }

    private func extractQueryURL(from url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let raw = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let parsed = URL(string: raw),
              let scheme = parsed.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return parsed
    }
}
