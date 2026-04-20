import SwiftUI
import Charts

struct CategoryChartView: View {
    let data: [CategorySpending]
    let currencyCode: String

    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text("Spending by Category")
                .font(typography.title)
                .foregroundStyle(colors.textPrimary)

            if data.isEmpty {
                Text("No expenses for this period yet.")
                    .font(typography.body)
                    .foregroundStyle(colors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Amount", item.amountDouble),
                        y: .value("Category", item.category.displayName)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: colors.primaryGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .annotation(position: .trailing, alignment: .center) {
                        Text(item.amountDouble.appCurrencyString(code: currencyCode))
                            .font(typography.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                }
                .chartXAxis(.hidden)
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
}

#Preview {
    CategoryChartView(
        data: [
            CategorySpending(category: .food, amount: 120),
            CategorySpending(category: .transportation, amount: 80),
            CategorySpending(category: .entertainment, amount: 60)
        ],
        currencyCode: "USD"
    )
}

