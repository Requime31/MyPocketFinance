import SwiftUI
import PhotosUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingFAQ: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.l) {
                    profileSection
                    themeSection
                    notificationsSection
                    faqSection
                    exportSection
                    languageSection
                    aboutSection
                }
                .padding(spacing.l)
            }
            .background(colors.background.ignoresSafeArea())
            .navigationDestination(isPresented: $isShowingFAQ) {
                FAQView()
            }
        }
    }


    private var profileSection: some View {
        sectionContainer(title: "Profile") {
            HStack(spacing: spacing.m) {
                profileImageView

                VStack(alignment: .leading, spacing: 4) {
                    TextField(
                        "Enter name",
                        text: Binding(
                            get: { settingsViewModel.settings.username },
                            set: { settingsViewModel.updateUsername($0) }
                        )
                    )
                    .font(typography.subtitle)
                    .foregroundStyle(colors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)

                    Text("This name is used across insights and reports.")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if
                        let data = settingsViewModel.settings.profileImageData,
                        let image = UIImage(data: data)
                    {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(colors.primary)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())

                Circle()
                    .fill(colors.card)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(colors.accent)
                    )
                    .offset(x: 4, y: 4)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        settingsViewModel.updateProfileImage(data)
                    }
                }
            }
        }
    }

    private var themeSection: some View {
        sectionContainer(title: "Theme") {
            SettingsRowView(
                iconName: "moon.circle.fill",
                iconColor: colors.secondary,
                title: "Appearance",
                subtitle: "Match system, light, or dark"
            , accessory: {
                Picker(
                    "",
                    selection: Binding(
                        get: { themeManager.mode },
                        set: { newValue in
                            themeManager.setMode(newValue)
                        }
                    )
                ) {
                    Image(systemName: "circle.lefthalf.filled")
                        .symbolRenderingMode(.hierarchical)
                        .tag(AppThemeMode.system)
                        .accessibilityLabel("System")

                    Image(systemName: "sun.max.fill")
                        .symbolRenderingMode(.hierarchical)
                        .tag(AppThemeMode.light)
                        .accessibilityLabel("Light")

                    Image(systemName: "moon.fill")
                        .symbolRenderingMode(.hierarchical)
                        .tag(AppThemeMode.dark)
                        .accessibilityLabel("Dark")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            })
        }
    }

    private var languageSection: some View {
        sectionContainer(title: "Language") {
            SettingsRowView(
                iconName: "globe",
                iconColor: colors.primary,
                title: "App language",
                subtitle: "English only (for now)"
            , accessory: {
                HStack(spacing: 4) {
                    Text("English")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(colors.textSecondary.opacity(0.8))
                }
            })
        }
    }

    private var notificationsSection: some View {
        sectionContainer(title: "Notifications") {
            SettingsRowView(
                iconName: "bell.badge.fill",
                iconColor: colors.accent,
                title: "Enable reminders",
                subtitle: "Get nudges to track spending"
            , accessory: {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settingsViewModel.settings.enableNotifications },
                        set: { settingsViewModel.setNotificationsEnabled($0) }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(colors.accent)
            })

            if settingsViewModel.settings.enableNotifications {
                Divider()
                    .padding(.leading, spacing.xl)

                SettingsRowView(
                    iconName: "clock",
                    iconColor: colors.secondary,
                    title: "Reminder time",
                    subtitle: "When to remind you"
                , accessory: {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { settingsViewModel.settings.notificationTime },
                            set: { settingsViewModel.updateNotificationTime($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_GB"))
                })
            }

            Divider()
                .padding(.leading, spacing.xl)

            SettingsRowView(
                iconName: "calendar",
                iconColor: colors.primary,
                title: "Weekly summary",
                subtitle: "Overview of your week"
            , accessory: {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settingsViewModel.settings.showWeeklySummary },
                        set: { _ in settingsViewModel.toggleWeeklySummary() }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(colors.accent)
            })
        }
    }

    private var faqSection: some View {
        sectionContainer(title: "Help & FAQ") {
            SettingsRowView(
                iconName: "questionmark.circle.fill",
                iconColor: colors.secondary,
                title: "Frequently asked questions",
                subtitle: "Tips, best practices, and troubleshooting",
                onTap: {
                    isShowingFAQ = true
                }
            , accessory: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })

            Divider()
                .padding(.leading, spacing.xl)

            SettingsRowView(
                iconName: "envelope.fill",
                iconColor: colors.accent,
                title: "Contact support",
                subtitle: "We usually respond within 24 hours",
                onTap: {
                    openSupportEmail()
                }
            , accessory: {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })
        }
    }

    private var exportSection: some View {
        sectionContainer(title: "Export data") {
            SettingsRowView(
                iconName: "arrow.down.doc.fill",
                iconColor: colors.primary,
                title: "Export transactions",
                subtitle: "CSV export (coming soon)",
                onTap: {
                }
            , accessory: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })
        }
    }

    private var aboutSection: some View {
        sectionContainer(title: "About") {
            SettingsRowView(
                iconName: "info.circle.fill",
                iconColor: colors.secondary,
                title: "MyPocketFinance",
                subtitle: "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
            , accessory: {
                EmptyView()
            })

            Divider()
                .padding(.leading, spacing.xl)

            SettingsRowView(
                iconName: "star.fill",
                iconColor: colors.accent,
                title: "Rate MyPocketFinance",
                subtitle: "Enjoying the app? Share your review on the App Store.",
                onTap: {
                    requestAppReview()
                }
            , accessory: {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })

            Divider()
                .padding(.leading, spacing.xl)

            SettingsRowView(
                iconName: "lock.shield.fill",
                iconColor: colors.primary,
                title: "Privacy Policy",
                subtitle: "How we handle your data",
                onTap: {
                    openURL("https://example.com/privacy")
                }
            , accessory: {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })

            SettingsRowView(
                iconName: "doc.text.fill",
                iconColor: colors.secondary,
                title: "Terms of Use",
                subtitle: "Important information about using the app",
                onTap: {
                    openURL("https://example.com/terms")
                }
            , accessory: {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(colors.textSecondary)
            })

            Divider()
                .padding(.leading, spacing.xl)

            VStack(alignment: .leading, spacing: 2) {
                Text("Created for educational purposes.")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
                Text("Not intended for real financial advice.")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary.opacity(0.9))
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
        }
    }


    private func sectionContainer<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text(title.uppercased())
                .font(typography.caption.weight(.semibold))
                .foregroundStyle(colors.textSecondary.opacity(0.9))

            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(colors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius.l,
                    style: .continuous
                )
            )
            .shadow(
                color: colors.subtleBorder.opacity(0.9),
                radius: 14,
                x: 0,
                y: 8
            )
        }
    }

    private func openSupportEmail() {
        let email = "support@mypocketfinance.app"
        let subject = "MyPocketFinance Support"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let urlString = "mailto:\(email)?subject=\(encodedSubject)"

        guard let url = URL(string: urlString) else { return }

        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }

    private func requestAppReview() {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
        #endif
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}

