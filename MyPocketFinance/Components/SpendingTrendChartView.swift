import SwiftUI
import Charts

struct SpendingTrendChartView: View {
    let data: [SpendingTrendPoint]
    let selectedFilter: ReportsTimeFilter
    let currencyCode: String

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending Trend")
                        .font(typography.title)
                        .foregroundStyle(colors.textPrimary)

                    Text(subtitle)
                        .font(typography.caption)
                        .foregroundStyle(colors.textSecondary)
                }
                Spacer()
            }

            if data.isEmpty {
                Text("You don't have any expenses for this period yet.")
                    .font(typography.body)
                    .foregroundStyle(colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Chart(data) { point in
                    AreaMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Amount", point.amountDouble)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                colors.primary.opacity(0.3),
                                colors.secondary.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Amount", point.amountDouble)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors.primaryGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Amount", point.amountDouble)
                    )
                    .symbolSize(40)
                    .foregroundStyle(colors.card)
                    .annotation(position: .top) {
                        Text(point.amountDouble.appCurrencyString(code: currencyCode))
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: data)
            }
        }
        .padding(spacing.l)
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 320)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.xl, style: .continuous)
                .fill(colors.card)
                .shadow(color: colors.subtleBorder, radius: 20, x: 0, y: 10)
        )
    }

    private var subtitle: String {
        switch selectedFilter {
        case .week:
            return "Daily spending over the last 7 days"
        case .month:
            return "Daily spending this month"
        case .year:
            return "Monthly spending this year"
        }
    }
}

#Preview {
    SpendingTrendChartView(
        data: [
            SpendingTrendPoint(periodLabel: "Jan", amount: 120),
            SpendingTrendPoint(periodLabel: "Feb", amount: 80),
            SpendingTrendPoint(periodLabel: "Mar", amount: 200)
        ],
        selectedFilter: .year,
        currencyCode: "USD"
    )
}

