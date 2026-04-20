import SwiftUI

private enum AppFlowPhase {
    case launch
    case onboarding
    case main
}

struct RootView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var phase: AppFlowPhase = .launch

    var body: some View {
        ZStack {
            themeManager.colors.background
                .ignoresSafeArea()

            switch phase {
            case .launch:
                LoadingView()
                    .transition(.opacity.combined(with: .scale))

            case .onboarding:
                OnboardingView {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                        settingsViewModel.settings.hasCompletedOnboarding = true
                        phase = .main
                    }

                    NotificationService.shared.requestAuthorization { granted in
                        guard granted else { return }
                        NotificationService.shared.applySettings(self.settingsViewModel.settings)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .main:
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .environmentObject(settingsViewModel)
        .onAppear {
            themeManager.updateSystemColorScheme(colorScheme)

            guard phase == .launch else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let hasCompletedOnboarding = settingsViewModel.settings.hasCompletedOnboarding

                withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                    phase = hasCompletedOnboarding ? .main : .onboarding
                }
            }
        }
        .onChange(of: colorScheme) { _, newValue in
            themeManager.updateSystemColorScheme(newValue)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(ThemeManager())
}

