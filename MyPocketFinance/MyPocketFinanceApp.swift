
import SwiftUI

@main
struct MyPocketFinanceApp: App {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environment(\.appColors, themeManager.colors)
                .environment(\.appTypography, themeManager.typography)
                .environment(\.appSpacing, themeManager.spacing)
                .environment(\.appCornerRadius, themeManager.cornerRadius)
                .onAppear {
                    themeManager.updateSystemColorScheme(systemColorScheme)
                }
                .onChange(of: systemColorScheme) { _, newValue in
                    themeManager.updateSystemColorScheme(newValue)
                }
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
    }
}
