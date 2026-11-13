import Foundation

public struct FrictionLockState: Equatable, Sendable {
    public private(set) var unlockedUntil: Date?

    public init(unlockedUntil: Date? = nil) {
        self.unlockedUntil = unlockedUntil
    }

    public func isLocked(config: FrictionLockConfig, now: Date = Date()) -> Bool {
        guard config.isEnabled else { return false }
        guard let unlockedUntil else { return true }
        return now >= unlockedUntil
    }

    public func remainingUnlockSeconds(now: Date = Date()) -> Int? {
        guard let unlockedUntil, unlockedUntil > now else { return nil }
        return Int(ceil(unlockedUntil.timeIntervalSince(now)))
    }

    public mutating func unlock(config: FrictionLockConfig, now: Date = Date()) {
        if let minutes = config.autoRelockMinutes, minutes > 0 {
            unlockedUntil = now.addingTimeInterval(TimeInterval(minutes * 60))
        } else {
            unlockedUntil = .distantFuture
        }
    }

    public mutating func relock() {
        unlockedUntil = nil
    }
}
