import SwiftUI

struct GoalsStatisticsView: View {
    let statistics: GoalsOverviewStatistics
    let currencyCode: String

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack(spacing: spacing.m) {
                statCard(
                    title: "Saved in goals",
                    value: statistics.totalCurrentAmount
                )

                statCard(
                    title: "All targets",
                    value: statistics.totalTargetAmount
                )
            }

            progressBar

            statusChips
        }
    }

    private func statCard(title: String, value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            Text(title)
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            Text(value.appCurrencyString(code: currencyCode))
                .font(typography.subtitle)
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colors.card)
        )
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: spacing.xs) {
            Text("Average progress")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            GeometryReader { proxy in
                let width = proxy.size.width
                let fraction = max(0, min(1, statistics.averageProgress))

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(colors.subtleBorder.opacity(0.6))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            LinearGradient(
                                colors: [colors.accent, colors.accent.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * fraction, height: 8)
                }
            }
            .frame(height: 10)
        }
    }

    private var statusChips: some View {
        let allStatuses = GoalStatus.allCases

        return HStack(spacing: spacing.s) {
            ForEach(allStatuses, id: \.self) { status in
                let count = statistics.statusCounts[status] ?? 0

                HStack(spacing: spacing.xs) {
                    Circle()
                        .fill(color(for: status))
                        .frame(width: 6, height: 6)

                    Text(label(for: status))
                        .font(typography.caption)
                        .foregroundStyle(colors.textPrimary)

                    Text("\(count)")
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.horizontal, spacing.m)
                .padding(.vertical, spacing.xs)
                .background(
                    Capsule(style: .continuous)
                        .fill(colors.card)
                )
            }
        }
    }

    private func label(for status: GoalStatus) -> String {
        switch status {
        case .active:
            return "Active"
        case .nearlyAchieved:
            return "Nearly"
        case .completed:
            return "Completed"
        }
    }

    private func color(for status: GoalStatus) -> Color {
        switch status {
        case .active:
            return colors.accent
        case .nearlyAchieved:
            return colors.warning
        case .completed:
            return colors.success
        }
    }
}

#Preview {
    let stats = GoalsOverviewStatistics(
        totalTargetAmount: 5000,
        totalCurrentAmount: 2500,
        averageProgress: 0.5,
        statusCounts: [.active: 2, .nearlyAchieved: 1, .completed: 1],
        categoryTotals: [:]
    )
    return GoalsStatisticsView(statistics: stats, currencyCode: Transaction.Currency.usd.rawValue)
}

