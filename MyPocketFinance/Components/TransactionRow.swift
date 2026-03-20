import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius
    
    var body: some View {
        HStack(spacing: spacing.m) {
            icon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note ?? transaction.category.displayName)
                    .font(typography.body)
                    .foregroundStyle(colors.textPrimary)
                
                Text(transaction.date, style: .date)
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            
            Spacer()
            
            Text(amountString)
                .font(typography.subtitle)
                .foregroundStyle(transaction.type == .income ? colors.success : colors.warning)
        }
        .padding(spacing.m)
        .background(colors.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius.m,
                style: .continuous
            )
        )
        .shadow(color: colors.subtleBorder.opacity(0.8), radius: 12, x: 0, y: 6)
    }
    
    private var icon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            colors.primary.opacity(0.18),
                            colors.accent.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: iconName(for: transaction.category))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(colors.primary)
        }
        .frame(width: 36, height: 36)
    }
    
    private func iconName(for category: Transaction.Category) -> String {
        switch category {
        case .income:
            return "arrow.down.left.circle.fill"
        case .housing:
            return "house.fill"
        case .food:
            return "fork.knife"
        case .transportation:
            return "car.fill"
        case .entertainment:
            return "gamecontroller.fill"
        case .savings:
            return "banknote.fill"
        case .utilities:
            return "bolt.fill"
        case .healthcare:
            return "cross.case.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    private var amountString: String {
        let number = NSDecimalNumber(decimal: transaction.amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = ""
        formatter.currencySymbol = transaction.currency == .usd ? "$" : "€"
        let value = formatter.string(from: number) ?? "\(transaction.amount)"
        return transaction.type == .income ? "+\(value)" : "-\(value)"
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        TransactionRowView(transaction: transaction)
    }
}

#Preview {
    TransactionRowView(
        transaction: Transaction(
            amount: 45,
            category: .food,
            type: .expense,
            note: "Dinner"
        )
    )
    .padding(24)
}
    
