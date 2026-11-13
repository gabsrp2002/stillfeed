# Stillfeed

**Stillfeed** is an open-source, native iOS SwiftUI + `WKWebView` wrapper app designed for intentional browsing on **Instagram** and **YouTube**—removing short-form video traps (Reels, Shorts), algorithmic Explore grids, and "Up Next" rabbit holes while keeping the parts you actually use.

> **Note:** Because iOS sandboxes third-party apps from modifying the official Instagram or YouTube native apps, Stillfeed wraps their mobile web experiences inside a persistent-session `WKWebView` controlled by navigation rules and CSS/JS filters.

---

## Features

### Instagram
- **DM-Safe Reels Mode:** Hides the Reels tab and blocks the `/reels/` infinite vertical feed, while still letting you watch a single `/reel/<id>` sent in Direct Messages with vertical swipe-to-next-reel locked.
- **No Explore Grid (Search Kept):** Hides the Explore discovery grid while keeping username search and search results usable.
- **Stories + Clean Home Feed:** Keeps Stories from people you follow visible at the top while hiding `"Suggested for you"` posts and posts from accounts you don't follow (`Follow` / `Seguir` header button).
- **Optional Strict Mode:** Toggle **Force Following-Only Feed** (`/?variant=following`) or **Hide Stories Tray** in Settings.

### YouTube
- **No Shorts:** Hides Shorts tabs, shelves, and cards across Home, Search, and Channels.
- **Standard Video Player Redirect:** Automatically redirects `/shorts/<id>` links to the regular `/watch?v=<id>` player.
- **Subscriptions & Search Focus:** Redirects the algorithmic Home feed (`/`) to Subscriptions (`/feed/subscriptions`) and hides the Home tab.
- **No "Up Next" Trap:** Hides related/recommended videos below the player and autoplay end-screen overlays (with an optional toggle to hide comments).

### Focus & iOS Integration
- **Clean Launcher Home:** Deliberately choose between Instagram, YouTube, or Settings—no cross-platform tab bar bouncing.
- **Settings Friction Lock:** Enabling filters is instant; weakening or disabling protections requires a continuous press-and-hold (default 10s) with an optional auto re-lock timer.
- **Deep Links & Shortcuts (`AppIntents`):** Supports `stillfeed://instagram`, `stillfeed://youtube`, `stillfeed://open?url=<encoded_url>`, and native **Shortcuts** actions (*Open Instagram in Stillfeed* / *Open YouTube in Stillfeed*) so you can auto-redirect reflexive taps on the official apps.
- **Multi-Language Support:** Built-in English, Portuguese, and Spanish translations with an option in Settings to apply your chosen language to Instagram and YouTube mobile web.

---

## Project Structure

```text
.
├── StillfeedCore/                 # Pure Swift package (cross-platform macOS + iOS)
│   ├── Package.swift
│   ├── Sources/StillfeedCore/
│   │   ├── Platform.swift         # Platform metadata, quick destinations, allowed auth hosts
│   │   ├── FilterConfig.swift     # Codable filter & friction lock configuration
│   │   ├── NavigationPolicyEngine.swift  # URL routing, scheme blocking, /shorts/ redirects
│   │   ├── DeepLinkParser.swift   # stillfeed:// URL parser
│   │   ├── Localization.swift     # Typed translations (EN/PT/ES) + platform locale helpers
│   │   ├── FrictionLockState.swift
│   │   ├── ScriptComposer.swift
│   │   ├── InstagramScriptBuilder.swift
│   │   └── YouTubeScriptBuilder.swift
│   └── Tests/StillfeedCoreTests/
├── Stillfeed/                     # iOS SwiftUI + WKWebView app target
│   ├── App/StillfeedApp.swift
│   ├── Intents/StillfeedShortcuts.swift
│   ├── State/
│   │   ├── FilterSettingsStore.swift
│   │   └── DeepLinkRouter.swift
│   ├── Views/
│   │   ├── LauncherHomeView.swift
│   │   ├── PlatformBrowserView.swift
│   │   ├── SettingsView.swift
│   │   ├── FrictionChallengeSheet.swift
│   │   └── ShortcutsSetupSheet.swift
│   ├── WebView/
│   │   ├── PlatformWebView.swift
│   │   └── SafariView.swift
│   ├── Resources/Assets.xcassets
│   └── Info.plist
└── Stillfeed.xcodeproj/
```

---

## Installing on Your iPhone (Free Apple ID)

No paid Apple Developer membership or special entitlements are required.

1. **Open the project in Xcode:**
   ```bash
   open Stillfeed.xcodeproj
   ```
2. **Configure signing:**
   - Select the **Stillfeed** project → **Stillfeed** target → **Signing & Capabilities**.
   - Enable **Automatically manage signing**, choose your **Personal Team** (Apple ID), and set a unique **Bundle Identifier** (e.g., `com.<yourname>.stillfeed`).
3. **Prepare your iPhone:**
   - Connect via USB, unlock, and tap **Trust** if prompted.
   - Enable **Developer Mode** on iPhone (*Settings → Privacy & Security → Developer Mode*).
4. **Build & Run (`⌘R`):**
   - Select your iPhone as the run destination and press **`⌘R`**.
   - On first install, trust your developer certificate on iPhone (*Settings → General → VPN & Device Management*).
5. **Optional — Redirect Official Apps:**
   - Open Stillfeed → tap **Redirect Official Instagram & YouTube Apps** (or in Settings) to set up a 20-second iOS Shortcuts automation that opens Stillfeed whenever you tap the normal apps.

*(Free Apple ID sideloaded apps expire after 7 days. Reconnect over USB or Wi-Fi and press `⌘R` in Xcode without deleting the app to refresh the signature while keeping your logins.)*

---

## Development & Testing

Run the core unit tests on macOS:
```bash
swift test --package-path StillfeedCore
```

Verify the iOS app compiles from the CLI:
```bash
xcodebuild -project Stillfeed.xcodeproj \
  -scheme Stillfeed \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
```

---

## Disclaimer

Stillfeed is an independent, personal-use project and is not affiliated with, endorsed by, or associated with Instagram, Meta Platforms, YouTube, or Google. DOM selectors target mobile web layouts (`www.instagram.com` and `m.youtube.com`) and may need periodic updates as those sites evolve.
