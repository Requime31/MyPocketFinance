import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    private let reminderIdentifier = "daily_spend_reminder"

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion?(granted)
                }
            case .authorized, .provisional:
                completion?(true)
            default:
                completion?(false)
            }
        }
    }

    func applySettings(_ settings: UserSettings) {
        if settings.enableNotifications {
            scheduleDailyReminder(at: settings.notificationTime)
        } else {
            cancelDailyReminder()
        }
    }

    func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            self.cancelDailyReminder()

            let calendar = Calendar.current
            var components = calendar.dateComponents([.hour, .minute], from: time)
            components.calendar = calendar

            let content = UNMutableNotificationContent()
            content.title = "MyPocketFinance"
            content.body = Self.randomReminderBody()
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: self.reminderIdentifier,
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    private static func randomReminderBody() -> String {
        let variants = [
            "Пора заглянуть в MyPocketFinance и записать сегодняшние траты и доходы.",
            "Не забудьте обновить свои расходы и доходы за день.",
            "Проверьте свои финансы: добавьте новые операции по расходам и доходам."
        ]

        return variants.randomElement() ?? variants[0]
    }
}

