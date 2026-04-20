import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif


struct AppColors {
    let primary: Color
    let secondary: Color
    let accent: Color

    let background: Color
    let card: Color

    let success: Color
    let warning: Color

    let textPrimary: Color
    let textSecondary: Color
    let subtleBorder: Color
    
    let onHero: Color
    let onHeroSecondary: Color
    let onHeroSubtleStroke: Color
    let onHeroSubtleFill: Color
    let onAccent: Color
    let controlInactiveFill: Color

    let primaryGradientColors: [Color]
    let accentGradientColors: [Color]
}

extension AppColors {
    static let light = AppColors(
        primary: Color(red: 0.30, green: 0.63, blue: 0.83),          // Soft cyan/blue (non-system)
        secondary: Color(red: 0.39, green: 0.40, blue: 0.74),        // Muted indigo
        accent: Color(red: 0.99, green: 0.76, blue: 0.47),           // Warm amber
        background: Color(red: 0.96, green: 0.97, blue: 1.00),       // Soft off-white with cool tint
        card: Color(red: 0.99, green: 0.99, blue: 1.00),             // Subtle elevated card
        success: Color(red: 0.30, green: 0.74, blue: 0.57),          // Muted green
        warning: Color(red: 0.96, green: 0.70, blue: 0.46),          // Soft orange
        textPrimary: Color(red: 0.07, green: 0.09, blue: 0.16),
        textSecondary: Color(red: 0.39, green: 0.43, blue: 0.55),
        subtleBorder: Color.black.opacity(0.06),
        onHero: Color.white,
        onHeroSecondary: Color.white.opacity(0.9),
        onHeroSubtleStroke: Color.white.opacity(0.12),
        onHeroSubtleFill: Color.white.opacity(0.16),
        onAccent: Color.white,
        controlInactiveFill: Color(red: 0.96, green: 0.97, blue: 1.00),
        primaryGradientColors: [
            Color(red: 0.30, green: 0.63, blue: 0.83),
            Color(red: 0.39, green: 0.40, blue: 0.74)
        ],
        accentGradientColors: [
            Color(red: 0.99, green: 0.76, blue: 0.47),
            Color(red: 0.96, green: 0.70, blue: 0.46)
        ]
    )

    static let dark = AppColors(
        primary: Color(red: 0.34, green: 0.60, blue: 0.90),          // More muted cyan/blue
        secondary: Color(red: 0.48, green: 0.49, blue: 0.86),        // Softer indigo
        accent: Color(red: 0.96, green: 0.78, blue: 0.56),           // Warmer but less bright
        background: Color(red: 0.06, green: 0.07, blue: 0.12),       // Deep but not pure black
        card: Color(red: 0.11, green: 0.13, blue: 0.19),             // Close to background for low contrast
        success: Color(red: 0.36, green: 0.78, blue: 0.62),
        warning: Color(red: 0.95, green: 0.72, blue: 0.54),
        textPrimary: Color(red: 0.93, green: 0.95, blue: 1.00),
        textSecondary: Color(red: 0.68, green: 0.72, blue: 0.86),
        subtleBorder: Color.white.opacity(0.03),
        onHero: Color.white,
        onHeroSecondary: Color.white.opacity(0.9),
        onHeroSubtleStroke: Color.white.opacity(0.12),
        onHeroSubtleFill: Color.white.opacity(0.16),
        onAccent: Color.white,
        controlInactiveFill: Color.white.opacity(0.10),
        primaryGradientColors: [
            Color(red: 0.22, green: 0.32, blue: 0.56),
            Color(red: 0.30, green: 0.42, blue: 0.68)
        ],
        accentGradientColors: [
            Color(red: 0.70, green: 0.52, blue: 0.88),
            Color(red: 0.46, green: 0.64, blue: 0.93)
        ]
    )
}

struct AppTypography {
    let largeTitle: Font
    let title: Font
    let subtitle: Font
    let body: Font
    let caption: Font

    static let `default` = AppTypography(
        largeTitle: .system(size: 34, weight: .bold, design: .rounded),
        title: .system(size: 24, weight: .semibold, design: .rounded),
        subtitle: .system(size: 17, weight: .medium, design: .rounded),
        body: .system(size: 15, weight: .regular, design: .rounded),
        caption: .system(size: 13, weight: .regular, design: .rounded)
    )
}

