import Foundation

public enum NavigationDecision: Equatable, Sendable {
    case allow
    case redirect(URL, notice: String?)
    case blockWithFallback(URL, reason: String)
    case openExternally(URL)
    case cancelAppScheme
}

public struct NavigationPolicyEngine: Sendable {
    private static let blockedSchemes: Set<String> = [
        "instagram",
        "youtube",
        "vnd.youtube",
        "itms-apps",
        "itms-appss",
        "itms"
    ]

    private static let appStoreHosts: Set<String> = [
        "apps.apple.com",
        "itunes.apple.com"
    ]

    public init() {}

    public func evaluate(
        url: URL,
        platform: SocialPlatform,
        config: StillfeedConfig,
        isMainFrame: Bool = true
    ) -> NavigationDecision {
        guard let scheme = url.scheme?.lowercased() else {
            return .allow
        }

        if Self.blockedSchemes.contains(scheme) {
            return .cancelAppScheme
        }

        // Allow internal browser schemes like about:blank or data:
        if scheme == "about" || scheme == "data" || scheme == "blob" {
            return .allow
        }

        guard scheme == "http" || scheme == "https" else {
            return .cancelAppScheme
        }

        guard let host = url.host?.lowercased() else {
            return .allow
        }

        if Self.appStoreHosts.contains(host) {
            return .cancelAppScheme
        }

        // Only evaluate top-level navigations for external routing and page-level blocks.
        guard isMainFrame else {
            return .allow
        }

        if !platform.ownsHost(host) {
            return .openExternally(url)
        }

        switch platform {
        case .instagram:
            return evaluateInstagram(url: url, host: host, config: config.instagram)
        case .youtube:
            return evaluateYouTube(url: url, host: host, config: config.youtube)
        }
    }

    private func evaluateInstagram(
        url: URL,
        host: String,
        config: InstagramFilterConfig
    ) -> NavigationDecision {
        // Leave Facebook OAuth/login bridges untouched.
        if host.contains("facebook.com") {
            return .allow
        }

        // Unwrap Instagram's outbound link shim (l.instagram.com/?u=...)
        if host == "l.instagram.com",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let targetString = components.queryItems?.first(where: { $0.name == "u" })?.value,
           let targetURL = URL(string: targetString) {
            return .openExternally(targetURL)
        }

        let path = normalizedPath(from: url)

        // Never interfere with authentication, DMs, or security challenge paths.
        let safePrefixes = ["/accounts/", "/direct/", "/challenge/", "/oauth/", "/two_factor/", "/consent/"]
        if safePrefixes.contains(where: { path.hasPrefix($0) }) {
            return .allow
        }

        // Plural /reels/ is the infinite vertical Reels feed.
        if config.blockReelsFeedAndTab && (path == "/reels" || path.hasPrefix("/reels/")) {
            let fallback = SocialPlatform.instagram.fallbackSafeURL
            return .blockWithFallback(fallback, reason: "Blocked Reels feed")
        }

        // Singular /reel/<id> can be opened from DMs when allowSingleReelFromDM is enabled.
        if path == "/reel" || path.hasPrefix("/reel/") {
            if config.blockReelsFeedAndTab && !config.allowSingleReelFromDM {
                let fallback = SocialPlatform.instagram.fallbackSafeURL
                return .blockWithFallback(fallback, reason: "Blocked Reel")
            }
            return .allow
        }

        // Prefer Following feed when landing on bare root "/".
        if config.preferFollowingFeed && path == "/" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let variant = components?.queryItems?.first(where: { $0.name == "variant" })?.value
            if variant != "following" {
                var updated = components ?? URLComponents(string: "https://www.instagram.com/")!
                var items = updated.queryItems ?? []
                items.removeAll { $0.name == "variant" }
                items.append(URLQueryItem(name: "variant", value: "following"))
                updated.queryItems = items
                if let target = updated.url {
                    return .redirect(target, notice: nil)
                }
            }
        }

        return .allow
    }

    private func evaluateYouTube(
        url: URL,
        host: String,
        config: YouTubeFilterConfig
    ) -> NavigationDecision {
        // Leave Google/YouTube auth & consent hosts untouched.
        if SocialPlatform.isGoogleHost(host) || host.hasPrefix("accounts.") || host.hasPrefix("consent.") {
            return .allow
        }

        let path = normalizedPath(from: url)

        // Block /feed/shorts or bare /shorts directory.
        if (config.hideShortsEverywhere || config.redirectShortsToWatchPlayer) &&
            (path == "/feed/shorts" || path == "/shorts") {
            return .blockWithFallback(
                SocialPlatform.youtube.fallbackSafeURL,
                reason: "Blocked Shorts feed"
            )
        }

        // Redirect /shorts/<id> -> /watch?v=<id>
        if path.hasPrefix("/shorts/") {
            let videoId = String(path.dropFirst("/shorts/".count))
                .split(separator: "/", maxSplits: 1)
                .first
                .map(String.init) ?? ""

            if !videoId.isEmpty {
                if config.redirectShortsToWatchPlayer {
                    var components = URLComponents()
                    components.scheme = "https"
                    components.host = "m.youtube.com"
                    components.path = "/watch"
                    var queryItems = [URLQueryItem(name: "v", value: videoId)]
                    if let existingItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                        let preserved = existingItems.filter { $0.name != "v" && $0.name != "feature" }
                        queryItems.append(contentsOf: preserved)
                    }
                    components.queryItems = queryItems
                    if let target = components.url {
                        return .redirect(target, notice: "Opened Short in standard player")
                    }
                } else if config.hideShortsEverywhere {
                    return .blockWithFallback(
                        SocialPlatform.youtube.fallbackSafeURL,
                        reason: "Blocked Short"
                    )
                }
            }
        }

        // Redirect Home ("/") to Subscriptions unless it's a watch/search URL with query args.
        if config.replaceHomeWithSubscriptions && path == "/" {
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let hasContentQuery = queryItems.contains { $0.name == "v" || $0.name == "search_query" || $0.name == "list" }
            if !hasContentQuery {
                return .redirect(
                    SocialPlatform.youtube.fallbackSafeURL,
                    notice: nil
                )
            }
        }

        return .allow
    }

    private func normalizedPath(from url: URL) -> String {
        let raw = url.path
        if raw.isEmpty { return "/" }
        if raw.count > 1 && raw.hasSuffix("/") {
            return String(raw.dropLast())
        }
        return raw
    }
}
