import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct MyPocketFinanceApp: App {
    @StateObject private var themeManager = ThemeManager()

    init() {
        #if os(iOS)
        UIWindow.appearance().backgroundColor = ThemeManager.launchWindowBackgroundUIColor()
        #endif
        Task {
            try? await FrankfurterRates.fetchUSDToEURRow()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environment(\.appColors, themeManager.colors)
                .environment(\.appTypography, themeManager.typography)
                .environment(\.appSpacing, themeManager.spacing)
                .environment(\.appCornerRadius, themeManager.cornerRadius)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
