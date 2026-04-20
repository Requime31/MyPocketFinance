import SwiftUI

struct BalanceCardView: View {
    let totalBalance: Decimal
    let income: Decimal
    let expenses: Decimal
    let currency: Transaction.Currency

    init(
        totalBalance: Decimal,
        income: Decimal,
        expenses: Decimal,
        currency: Transaction.Currency = .usd
    ) {
        self.totalBalance = totalBalance
        self.income = income
        self.expenses = expenses
        self.currency = currency
    }
    
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            VStack(alignment: .leading, spacing: spacing.xs) {
                Text("Total balance".uppercased())
                    .font(typography.caption.weight(.semibold))
                    .foregroundStyle(colors.onHeroSecondary)
                    .padding(.horizontal, spacing.s)
                    .padding(.vertical, 4)
                    .background(colors.onHeroSubtleFill)
                    .clipShape(Capsule())

                Text(formattedAmount(totalBalance))
                    .font(typography.largeTitle)
                    .foregroundStyle(colors.onHero)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .monospacedDigit()
            }

            HStack(spacing: spacing.m) {
                summaryPill(title: "Income", value: income)

                summaryPill(title: "Expenses", value: expenses)
            }
        }
        .padding(spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: colors.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius.xl, style: .continuous)
                .strokeBorder(colors.onHeroSubtleStroke, lineWidth: 1)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.xl,
                style: .continuous
            )
        )
        .shadow(color: colors.primary.opacity(0.22), radius: 20, x: 0, y: 14)
    }

    
    private func summaryPill(title: String, value: Decimal) -> some View {
        HStack(spacing: spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(typography.caption)
                    .foregroundStyle(colors.onHero.opacity(0.75))

                Text(formattedAmount(value))
                    .font(typography.subtitle)
                    .foregroundStyle(colors.onHero)
            }
        }
        .padding(.vertical, spacing.s)
        .padding(.horizontal, spacing.m)
        .background(colors.onHero.opacity(0.08))
        .clipShape(Capsule())
    }

    private func formattedAmount(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        switch currency {
        case .usd:
            formatter.currencySymbol = "$"
        case .eur:
            formatter.currencySymbol = "€"
        }

        formatter.currencyCode = ""

        return formatter.string(from: number) ?? "\(value)"
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        BalanceCardView(
            totalBalance: 2450,
            income: 3200,
            expenses: 750
        )
        .padding(24)
    }
}

