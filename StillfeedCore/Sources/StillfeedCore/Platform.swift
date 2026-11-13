import Foundation

public enum SocialPlatform: String, CaseIterable, Codable, Identifiable, Sendable {
    case instagram
    case youtube

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .instagram: "Instagram"
        case .youtube: "YouTube"
        }
    }

    public var systemImageName: String {
        switch self {
        case .instagram: "camera.aperture"
        case .youtube: "play.rectangle"
        }
    }

    public func entryURL(using config: StillfeedConfig) -> URL {
        switch self {
        case .instagram:
            if config.instagram.preferFollowingFeed {
                return URL(string: "https://www.instagram.com/?variant=following")!
            }
            return URL(string: "https://www.instagram.com/")!
        case .youtube:
            if config.youtube.replaceHomeWithSubscriptions {
                return URL(string: "https://m.youtube.com/feed/subscriptions")!
            }
            return URL(string: "https://m.youtube.com/")!
        }
    }

    public var fallbackSafeURL: URL {
        switch self {
        case .instagram: URL(string: "https://www.instagram.com/?variant=following")!
        case .youtube: URL(string: "https://m.youtube.com/feed/subscriptions")!
        }
    }

    public var quickDestinations: [QuickDestination] {
        switch self {
        case .instagram:
            return [
                QuickDestination(title: "Following Feed", systemImage: "person.2", url: URL(string: "https://www.instagram.com/?variant=following")!),
                QuickDestination(title: "Direct Messages", systemImage: "paperplane", url: URL(string: "https://www.instagram.com/direct/inbox/")!),
                QuickDestination(title: "Search", systemImage: "magnifyingglass", url: URL(string: "https://www.instagram.com/explore/")!),
                QuickDestination(title: "Profile", systemImage: "person.crop.circle", url: URL(string: "https://www.instagram.com/accounts/edit/")!)
            ]
        case .youtube:
            return [
                QuickDestination(title: "Subscriptions", systemImage: "rectangle.stack", url: URL(string: "https://m.youtube.com/feed/subscriptions")!),
                QuickDestination(title: "Search", systemImage: "magnifyingglass", url: URL(string: "https://m.youtube.com/results")!),
                QuickDestination(title: "Library", systemImage: "books.vertical", url: URL(string: "https://m.youtube.com/feed/library")!)
            ]
        }
    }

    /// Hosts that should stay inside the platform WebView (including login/OAuth hosts).
    public var allowedInAppHosts: Set<String> {
        switch self {
        case .instagram:
            return [
                "instagram.com",
                "www.instagram.com",
                "m.instagram.com",
                "l.instagram.com",
                "facebook.com",
                "www.facebook.com",
                "m.facebook.com",
                "fb.com",
                "meta.com"
            ]
        case .youtube:
            return [
                "youtube.com",
                "m.youtube.com",
                "www.youtube.com",
                "youtu.be",
                "youtube-nocookie.com",
                "accounts.youtube.com",
                "consent.youtube.com"
            ]
        }
    }

    public func ownsHost(_ host: String) -> Bool {
        let lower = host.lowercased()
        if allowedInAppHosts.contains(lower) {
            return true
        }
        if allowedInAppHosts.contains(where: { lower.hasSuffix(".\($0)") }) {
            return true
        }
        if self == .youtube && Self.isGoogleHost(lower) {
            return true
        }
        return false
    }

    public static func isGoogleHost(_ host: String) -> Bool {
        let labels = host.lowercased().split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !labels.contains(where: { $0.isEmpty }) else { return false }

        if labels.count >= 2,
           labels[labels.count - 2] == "google",
           isValidTLD(labels[labels.count - 1]) {
            return true
        }

        if labels.count >= 3,
           labels[labels.count - 3] == "google",
           ["com", "co", "org", "net"].contains(labels[labels.count - 2]),
           isCountryCode(labels[labels.count - 1]) {
            return true
        }

        return false
    }

    private static func isValidTLD(_ tld: String) -> Bool {
        tld == "com" || isCountryCode(tld)
    }

    private static func isCountryCode(_ code: String) -> Bool {
        code.count == 2 && code.allSatisfy { $0.isASCII && $0.isLetter }
    }
}

public struct QuickDestination: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let url: URL

    public init(title: String, systemImage: String, url: URL) {
        self.id = url.absoluteString
        self.title = title
        self.systemImage = systemImage
        self.url = url
    }
}
