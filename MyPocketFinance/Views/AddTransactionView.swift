import SwiftUI

private enum TransactionFormType: String, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

private struct TransactionCategoryItem: Identifiable, Hashable {
    let category: Transaction.Category
    let systemImage: String
    let color: Color

    var id: Transaction.Category { category }

    static func all(using colors: AppColors) -> [TransactionCategoryItem] {
        [
            .init(category: .food,           systemImage: "fork.knife",        color: colors.accent),
            .init(category: .transportation, systemImage: "car.fill",          color: colors.primary),
            .init(category: .entertainment,  systemImage: "gamecontroller.fill", color: colors.secondary),
            .init(category: .housing,        systemImage: "house.fill",        color: colors.secondary),
            .init(category: .utilities,      systemImage: "bolt.fill",         color: colors.accent),
            .init(category: .savings,        systemImage: "banknote.fill",     color: colors.success),
            .init(category: .healthcare,     systemImage: "cross.case.fill",   color: colors.warning),
            .init(category: .other,          systemImage: "ellipsis.circle.fill", color: colors.textSecondary)
        ]
    }
}

struct AddTransactionView: View {
    let existingTransaction: Transaction?
    let onSave: (Transaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColors) private var colors
    @Environment(\.appTypography) private var typography
    @Environment(\.appSpacing) private var spacing
    @Environment(\.appCornerRadius) private var cornerRadius

    @State private var formType: TransactionFormType
    @State private var amountText: String
    @State private var selectedCurrency: Transaction.Currency
    @State private var selectedCategoryItem: TransactionCategoryItem?
    @State private var date: Date
    @State private var note: String
    @State private var errorMessage: String?

