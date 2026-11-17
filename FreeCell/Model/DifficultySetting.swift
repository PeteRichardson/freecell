import Foundation

/// The difficulty of the next new game. The player's iCloud account syncs it to their other
/// devices, and the device keeps a copy for when iCloud is not available. The last change wins.
@MainActor @Observable
final class DifficultySetting {
    static let key = "difficulty"

    var difficulty: Difficulty {
        didSet {
            guard difficulty != oldValue else { return }
            local.set(difficulty.rawValue, forKey: Self.key)
            cloud?.set(difficulty.rawValue, forKey: Self.key)
        }
    }

    private let local: UserDefaults
    private let cloud: NSUbiquitousKeyValueStore?
    @ObservationIgnored private var observer: NSObjectProtocol?

    /// - Parameters:
    ///   - local: The store on this device.
    ///   - cloud: The iCloud store, or nil to use only the store on this device (for tests).
    init(local: UserDefaults = .standard, cloud: NSUbiquitousKeyValueStore? = .default) {
        self.local = local
        self.cloud = cloud
        let stored = cloud?.string(forKey: Self.key) ?? local.string(forKey: Self.key)
        difficulty = stored.flatMap(Difficulty.init(rawValue:)) ?? .easy

        guard let cloud else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.loadFromCloud() }
        }
        cloud.synchronize()
    }

    /// Takes a change that came from another device.
    private func loadFromCloud() {
        guard let stored = cloud?.string(forKey: Self.key), let difficulty = Difficulty(rawValue: stored) else { return }
        self.difficulty = difficulty
    }
}
