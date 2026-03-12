import SwiftUI
import Charts

struct CashflowChartView: View {
    let data: [CashflowPoint]

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Income vs Expenses")
                .font(typography.subtitle)
                .foregroundStyle(colors.textSecondary)

            Chart {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Expenses", point.expensesDouble)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                colors.warning.opacity(0.4),
                                colors.warning.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Expenses", point.expensesDouble)
                    )
                    .foregroundStyle(colors.warning)
                    .lineStyle(.init(lineWidth: 2.0, lineCap: .round))

                    LineMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Income", point.incomeDouble)
                    )
                    .foregroundStyle(colors.success)
                    .lineStyle(.init(lineWidth: 2.0, lineCap: .round))

                    PointMark(
                        x: .value("Period", point.periodLabel),
                        y: .value("Income", point.incomeDouble)
                    )
                    .foregroundStyle(colors.success)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colors.card)
            )
        }
    }
}

#Preview {
    let sample = [
        CashflowPoint(periodLabel: "Mon", income: 200, expenses: 120),
        CashflowPoint(periodLabel: "Tue", income: 140, expenses: 160),
        CashflowPoint(periodLabel: "Wed", income: 180, expenses: 90)
    ]
    return CashflowChartView(data: sample)
}

