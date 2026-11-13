import XCTest
@testable import StillfeedCore

final class DeepLinkParserTests: XCTestCase {
    private let parser = DeepLinkParser()

    func testPlatformDeepLinks() {
        XCTAssertEqual(
            parser.parse(URL(string: "stillfeed://instagram")!),
            DeepLinkTarget(platform: .instagram, initialURL: nil)
        )
        XCTAssertEqual(
            parser.parse(URL(string: "stillfeed://youtube")!),
            DeepLinkTarget(platform: .youtube, initialURL: nil)
        )
    }

    func testOpenQueryDeepLinkMatchesOwningPlatform() {
        let ytDeepLink = URL(string: "stillfeed://open?url=https%3A%2F%2Fm.youtube.com%2Fshorts%2FdQw4w9WgXcQ")!
        XCTAssertEqual(
            parser.parse(ytDeepLink),
            DeepLinkTarget(
                platform: .youtube,
                initialURL: URL(string: "https://m.youtube.com/shorts/dQw4w9WgXcQ")!
            )
        )

        let igDeepLink = URL(string: "stillfeed://open?url=https%3A%2F%2Fwww.instagram.com%2Freel%2FCx123%2F")!
        XCTAssertEqual(
            parser.parse(igDeepLink),
            DeepLinkTarget(
                platform: .instagram,
                initialURL: URL(string: "https://www.instagram.com/reel/Cx123/")!
            )
        )
    }

    func testUnsupportedHostsAndSchemesReturnNil() {
        XCTAssertNil(parser.parse(URL(string: "https://stillfeed.app/instagram")!))
        XCTAssertNil(parser.parse(URL(string: "stillfeed://unknown")!))
        XCTAssertNil(parser.parse(URL(string: "stillfeed://open?url=https%3A%2F%2Fexample.com")!))
        XCTAssertNil(parser.parse(URL(string: "stillfeed://open?url=javascript:alert(1)")!))
    }
}
