import Foundation
import SwiftUI
import Combine

struct OnboardingPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImageName: String
    let gradient: [Color]
}

final class OnboardingViewModel: ObservableObject {
    @Published var currentPageIndex: Int = 0
    @Published private(set) var completed: Bool = false

    private let settingsService: UserSettingsService

    let pages: [OnboardingPage]

    init(settingsService: UserSettingsService = UserDefaultsSettingsService()) {
        self.settingsService = settingsService

        // Configure the three onboarding pages
        self.pages = [
            OnboardingPage(
                title: "Take Control of Your Money",
                subtitle: "Track expenses and understand where your money goes",
                systemImageName: "chart.pie.fill",
                gradient: [
                    Color(red: 0.30, green: 0.63, blue: 0.83),
                    Color(red: 0.39, green: 0.40, blue: 0.74)
                ]
            ),
            OnboardingPage(
                title: "Smart Budgeting",
                subtitle: "Plan monthly spending and stay on track",
                systemImageName: "calendar.badge.clock",
                gradient: [
                    Color(red: 0.47, green: 0.67, blue: 0.93),
                    Color(red: 0.99, green: 0.76, blue: 0.47)
                ]
            ),
            OnboardingPage(
                title: "Reach Your Goals",
                subtitle: "Save money for things that matter",
                systemImageName: "target",
                gradient: [
                    Color(red: 0.55, green: 0.54, blue: 0.96),
                    Color(red: 0.30, green: 0.74, blue: 0.57)
                ]
            )
        ]
    }

    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }

    func goToNextPage() {
        guard currentPageIndex < pages.count - 1 else {
            finish()
            return
        }
        currentPageIndex += 1
    }

    func skip() {
        finish()
    }

    func finish() {
        var settings = settingsService.load()
        settings.hasCompletedOnboarding = true
        settingsService.save(settings)
        completed = true
    }
}