struct AppSpacing {
    let xs: CGFloat
    let s: CGFloat
    let m: CGFloat
    let l: CGFloat
    let xl: CGFloat

    static let standard = AppSpacing(
        xs: 4,
        s: 8,
        m: 12,
        l: 16,
        xl: 24
    )
}

struct AppCornerRadius {
    let s: CGFloat
    let m: CGFloat
    let l: CGFloat
    let xl: CGFloat

    static let standard = AppCornerRadius(
        s: 8,
        m: 12,
        l: 16,
        xl: 24
    )
}


enum AppThemeMode: String, CaseIterable {
    case system
    case light
    case dark
}

final class ThemeManager: ObservableObject {
    @Published private(set) var mode: AppThemeMode
    @Published private var systemColorScheme: ColorScheme

    private let settingsService: UserSettingsService

    init(settingsService: UserSettingsService = UserDefaultsSettingsService()) {
        self.settingsService = settingsService

        let storedSettings = settingsService.load()
        let storedMode = AppThemeMode(rawValue: storedSettings.preferredTheme) ?? .system
        self.mode = storedMode
        self.systemColorScheme = Self.systemColorSchemeFromCurrentTraits()
    }

    /// `UITraitCollection` matches the launch window more reliably than `Environment(\.colorScheme)` on `App`.
    private static func systemColorSchemeFromCurrentTraits() -> ColorScheme {
        #if os(iOS)
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark:
            return .dark
        case .light, .unspecified:
            fallthrough
        @unknown default:
            return .light
        }
        #else
        return .light
        #endif
    }
    
    
    func setMode(_ newMode: AppThemeMode) {
        guard newMode != mode else { return }
        mode = newMode
        
        var settings = settingsService.load()
        settings.preferredTheme = newMode.rawValue
        settingsService.save(settings)
    }
    
    func updateSystemColorScheme(_ colorScheme: ColorScheme) {
        guard systemColorScheme != colorScheme else { return }
        systemColorScheme = colorScheme
    }
    
    var colors: AppColors {
        let useDarkPalette: Bool
        
        switch mode {
        case .light:
            useDarkPalette = false
        case .dark:
            useDarkPalette = true
        case .system:
            useDarkPalette = (systemColorScheme == .dark)
        }
        
        return useDarkPalette ? .dark : .light
    }
    
    var typography: AppTypography {
        .default
    }
    
    var spacing: AppSpacing {
        .standard
    }
    
    var cornerRadius: AppCornerRadius {
        .standard
    }
    
    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    /// Same palette resolution as ``colors`` for freshly loaded settings (used before the first SwiftUI frame).
    static func resolvedColorsMatchingStoredPreferences() -> AppColors {
        let storedSettings = UserDefaultsSettingsService().load()
        let storedMode = AppThemeMode(rawValue: storedSettings.preferredTheme) ?? .system
        let systemColorScheme = systemColorSchemeFromCurrentTraits()
        let useDarkPalette: Bool
        switch storedMode {
        case .light:
            useDarkPalette = false
        case .dark:
            useDarkPalette = true
        case .system:
            useDarkPalette = (systemColorScheme == .dark)
        }
        return useDarkPalette ? .dark : .light
    }

    #if os(iOS)
    static func launchWindowBackgroundUIColor() -> UIColor {
        UIColor(resolvedColorsMatchingStoredPreferences().background)
    }
    #endif
}


private struct AppColorsKey: EnvironmentKey {
    static let defaultValue: AppColors = .light
}

private struct AppTypographyKey: EnvironmentKey {
    static let defaultValue: AppTypography = .default
}

private struct AppSpacingKey: EnvironmentKey {
    static let defaultValue: AppSpacing = .standard
}

private struct AppCornerRadiusKey: EnvironmentKey {
    static let defaultValue: AppCornerRadius = .standard
}
                            
extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }

    var appTypography: AppTypography {
        get { self[AppTypographyKey.self] }
        set { self[AppTypographyKey.self] = newValue }
    }

    var appSpacing: AppSpacing {
        get { self[AppSpacingKey.self] }
        set { self[AppSpacingKey.self] = newValue }
    }

    var appCornerRadius: AppCornerRadius {
        get { self[AppCornerRadiusKey.self] }
        set { self[AppCornerRadiusKey.self] = newValue }
    }
}
