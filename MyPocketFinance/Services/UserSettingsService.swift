import Foundation

protocol UserSettingsService {
    func load() -> UserSettings
    func save(_ settings: UserSettings)
}

final class UserDefaultsSettingsService: UserSettingsService {
    private let key = "FinTrack.UserSettings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UserSettings {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(UserSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }

    func save(_ settings: UserSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}

