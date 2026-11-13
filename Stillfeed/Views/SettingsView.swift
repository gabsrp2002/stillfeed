import StillfeedCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FilterSettingsStore.self) private var store

    @State private var showingFrictionSheet = false
    @State private var showingShortcutsSetup = false
    @State private var pendingUnlockAction: (() -> Void)?
    @State private var platformPendingClear: SocialPlatform?
    @State private var statusBanner: String?

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                frictionStatusSection
                instagramSection
                youtubeSection
                frictionConfigSection
                automationSection
                sessionManagementSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingFrictionSheet) {
                FrictionChallengeSheet(
                    holdDurationSeconds: store.config.frictionLock.holdDurationSeconds
                ) {
                    store.unlockWithFrictionChallenge()
                    pendingUnlockAction?()
                    pendingUnlockAction = nil
                }
            }
            .sheet(isPresented: $showingShortcutsSetup) {
                ShortcutsSetupSheet()
            }
            .alert(
                "Clear \(platformPendingClear?.displayName ?? "") Session?",
                isPresented: Binding(
                    get: { platformPendingClear != nil },
                    set: { if !$0 { platformPendingClear = nil } }
                )
            ) {
                Button("Log Out & Clear Cookies", role: .destructive) {
                    if let target = platformPendingClear {
                        Task {
                            await SessionStorageCleaner.clearCookies(for: target)
                            statusBanner = "Cleared \(target.displayName) session."
                        }
                    }
                    platformPendingClear = nil
                }
                Button("Cancel", role: .cancel) {
                    platformPendingClear = nil
                }
            } message: {
                Text("You will need to sign in again the next time you open this platform.")
            }
        }
        .onAppear {
            store.refreshClock()
        }
    }

    private var frictionStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: store.isLocked ? "lock.shield.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(store.isLocked ? .teal : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isLocked ? "Friction Lock Active" : "Filters Temporarily Unlocked")
                        .font(.subheadline.weight(.semibold))
                    if store.isLocked {
                        Text("Turning protections off requires a \(store.config.frictionLock.holdDurationSeconds)s hold.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let remaining = store.remainingUnlockSeconds {
                        Text("Auto-locks in \(max(1, remaining / 60)) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You can adjust protections freely.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if !store.isLocked && store.config.frictionLock.isEnabled {
                    Button("Lock Now") {
                        store.relockNow()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                }
            }

            if let statusBanner {
                Text(statusBanner)
                    .font(.caption)
                    .foregroundStyle(.teal)
            }
        }
    }

    private var instagramSection: some View {
        Section("Instagram") {
            Toggle(
                "Block Reels Feed & Tab",
                isOn: store.protectionBinding(for: \.instagram.blockReelsFeedAndTab, onRequireUnlock: requestUnlock)
            )
            if store.config.instagram.blockReelsFeedAndTab {
                Toggle(
                    "Allow Single Reel from DMs",
                    isOn: store.relaxableBinding(for: \.instagram.allowSingleReelFromDM, onRequireUnlock: requestUnlock)
                )
            }
            Toggle(
                "Block Explore Grid (Keep Search)",
                isOn: store.protectionBinding(for: \.instagram.blockExploreGridKeepSearch, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Hide Suggested Posts",
                isOn: store.protectionBinding(for: \.instagram.hideSuggestedAndSponsored, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Force Following-Only Feed (Hides Stories)",
                isOn: store.protectionBinding(for: \.instagram.preferFollowingFeed, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Hide Stories Tray",
                isOn: store.protectionBinding(for: \.instagram.hideStoriesTray, onRequireUnlock: requestUnlock)
            )
        }
    }

    private var youtubeSection: some View {
        Section("YouTube") {
            Toggle(
                "Hide Shorts Everywhere",
                isOn: store.protectionBinding(for: \.youtube.hideShortsEverywhere, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Open /shorts/ in Normal Player",
                isOn: store.protectionBinding(for: \.youtube.redirectShortsToWatchPlayer, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Replace Home with Subscriptions",
                isOn: store.protectionBinding(for: \.youtube.replaceHomeWithSubscriptions, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Hide \"Up Next\" Recommendations",
                isOn: store.protectionBinding(for: \.youtube.hideUpNextRecommendations, onRequireUnlock: requestUnlock)
            )
            Toggle(
                "Hide Video Comments",
                isOn: store.protectionBinding(for: \.youtube.hideComments, onRequireUnlock: requestUnlock)
            )
        }
    }

    private var frictionConfigSection: some View {
        Section("Friction Lock Settings") {
            Toggle(
                "Require Hold to Disable Filters",
                isOn: store.protectionBinding(for: \.frictionLock.isEnabled, onRequireUnlock: requestUnlock)
            )

            Picker(
                "Hold Duration",
                selection: Binding(
                    get: { store.config.frictionLock.holdDurationSeconds },
                    set: { newVal in
                        if newVal >= store.config.frictionLock.holdDurationSeconds || !store.isLocked {
                            store.config.frictionLock.holdDurationSeconds = newVal
                        } else {
                            requestUnlock {
                                store.config.frictionLock.holdDurationSeconds = newVal
                            }
                        }
                    }
                )
            ) {
                Text("5 seconds").tag(5)
                Text("10 seconds").tag(10)
                Text("20 seconds").tag(20)
            }

            Picker(
                "Auto Re-Lock After",
                selection: Binding(
                    get: { store.config.frictionLock.autoRelockMinutes ?? 0 },
                    set: { newVal in
                        let optionalVal: Int? = newVal == 0 ? nil : newVal
                        if !store.isLocked {
                            store.config.frictionLock.autoRelockMinutes = optionalVal
                        } else {
                            requestUnlock {
                                store.config.frictionLock.autoRelockMinutes = optionalVal
                            }
                        }
                    }
                )
            ) {
                Text("5 minutes").tag(5)
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("Manual only").tag(0)
            }
        }
    }

    private var automationSection: some View {
        Section("App Redirects & Deep Links") {
            Button {
                showingShortcutsSetup = true
            } label: {
                Label("Redirect Official Apps via Shortcuts", systemImage: "bolt.badge.checkmark")
            }
        }
    }

    private var sessionManagementSection: some View {
        Section("Sessions") {
            Button("Clear Instagram Session", role: .destructive) {
                platformPendingClear = .instagram
            }
            Button("Clear YouTube Session", role: .destructive) {
                platformPendingClear = .youtube
            }
        }
    }

    private func requestUnlock(_ action: @escaping () -> Void) {
        pendingUnlockAction = action
        showingFrictionSheet = true
    }
}
