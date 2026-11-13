import XCTest
@testable import StillfeedCore

final class NavigationPolicyEngineTests: XCTestCase {
    private let engine = NavigationPolicyEngine()

    func testAppSchemesAreCancelled() {
        let config = StillfeedConfig()
        let schemes = [
            "instagram://reel/123",
            "youtube://watch?v=abc",
            "vnd.youtube://abc",
            "itms-apps://apps.apple.com/app/id123",
            "https://apps.apple.com/us/app/instagram/id389801252"
        ]

        for raw in schemes {
            let url = URL(string: raw)!
            XCTAssertEqual(
                engine.evaluate(url: url, platform: .instagram, config: config),
                .cancelAppScheme,
                "Expected \(raw) to be cancelled"
            )
        }
    }

    func testYouTubeShortsRedirectsToStandardWatchPlayerAndIsIdempotent() {
        var config = StillfeedConfig()
        config.language = .english
        let shortsURL = URL(string: "https://m.youtube.com/shorts/dQw4w9WgXcQ?t=12&feature=share")!

        let decision = engine.evaluate(url: shortsURL, platform: .youtube, config: config)
        guard case let .redirect(targetURL, notice) = decision else {
            return XCTFail("Expected redirect, got \(decision)")
        }

        XCTAssertEqual(targetURL.host, "m.youtube.com")
        XCTAssertEqual(targetURL.path, "/watch")
        let items = URLComponents(url: targetURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first(where: { $0.name == "v" })?.value, "dQw4w9WgXcQ")
        XCTAssertEqual(items.first(where: { $0.name == "t" })?.value, "12")
        XCTAssertNil(items.first(where: { $0.name == "feature" }))
        XCTAssertEqual(notice, "Opened Short in standard player")

        // Re-evaluating the redirect target must allow without looping.
        XCTAssertEqual(engine.evaluate(url: targetURL, platform: .youtube, config: config), .allow)
    }

    func testYouTubeShortsBlockedWhenRedirectDisabled() {
        var config = StillfeedConfig()
        config.language = .english
        config.youtube.redirectShortsToWatchPlayer = false
        config.youtube.hideShortsEverywhere = true

        let shortsURL = URL(string: "https://m.youtube.com/shorts/abc123")!
        let decision = engine.evaluate(url: shortsURL, platform: .youtube, config: config)
        XCTAssertEqual(
            decision,
            .blockWithFallback(SocialPlatform.youtube.fallbackSafeURL, reason: "Blocked Short")
        )
    }

    func testYouTubeHomeRedirectsToSubscriptionsWhileWatchAndSearchPass() {
        let config = StillfeedConfig()
        let homeDecision = engine.evaluate(
            url: URL(string: "https://m.youtube.com/")!,
            platform: .youtube,
            config: config
        )
        XCTAssertEqual(
            homeDecision,
            .redirect(URL(string: "https://m.youtube.com/feed/subscriptions")!, notice: nil)
        )

        // Idempotent on target
        XCTAssertEqual(
            engine.evaluate(
                url: URL(string: "https://m.youtube.com/feed/subscriptions")!,
                platform: .youtube,
                config: config
            ),
            .allow
        )

        // Watch, search, and Google auth pass cleanly
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://m.youtube.com/watch?v=abc")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://m.youtube.com/results?search_query=swift")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://accounts.google.com/v3/signin")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.google.com/accounts/SetOSID")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://accounts.google.com.br/ServiceLogin")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.google.co.uk/")!, platform: .youtube, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://evilgoogle.com/")!, platform: .youtube, config: config),
            .openExternally(URL(string: "https://evilgoogle.com/")!)
        )
    }

    func testInstagramBlocksReelsFeedButAllowsSingleReelFromDM() {
        var config = StillfeedConfig()
        config.language = .english

        let reelsFeed = engine.evaluate(
            url: URL(string: "https://www.instagram.com/reels/")!,
            platform: .instagram,
            config: config
        )
        XCTAssertEqual(
            reelsFeed,
            .blockWithFallback(SocialPlatform.instagram.fallbackSafeURL, reason: "Blocked Reels feed")
        )

        let singleReel = engine.evaluate(
            url: URL(string: "https://www.instagram.com/reel/Cx12345/")!,
            platform: .instagram,
            config: config
        )
        XCTAssertEqual(singleReel, .allow)

        var strictConfig = config
        strictConfig.instagram.allowSingleReelFromDM = false
        let blockedSingleReel = engine.evaluate(
            url: URL(string: "https://www.instagram.com/reel/Cx12345/")!,
            platform: .instagram,
            config: strictConfig
        )
        XCTAssertEqual(
            blockedSingleReel,
            .blockWithFallback(SocialPlatform.instagram.fallbackSafeURL, reason: "Blocked Reel")
        )
    }

    func testInstagramFollowingRedirectAndAuthPaths() {
        var config = StillfeedConfig()

        // Default keeps root "/" so Stories from followed accounts stay visible.
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.instagram.com/")!, platform: .instagram, config: config),
            .allow
        )

        // When preferFollowingFeed is enabled, "/" redirects to "/?variant=following".
        config.instagram.preferFollowingFeed = true
        let bareHome = engine.evaluate(
            url: URL(string: "https://www.instagram.com/")!,
            platform: .instagram,
            config: config
        )
        guard case let .redirect(followingURL, _) = bareHome else {
            return XCTFail("Expected redirect to following feed, got \(bareHome)")
        }
        XCTAssertTrue(followingURL.absoluteString.contains("variant=following"))
        XCTAssertEqual(engine.evaluate(url: followingURL, platform: .instagram, config: config), .allow)

        // Login, DMs, and Explore(Search) remain allowed
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.instagram.com/accounts/login/")!, platform: .instagram, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.instagram.com/direct/inbox/")!, platform: .instagram, config: config),
            .allow
        )
        XCTAssertEqual(
            engine.evaluate(url: URL(string: "https://www.instagram.com/explore/")!, platform: .instagram, config: config),
            .allow
        )
    }

    func testInstagramOutboundShimAndExternalLinksOpenExternally() {
        let config = StillfeedConfig()
        let external = URL(string: "https://example.com/article")!
        XCTAssertEqual(
            engine.evaluate(url: external, platform: .instagram, config: config),
            .openExternally(external)
        )

        let shim = URL(string: "https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2Fpost")!
        XCTAssertEqual(
            engine.evaluate(url: shim, platform: .instagram, config: config),
            .openExternally(URL(string: "https://example.com/post")!)
        )
    }
}
