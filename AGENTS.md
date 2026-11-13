# AGENTS.md

Guidance for AI coding agents working in the **Stillfeed** repository.

## Architecture & Module Boundaries

- **`StillfeedCore/` (Local Swift Package — iOS 17+ & macOS 14+)**
  - Contains all pure Swift, platform-agnostic business logic so it can be fast-tested on macOS via `swift test`.
  - Put URL evaluation rules, deep-link parsing, filter configuration models, friction-lock state logic, and injected CSS/JS generators here—not inside SwiftUI views.
- **`Stillfeed/` (iOS App Target)**
  - SwiftUI UI, `WKWebView` integration (`PlatformWebView`), `UserDefaults` persistence (`FilterSettingsStore`), `DeepLinkRouter`, and `AppIntents` (`StillfeedShortcuts`).
  - **Important:** `Stillfeed.xcodeproj/project.pbxproj` uses explicit `PBXFileReference` / `PBXBuildFile` entries for files in `Stillfeed/`. Whenever you add, rename, or delete a Swift file under `Stillfeed/`, update `Stillfeed.xcodeproj/project.pbxproj` accordingly. Files added under `StillfeedCore/` are picked up automatically by SPM.

## Core Design Invariants

1. **Two-Layer SPA Filtering:** Both Instagram (`www.instagram.com`) and YouTube (`m.youtube.com`) are Single-Page Applications. Keep navigation rules enforced in **both**:
   - Native layer (`NavigationPolicyEngine` via `WKNavigationDelegate` + KVO on `webView.url`).
   - Client-side JS layer (`history.pushState` / `replaceState` / `popstate` + `MutationObserver`).
2. **Idempotent Redirects:** Every `.redirect(targetURL, ...)` returned by `NavigationPolicyEngine` must evaluate to `.allow` when `targetURL` is passed back into `NavigationPolicyEngine.evaluate(...)` to prevent redirect loops.
3. **Preserve Auth & Session Flows:** Never redirect or block login, 2FA, consent, DM, or OAuth hosts/paths (`/accounts/`, `/direct/`, `/challenge/`, `facebook.com`, `meta.com`, `SocialPlatform.isGoogleHost(_:)`). Keep `ownsHost(_:)` accurate so in-platform auth flows do not pop open `SFSafariViewController`.
4. **Backwards-Compatible Persistence:** When adding or modifying properties in `StillfeedConfig` (`FilterConfig.swift`), preserve backwards-compatible `Codable` decoding or handle migration in `FilterSettingsStore` so existing `UserDefaults` data does not reset unexpectedly.
5. **Passive DOM Filtering:** Keep Stillfeed focused on removing algorithmic distractions (Reels, Shorts, Explore, Suggested posts, Up Next) via passive CSS/DOM rules and navigation policies—do not add ad/tracker blockers or automated UI clickers unless explicitly requested.

## Verification Commands

Always run both checks after code changes:

```bash
# 1. Unit tests (macOS)
swift test --package-path StillfeedCore

# 2. Unsigned iOS app compilation check
xcodebuild -project Stillfeed.xcodeproj \
  -scheme Stillfeed \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
```
