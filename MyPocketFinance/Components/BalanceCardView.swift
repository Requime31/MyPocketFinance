import SwiftUI

struct BalanceCardView: View {
    let totalBalance: Decimal
    let income: Decimal
    let expenses: Decimal
    let currencyCode: String
    let currency: Transaction.Currency
    let onCurrencyChange: (Transaction.Currency) -> Void

    init(
        totalBalance: Decimal,
        income: Decimal,
        expenses: Decimal,
        currencyCode: String = "USD",
        currency: Transaction.Currency = .usd,
        onCurrencyChange: @escaping (Transaction.Currency) -> Void = { _ in }
    ) {
        self.totalBalance = totalBalance
        self.income = income
        self.expenses = expenses
        self.currencyCode = currencyCode
        self.currency = currency
        self.onCurrencyChange = onCurrencyChange
    }
    
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: spacing.xs) {
                    Text("Total balance".uppercased())
                        .font(typography.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.horizontal, spacing.s)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())
                    
                    Text(formattedAmount(totalBalance))
                        .font(typography.largeTitle)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .monospacedDigit()
                }
                
                Spacer()

                currencyToggle
            }
            
            HStack(spacing: spacing.m) {
                summaryPill(
                    title: "Income",
                    value: income,
                    color: colors.success
                )
                
                summaryPill(
                    title: "Expenses",
                    value: expenses,
                    color: colors.warning
                )
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
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.xl,
                style: .continuous
            )
        )
        .shadow(color: colors.primary.opacity(0.22), radius: 20, x: 0, y: 14)
    }

    private var currencyToggle: some View {
        HStack(spacing: 4) {
            currencyChip(for: .usd)
            currencyChip(for: .eur)
        }
    }

    private func currencyChip(for value: Transaction.Currency) -> some View {
        let isSelected = value == currency

        return Button {
            guard !isSelected else { return }
            onCurrencyChange(value)
        } label: {
            Text(value.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, spacing.s)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.white.opacity(isSelected ? 0.9 : 0.4),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
    
    private func summaryPill(title: String, value: Decimal, color: Color) -> some View {
        HStack(spacing: spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(typography.caption)
                    .foregroundStyle(.white.opacity(0.75))
                
                Text(formattedAmount(value))
                    .font(typography.subtitle)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, spacing.s)
        .padding(.horizontal, spacing.m)
        .background(.white.opacity(0.08))
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

        // Avoid showing currency code like "USD"/"EUR"
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

