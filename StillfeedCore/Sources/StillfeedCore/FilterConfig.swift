import Foundation

public struct StillfeedConfig: Codable, Equatable, Sendable {
    public var instagram: InstagramFilterConfig
    public var youtube: YouTubeFilterConfig
    public var frictionLock: FrictionLockConfig
    public var language: AppLanguage
    public var applyLanguageToPlatforms: Bool

    public init(
        instagram: InstagramFilterConfig = InstagramFilterConfig(),
        youtube: YouTubeFilterConfig = YouTubeFilterConfig(),
        frictionLock: FrictionLockConfig = FrictionLockConfig(),
        language: AppLanguage = .system,
        applyLanguageToPlatforms: Bool = false
    ) {
        self.instagram = instagram
        self.youtube = youtube
        self.frictionLock = frictionLock
        self.language = language
        self.applyLanguageToPlatforms = applyLanguageToPlatforms
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.instagram = try container.decodeIfPresent(InstagramFilterConfig.self, forKey: .instagram) ?? InstagramFilterConfig()
        self.youtube = try container.decodeIfPresent(YouTubeFilterConfig.self, forKey: .youtube) ?? YouTubeFilterConfig()
        self.frictionLock = try container.decodeIfPresent(FrictionLockConfig.self, forKey: .frictionLock) ?? FrictionLockConfig()
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        self.applyLanguageToPlatforms = try container.decodeIfPresent(Bool.self, forKey: .applyLanguageToPlatforms) ?? false
    }

    public var totalActiveProtections: Int {
        instagram.activeCount + youtube.activeCount
    }
}

public struct InstagramFilterConfig: Codable, Equatable, Sendable {
    /// Hides Reels tab/shelves and blocks the /reels/ infinite feed.
    public var blockReelsFeedAndTab: Bool
    /// Allows opening a single /reel/<id> (e.g., sent in DMs) while locking vertical swipe to next reel.
    public var allowSingleReelFromDM: Bool
    /// Hides the algorithmic Explore grid while keeping Search usable.
    public var blockExploreGridKeepSearch: Bool
    /// Strips "Suggested for you" and Sponsored posts from feeds.
    public var hideSuggestedAndSponsored: Bool
    /// Redirects bare "/" home feed to "/?variant=following".
    public var preferFollowingFeed: Bool
    /// Optional toggle to also hide the Stories tray at the top of Home.
    public var hideStoriesTray: Bool

    public init(
        blockReelsFeedAndTab: Bool = true,
        allowSingleReelFromDM: Bool = true,
        blockExploreGridKeepSearch: Bool = true,
        hideSuggestedAndSponsored: Bool = true,
        preferFollowingFeed: Bool = false,
        hideStoriesTray: Bool = false
    ) {
        self.blockReelsFeedAndTab = blockReelsFeedAndTab
        self.allowSingleReelFromDM = allowSingleReelFromDM
        self.blockExploreGridKeepSearch = blockExploreGridKeepSearch
        self.hideSuggestedAndSponsored = hideSuggestedAndSponsored
        self.preferFollowingFeed = preferFollowingFeed
        self.hideStoriesTray = hideStoriesTray
    }

    public var activeCount: Int {
        [
            blockReelsFeedAndTab,
            blockExploreGridKeepSearch,
            hideSuggestedAndSponsored,
            preferFollowingFeed,
            hideStoriesTray
        ].filter { $0 }.count
    }

    public var summaryText: String {
        summaryText(using: .english)
    }

    public func summaryText(using copy: AppCopy) -> String {
        var parts: [String] = []
        if blockReelsFeedAndTab {
            parts.append(allowSingleReelFromDM ? copy.summaryDMSafeReels : copy.summaryNoReels)
        }
        if blockExploreGridKeepSearch {
            parts.append(copy.summaryNoExplore)
        }
        if hideSuggestedAndSponsored || preferFollowingFeed {
            parts.append(copy.summaryCleanFeed)
        }
        return parts.isEmpty ? copy.summaryFiltersPaused : parts.joined(separator: " • ")
    }
}

public struct YouTubeFilterConfig: Codable, Equatable, Sendable {
    /// Hides Shorts tabs, shelves, and lockups across YouTube.
    public var hideShortsEverywhere: Bool
    /// Redirects /shorts/<id> URLs to the regular /watch?v=<id> player.
    public var redirectShortsToWatchPlayer: Bool
    /// Redirects Home ("/") to Subscriptions ("/feed/subscriptions") and hides Home tab.
    public var replaceHomeWithSubscriptions: Bool
    /// Hides "Up Next" / related video recommendations under the player.
    public var hideUpNextRecommendations: Bool
    /// Optional toggle to also hide comments under videos.
    public var hideComments: Bool

    public init(
        hideShortsEverywhere: Bool = true,
        redirectShortsToWatchPlayer: Bool = true,
        replaceHomeWithSubscriptions: Bool = true,
        hideUpNextRecommendations: Bool = true,
        hideComments: Bool = false
    ) {
        self.hideShortsEverywhere = hideShortsEverywhere
        self.redirectShortsToWatchPlayer = redirectShortsToWatchPlayer
        self.replaceHomeWithSubscriptions = replaceHomeWithSubscriptions
        self.hideUpNextRecommendations = hideUpNextRecommendations
        self.hideComments = hideComments
    }

    public var activeCount: Int {
        [
            hideShortsEverywhere,
            redirectShortsToWatchPlayer,
            replaceHomeWithSubscriptions,
            hideUpNextRecommendations,
            hideComments
        ].filter { $0 }.count
    }

    public var summaryText: String {
        summaryText(using: .english)
    }

    public func summaryText(using copy: AppCopy) -> String {
        var parts: [String] = []
        if replaceHomeWithSubscriptions {
            parts.append(copy.summarySubscriptionsAndSearch)
        }
        if hideShortsEverywhere || redirectShortsToWatchPlayer {
            parts.append(copy.summaryNoShorts)
        }
        if hideUpNextRecommendations {
            parts.append(copy.summaryNoUpNext)
        }
        return parts.isEmpty ? copy.summaryFiltersPaused : parts.joined(separator: " • ")
    }
}

public struct FrictionLockConfig: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var holdDurationSeconds: Int
    public var autoRelockMinutes: Int?

    public init(
        isEnabled: Bool = true,
        holdDurationSeconds: Int = 10,
        autoRelockMinutes: Int? = 15
    ) {
        self.isEnabled = isEnabled
        self.holdDurationSeconds = max(3, holdDurationSeconds)
        self.autoRelockMinutes = autoRelockMinutes
    }
}