    private var amountDecimal: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        if let value = amountDecimal, value > 0, selectedCategoryItem != nil {
            return true
        }
        return false
    }

    init(existingTransaction: Transaction? = nil, onSave: @escaping (Transaction) -> Void = { _ in }) {
        self.existingTransaction = existingTransaction
        self.onSave = onSave

        if let transaction = existingTransaction {
            _formType = State(initialValue: transaction.type == .income ? .income : .expense)
            _amountText = State(initialValue: NSDecimalNumber(decimal: transaction.amount).stringValue)
            _selectedCurrency = State(initialValue: transaction.currency)
            _selectedCategoryItem = State(initialValue: TransactionCategoryItem(category: transaction.category, systemImage: "", color: .clear))
            _date = State(initialValue: transaction.date)
            _note = State(initialValue: transaction.note ?? "")
        } else {
            _formType = State(initialValue: .expense)
            _amountText = State(initialValue: "")
            _selectedCurrency = State(initialValue: .usd)
            _selectedCategoryItem = State(initialValue: nil)
            _date = State(initialValue: .now)
            _note = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: spacing.l) {
                    typeSection
                    amountSection
                    notesSection
                    categorySection
                    dateSection
                }
                .padding(.horizontal, spacing.l)
                .padding(.top, spacing.xl)
                .padding(.bottom, spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(colors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationTitle(existingTransaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(colors.textSecondary)
                }
            }
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Transaction Type")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)
            
            HStack(spacing: spacing.s) {
                transactionTypeChip(for: .expense, icon: "arrow.up.right.circle.fill", color: colors.warning)
                transactionTypeChip(for: .income, icon: "arrow.down.left.circle.fill", color: colors.success)
            }
        }
    }

    private func transactionTypeChip(
        for type: TransactionFormType,
        icon: String,
        color: Color
    ) -> some View {
        let isSelected = formType == type

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                formType = type
            }
        } label: {
            HStack(spacing: spacing.s) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.24 : 0.14))
                        .frame(width: 30, height: 30)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                }

                Text(type.displayName)
                    .font(typography.body.weight(.semibold))

                Spacer()
            }
            .padding(.vertical, spacing.s)
            .padding(.horizontal, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(isSelected ? colors.card : colors.card.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .strokeBorder(isSelected ? color : colors.subtleBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? color.opacity(0.18) : .clear,
                radius: 10, x: 0, y: 4
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Amount")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            HStack(spacing: spacing.s) {
                Text(formType == .expense ? "-" : "+")
                    .font(typography.title)
                    .foregroundStyle(formType == .expense ? colors.warning : colors.success)

                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(typography.title)
                    .foregroundStyle(colors.textPrimary)
                    .onChange(of: amountText, initial: false) { _, newValue in
                        let allowed = "0123456789.,"
                        var filtered = newValue.filter { allowed.contains($0) }

                        let separators: [Character] = [".", ","]
                        for separator in separators {
                            let parts = filtered.split(separator: separator, omittingEmptySubsequences: false)
                            if parts.count > 2 {
                                let first = parts.prefix(2).joined(separator: String(separator))
                                filtered = first
                            }
                        }

                        if filtered != newValue {
                            amountText = filtered
                        }

                        if errorMessage != nil {
                            errorMessage = nil
                        }
                    }

                Spacer(minLength: spacing.s)

                HStack(spacing: 0) {
                    currencyChip(for: .usd)
                    currencyChip(for: .eur)
                }
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
        }
    }

    private func currencyChip(for value: Transaction.Currency) -> some View {
        let isSelected = selectedCurrency == value

        return Button {
            guard !isSelected else { return }
            selectedCurrency = value
        } label: {
            Text(value.rawValue)
                .font(typography.caption.weight(.medium))
                .frame(width: 52)
                .padding(.vertical, spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius.s, style: .continuous)
                        .fill(isSelected ? colors.accent : colors.controlInactiveFill)
                )
                .foregroundStyle(isSelected ? colors.onAccent : colors.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Category")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            CategorySelectorView(
                categories: TransactionCategoryItem.all(using: colors),
                selectedCategory: $selectedCategoryItem,
                title: { $0.category.displayName },
                icon: { item in (item.systemImage, item.color) }
            )
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Date")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            VStack(alignment: .center, spacing: spacing.m) {
                HStack(spacing: spacing.s) {
                    Spacer(minLength: 0)

                    ZStack {
                        Circle()
                            .fill(colors.accent.opacity(0.18))
                            .frame(width: 28, height: 28)

                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(colors.accent)
                    }

                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: spacing.s) {
            Text("Notes")
                .font(typography.caption)
                .foregroundStyle(colors.textSecondary)

            HStack(alignment: .top, spacing: spacing.s) {
                ZStack {
                    Circle()
                        .fill(colors.accent.opacity(0.18))
                        .frame(width: 28, height: 28)

                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(colors.accent)
                }

                TextField("Add a short note (e.g. \"Birthday dinner\")", text: $note, axis: .vertical)
                    .lineLimit(1...4)
                    .font(typography.body)
            }
            .padding(.horizontal, spacing.m)
            .padding(.vertical, spacing.m)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius.l, style: .continuous)
                    .fill(colors.card)
            )
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(colors.subtleBorder.opacity(0.55))
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            VStack(spacing: spacing.s) {
                if let error = errorMessage {
                    Text(error)
                        .font(typography.caption)
                        .foregroundStyle(colors.warning)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, spacing.m)
                }

                PrimaryButton(title: "Save") {
                    save()
                }
                .opacity(canSave ? 1 : 0.5)
                .disabled(!canSave)
            }
            .padding(.horizontal, spacing.l)
            .padding(.top, spacing.m)
            .padding(.bottom, spacing.l)
        }
        .frame(maxWidth: .infinity)
        .background {
            colors.background
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -6)
        }
    }

    private func save() {
        guard let amount = amountDecimal else {
            errorMessage = "Please enter a valid amount."
            return
        }
        guard let selected = selectedCategoryItem else {
            errorMessage = "Please select a category."
            return
        }

        errorMessage = nil

        let kind: Transaction.Kind = (formType == .income) ? .income : .expense

        let transaction = Transaction(
            id: existingTransaction?.id ?? UUID(),
            date: date,
            amount: amount,
            currency: selectedCurrency,
            category: selected.category,
            type: kind,
            note: note.isEmpty ? nil : note
        )

        onSave(transaction)

        dismiss()
    }
}

#Preview {
    AddTransactionView()
}

