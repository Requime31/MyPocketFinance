import Foundation
import os.log

protocol UserSettingsService {
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}

final class UserDefaultsSettingsService: UserSettingsService {
    private let key = "FinTrack.UserSettings"
    private let defaults: UserDefaults

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MyPocketFinance",
        category: "UserSettings"
    )

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSettings {
        guard let data = defaults.data(forKey: key) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(UserSettings.self, from: data)
        } catch {
            Self.log.error("Failed to decode UserSettings: \(error.localizedDescription, privacy: .public)")
            return .default
        }
    }

    func save(_ settings: UserSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: key)
        } catch {
            Self.log.error("Failed to encode UserSettings: \(error.localizedDescription, privacy: .public)")
        }
    }
}

extension Notification.Name {
    static let userSettingsDidChange = Notification.Name("userSettingsDidChange")
}

