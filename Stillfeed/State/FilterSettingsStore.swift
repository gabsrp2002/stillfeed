import Foundation
import Observation
import StillfeedCore
import SwiftUI

@MainActor
@Observable
public final class FilterSettingsStore {
    private static let legacyStorageKey = "stillfeed.config.v1"
    private static let storageKey = "stillfeed.config.v2"

    public var config: StillfeedConfig {
        didSet {
            save()
        }
    }

    public var frictionState: FrictionLockState = FrictionLockState()
    public var now: Date = Date()

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(StillfeedConfig.self, from: data) {
            self.config = decoded
        } else if let legacyData = userDefaults.data(forKey: Self.legacyStorageKey),
                  var migrated = try? JSONDecoder().decode(StillfeedConfig.self, from: legacyData) {
            // Migrate v1 -> v2 so Stories from followed accounts appear on Home by default.
            migrated.instagram.preferFollowingFeed = false
            self.config = migrated
            save()
        } else {
            self.config = StillfeedConfig()
        }
    }

    public var isLocked: Bool {
        frictionState.isLocked(config: config.frictionLock, now: now)
    }

    public var remainingUnlockSeconds: Int? {
        guard config.frictionLock.isEnabled else { return nil }
        return frictionState.remainingUnlockSeconds(now: now)
    }

    public func refreshClock() {
        now = Date()
    }

    public func unlockWithFrictionChallenge() {
        now = Date()
        frictionState.unlock(config: config.frictionLock, now: now)
    }

    public func relockNow() {
        now = Date()
        frictionState.relock()
    }

    /// Creates a SwiftUI binding that allows enabling protections instantly,
    /// while requiring a Friction Lock unlock before weakening/disabling any protection.
    public func protectionBinding(
        for keyPath: WritableKeyPath<StillfeedConfig, Bool>,
        onRequireUnlock: @escaping (@escaping () -> Void) -> Void
    ) -> Binding<Bool> {
        Binding(
            get: { self.config[keyPath: keyPath] },
            set: { newValue in
                self.refreshClock()
                if newValue || !self.isLocked {
                    self.config[keyPath: keyPath] = newValue
                } else {
                    onRequireUnlock { [weak self] in
                        self?.config[keyPath: keyPath] = false
                    }
                }
            }
        )
    }

    /// Special binding for `allowSingleReelFromDM`: turning it ON relaxes strictness,
    /// so enabling it when locked requires friction, while turning it OFF is instant.
    public func relaxableBinding(
        for keyPath: WritableKeyPath<StillfeedConfig, Bool>,
        onRequireUnlock: @escaping (@escaping () -> Void) -> Void
    ) -> Binding<Bool> {
        Binding(
            get: { self.config[keyPath: keyPath] },
            set: { newValue in
                self.refreshClock()
                if !newValue || !self.isLocked {
                    self.config[keyPath: keyPath] = newValue
                } else {
                    onRequireUnlock { [weak self] in
                        self?.config[keyPath: keyPath] = true
                    }
                }
            }
        )
    }

    private func save() {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: Self.storageKey)
        }
    }
}
