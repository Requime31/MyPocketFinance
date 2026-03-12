import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String

    var primaryActionTitle: String? = nil
    var primaryAction: (() -> Void)? = nil

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    var body: some View {
        VStack(spacing: spacing.l) {
            icon

            VStack(spacing: spacing.s) {
                Text(title)
                    .font(typography.title)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(colors.textPrimary)

                Text(message)
                    .font(typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(colors.textSecondary)
            }
            .padding(.horizontal, spacing.l)

            if let primaryActionTitle, let primaryAction {
                PrimaryButton(
                    title: primaryActionTitle,
                    action: primaryAction,
                    leadingSymbol: "plus"
                )
                .frame(maxWidth: 260)
            }
        }
        .padding(spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                .fill(colors.card)
                .shadow(color: colors.subtleBorder.opacity(1.2), radius: 10, x: 0, y: 4)
        )
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(colors.background)
                .frame(width: 74, height: 74)
                .shadow(color: colors.subtleBorder, radius: 14, x: 0, y: 10)

            Circle()
                .strokeBorder(colors.subtleBorder, lineWidth: 1)
                .frame(width: 74, height: 74)

            Image(systemName: iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(colors.secondary)
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.03, green: 0.05, blue: 0.11).ignoresSafeArea()

        EmptyStateView(
            iconName: "tray",
            title: "No transactions yet",
            message: "Once you start adding transactions, you'll see your insights and trends here.",
            primaryActionTitle: "Add first transaction",
            primaryAction: {}
        )
        .padding(24)
    }
}

