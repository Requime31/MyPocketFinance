import SwiftUI

struct SettingsRowView<Accessory: View>: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let isDestructive: Bool
    let onTap: (() -> Void)?
    @ViewBuilder let accessory: () -> Accessory

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    init(
        iconName: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.onTap = onTap
        self.accessory = accessory
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius.m, style: .continuous)
                        .fill(iconColor.opacity(0.12))

                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(typography.body)
                        .foregroundStyle(isDestructive ? Color.red : colors.textPrimary)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }

                Spacer(minLength: spacing.s)

                accessory()
            }
            .contentShape(Rectangle())
            .padding(.vertical, spacing.s)
            .padding(.horizontal, spacing.m)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        SettingsRowView(
            iconName: "person.crop.circle",
            iconColor: .blue,
            title: "Username",
            subtitle: "How your name appears",
            accessory: {
                Text("Roman")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        )

        SettingsRowView(
            iconName: "moon.circle.fill",
            iconColor: .purple,
            title: "Dark Mode",
            subtitle: "Match your environment",
            accessory: {
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
            }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

