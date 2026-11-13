import StillfeedCore
import SwiftUI

struct LauncherHomeView: View {
    @Environment(FilterSettingsStore.self) private var store
    @Environment(DeepLinkRouter.self) private var router
    @State private var showingSettings = false
    @State private var showingShortcutsSetup = false

    var body: some View {
        @Bindable var router = router

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    platformCardsSection
                    footerNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .fontWeight(.medium)
                    }
                    .accessibilityLabel("Filter Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingShortcutsSetup) {
                ShortcutsSetupSheet()
            }
            .onChange(of: showingSettings) { _, isPresented in
                if !isPresented {
                    store.refreshClock()
                }
            }
            .onAppear {
                store.refreshClock()
            }
            .fullScreenCover(item: $router.activeSession) { session in
                PlatformBrowserView(platform: session.platform, initialURL: session.initialURL)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(.teal)
                Text("Stillfeed")
                    .font(.largeTitle.bold())
            }

            Text("Intentional social browsing with short-form video traps and algorithmic suggestions removed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: store.isLocked ? "lock.shield.fill" : "lock.open.fill")
                    .foregroundStyle(store.isLocked ? .teal : .orange)
                Text("\(store.config.totalActiveProtections) protections active")
                    .font(.footnote.weight(.medium))
                if !store.isLocked, store.config.frictionLock.isEnabled {
                    Text("• Unlocked")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        }
    }

    private var platformCardsSection: some View {
        VStack(spacing: 14) {
            PlatformLaunchCard(
                platform: .instagram,
                subtitle: store.config.instagram.summaryText,
                accentColor: .pink
            ) {
                router.open(.instagram)
            }

            PlatformLaunchCard(
                platform: .youtube,
                subtitle: store.config.youtube.summaryText,
                accentColor: .red
            ) {
                router.open(.youtube)
            }
        }
    }

    private var footerNote: some View {
        Button {
            showingShortcutsSetup = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Redirect Official Instagram & YouTube Apps")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Set up a 20-second iOS Shortcuts automation so tapping the normal apps opens Stillfeed instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct PlatformLaunchCard: View {
    let platform: SocialPlatform
    let subtitle: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 52, height: 52)
                    Image(systemName: platform.systemImageName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(platform.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
