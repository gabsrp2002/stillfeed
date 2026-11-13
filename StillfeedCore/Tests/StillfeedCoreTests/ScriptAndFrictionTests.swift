import XCTest
@testable import StillfeedCore

final class ScriptAndFrictionTests: XCTestCase {
    func testScriptComposerIncludesConfigFlags() {
        var config = StillfeedConfig()
        config.instagram.hideStoriesTray = true
        config.youtube.hideComments = true

        let composer = ScriptComposer()
        let igScripts = composer.buildScripts(for: .instagram, config: config)
        XCTAssertTrue(igScripts.documentStartScript.contains("\"hideStoriesTray\":true"))
        XCTAssertTrue(igScripts.documentEndScript.contains("__stillfeedUpdateConfig"))

        let ytScripts = composer.buildScripts(for: .youtube, config: config)
        XCTAssertTrue(ytScripts.documentStartScript.contains("\"hideComments\":true"))
        XCTAssertTrue(ytScripts.documentEndScript.contains("watchURLForShortsPath"))

        let update = composer.configUpdateScript(for: .youtube, config: config)
        XCTAssertTrue(update.contains("window.__stillfeedUpdateConfig"))
        XCTAssertTrue(update.contains("\"hideComments\":true"))
    }

    func testFrictionLockStateLifecycle() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let config = FrictionLockConfig(isEnabled: true, holdDurationSeconds: 10, autoRelockMinutes: 15)
        var state = FrictionLockState()

        XCTAssertTrue(state.isLocked(config: config, now: start))
        XCTAssertNil(state.remainingUnlockSeconds(now: start))

        state.unlock(config: config, now: start)
        XCTAssertFalse(state.isLocked(config: config, now: start.addingTimeInterval(60)))
        XCTAssertEqual(state.remainingUnlockSeconds(now: start.addingTimeInterval(60)), 14 * 60)

        // Automatically re-locks after 15 minutes
        XCTAssertTrue(state.isLocked(config: config, now: start.addingTimeInterval(15 * 60)))

        // Manual re-lock works immediately
        state.unlock(config: config, now: start)
        state.relock()
        XCTAssertTrue(state.isLocked(config: config, now: start))
    }
}
