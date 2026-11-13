import Observation
import StillfeedCore
import SwiftUI
import WebKit

@MainActor
@Observable
final class WebBrowserController {
    var canGoBack = false
    var canGoForward = false
    var isLoading = false
    var estimatedProgress: Double = 0
    var currentURL: URL?
    var noticeMessage: String?
    var externalURL: IdentifiableURL?

    fileprivate weak var webView: WKWebView?
    private var noticeDismissTask: Task<Void, Never>?

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func load(url: URL, config: StillfeedConfig? = nil, platform: SocialPlatform? = nil) {
        var resolvedURL = url
        if let config, let platform {
            resolvedURL = platform.applyingLanguageIfNeeded(to: url, config: config)
        }
        webView?.load(PlatformWebView.makeRequest(for: resolvedURL, config: config))
    }

    func pushUpdatedConfig(_ config: StillfeedConfig, platform: SocialPlatform) {
        let js = ScriptComposer().configUpdateScript(for: platform, config: config)
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func showNotice(_ message: String) {
        noticeDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            noticeMessage = message
        }
        noticeDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                self?.noticeMessage = nil
            }
        }
    }
}

struct PlatformWebView: UIViewRepresentable {
    let platform: SocialPlatform
    let initialURL: URL?
    let config: StillfeedConfig
    let controller: WebBrowserController

    private static let safariCompatibleMobileUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    static func makeRequest(for url: URL, config: StillfeedConfig?) -> URLRequest {
        var request = URLRequest(url: url)
        if let config, config.applyLanguageToPlatforms {
            request.setValue(config.language.resolved().acceptLanguageHeader, forHTTPHeaderField: "Accept-Language")
        }
        return request
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(platform: platform, config: config, controller: controller)
    }

    func makeUIView(context: Context) -> WKWebView {
        let wkConfig = WKWebViewConfiguration()
        wkConfig.websiteDataStore = .default()
        wkConfig.allowsInlineMediaPlayback = true
        wkConfig.mediaTypesRequiringUserActionForPlayback = []
        wkConfig.defaultWebpagePreferences.preferredContentMode = .mobile

        let scripts = ScriptComposer().buildScripts(for: platform, config: config)
        let contentController = WKUserContentController()
        contentController.addUserScript(
            WKUserScript(
                source: scripts.documentStartScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        contentController.addUserScript(
            WKUserScript(
                source: scripts.documentEndScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        wkConfig.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: wkConfig)
        webView.customUserAgent = Self.safariCompatibleMobileUserAgent
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic

        context.coordinator.attachObservers(to: webView)
        controller.webView = webView

        let rawStartURL = initialURL ?? platform.entryURL(using: config)
        let startURL = platform.applyingLanguageIfNeeded(to: rawStartURL, config: config)
        webView.load(Self.makeRequest(for: startURL, config: config))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.config != config {
            context.coordinator.config = config
            controller.pushUpdatedConfig(config, platform: platform)
        }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let platform: SocialPlatform
        var config: StillfeedConfig
        let controller: WebBrowserController
        private let policyEngine = NavigationPolicyEngine()
        private var observations: [NSKeyValueObservation] = []

        init(platform: SocialPlatform, config: StillfeedConfig, controller: WebBrowserController) {
            self.platform = platform
            self.config = config
            self.controller = controller
        }

        func attachObservers(to webView: WKWebView) {
            observations = [
                webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] view, _ in
                    Task { @MainActor in self?.controller.canGoBack = view.canGoBack }
                },
                webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] view, _ in
                    Task { @MainActor in self?.controller.canGoForward = view.canGoForward }
                },
                webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] view, _ in
                    Task { @MainActor in self?.controller.isLoading = view.isLoading }
                },
                webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] view, _ in
                    Task { @MainActor in self?.controller.estimatedProgress = view.estimatedProgress }
                },
                webView.observe(\.url, options: [.initial, .new]) { [weak self] view, _ in
                    Task { @MainActor in
                        guard let self, let url = view.url else { return }
                        self.controller.currentURL = url
                        self.enforceSPAURL(url, in: view)
                    }
                }
            ]
        }

        private func enforceSPAURL(_ url: URL, in webView: WKWebView) {
            let decision = policyEngine.evaluate(
                url: url,
                platform: platform,
                config: config,
                isMainFrame: true
            )
            switch decision {
            case .allow, .cancelAppScheme, .openExternally:
                break
            case let .redirect(targetURL, notice):
                if targetURL != url {
                    if let notice { controller.showNotice(notice) }
                    webView.load(PlatformWebView.makeRequest(for: targetURL, config: config))
                }
            case let .blockWithFallback(fallbackURL, reason):
                controller.showNotice(reason)
                if fallbackURL != url {
                    webView.load(PlatformWebView.makeRequest(for: fallbackURL, config: config))
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            let decision = policyEngine.evaluate(
                url: url,
                platform: platform,
                config: config,
                isMainFrame: isMainFrame
            )

            switch decision {
            case .allow:
                decisionHandler(.allow)

            case .cancelAppScheme:
                decisionHandler(.cancel)

            case let .openExternally(externalURL):
                decisionHandler(.cancel)
                controller.externalURL = IdentifiableURL(url: externalURL)

            case let .redirect(targetURL, notice):
                decisionHandler(.cancel)
                if let notice {
                    controller.showNotice(notice)
                }
                webView.load(PlatformWebView.makeRequest(for: targetURL, config: config))

            case let .blockWithFallback(fallbackURL, reason):
                decisionHandler(.cancel)
                controller.showNotice(reason)
                webView.load(PlatformWebView.makeRequest(for: fallbackURL, config: config))
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Handle target="_blank" links cleanly inside the same navigation policy.
            if let url = navigationAction.request.url {
                let decision = policyEngine.evaluate(url: url, platform: platform, config: config, isMainFrame: true)
                switch decision {
                case .allow:
                    webView.load(PlatformWebView.makeRequest(for: url, config: config))
                case let .redirect(target, notice):
                    if let notice { controller.showNotice(notice) }
                    webView.load(PlatformWebView.makeRequest(for: target, config: config))
                case let .blockWithFallback(fallback, reason):
                    controller.showNotice(reason)
                    webView.load(PlatformWebView.makeRequest(for: fallback, config: config))
                case let .openExternally(externalURL):
                    controller.externalURL = IdentifiableURL(url: externalURL)
                case .cancelAppScheme:
                    break
                }
            }
            return nil
        }
    }
}

enum SessionStorageCleaner {
    static func clearCookies(for platform: SocialPlatform) async {
        let dataStore = WKWebsiteDataStore.default()
        let records = await dataStore.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        let matching = records.filter { record in
            let name = record.displayName.lowercased()
            switch platform {
            case .instagram:
                return name.contains("instagram") || name.contains("facebook")
            case .youtube:
                return name.contains("youtube") || name.contains("google")
            }
        }
        await dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: matching)
    }
}
