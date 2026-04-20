import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.xl) {
                periodSelector
                summarySection
                insightsSection
                expensesSection
                cashflowSection
                goalsSection
            }
            .padding(.horizontal, spacing.l)
            .padding(.vertical, spacing.xl)
        }
        .background(colors.background.ignoresSafeArea())
        .onAppear {
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsDidChange)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalsDidChange)) { _ in
            viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userSettingsDidChange)) { _ in
            viewModel.load()
        }
    }

    private var periodSelector: some View {
        HStack(spacing: spacing.s) {
            ForEach(ReportsTimeFilter.allCases) { filter in
                periodChip(for: filter)
            }
        }
    }

    private func periodChip(for filter: ReportsTimeFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter

        return Button {
            guard !isSelected else { return }
            viewModel.selectedFilter = filter
        } label: {
            HStack(spacing: 6) {
                Text(filter.title)
                    .font(typography.caption.weight(.medium))
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                        ? colors.accent.opacity(0.18)
                        : colors.card
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        isSelected ? colors.accent : colors.subtleBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Overview")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            if let summary = viewModel.summary {
                HStack(spacing: spacing.m) {
                    summaryCard(
                        title: "Income",
                        value: summary.totalIncome
                    )

                    summaryCard(
                        title: "Expenses",
                        value: summary.totalExpenses
                    )

                    summaryCard(
                        title: "Net",
                        value: summary.netBalance
                    )
                }

                if let rate = viewModel.savingsRate {
                    savingsRateView(rate: rate)
                }

                if let comparison = summary.comparison {
                    let sign = comparison.isIncrease ? "+" : "−"
                    let text = comparison.isIncrease
                        ? "Spending is \(sign)\(Int(comparison.percentageChange))% vs previous period"
                        : "Spending is \(sign)\(Int(comparison.percentageChange))% vs previous period"

                    Text(text)
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)
                        .padding(.top, spacing.s)
                }
            } else {
                Text("Not enough data yet for this period.")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
        }
    }

    private func savingsRateView(rate: Double) -> some View {
        let clamped = max(0, min(1, rate))
        let percent = Int(clamped * 100)

        return VStack(alignment: .leading, spacing: spacing.xs) {
            HStack(spacing: spacing.s) {
                Text("Savings rate")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)

                Text("\(percent)%")
                    .font(typography.caption.weight(.semibold))
                    .foregroundStyle(colors.success)
                    .padding(.horizontal, spacing.s)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colors.card)
                    )
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(colors.subtleBorder.opacity(0.7))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            LinearGradient(
                                colors: [colors.success, colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * CGFloat(clamped), height: 6)
                }
            }
            .frame(height: 8)
        }
    }

    private func summaryCard(title: String, value: Decimal) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: spacing.xs) {
                Text(title)
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)

                Text(value.appCurrencyString(code: viewModel.displayCurrencyCode))
                    .font(typography.subtitle)
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            if viewModel.insights.isEmpty {
                EmptyView()
            } else {
                Text("Insights")
                    .font(typography.title)
                    .foregroundStyle(colors.textPrimary)

                VStack(spacing: spacing.s) {
                    ForEach(viewModel.insights) { insight in
                        HStack(alignment: .top, spacing: spacing.m) {
                            ZStack {
                                Circle()
                                    .fill(colors.accent.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: insight.systemImageName)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(colors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title)
                                    .font(typography.subtitle)
                                    .foregroundStyle(colors.textPrimary)

                                Text(insight.subtitle)
                                    .font(typography.caption)
                                    .foregroundStyle(colors.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                                .fill(colors.card)
                                .shadow(color: colors.subtleBorder.opacity(0.5), radius: 10, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Spending")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            CategoryChartView(
                data: viewModel.categorySpending,
                currencyCode: viewModel.displayCurrencyCode
            )

            SpendingTrendChartView(
                data: viewModel.spendingTrend,
                selectedFilter: viewModel.selectedFilter,
                currencyCode: viewModel.displayCurrencyCode
            )
        }
    }

    private var cashflowSection: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Cashflow")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            if viewModel.cashflowTrend.isEmpty {
                Text("No cashflow data for this period yet.")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            } else {
                CashflowChartView(data: viewModel.cashflowTrend)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Goals")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            if let stats = viewModel.goalsStatistics {
                GoalsStatisticsView(
                    statistics: stats,
                    currencyCode: viewModel.displayCurrencyCode
                )
                if viewModel.contributionsThisPeriod > 0 {
                    HStack(spacing: spacing.xs) {
                        Text("Contributions this period:")
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)

                        Text(viewModel.contributionsThisPeriod.appCurrencyString(code: viewModel.displayCurrencyCode))
                            .font(typography.caption.weight(.semibold))
                            .foregroundStyle(colors.textPrimary)
                    }
                }
            } else {
                Text("Create your first goal to see statistics here.")
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
        }
    }
}

#Preview {
    ReportsView()
}

