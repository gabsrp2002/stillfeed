import Foundation

public struct ScriptBundle: Equatable, Sendable {
    public let documentStartScript: String
    public let documentEndScript: String

    public init(documentStartScript: String, documentEndScript: String) {
        self.documentStartScript = documentStartScript
        self.documentEndScript = documentEndScript
    }
}

public struct ScriptComposer: Sendable {
    public init() {}

    public func buildScripts(for platform: SocialPlatform, config: StillfeedConfig) -> ScriptBundle {
        let bundle: ScriptBundle
        switch platform {
        case .instagram:
            bundle = InstagramScriptBuilder().build(config: config.instagram)
        case .youtube:
            bundle = YouTubeScriptBuilder().build(config: config.youtube)
        }

        guard config.applyLanguageToPlatforms else {
            return bundle
        }

        let resolved = config.language.resolved()
        let languageShim = """
        (function() {
          try {
            Object.defineProperty(navigator, 'language', { get: function() { return '\(resolved.bcp47LanguageTag)'; }, configurable: true });
            Object.defineProperty(navigator, 'languages', { get: function() { return ['\(resolved.bcp47LanguageTag)', '\(resolved.webLocaleTag)']; }, configurable: true });
          } catch (_) {}
        })();
        """
        return ScriptBundle(
            documentStartScript: languageShim + "\n" + bundle.documentStartScript,
            documentEndScript: bundle.documentEndScript
        )
    }

    public func configUpdateScript(for platform: SocialPlatform, config: StillfeedConfig) -> String {
        let json: String
        switch platform {
        case .instagram:
            json = Self.encodeJSON(config.instagram)
        case .youtube:
            json = Self.encodeJSON(config.youtube)
        }
        return "if (window.__stillfeedUpdateConfig) { window.__stillfeedUpdateConfig(\(json)); }"
    }

    static func encodeJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
