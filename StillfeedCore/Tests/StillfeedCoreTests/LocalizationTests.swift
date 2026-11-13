import XCTest
@testable import StillfeedCore

final class LocalizationTests: XCTestCase {
    func testSystemLanguageResolution() {
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["pt-BR", "en-US"]), .portuguese)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["es-419"]), .spanish)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["en-GB"]), .english)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["ja-JP"]), .english)
    }

    func testAllLanguagesHaveNonEmptyCopyAndCorrectLocalizedNotices() {
        for lang in ConcreteLanguage.allCases {
            let copy = AppCopy.catalog(for: lang)
            XCTAssertFalse(copy.launcherTagline.isEmpty)
            XCTAssertFalse(copy.settingsTitle.isEmpty)
            XCTAssertFalse(copy.noticeOpenedShortInPlayer.isEmpty)
            XCTAssertFalse(copy.protectionsActiveFormat(5).isEmpty)
        }

        var config = StillfeedConfig()
        config.language = .portuguese
        let decision = NavigationPolicyEngine().evaluate(
            url: URL(string: "https://m.youtube.com/shorts/dQw4w9WgXcQ")!,
            platform: .youtube,
            config: config
        )
        guard case let .redirect(_, notice) = decision else {
            return XCTFail("Expected redirect, got \(decision)")
        }
        XCTAssertEqual(notice, AppCopy.portuguese.noticeOpenedShortInPlayer)
    }

    func testApplyLanguageToPlatformsModifiesEntryURLsAndScripts() {
        var config = StillfeedConfig()
        config.language = .spanish
        config.applyLanguageToPlatforms = true

        let igURL = SocialPlatform.instagram.entryURL(using: config)
        let ytURL = SocialPlatform.youtube.entryURL(using: config)
        XCTAssertTrue(igURL.absoluteString.contains("hl=es"))
        XCTAssertTrue(ytURL.absoluteString.contains("hl=es"))
        XCTAssertTrue(ytURL.absoluteString.contains("persist_hl=1"))

        let ytBundle = ScriptComposer().buildScripts(for: .youtube, config: config)
        XCTAssertTrue(ytBundle.documentStartScript.contains("es-ES"))
    }

    func testLegacyStillfeedConfigDecodesWithoutLanguageFields() throws {
        let legacyJSON = """
        {
          "instagram": {
            "blockReelsFeedAndTab": true,
            "allowSingleReelFromDM": true,
            "blockExploreGridKeepSearch": true,
            "hideSuggestedAndSponsored": true,
            "preferFollowingFeed": false,
            "hideStoriesTray": false
          },
          "youtube": {
            "hideShortsEverywhere": true,
            "redirectShortsToWatchPlayer": true,
            "replaceHomeWithSubscriptions": true,
            "hideUpNextRecommendations": true,
            "hideComments": false
          },
          "frictionLock": {
            "isEnabled": true,
            "holdDurationSeconds": 10,
            "autoRelockMinutes": 15
          }
        }
        """
        let decoded = try JSONDecoder().decode(StillfeedConfig.self, from: Data(legacyJSON.utf8))
        XCTAssertEqual(decoded.language, .system)
        XCTAssertFalse(decoded.applyLanguageToPlatforms)
    }
}
