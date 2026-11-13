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
        let copy = store.copy

        NavigationStack {
            Form {
                frictionStatusSection(copy)
                languageSection(copy)
                instagramSection(copy)
                youtubeSection(copy)
                frictionConfigSection(copy)
                automationSection(copy)
                sessionManagementSection(copy)
            }
            .navigationTitle(copy.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(copy.doneButton) { dismiss() }
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
                copy.clearSessionAlertTitleFormat(platformPendingClear?.displayName ?? ""),
                isPresented: Binding(
                    get: { platformPendingClear != nil },
                    set: { if !$0 { platformPendingClear = nil } }
                )
            ) {
                Button(copy.clearSessionAlertAction, role: .destructive) {
                    if let target = platformPendingClear {
                        Task {
                            await SessionStorageCleaner.clearCookies(for: target)
                            statusBanner = copy.clearedSessionBannerFormat(target.displayName)
                        }
                    }
                    platformPendingClear = nil
                }
                Button(copy.cancelButton, role: .cancel) {
                    platformPendingClear = nil
                }
            } message: {
                Text(copy.clearSessionAlertMessage)
            }
        }
        .onAppear {
            store.refreshClock()
        }
    }

    private func frictionStatusSection(_ copy: AppCopy) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: store.isLocked ? "lock.shield.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundStyle(store.isLocked ? .teal : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isLocked ? copy.frictionActiveTitle : copy.frictionUnlockedTitle)
                        .font(.subheadline.weight(.semibold))
                    if store.isLocked {
                        Text(copy.frictionHoldSubtitleFormat(store.config.frictionLock.holdDurationSeconds))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let remaining = store.remainingUnlockSeconds {
                        Text(copy.frictionAutoLocksFormat(max(1, remaining / 60)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(copy.frictionAdjustFreely)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if !store.isLocked && store.config.frictionLock.isEnabled {
                    Button(copy.lockNowButton) {
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

    private func languageSection(_ copy: AppCopy) -> some View {
        @Bindable var store = store
        return Section {
            Picker(copy.appLanguageLabel, selection: $store.config.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.label(using: copy)).tag(lang)
                }
            }
            Toggle(copy.applyLanguageToPlatformsLabel, isOn: $store.config.applyLanguageToPlatforms)
        } header: {
            Text(copy.languageSectionTitle)
        } footer: {
            Text(copy.applyLanguageToPlatformsFooter)
        }
    }

    private func instagramSection(_ copy: AppCopy) -> some View {
        Section(copy.igSectionTitle) {
            Toggle(
                copy.igBlockReels,
                isOn: store.protectionBinding(for: \.instagram.blockReelsFeedAndTab, onRequireUnlock: requestUnlock)
            )
            if store.config.instagram.blockReelsFeedAndTab {
                Toggle(
                    copy.igAllowSingleReelFromDM,
                    isOn: store.relaxableBinding(for: \.instagram.allowSingleReelFromDM, onRequireUnlock: requestUnlock)
                )
            }
            Toggle(
                copy.igBlockExploreKeepSearch,
                isOn: store.protectionBinding(for: \.instagram.blockExploreGridKeepSearch, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.igHideSuggestedPosts,
                isOn: store.protectionBinding(for: \.instagram.hideSuggestedAndSponsored, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.igForceFollowingOnly,
                isOn: store.protectionBinding(for: \.instagram.preferFollowingFeed, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.igHideStoriesTray,
                isOn: store.protectionBinding(for: \.instagram.hideStoriesTray, onRequireUnlock: requestUnlock)
            )
        }
    }

    private func youtubeSection(_ copy: AppCopy) -> some View {
        Section(copy.ytSectionTitle) {
            Toggle(
                copy.ytHideShorts,
                isOn: store.protectionBinding(for: \.youtube.hideShortsEverywhere, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.ytOpenShortsInNormalPlayer,
                isOn: store.protectionBinding(for: \.youtube.redirectShortsToWatchPlayer, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.ytReplaceHomeWithSubscriptions,
                isOn: store.protectionBinding(for: \.youtube.replaceHomeWithSubscriptions, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.ytHideUpNext,
                isOn: store.protectionBinding(for: \.youtube.hideUpNextRecommendations, onRequireUnlock: requestUnlock)
            )
            Toggle(
                copy.ytHideComments,
                isOn: store.protectionBinding(for: \.youtube.hideComments, onRequireUnlock: requestUnlock)
            )
        }
    }

    private func frictionConfigSection(_ copy: AppCopy) -> some View {
        Section(copy.frictionSettingsSectionTitle) {
            Toggle(
                copy.requireHoldToDisable,
                isOn: store.protectionBinding(for: \.frictionLock.isEnabled, onRequireUnlock: requestUnlock)
            )

            Picker(
                copy.holdDurationLabel,
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
                Text(copy.secondsOptionFormat(5)).tag(5)
                Text(copy.secondsOptionFormat(10)).tag(10)
                Text(copy.secondsOptionFormat(20)).tag(20)
            }

            Picker(
                copy.autoRelockAfterLabel,
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
                Text(copy.minutesOptionFormat(5)).tag(5)
                Text(copy.minutesOptionFormat(15)).tag(15)
                Text(copy.minutesOptionFormat(30)).tag(30)
                Text(copy.manualOnlyOption).tag(0)
            }
        }
    }

    private func automationSection(_ copy: AppCopy) -> some View {
        Section(copy.appRedirectsSectionTitle) {
            Button {
                showingShortcutsSetup = true
            } label: {
                Label(copy.redirectOfficialAppsButton, systemImage: "bolt.badge.checkmark")
            }
        }
    }

    private func sessionManagementSection(_ copy: AppCopy) -> some View {
        Section(copy.sessionsSectionTitle) {
            Button(copy.clearInstagramSession, role: .destructive) {
                platformPendingClear = .instagram
            }
            Button(copy.clearYouTubeSession, role: .destructive) {
                platformPendingClear = .youtube
            }
        }
    }

    private func requestUnlock(_ action: @escaping () -> Void) {
        pendingUnlockAction = action
        showingFrictionSheet = true
    }
}
