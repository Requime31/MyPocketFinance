import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let onUpdate: (Transaction) -> Void
    let onDelete: (Transaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var isPresentingEdit = false

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()

                VStack(spacing: spacing.l) {
                    headerCard
                    metaSection
                    Spacer()
                }
                .padding(spacing.l)
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        isPresentingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            AddTransactionView(existingTransaction: transaction) { updated in
                onUpdate(updated)
                isPresentingEdit = false
                dismiss()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: spacing.m) {
            Text(transaction.category.displayName)
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            Text(formattedAmount)
                .font(typography.largeTitle)
                .foregroundStyle(transaction.type == .income ? colors.success : colors.warning)
        }
        .padding(spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius.xl, style: .continuous)
                .fill(colors.card)
        )
        .shadow(color: colors.subtleBorder.opacity(0.8), radius: 18, x: 0, y: 10)
    }

    private var metaSection: some View {
        VStack(spacing: spacing.m) {
            if let note = transaction.note, !note.isEmpty {
                infoRow(
                    title: "Description",
                    value: note,
                    systemImage: "text.bubble.fill"
                )
            }

            infoRow(
                title: "Type",
                value: transaction.type == .income ? "Income" : "Expense",
                systemImage: transaction.type == .income ? "arrow.down.left.circle" : "arrow.up.right.circle"
            )

            infoRow(
                title: "Date",
                value: DateFormatter.localizedString(from: transaction.date, dateStyle: .medium, timeStyle: .short),
                systemImage: "calendar"
            )

            infoRow(
                title: "Currency",
                value: transaction.currency.rawValue,
                systemImage: "dollarsign.circle"
            )

            Button(role: .destructive) {
                onDelete(transaction)
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Transaction")
                        .font(typography.body.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, spacing.l)
        }
    }

    private func infoRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: spacing.m) {
            Image(systemName: systemImage)
                .foregroundStyle(colors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(typography.caption)
                    .foregroundStyle(colors.textSecondary)
                Text(value)
                    .font(typography.body)
                    .foregroundStyle(colors.textPrimary)
            }

            Spacer()
        }
        .padding(.vertical, spacing.s)
    }

    private var formattedAmount: String {
        let number = NSDecimalNumber(decimal: transaction.amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = ""
        formatter.currencySymbol = transaction.currency == .usd ? "$" : "€"
        let value = formatter.string(from: number) ?? "\(transaction.amount)"
        return transaction.type == .income ? "+\(value)" : "-\(value)"
    }
}

