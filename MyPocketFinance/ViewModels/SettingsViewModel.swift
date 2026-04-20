import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var settings: UserSettings

    private let service: UserSettingsService

    init(service: UserSettingsService = UserDefaultsSettingsService()) {
        self.service = service
        var loaded = service.load()
        let normalized = Self.canonicalCurrencyCode(loaded.currencyCode)
        if normalized != loaded.currencyCode {
            loaded.currencyCode = normalized
            service.save(loaded)
        }
        self.settings = loaded
        NotificationService.shared.applySettings(self.settings)
    }


    func updateUsername(_ username: String) {
        settings.username = username
        persist()
    }

    func updateProfileImage(_ data: Data?) {
        settings.profileImageData = data
        persist()
    }


    func toggleWeeklySummary() {
        settings.showWeeklySummary.toggle()
        persist()
    }

    func setNotificationsEnabled(_ isOn: Bool) {
        if isOn {
            NotificationService.shared.requestAuthorization { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.settings.enableNotifications = granted
                    self.persist()
                }
            }
        } else {
            settings.enableNotifications = false
            persist()
            NotificationService.shared.cancelDailyReminder()
        }
    }

    func updateNotificationTime(_ date: Date) {
        settings.notificationTime = date
        persist()
    }


    func updateCurrency(code: String) {
        settings.currencyCode = Self.canonicalCurrencyCode(code)
        persist()
    }

    private func persist() {
        service.save(settings)
        NotificationService.shared.applySettings(settings)
        NotificationCenter.default.post(name: .userSettingsDidChange, object: nil)
    }

    private static func canonicalCurrencyCode(_ code: String) -> String {
        switch code.uppercased() {
        case "EUR": return "EUR"
        default: return "USD"
        }
    }
}

