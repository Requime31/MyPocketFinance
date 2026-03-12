import Foundation
import UIKit

struct UserSettings: Codable, Equatable {
    var hasCompletedOnboarding: Bool
    var username: String
    var currencyCode: String
    var showWeeklySummary: Bool
    var enableNotifications: Bool
    var notificationTime: Date
    var profileImageData: Data?
    var preferredTheme: String
    
    static let `default` = UserSettings(
        hasCompletedOnboarding: false,
        username: UserSettings.defaultUsername,
        currencyCode: Locale.current.currency?.identifier ?? "USD",
        showWeeklySummary: true,
        enableNotifications: true,
        notificationTime: UserSettings.defaultNotificationTime,
        profileImageData: nil,
        preferredTheme: "system"
    )

    private static var defaultUsername: String {
        if let name = PersonNameComponentsFormatter().personNameComponents(from: UIDevice.current.name)?.givenName,
           !name.isEmpty {
            return name
        }
        return "Guest"
    }

    private static var defaultNotificationTime: Date {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case username
        case currencyCode
        case showWeeklySummary
        case enableNotifications
        case notificationTime
        case profileImageData
        case preferredTheme
    }

    init(
        hasCompletedOnboarding: Bool,
        username: String,
        currencyCode: String,
        showWeeklySummary: Bool,
        enableNotifications: Bool,
        notificationTime: Date,
        profileImageData: Data?,
        preferredTheme: String
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.username = username
        self.currencyCode = currencyCode
        self.showWeeklySummary = showWeeklySummary
        self.enableNotifications = enableNotifications
        self.notificationTime = notificationTime
        self.profileImageData = profileImageData
        self.preferredTheme = preferredTheme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? UserSettings.defaultUsername
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
            ?? (Locale.current.currency?.identifier ?? "USD")
        showWeeklySummary = try container.decodeIfPresent(Bool.self, forKey: .showWeeklySummary) ?? true
        enableNotifications = try container.decodeIfPresent(Bool.self, forKey: .enableNotifications) ?? true
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime)
            ?? UserSettings.defaultNotificationTime
        profileImageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData)
        preferredTheme = try container.decodeIfPresent(String.self, forKey: .preferredTheme) ?? "system"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(username, forKey: .username)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(showWeeklySummary, forKey: .showWeeklySummary)
        try container.encode(enableNotifications, forKey: .enableNotifications)
        try container.encode(notificationTime, forKey: .notificationTime)
        try container.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try container.encode(preferredTheme, forKey: .preferredTheme)
    }
}

